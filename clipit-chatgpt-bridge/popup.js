// ClipIt Bridge Popup Logic - Supports ChatGPT, Claude, Gemini, Arena AI

const statusDot = document.getElementById('statusDot');
const statusText = document.getElementById('statusText');
const detailsText = document.getElementById('detailsText');
const toggleBtn = document.getElementById('toggleBtn');
const powerBtn = document.getElementById('powerBtn');
const powerText = document.getElementById('powerText');
const platformBadge = document.getElementById('activePlatformBadge');

const chatgptBtn = document.getElementById('chatgptBtn');
const claudeBtn = document.getElementById('claudeBtn');
const geminiBtn = document.getElementById('geminiBtn');
const arenaBtn = document.getElementById('arenaBtn');

let isPoweredOn = true;

function updatePowerUi(poweredOn) {
  isPoweredOn = poweredOn;
  if (poweredOn) {
    powerBtn.className = 'power-toggle on';
    powerText.textContent = 'ON';
    toggleBtn.disabled = false;
  } else {
    powerBtn.className = 'power-toggle off';
    powerText.textContent = 'OFF';
    statusDot.className = 'status-dot off';
    statusText.className = 'status-badge off';
    statusText.textContent = 'Bridge Switched OFF';
    detailsText.textContent = 'WebSocket bridge is completely disabled. Turn ON to reconnect.';
    toggleBtn.textContent = 'Connect';
    toggleBtn.disabled = true;
  }
}

function renderStatus(status, details, platform) {
  if (!isPoweredOn) return;

  statusDot.className = 'status-dot ' + status;
  statusText.className = 'status-badge ' + status;

  if (status === 'connected') {
    statusText.textContent = 'Connected';
    toggleBtn.textContent = 'Disconnect';
    toggleBtn.className = 'btn secondary';
  } else if (status === 'connecting') {
    statusText.textContent = 'Connecting...';
    toggleBtn.textContent = 'Connecting...';
    toggleBtn.className = 'btn primary';
  } else {
    statusText.textContent = 'Disconnected';
    toggleBtn.textContent = 'Connect';
    toggleBtn.className = 'btn primary';
  }

  if (details) {
    detailsText.textContent = details;
  }

  if (platform && platformBadge) {
    platformBadge.textContent = platform;
  }
}

// Fetch initial state
chrome.storage.local.get(['bridgePowerEnabled', 'bridgeStatus', 'bridgeDetails'], (res) => {
  const powered = res.bridgePowerEnabled !== false;
  updatePowerUi(powered);
  if (powered) {
    chrome.runtime.sendMessage({ action: 'GET_STATUS' }, (statusRes) => {
      if (chrome.runtime.lastError || !statusRes) {
        renderStatus('disconnected', 'Extension service worker starting up...', 'ChatGPT');
      } else {
        renderStatus(statusRes.status, statusRes.details, statusRes.platform);
      }
    });
  }
});

// Listen for push updates from background script
chrome.runtime.onMessage.addListener((message) => {
  if (message.action === 'STATUS_UPDATE') {
    if (isPoweredOn) {
      renderStatus(message.status, message.details, message.platform);
    }
  } else if (message.action === 'POWER_UPDATE') {
    updatePowerUi(message.enabled);
  }
});

// Power Button Toggle
powerBtn.addEventListener('click', () => {
  const newPowerState = !isPoweredOn;
  updatePowerUi(newPowerState);
  chrome.storage.local.set({ bridgePowerEnabled: newPowerState });
  chrome.runtime.sendMessage({ action: 'SET_POWER', enabled: newPowerState }, (res) => {
    if (newPowerState && res) {
      renderStatus(res.status, res.details, res.platform);
    }
  });
});

// Toggle Connect / Disconnect
toggleBtn.addEventListener('click', () => {
  if (!isPoweredOn) return;
  if (toggleBtn.textContent === 'Disconnect') {
    chrome.runtime.sendMessage({ action: 'DISCONNECT' });
    renderStatus('disconnected', 'Disconnected by user');
  } else {
    renderStatus('connecting', 'Attempting connection...');
    chrome.runtime.sendMessage({ action: 'CONNECT' });
  }
});

// Helper to open or focus specific AI URL
async function openOrFocusAiTab(urlPattern, defaultUrl) {
  const tabs = await chrome.tabs.query({ url: urlPattern });
  if (tabs.length > 0) {
    await chrome.tabs.update(tabs[0].id, { active: true });
    if (tabs[0].windowId) {
      await chrome.windows.update(tabs[0].windowId, { focused: true });
    }
  } else {
    await chrome.tabs.create({ url: defaultUrl });
  }
}

// Quick Open Button Handlers
chatgptBtn.addEventListener('click', () => {
  openOrFocusAiTab(['https://chatgpt.com/*', 'https://chat.openai.com/*'], 'https://chatgpt.com/');
});

claudeBtn.addEventListener('click', () => {
  openOrFocusAiTab(['https://claude.ai/*'], 'https://claude.ai/');
});

geminiBtn.addEventListener('click', () => {
  openOrFocusAiTab(['https://gemini.google.com/*'], 'https://gemini.google.com/');
});

arenaBtn.addEventListener('click', () => {
  openOrFocusAiTab(['https://lmarena.ai/*', 'https://arena.lmsys.org/*'], 'https://lmarena.ai/?mode=direct');
});
