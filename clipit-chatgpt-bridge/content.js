// ClipIt - AI Chatbot Web Content Script
// Resilient DOM automation supporting ChatGPT, Claude, Gemini, and Arena AI (Direct Chat)
// Features precise completion detection, clean extraction, on-screen visual confirmation,
// and ClipIt desktop app display acknowledgment.

(() => {
  // Guard against duplicate injection
  if (window.__CLIPIT_BRIDGE_CONTENT_SCRIPT_INITIALIZED__) {
    console.log('[ClipIt Bridge] Content script already active in this tab.');
    return;
  }
  window.__CLIPIT_BRIDGE_CONTENT_SCRIPT_INITIALIZED__ = true;

  console.log('[ClipIt Bridge] Content script active on page:', window.location.href);

  // Determine current AI Platform
  function detectPlatform() {
    const host = window.location.hostname.toLowerCase();
    if (host.includes('chatgpt.com') || host.includes('openai.com')) {
      return 'ChatGPT';
    } else if (host.includes('claude.ai')) {
      return 'Claude';
    } else if (host.includes('gemini.google.com')) {
      return 'Gemini';
    } else if (host.includes('lmarena.ai') || host.includes('arena.lmsys.org')) {
      return 'Arena AI';
    }
    return 'AI Chatbot';
  }

  const currentPlatform = detectPlatform();
  console.log('[ClipIt Bridge] Detected platform:', currentPlatform);

  // Listen for commands from background service worker
  chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.action === 'CLIPIT_PING') {
      sendResponse({ status: 'alive', platform: currentPlatform, url: window.location.href });
      return false;
    }

    if (request.action === 'GET_TAB_INFO') {
      sendResponse({
        platform: currentPlatform,
        url: window.location.href,
        isArenaDirectChat: currentPlatform === 'Arena AI' ? isArenaDirectChat() : true
      });
      return false;
    }

    if (request.action === 'EXECUTE_PROMPT') {
      executePrompt(request.prompt, request.id)
        .then((result) => {
          sendResponse({ success: true, text: result.text, acknowledged: result.acknowledged });
        })
        .catch((err) => {
          console.error('[ClipIt Bridge] Prompt execution error:', err);
          sendResponse({ success: false, error: err.message || String(err) });
        });
      return true; // Keep message channel open for async response
    }
  });

  // Notify background script that content script is mounted
  chrome.runtime.sendMessage({
    action: 'CONTENT_SCRIPT_MOUNTED',
    platform: currentPlatform,
    url: window.location.href,
    isArenaDirectChat: currentPlatform === 'Arena AI' ? isArenaDirectChat() : true
  }).catch(() => {});

  // ── Arena AI Direct Chat Validation ──────────────────────────────────────────

  function isArenaDirectChat() {
    if (currentPlatform !== 'Arena AI') return true;

    const url = window.location.href;
    if (url.includes('mode=direct') || url.includes('tab=direct') || url.includes('arena=direct')) {
      return true;
    }

    // Look for tab buttons in Gradio / LMSYS
    const tabButtons = Array.from(document.querySelectorAll('button, [role="tab"], .tab, a, div[class*="tab"]'));
    const directTab = tabButtons.find(el => {
      const text = (el.innerText || el.textContent || '').trim().toLowerCase();
      return text.includes('direct chat');
    });

    if (directTab) {
      const isSelected = directTab.getAttribute('aria-selected') === 'true' ||
                         directTab.classList.contains('selected') ||
                         directTab.classList.contains('active') ||
                         directTab.getAttribute('data-state') === 'active';
      if (isSelected) return true;
    }

    // Check if there are battle labels (Model A / Model B). If not, and there is a single chatbot, it's direct chat
    const hasBattleLabels = Array.from(document.querySelectorAll('*')).some(el => {
      const t = el.innerText || el.textContent || '';
      return (t.includes('Model A') && t.includes('Model B')) || t.includes('Arena (battle)');
    });

    if (directTab && !hasBattleLabels) {
      return true;
    }

    return false;
  }

  async function ensureArenaDirectChat() {
    if (currentPlatform !== 'Arena AI') return true;
    if (isArenaDirectChat()) return true;

    console.log('[ClipIt Bridge] Arena AI detected: Checking for Direct Chat tab...');
    showClipItToast('Arena AI: Switching to Direct Chat tab...', false);

    const tabButtons = Array.from(document.querySelectorAll('button, [role="tab"], .tab, a, div[class*="tab"]'));
    const directTab = tabButtons.find(el => {
      const text = (el.innerText || el.textContent || '').trim().toLowerCase();
      return text.includes('direct chat');
    });

    if (directTab) {
      directTab.click();
      await sleep(750);
      if (isArenaDirectChat()) {
        console.log('[ClipIt Bridge] Successfully switched to Arena AI Direct Chat tab.');
        return true;
      }
    }

    return false;
  }

  // ── Prompt Execution ─────────────────────────────────────────────────────────

  async function executePrompt(promptText, promptId = null) {
    const currentId = promptId || 'prompt_' + Date.now();
    console.log(`[ClipIt Bridge] Executing prompt on ${currentPlatform} (${currentId}):`, promptText);

    // Validate Arena AI Direct Chat condition
    if (currentPlatform === 'Arena AI') {
      const isDirect = await ensureArenaDirectChat();
      if (!isDirect) {
        showClipItToast('Arena AI: Please click the "Direct Chat" tab', true);
        throw new Error('Arena AI only works in Direct Chat mode. Please click the "Direct Chat" tab on lmarena.ai and retry.');
      }
    }

    showClipItToast(`Preparing ${currentPlatform} composer...`, false);

    // 1. Locate Composer Input Element
    const composer = await waitForComposer(currentPlatform, 18000);
    if (!composer) {
      showClipItToast(`Could not find ${currentPlatform} input area`, true);
      throw new Error(`Could not find ${currentPlatform} input area. Please ensure ${currentPlatform} is open and logged in.`);
    }

    // Baseline assistant turns before sending prompt
    const initialAssistantTurns = getAssistantTurns(currentPlatform);
    const initialAssistantCount = initialAssistantTurns.length;
    console.log(`[ClipIt Bridge] Baseline ${currentPlatform} assistant turns before prompt:`, initialAssistantCount);

    // 2. Set Text into Composer
    await setComposerText(composer, promptText, currentPlatform);
    await sleep(350);

    // 3. Click Send Button
    showClipItToast(`Submitting prompt to ${currentPlatform}...`, false);
    const sent = await clickSendButton(composer, currentPlatform);
    if (!sent) {
      showClipItToast(`Failed to submit prompt on ${currentPlatform}`, true);
      throw new Error(`Failed to submit prompt to ${currentPlatform}. Send button was not reachable.`);
    }

    console.log(`[ClipIt Bridge] Prompt submitted to ${currentPlatform}. Monitoring live DOM for response generation...`);
    showClipItToast(`${currentPlatform} is generating response...`, false);

    // 4. Wait for generation to complete and extract complete response text
    const responseText = await waitForResponseCompletion(initialAssistantCount, currentPlatform, 95000);

    console.log(`[ClipIt Bridge] Response generation complete (${responseText.length} chars).`);
    showClipItToast('Sending response to ClipIt...', false);

    // 5. Send through local bridge and wait for acknowledgment from ClipIt
    const ackReceived = await sendResponseAndWaitForAck(currentId, responseText, 15000);

    if (ackReceived) {
      console.log('[ClipIt Bridge] Success: Response displayed in ClipIt app.');
      showClipItToast('Response displayed in ClipIt app ✓', true);
    } else {
      console.warn('[ClipIt Bridge] Response sent to ClipIt, but display acknowledgment timed out.');
      showClipItToast('Response sent to ClipIt ✓', true);
    }

    return { text: responseText, acknowledged: ackReceived };
  }

  function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  // ── DOM Utilities ───────────────────────────────────────────────────────────

  async function waitForComposer(platform, timeoutMs = 18000) {
    const startTime = Date.now();
    let selectors = [];

    switch (platform) {
      case 'ChatGPT':
        selectors = [
          '#prompt-textarea',
          'div[contenteditable="true"][id="prompt-textarea"]',
          'div.ProseMirror[contenteditable="true"]',
          'div[contenteditable="true"]',
          'textarea[data-id="root"]',
          'textarea'
        ];
        break;

      case 'Claude':
        selectors = [
          'div.ProseMirror[contenteditable="true"]',
          'div[contenteditable="true"][data-placeholder]',
          'fieldset div[contenteditable="true"]',
          'div[contenteditable="true"]',
          'textarea'
        ];
        break;

      case 'Gemini':
        selectors = [
          'rich-textarea div[contenteditable="true"]',
          'div.ql-editor[contenteditable="true"]',
          'div[contenteditable="true"][role="textbox"]',
          'div[contenteditable="true"]',
          'textarea'
        ];
        break;

      case 'Arena AI':
        selectors = [
          'textarea[data-testid="textbox"]',
          'textarea.scroll-hide',
          'div[data-testid="textbox"] textarea',
          '#chatbot ~ div textarea',
          '.chatbot ~ div textarea',
          'textarea'
        ];
        break;

      default:
        selectors = [
          '#prompt-textarea',
          'div[contenteditable="true"]',
          'textarea'
        ];
        break;
    }

    while (Date.now() - startTime < timeoutMs) {
      for (const sel of selectors) {
        const el = document.querySelector(sel);
        if (el && isElementVisible(el)) {
          return el;
        }
      }
      await sleep(200);
    }
    return null;
  }

  function isElementVisible(el) {
    return Boolean(el && (el.offsetWidth > 0 || el.offsetHeight > 0 || el.getClientRects().length > 0));
  }

  async function setComposerText(composer, text, platform) {
    composer.focus();
    await sleep(60);

    const isTextarea = composer.tagName.toLowerCase() === 'textarea' || composer.tagName.toLowerCase() === 'input';

    if (isTextarea) {
      // React / Gradio controlled textarea
      try {
        const nativeSetter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, 'value')?.set;
        if (nativeSetter) {
          nativeSetter.call(composer, text);
        } else {
          composer.value = text;
        }
      } catch (_) {
        composer.value = text;
      }

      composer.dispatchEvent(new Event('input', { bubbles: true }));
      composer.dispatchEvent(new Event('change', { bubbles: true }));
    } else {
      // Contenteditable (ChatGPT, Claude, Gemini)
      try {
        const selection = window.getSelection();
        const range = document.createRange();
        range.selectNodeContents(composer);
        selection.removeAllRanges();
        selection.addRange(range);
      } catch (_) {}

      try {
        composer.dispatchEvent(new InputEvent('beforeinput', {
          bubbles: true,
          cancelable: true,
          inputType: 'insertText',
          data: text
        }));
      } catch (_) {}

      let inserted = false;
      try {
        document.execCommand('selectAll', false, null);
        document.execCommand('delete', false, null);
        inserted = document.execCommand('insertText', false, text);
      } catch (_) {}

      const currentText = composer.innerText || composer.textContent || '';
      if (!inserted || !currentText.includes(text)) {
        let p = composer.querySelector('p');
        if (!p) {
          composer.innerHTML = `<p>${escapeHtml(text)}</p>`;
        } else {
          p.textContent = text;
        }
      }

      composer.dispatchEvent(new InputEvent('input', {
        bubbles: true,
        cancelable: true,
        inputType: 'insertText',
        data: text
      }));
      composer.dispatchEvent(new Event('input', { bubbles: true }));
      composer.dispatchEvent(new Event('change', { bubbles: true }));
    }

    await sleep(150);
  }

  function escapeHtml(str) {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  async function clickSendButton(composer, platform) {
    const sendSelectors = [
      // ChatGPT
      'button[data-testid="send-button"]',
      'button[data-testid="fruitjuice-send-button"]',
      'button[aria-label*="Send prompt"]',
      'button#send-button',
      // Claude
      'button[aria-label="Send Message"]',
      'button[aria-label="Send message"]',
      'fieldset button[type="button"]:has(svg)',
      'button[data-testid="send-button"]',
      // Gemini
      'button.send-button',
      'button[aria-label*="Send message"]',
      'button[aria-label*="Send prompt"]',
      'button[mattooltip*="Send"]',
      'button[aria-label*="Submit"]',
      // Arena AI
      'button#component-submit',
      'button[id*="submit"]',
      'button.primary',
      // General fallbacks
      'button[aria-label*="Send"]',
      'button[aria-label*="send"]',
      'button[aria-label*="Submit"]',
      'form button[type="submit"]'
    ];

    // Wait up to 2.5 seconds for Send button to become enabled
    for (let i = 0; i < 25; i++) {
      for (const sel of sendSelectors) {
        const btn = document.querySelector(sel);
        if (btn && isElementVisible(btn)) {
          const isDisabled = btn.disabled || btn.getAttribute('aria-disabled') === 'true';
          if (!isDisabled) {
            btn.click();
            return true;
          }
        }
      }
      await sleep(100);
    }

    // Force click if still marked disabled
    for (const sel of sendSelectors) {
      const btn = document.querySelector(sel);
      if (btn && isElementVisible(btn)) {
        btn.disabled = false;
        btn.removeAttribute('aria-disabled');
        btn.click();
        return true;
      }
    }

    // Fallback: Dispatch Enter key events on composer
    composer.focus();
    composer.dispatchEvent(new KeyboardEvent('keydown', {
      key: 'Enter',
      code: 'Enter',
      keyCode: 13,
      which: 13,
      bubbles: true,
      cancelable: true
    }));
    composer.dispatchEvent(new KeyboardEvent('keyup', {
      key: 'Enter',
      code: 'Enter',
      keyCode: 13,
      which: 13,
      bubbles: true,
      cancelable: true
    }));

    return true;
  }

  // ── Assistant Turns & Generation Detection ──────────────────────────────────

  function getAssistantTurns(platform) {
    let turns = [];

    switch (platform) {
      case 'ChatGPT':
        turns = Array.from(document.querySelectorAll('[data-message-author-role="assistant"]'));
        if (turns.length === 0) {
          turns = Array.from(document.querySelectorAll('article:has([data-message-author-role="assistant"]), div[data-testid^="conversation-turn"]:not(:has([data-message-author-role="user"]))'));
        }
        break;

      case 'Claude':
        turns = Array.from(document.querySelectorAll('.font-claude-message, [data-testid="chat-message"], div.font-claude-response, div[class*="font-claude"]'));
        break;

      case 'Gemini':
        turns = Array.from(document.querySelectorAll('message-content, model-response, div.response-container-content, div[class*="model-response"], .model-message'));
        break;

      case 'Arena AI':
        turns = Array.from(document.querySelectorAll('.chatbot .message.bot, [data-testid="bot"], .message.bot, .bubble.bot, div[class*="message"][class*="bot"]'));
        break;

      default:
        turns = Array.from(document.querySelectorAll('[data-message-author-role="assistant"], message-content, model-response, .font-claude-message, .message.bot'));
        break;
    }

    if (turns.length === 0) {
      turns = Array.from(document.querySelectorAll('.markdown, .prose, div[class*="markdown"]'));
    }

    return turns;
  }

  function isGeneratingActive(platform) {
    switch (platform) {
      case 'ChatGPT': {
        // 1. ChatGPT Stop button (scoped to composer / form)
        const stopBtn = document.querySelector(
          'button[data-testid="stop-button"], ' +
          'button[data-testid="fruitjuice-stop-button"], ' +
          'button[aria-label="Stop generating"], ' +
          'button[aria-label="Stop streaming"], ' +
          'button[aria-label="Stop response"], ' +
          'form button[aria-label*="Stop"]'
        );
        if (stopBtn && isElementVisible(stopBtn)) return true;

        // 2. Active streaming indicators on assistant turn (avoid broad "thinking" match that catches Think button)
        const streamingTurn = document.querySelector(
          '[data-message-author-role="assistant"].result-streaming, ' +
          '[data-message-author-role="assistant"] [data-is-streaming="true"], ' +
          '.result-streaming, ' +
          '[data-is-streaming="true"], ' +
          'span.cursor'
        );
        if (streamingTurn && isElementVisible(streamingTurn)) return true;

        return false;
      }

      case 'Claude': {
        const stopBtn = document.querySelector(
          'button[aria-label="Stop Response"], ' +
          'button[aria-label="Stop response"], ' +
          'button[aria-label="Stop generating"], ' +
          'button[data-testid="stop-button"]'
        );
        if (stopBtn && isElementVisible(stopBtn)) return true;

        const streaming = document.querySelector(
          '.streaming, ' +
          '[data-is-streaming="true"], ' +
          '.streaming-animation'
        );
        if (streaming && isElementVisible(streaming)) return true;

        return false;
      }

      case 'Gemini': {
        const stopBtn = document.querySelector(
          'button.stop-button, ' +
          'button[aria-label*="Stop generating"], ' +
          'button[aria-label*="Stop response"]'
        );
        if (stopBtn && isElementVisible(stopBtn)) return true;

        const streaming = document.querySelector(
          'mat-progress-bar, ' +
          '.sparkle-animating'
        );
        if (streaming && isElementVisible(streaming)) return true;

        return false;
      }

      case 'Arena AI': {
        const stopBtn = document.querySelector(
          'button#component-stop, ' +
          '.chatbot ~ div button[id*="stop"]'
        );
        if (stopBtn && isElementVisible(stopBtn)) return true;

        const streaming = document.querySelector('.chatbot .pending, .chatbot .generating');
        if (streaming && isElementVisible(streaming)) return true;

        return false;
      }

      default: {
        const stopBtn = document.querySelector(
          'button[data-testid="stop-button"], ' +
          'button[aria-label*="Stop generating"]'
        );
        return Boolean(stopBtn && isElementVisible(stopBtn));
      }
    }
  }

  function isSendButtonReady() {
    const sendBtn = document.querySelector(
      'button[data-testid="send-button"]:not(:disabled), ' +
      'button[data-testid="fruitjuice-send-button"]:not(:disabled), ' +
      'button.send-button:not(:disabled), ' +
      'button[aria-label*="Send"]:not(:disabled)'
    );
    return Boolean(sendBtn && isElementVisible(sendBtn));
  }

  function hasTurnActionToolbar(turnElement) {
    if (!turnElement) return false;
    const container = turnElement.closest('article') ||
                      turnElement.closest('[data-testid^="conversation-turn"]') ||
                      turnElement.closest('.agent-turn') ||
                      turnElement.parentElement?.parentElement ||
                      turnElement.parentElement;
    if (!container) return false;

    const actionBtn = container.querySelector(
      'button[data-testid="copy-turn-action-button"], ' +
      'button[aria-label*="Copy"], ' +
      'button[aria-label*="copy"], ' +
      'button[aria-label*="Read aloud"], ' +
      'button[data-testid*="good-response"], ' +
      'button[data-testid*="thumbs"], ' +
      'button[aria-label*="Good response"], ' +
      'button[aria-label*="Bad response"]'
    );
    return Boolean(actionBtn);
  }

  async function waitForResponseCompletion(initialAssistantCount, platform, timeoutMs = 95000) {
    const startTime = Date.now();
    let lastCandidate = '';
    let stableTicks = 0;
    let hasInitiated = false;

    await sleep(750);

    while (Date.now() - startTime < timeoutMs) {
      const turns = getAssistantTurns(platform);
      const hasNewTurn = turns.length > initialAssistantCount;
      const isGenerating = isGeneratingActive(platform);
      const targetTurn = turns.length > 0 ? turns[turns.length - 1] : null;

      if (isGenerating || hasNewTurn || (targetTurn && hasTurnActionToolbar(targetTurn))) {
        hasInitiated = true;
      }

      // If active generation in progress, reset stability and continue
      if (isGenerating) {
        stableTicks = 0;
        await sleep(250);
        continue;
      }

      // Give generation up to 4s to initiate if nothing detected yet
      if (!hasInitiated && Date.now() - startTime < 4000) {
        await sleep(250);
        continue;
      }

      // Generation finished or not active. Inspect target assistant turn
      const candidateText = targetTurn ? extractCleanText(targetTurn) : '';

      if (candidateText && candidateText.length > 0) {
        const toolbarMounted = hasTurnActionToolbar(targetTurn);
        const sendReady = isSendButtonReady();

        if (candidateText === lastCandidate) {
          stableTicks++;

          // If toolbar mounted and text stable for >= 2 checks (500ms): complete!
          if (toolbarMounted && stableTicks >= 2) {
            console.log(`[ClipIt Bridge] Action toolbar mounted on ${platform} turn and response text stable (${stableTicks} ticks). Generation complete!`);
            return candidateText;
          }

          // If text stable for >= 4 checks (1000ms) without generation indicators: complete!
          if (stableTicks >= 4 && (sendReady || stableTicks >= 5)) {
            console.log(`[ClipIt Bridge] Response text on ${platform} stable for 1000ms+ without generation indicators. Complete!`);
            return candidateText;
          }
        } else {
          lastCandidate = candidateText;
          stableTicks = 1;
        }
      }

      await sleep(250);
    }

    // Fallback: return last captured assistant text if non-empty
    const finalTurns = getAssistantTurns(platform);
    if (finalTurns.length > 0) {
      const fallbackText = extractCleanText(finalTurns[finalTurns.length - 1]);
      if (fallbackText && fallbackText.length > 0) {
        return fallbackText;
      }
    }

    throw new Error(`${platform} response generation timed out after ${Math.round(timeoutMs / 1000)}s`);
  }

  function extractCleanText(element) {
    if (!element) return '';

    try {
      const clone = element.cloneNode(true);
      // Remove reasoning/thinking blocks & citation/ad badges
      clone.querySelectorAll(
        'details, [data-testid="thinking"], .thinking-content, div[class*="thinking"], ' +
        '.citation, .citations, [data-testid*="citation"], [data-testid*="source"], ' +
        '[data-testid*="ad"], [data-testid*="sponsor"], div[class*="citation"]'
      ).forEach(el => el.remove());

      // Remove all buttons, icons, and action bars
      clone.querySelectorAll(
        'button, [role="button"], svg, nav, footer, ' +
        '[aria-label*="Copy"], [aria-label*="Good"], [aria-label*="Bad"], [aria-label*="Read aloud"]'
      ).forEach(btn => btn.remove());

      const inner = clone.querySelector('.markdown, [class*="markdown"], .prose, div[class*="text-message"], .response-content, .message-content') || clone;
      const text = (inner.innerText || inner.textContent || '').trim();
      if (text.length > 0) {
        return text;
      }
    } catch (_) {}

    return (element.innerText || element.textContent || '').trim();
  }

  // ── Bridge Communication & Acknowledgment ───────────────────────────────────

  function sendResponseAndWaitForAck(promptId, text, timeoutMs = 15000) {
    return new Promise((resolve) => {
      let resolved = false;

      const timeout = setTimeout(() => {
        if (!resolved) {
          resolved = true;
          chrome.runtime.onMessage.removeListener(ackListener);
          resolve(false);
        }
      }, timeoutMs);

      function ackListener(message) {
        if (message.action === 'CLIPIT_ACK_CONFIRMED' && (!message.id || message.id === promptId)) {
          if (!resolved) {
            resolved = true;
            clearTimeout(timeout);
            chrome.runtime.onMessage.removeListener(ackListener);
            resolve(true);
          }
        }
      }

      chrome.runtime.onMessage.addListener(ackListener);

      chrome.runtime.sendMessage({
        action: 'SEND_RESPONSE_WITH_ACK',
        id: promptId,
        text: text,
        platform: currentPlatform,
        status: 'success'
      }).then((res) => {
        if (res && res.acknowledged && !resolved) {
          resolved = true;
          clearTimeout(timeout);
          chrome.runtime.onMessage.removeListener(ackListener);
          resolve(true);
        }
      }).catch(() => {});
    });
  }

  // ── On-Screen HUD Toast ─────────────────────────────────────────────────────

  function showClipItToast(message, isDone = false) {
    let toast = document.getElementById('clipit-bridge-toast');

    if (!toast) {
      if (!document.getElementById('clipit-toast-style')) {
        const style = document.createElement('style');
        style.id = 'clipit-toast-style';
        style.textContent = `
          @keyframes clipit-spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
        `;
        document.head.appendChild(style);
      }

      toast = document.createElement('div');
      toast.id = 'clipit-bridge-toast';
      toast.style.cssText = `
        position: fixed;
        bottom: 24px;
        right: 24px;
        z-index: 9999999;
        background: #141524;
        color: #F3F4F8;
        border: 1px solid #8B5CF6;
        border-radius: 10px;
        padding: 10px 16px;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        font-size: 13px;
        font-weight: 600;
        box-shadow: 0 8px 24px rgba(0,0,0,0.5), 0 0 14px rgba(139,92,246,0.3);
        display: flex;
        align-items: center;
        gap: 10px;
        transition: opacity 0.3s ease, transform 0.3s ease;
        pointer-events: none;
      `;
      document.body.appendChild(toast);
    }

    toast.innerHTML = isDone
      ? `<span style="color:#10B981;font-size:16px;line-height:1;">✓</span> <span>${escapeHtml(message)}</span>`
      : `<span style="display:inline-block;width:13px;height:13px;border:2px solid #8B5CF6;border-top-color:transparent;border-radius:50%;animation:clipit-spin 0.8s linear infinite;"></span> <span>${escapeHtml(message)}</span>`;

    toast.style.opacity = '1';
    toast.style.transform = 'translateY(0)';

    if (isDone) {
      setTimeout(() => {
        if (toast) {
          toast.style.opacity = '0';
          toast.style.transform = 'translateY(10px)';
        }
      }, 4000);
    }
  }
})();
