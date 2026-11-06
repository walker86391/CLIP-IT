# ClipIt - AI Chatbot Local Browser Bridge Extension

This Chrome Extension creates a direct, local bridge between the **ClipIt Windows Desktop App** and your active browser sessions on:
- **ChatGPT** (`chatgpt.com`, `chat.openai.com`)
- **Claude** (`claude.ai`)
- **Gemini** (`gemini.google.com`)
- **Arena AI** (`lmarena.ai`, `arena.lmsys.org`) — *Direct Chat mode only*

> **Key Feature:** No API keys or paid subscriptions required. It communicates directly with your already-open browser session via a local WebSocket (`ws://127.0.0.1:28475`).

---

## 🚀 How to Install / Reload in Google Chrome

1. Open Google Chrome.
2. In the URL bar, go to:
   ```
   chrome://extensions/
   ```
3. In the top-right corner, turn **ON** the **Developer mode** toggle.
4. Click the **Load unpacked** button in the top-left toolbar (or click the **Reload icon 🔄** on the extension card if already installed).
5. In the file picker, select this exact folder:
   ```
   C:\Users\Dell\Desktop\clipit\clipit-chatgpt-bridge
   ```
6. The **ClipIt - AI Chatbot Local Bridge** card will appear in your extensions list.

---

## 🔘 Extension Controls

- **ON / OFF Toggle Switch**: Located in the extension popup header next to the status dot.
  - **ON**: Bridge is active, ready to connect to ClipIt.
  - **OFF**: Bridge is completely disabled; stops background reconnect attempts and closes WebSocket.
- **Connection Status Dot**:
  - 🟢 **Green**: Connected to ClipIt desktop app.
  - 🟡 **Yellow**: Connecting / Attempting connection.
  - 🔴 **Red / Gray**: Disconnected or waiting for ClipIt.
- **Active Platform Badge**: Displays whether you are currently routed to ChatGPT, Claude, Gemini, or Arena AI.
- **Quick Launch Buttons**: One-click opening for ChatGPT, Claude, Gemini, and Arena AI (opens Direct Chat mode).

---

## ⚡ How to Use with ClipIt

1. **Open your Preferred AI Chatbot**:
   - **ChatGPT**: [https://chatgpt.com/](https://chatgpt.com/)
   - **Claude**: [https://claude.ai/](https://claude.ai/)
   - **Gemini**: [https://gemini.google.com/](https://gemini.google.com/)
   - **Arena AI**: [https://lmarena.ai/?mode=direct](https://lmarena.ai/?mode=direct) (Must be in **Direct Chat** mode)
2. **Launch ClipIt**:
   - Start the project in ClipIt.
3. **Connect the AI Bridge**:
   - On the **Connect to your AI chatbot** screen, ClipIt automatically initializes the connection.
   - The Chrome extension connects, and ClipIt displays a glowing green badge: **Connected** with the active AI platform.
4. **Test the Connection & Auto-Copy**:
   - In the test input area, click **Send** for the test message `hi there`.
   - The extension types the prompt into your active AI chatbot and sends it.
   - When the AI finishes generating, the extension captures the full response and transmits it directly into ClipIt.
   - ClipIt displays the response and **automatically copies it to your clipboard**, with a manual **Copy Response** button available anytime.
5. **Proceed with Project**:
   - Click the **Continue** arrow in the bottom right corner to advance to the next workflow stage (`GenreSelectionPage`).
