// ClipIt - AI Chatbot Local Bridge Background Service Worker
// Supports ChatGPT, Claude, Gemini, and Arena AI (Direct Chat)
// Manages WebSocket link to ClipIt desktop app (ws://127.0.0.1:28475),
// bidirectional message routing, queuing, and reliable delivery/display acknowledgments.

const WS_URL = 'ws://127.0.0.1:28475';
const SUPPORTED_URL_PATTERNS = [
  'https://chatgpt.com/*',
  'https://chat.openai.com/*',
  'https://claude.ai/*',
  'https://gemini.google.com/*',
  'https://lmarena.ai/*',
  'https://arena.lmsys.org/*'
];

let socket = null;
let isConnected = false;
let reconnectTimer = null;
let heartbeatTimer = null;
let manualDisconnect = false;
let isPowerEnabled = true;
let currentPromptId = null;
let currentPromptHandled = false;

// Pending acknowledgment callbacks: id -> { resolve, timer }
const pendingAcks = new Map();
// Outgoing message queue
const outgoingQueue = [];

function isSupportedUrl(url) {
  if (!url) return false;
  const u = url.toLowerCase();
  return u.includes('chatgpt.com') ||
         u.includes('chat.openai.com') ||
         u.includes('claude.ai') ||
         u.includes('gemini.google.com') ||
         u.includes('lmarena.ai') ||
         u.includes('arena.lmsys.org');
}

function getPlatformFromUrl(url) {
  if (!url) return 'ChatGPT';
  const u = url.toLowerCase();
  if (u.includes('claude.ai')) return 'Claude';
  if (u.includes('gemini.google.com')) return 'Gemini';
  if (u.includes('lmarena.ai') || u.includes('arena.lmsys.org')) return 'Arena AI';
  if (u.includes('chatgpt.com') || u.includes('openai.com')) return 'ChatGPT';
  return 'AI Chatbot';
}

function setExtensionStatus(status, details = '') {
  chrome.storage.local.set({ bridgeStatus: status, bridgeDetails: details });
  chrome.runtime.sendMessage({ action: 'STATUS_UPDATE', status, details }).catch(() => {});

  if (!isPowerEnabled) {
    chrome.action.setBadgeBackgroundColor({ color: '#374151' });
    chrome.action.setBadgeText({ text: 'OFF' });
    return;
  }

  if (status === 'connected') {
    chrome.action.setBadgeBackgroundColor({ color: '#10B981' });
    chrome.action.setBadgeText({ text: 'ON' });
  } else if (status === 'connecting') {
    chrome.action.setBadgeBackgroundColor({ color: '#F59E0B' });
    chrome.action.setBadgeText({ text: '...' });
  } else {
    chrome.action.setBadgeBackgroundColor({ color: '#6B7280' });
    chrome.action.setBadgeText({ text: '' });
  }
}

function startHeartbeat() {
  stopHeartbeat();
  heartbeatTimer = setInterval(async () => {
    try {
      await chrome.runtime.getPlatformInfo();
    } catch (_) {}

    if (socket && socket.readyState === WebSocket.OPEN) {
      try {
        socket.send(JSON.stringify({ type: 'PING', timestamp: Date.now() }));
      } catch (e) {
        console.warn('[ClipIt Bridge] Heartbeat send error:', e);
      }
    }
  }, 10000);
}

function stopHeartbeat() {
  if (heartbeatTimer) {
    clearInterval(heartbeatTimer);
    heartbeatTimer = null;
  }
}

function sendWs(payload) {
  if (socket && socket.readyState === WebSocket.OPEN) {
    try {
      socket.send(JSON.stringify(payload));
      return true;
    } catch (e) {
      console.warn('[ClipIt Bridge] sendWs error:', e);
    }
  }

  outgoingQueue.push(payload);
  if (isPowerEnabled && (!socket || socket.readyState === WebSocket.CLOSED)) {
    connectToClipIt();
  }
  return false;
}

function flushOutgoingWsQueue() {
  while (outgoingQueue.length > 0 && socket && socket.readyState === WebSocket.OPEN) {
    const item = outgoingQueue.shift();
    try {
      socket.send(JSON.stringify(item));
    } catch (e) {
      console.warn('[ClipIt Bridge] flush error:', e);
      outgoingQueue.unshift(item);
      break;
    }
  }
}

async function findTargetTab() {
  const tabs = await chrome.tabs.query({ url: SUPPORTED_URL_PATTERNS });
  if (tabs.length === 0) return null;

  // 1. Check if the currently active tab in last focused window is supported
  const activeTabs = tabs.filter(t => t.active);
  if (activeTabs.length > 0) {
    const focusedTab = activeTabs.find(t => t.lastFocusedWindow);
    if (focusedTab) return focusedTab;
    return activeTabs[0];
  }

  // 2. Return first available supported tab
  return tabs[0];
}

function connectToClipIt() {
  if (!isPowerEnabled) {
    console.log('[ClipIt Bridge] Bridge is powered OFF. Skipping connection.');
    setExtensionStatus('off', 'Bridge switched OFF');
    return;
  }

  if (socket && (socket.readyState === WebSocket.OPEN || socket.readyState === WebSocket.CONNECTING)) {
    return;
  }

  manualDisconnect = false;
  setExtensionStatus('connecting', 'Connecting to ClipIt desktop app on port 28475...');

  try {
    socket = new WebSocket(WS_URL);
  } catch (err) {
    setExtensionStatus('error', err.message);
    scheduleReconnect();
    return;
  }

  socket.onopen = async () => {
    isConnected = true;
    setExtensionStatus('connected', 'Connected to ClipIt desktop app');
    startHeartbeat();

    // Identify active AI tab platform
    const targetTab = await findTargetTab();
    const platform = targetTab ? getPlatformFromUrl(targetTab.url) : 'ChatGPT';
    const tabUrl = targetTab ? targetTab.url : 'https://chatgpt.com';

    // Handshake
    socket.send(JSON.stringify({
      type: 'HELLO',
      client: 'clipit-chrome-extension',
      version: '1.3.1',
      platform: platform,
      tabUrl: tabUrl
    }));

    flushOutgoingWsQueue();
  };

  socket.onmessage = async (event) => {
    try {
      const data = JSON.parse(event.data);

      if (data.type === 'WELCOME') {
        console.log('[ClipIt Bridge] Handshake acknowledged by ClipIt:', data);
      } else if (data.type === 'PING') {
        if (socket && socket.readyState === WebSocket.OPEN) {
          socket.send(JSON.stringify({ type: 'PONG' }));
        }
      } else if (data.type === 'PONG') {
        // Heartbeat acknowledged
      } else if (data.type === 'SEND_PROMPT') {
        await handleSendPrompt(data.prompt, data.id);
      } else if (data.type === 'ACK_RESPONSE') {
        handleClipItResponseAck(data);
      }
    } catch (e) {
      console.error('[ClipIt Bridge] Error parsing WS message:', e);
    }
  };

  socket.onclose = () => {
    isConnected = false;
    socket = null;
    stopHeartbeat();

    if (!manualDisconnect && isPowerEnabled) {
      setExtensionStatus('disconnected', 'ClipIt app disconnected. Retrying...');
      scheduleReconnect();
    } else if (!isPowerEnabled) {
      setExtensionStatus('off', 'Bridge switched OFF by user.');
    } else {
      setExtensionStatus('disconnected', 'Bridge paused by user.');
    }
  };

  socket.onerror = (err) => {
    console.warn('[ClipIt Bridge] WebSocket error:', err);
    setExtensionStatus('error', 'Cannot reach ClipIt on 127.0.0.1:28475');
  };
}

function disconnectFromClipIt(isPowerOff = false) {
  manualDisconnect = true;
  stopHeartbeat();
  if (reconnectTimer) {
    clearTimeout(reconnectTimer);
    reconnectTimer = null;
  }
  if (socket) {
    socket.close();
    socket = null;
  }
  isConnected = false;
  if (isPowerOff) {
    setExtensionStatus('off', 'Bridge switched OFF by user');
  } else {
    setExtensionStatus('disconnected', 'Disconnected by user');
  }
}

function scheduleReconnect() {
  if (reconnectTimer || manualDisconnect || !isPowerEnabled) return;
  reconnectTimer = setTimeout(() => {
    reconnectTimer = null;
    connectToClipIt();
  }, 1500);
}

// Keep service worker awake using alarms
chrome.alarms.create('clipitKeepAlive', { periodInMinutes: 0.35 });
chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'clipitKeepAlive' && isPowerEnabled && !manualDisconnect) {
    if (!socket || socket.readyState !== WebSocket.OPEN) {
      connectToClipIt();
    }
  }
});

// Broadcast active platform when tab changes
chrome.tabs.onActivated.addListener(async (activeInfo) => {
  try {
    const tab = await chrome.tabs.get(activeInfo.tabId);
    if (tab && tab.url && isSupportedUrl(tab.url)) {
      const platform = getPlatformFromUrl(tab.url);
      sendWs({
        type: 'STATUS',
        platform: platform,
        tabUrl: tab.url,
        message: `Active tab changed to ${platform}`
      });
    }
  } catch (_) {}
});

chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === 'complete' && tab && tab.url && isSupportedUrl(tab.url)) {
    const platform = getPlatformFromUrl(tab.url);
    sendWs({
      type: 'STATUS',
      platform: platform,
      tabUrl: tab.url,
      message: `${platform} page loaded: ${tab.url}`
    });
  }
});

/**
 * Handles incoming ACK_RESPONSE from ClipIt confirming that the response
 * was received and is displayed in ClipIt's UI.
 */
function handleClipItResponseAck(ackData) {
  const promptId = ackData.id || currentPromptId;
  console.log('[ClipIt Bridge] Received ACK_RESPONSE from ClipIt for prompt:', promptId, ackData);

  setExtensionStatus('connected', 'Response displayed in ClipIt app');

  if (promptId && pendingAcks.has(promptId)) {
    const entry = pendingAcks.get(promptId);
    clearTimeout(entry.timer);
    pendingAcks.delete(promptId);
    entry.resolve(true);
  }

  // Notify active AI tabs that ClipIt has confirmed display
  chrome.tabs.query({ url: SUPPORTED_URL_PATTERNS }).then((tabs) => {
    for (const tab of tabs) {
      chrome.tabs.sendMessage(tab.id, {
        action: 'CLIPIT_ACK_CONFIRMED',
        id: promptId,
        status: ackData.status || 'displayed',
        length: ackData.textLength || 0
      }).catch(() => {});
    }
  }).catch(() => {});
}

/**
 * Forwards extracted response text to ClipIt over WebSocket
 * and sets up a promise waiting for ClipIt's ACK_RESPONSE.
 */
function sendResponseToClipIt(text, promptId = null, status = 'success', platform = null) {
  const id = promptId || currentPromptId || 'prompt_' + Date.now();
  currentPromptHandled = true;

  return new Promise((resolve) => {
    const payload = {
      type: 'RESPONSE',
      id: id,
      text: text,
      status: status,
      platform: platform,
      timestamp: Date.now()
    };

    console.log('[ClipIt Bridge] Sending RESPONSE to ClipIt over WS (' + text.length + ' chars):', id);
    sendWs(payload);

    // 15s timeout waiting for ACK_RESPONSE from ClipIt
    const timer = setTimeout(() => {
      console.warn('[ClipIt Bridge] ACK_RESPONSE timeout from ClipIt for id:', id);
      pendingAcks.delete(id);
      resolve(false);
    }, 15000);

    pendingAcks.set(id, { resolve, timer });
  });
}

// Find or activate target tab and send prompt
async function handleSendPrompt(promptText, promptId = null) {
  currentPromptId = promptId || 'prompt_' + Date.now();
  currentPromptHandled = false;

  try {
    let targetTab = await findTargetTab();

    if (!targetTab) {
      // Default to opening ChatGPT if no supported AI tab is open
      console.log('[ClipIt Bridge] No supported AI tab found. Opening https://chatgpt.com/...');
      targetTab = await chrome.tabs.create({ url: 'https://chatgpt.com/', active: true });
      await new Promise(r => setTimeout(r, 4500));
    }

    const platform = getPlatformFromUrl(targetTab.url);
    console.log(`[ClipIt Bridge] Routing prompt (${currentPromptId}) to ${platform} (Tab ${targetTab.id})`);

    // Notify ClipIt of active platform before execution
    sendWs({
      type: 'STATUS',
      platform: platform,
      tabUrl: targetTab.url,
      message: `Executing prompt on ${platform}...`
    });

    // Check if content script is responsive
    let isResponsive = false;
    try {
      const pingRes = await chrome.tabs.sendMessage(targetTab.id, { action: 'CLIPIT_PING' });
      if (pingRes && pingRes.status === 'alive') {
        isResponsive = true;
      }
    } catch (_) {}

    // Only inject if not already active
    if (!isResponsive) {
      try {
        await chrome.scripting.executeScript({
          target: { tabId: targetTab.id },
          files: ['content.js']
        });
        await new Promise(r => setTimeout(r, 350));
      } catch (err) {
        console.warn('[ClipIt Bridge] Script injection notice:', err);
      }
    }

    // Send execution request to content script
    const response = await chrome.tabs.sendMessage(targetTab.id, {
      action: 'EXECUTE_PROMPT',
      prompt: promptText,
      id: currentPromptId
    });

    console.log(`[ClipIt Bridge] ${platform} executePrompt returned:`, response);

    if (response && response.success && response.text && !currentPromptHandled) {
      await sendResponseToClipIt(response.text, currentPromptId, 'success', platform);
    } else if (response && !response.success && response.error && !currentPromptHandled) {
      await sendResponseToClipIt('Error: ' + response.error, currentPromptId, 'error', platform);
    }
  } catch (err) {
    console.warn('[ClipIt Bridge] handleSendPrompt error:', err);
    setTimeout(async () => {
      if (!currentPromptHandled) {
        await sendResponseToClipIt('Bridge error: ' + err.message, currentPromptId, 'error');
      }
    }, 1500);
  }
}

// Listen for messages from popup & content script
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'CONNECT') {
    connectToClipIt();
    sendResponse({ success: true });
  } else if (message.action === 'DISCONNECT') {
    disconnectFromClipIt(false);
    sendResponse({ success: true });
  } else if (message.action === 'SET_POWER') {
    isPowerEnabled = message.enabled;
    if (isPowerEnabled) {
      manualDisconnect = false;
      connectToClipIt();
      sendResponse({ status: 'connecting', details: 'Connecting to ClipIt desktop app...' });
    } else {
      disconnectFromClipIt(true);
      sendResponse({ status: 'off', details: 'Bridge switched OFF' });
    }
  } else if (message.action === 'GET_STATUS') {
    chrome.storage.local.get(['bridgeStatus', 'bridgeDetails', 'bridgePowerEnabled'], async (res) => {
      const targetTab = await findTargetTab();
      const detectedPlatform = targetTab ? getPlatformFromUrl(targetTab.url) : 'None';

      sendResponse({
        status: res.bridgePowerEnabled === false ? 'off' : (res.bridgeStatus || (isConnected ? 'connected' : 'disconnected')),
        details: res.bridgeDetails || '',
        powerEnabled: res.bridgePowerEnabled !== false,
        platform: detectedPlatform
      });
    });
    return true; // async
  } else if (message.action === 'CONTENT_SCRIPT_MOUNTED') {
    console.log(`[ClipIt Bridge] Content script mounted on ${message.platform}: ${message.url}`);
    if (isConnected) {
      sendWs({
        type: 'STATUS',
        platform: message.platform,
        tabUrl: message.url,
        message: `Connected to ${message.platform}`
      });
    }
    sendResponse({ success: true });
  } else if (message.action === 'SEND_RESPONSE_WITH_ACK' || message.action === 'PROMPT_RESPONSE_PUSH') {
    console.log('[ClipIt Bridge] Received response from content script for id:', message.id);
    sendResponseToClipIt(message.text, message.id, message.status || 'success', message.platform)
      .then((acknowledged) => {
        sendResponse({ success: true, acknowledged });
      })
      .catch((err) => {
        sendResponse({ success: false, error: String(err) });
      });
    return true; // async
  }
});

// Check power state before initial connect
chrome.storage.local.get(['bridgePowerEnabled'], (res) => {
  if (res.bridgePowerEnabled !== false) {
    isPowerEnabled = true;
    connectToClipIt();
  } else {
    isPowerEnabled = false;
    setExtensionStatus('off', 'Bridge switched OFF');
  }
});
