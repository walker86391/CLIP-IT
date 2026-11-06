import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connection states for the local ChatGPT browser bridge.
enum BridgeConnectionStatus {
  disconnected,
  connecting,
  connected,
  timeout,
  error,
}

/// Prompt transmission states for test messages.
enum BridgePromptStatus {
  idle,
  sending,
  waiting,
  completed,
  error,
}

/// Immutable state snapshot of the ChatGPT / AI chatbot bridge.
class ChatGptBridgeState {
  const ChatGptBridgeState({
    this.connectionStatus = BridgeConnectionStatus.disconnected,
    this.promptStatus = BridgePromptStatus.idle,
    this.timeoutRemainingSeconds = 120,
    this.lastPrompt,
    this.lastResponse,
    this.lastError,
    this.connectedUrl,
    this.connectedPlatform,
    this.logs = const [],
    this.isResponseDisplayed = false,
  });

  final BridgeConnectionStatus connectionStatus;
  final BridgePromptStatus promptStatus;
  final int timeoutRemainingSeconds;
  final String? lastPrompt;
  final String? lastResponse;
  final String? lastError;
  final String? connectedUrl;
  final String? connectedPlatform;
  final List<String> logs;
  final bool isResponseDisplayed;

  bool get isConnected => connectionStatus == BridgeConnectionStatus.connected;
  bool get isConnecting => connectionStatus == BridgeConnectionStatus.connecting;
  bool get isTimeout => connectionStatus == BridgeConnectionStatus.timeout;
  bool get isSending => promptStatus == BridgePromptStatus.sending || promptStatus == BridgePromptStatus.waiting;

  String get effectivePlatform {
    if (connectedPlatform != null && connectedPlatform!.trim().isNotEmpty) {
      return connectedPlatform!.trim();
    }
    if (connectedUrl != null) {
      final u = connectedUrl!.toLowerCase();
      if (u.contains('claude.ai')) return 'Claude';
      if (u.contains('gemini.google.com')) return 'Gemini';
      if (u.contains('lmarena.ai') || u.contains('arena.lmsys.org')) return 'Arena AI';
      if (u.contains('chatgpt.com') || u.contains('openai.com')) return 'ChatGPT';
    }
    return 'ChatGPT';
  }

  ChatGptBridgeState copyWith({
    BridgeConnectionStatus? connectionStatus,
    BridgePromptStatus? promptStatus,
    int? timeoutRemainingSeconds,
    String? lastPrompt,
    String? lastResponse,
    String? lastError,
    String? connectedUrl,
    String? connectedPlatform,
    List<String>? logs,
    bool? isResponseDisplayed,
  }) {
    return ChatGptBridgeState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      promptStatus: promptStatus ?? this.promptStatus,
      timeoutRemainingSeconds: timeoutRemainingSeconds ?? this.timeoutRemainingSeconds,
      lastPrompt: lastPrompt ?? this.lastPrompt,
      lastResponse: lastResponse ?? this.lastResponse,
      lastError: lastError ?? this.lastError,
      connectedUrl: connectedUrl ?? this.connectedUrl,
      connectedPlatform: connectedPlatform ?? this.connectedPlatform,
      logs: logs ?? this.logs,
      isResponseDisplayed: isResponseDisplayed ?? this.isResponseDisplayed,
    );
  }
}

/// Local WebSocket Bridge Service managing communication with the Chrome Extension.
class ChatGptBridgeService extends Notifier<ChatGptBridgeState> {
  static const int defaultPort = 28475;

  HttpServer? _server;
  WebSocket? _socket;
  Timer? _timeoutTimer;
  Timer? _countdownTimer;
  Timer? _promptTimeoutTimer;
  Timer? _heartbeatTimer;
  Timer? _disconnectGraceTimer;

  final Map<String, Completer<String>> _pendingPromptCompleters = {};
  Completer<String>? _fallbackPromptCompleter;

  @override
  ChatGptBridgeState build() {
    ref.onDispose(() {
      _timeoutTimer?.cancel();
      _countdownTimer?.cancel();
      _promptTimeoutTimer?.cancel();
      _heartbeatTimer?.cancel();
      _disconnectGraceTimer?.cancel();
      _closeSocketAndServerOnly();
    });
    return const ChatGptBridgeState();
  }

  void _addLog(String message) {
    debugPrint(message);
    state = state.copyWith(
      logs: [...state.logs, message],
    );
  }

  /// Start the local bridge and begin the 120-second timeout window.
  Future<void> startConnection({int port = defaultPort, int timeoutSeconds = 120}) async {
    // If already running or connected, reset first
    await stop();

    _addLog('[ClipIt Bridge] Starting server on ws://127.0.0.1:$port...');
    _addLog('[ClipIt Bridge] Waiting for extension...');

    try {
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        port,
        shared: true,
      );

      state = state.copyWith(
        connectionStatus: BridgeConnectionStatus.connecting,
        timeoutRemainingSeconds: timeoutSeconds,
        lastError: null,
      );

      // Listen for incoming WebSocket connections
      _server!.listen(
        _handleHttpRequest,
        onError: (Object error) {
          _addLog('[ClipIt Bridge] Server error: $error');
          state = state.copyWith(
            connectionStatus: BridgeConnectionStatus.error,
            lastError: error.toString(),
          );
        },
      );

      // Start 1-second countdown timer for UI feedback
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.timeoutRemainingSeconds > 1) {
          state = state.copyWith(
            timeoutRemainingSeconds: state.timeoutRemainingSeconds - 1,
          );
        } else {
          timer.cancel();
        }
      });

      // Start the 120-second timeout
      _timeoutTimer = Timer(Duration(seconds: timeoutSeconds), () {
        if (!state.isConnected) {
          _addLog('[ClipIt Bridge] Connection attempt timed out after ${timeoutSeconds}s');
          _countdownTimer?.cancel();
          _closeSocketAndServerOnly();
          state = state.copyWith(
            connectionStatus: BridgeConnectionStatus.timeout,
            lastError: 'Connection timed out after $timeoutSeconds seconds. Ensure ChatGPT tab is open and extension is started.',
          );
        }
      });
    } catch (e) {
      _addLog('[ClipIt Bridge] Failed to start server: $e');
      state = state.copyWith(
        connectionStatus: BridgeConnectionStatus.error,
        lastError: 'Failed to bind to port $port: $e',
      );
    }
  }

  /// Ensures the local WebSocket server is actively running without resetting
  /// if it is already running or connected.
  Future<void> ensureServerRunning({int port = defaultPort, int timeoutSeconds = 120}) async {
    if (state.isConnected) return;
    if (_server != null && state.connectionStatus == BridgeConnectionStatus.connecting) return;
    await startConnection(port: port, timeoutSeconds: timeoutSeconds);
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    // Enable CORS for any HTTP requests (e.g. extension ping or preflight)
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    if (WebSocketTransformer.isUpgradeRequest(request)) {
      try {
        final socket = await WebSocketTransformer.upgrade(request);
        _handleNewClient(socket);
      } catch (e) {
        _addLog('[ClipIt Bridge] WebSocket upgrade error: $e');
      }
    } else {
      // Simple status response for browser checks
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'status': 'ClipIt Bridge Active',
          'connected': state.isConnected,
          'version': '1.0.0',
        }),
      );
      await request.response.close();
    }
  }

  void _handleNewClient(WebSocket socket) {
    // Cancel the initial connection timeout immediately upon WebSocket connection
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    _disconnectGraceTimer?.cancel();

    _socket?.close();
    _socket = socket;

    // Start sending PING heartbeat every 10 seconds to keep connection and Chrome SW active
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_socket != null && _socket?.readyState == WebSocket.open) {
        _sendRaw({'type': 'PING', 'timestamp': DateTime.now().millisecondsSinceEpoch});
      }
    });

    _socket!.listen(
      (data) {
        _handleIncomingData(data);
      },
      onDone: () {
        if (_socket == socket) {
          _heartbeatTimer?.cancel();
          // Give Chrome service worker a 4-second grace period to reconnect before declaring disconnected
          _disconnectGraceTimer?.cancel();
          _disconnectGraceTimer = Timer(const Duration(seconds: 4), () {
            if (_socket == socket &&
                state.isConnected &&
                (_socket == null || _socket?.readyState != WebSocket.open)) {
              _addLog('[ClipIt Bridge] Extension disconnected');
              state = state.copyWith(
                connectionStatus: BridgeConnectionStatus.disconnected,
                lastError: 'Extension closed the connection.',
              );
            }
          });
        }
      },
      onError: (Object error) {
        if (_socket == socket) {
          _addLog('[ClipIt Bridge] Client socket error: $error');
          state = state.copyWith(
            connectionStatus: BridgeConnectionStatus.error,
            lastError: error.toString(),
          );
        }
      },
    );
  }

  void _handleIncomingData(dynamic rawData) {
    try {
      final decoded = jsonDecode(rawData as String) as Map<String, dynamic>;
      final type = decoded['type'] as String?;

      switch (type) {
        case 'PING':
          // Reply with PONG to satisfy extension heartbeat
          _sendRaw({'type': 'PONG'});
          break;

        case 'PONG':
          // Heartbeat reply acknowledged
          break;

        case 'HELLO':
          // Cancel timeout and grace period immediately on valid handshake
          _timeoutTimer?.cancel();
          _countdownTimer?.cancel();
          _disconnectGraceTimer?.cancel();

          final tabUrl = decoded['tabUrl'] as String? ?? 'ChatGPT';
          final platform = decoded['platform'] as String?;
          _addLog('[ClipIt Bridge] Extension connected (${platform ?? 'AI Chatbot'} - Tab: $tabUrl)');

          // Send welcome acknowledgment back to extension
          _sendRaw({
            'type': 'WELCOME',
            'status': 'connected',
            'server': 'ClipIt Bridge v1.3',
          });

          state = state.copyWith(
            connectionStatus: BridgeConnectionStatus.connected,
            connectedUrl: tabUrl,
            connectedPlatform: platform,
            lastError: null,
          );
          break;

        case 'RESPONSE':
          _promptTimeoutTimer?.cancel();
          final responseText = decoded['text'] as String? ?? '';
          final promptId = decoded['id'] as String?;
          final platform = decoded['platform'] as String?;
          _addLog('[ClipIt Bridge] Response received (${responseText.length} chars)');

          // Acknowledge receipt and UI display immediately back to the Chrome Extension
          _sendRaw({
            'type': 'ACK_RESPONSE',
            'status': 'displayed',
            'id': ?promptId,
            'textLength': responseText.length,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });

          // Dispatch to any awaiting sendPromptAndWait future
          final cleaned = _stripCodeFence(responseText);
          if (promptId != null && _pendingPromptCompleters.containsKey(promptId)) {
            _pendingPromptCompleters.remove(promptId)!.complete(cleaned);
          } else if (_fallbackPromptCompleter != null && !_fallbackPromptCompleter!.isCompleted) {
            _fallbackPromptCompleter!.complete(cleaned);
            _fallbackPromptCompleter = null;
          }

          state = state.copyWith(
            promptStatus: BridgePromptStatus.completed,
            lastResponse: responseText,
            connectedPlatform: platform ?? state.connectedPlatform,
            isResponseDisplayed: true,
          );
          break;

        case 'STATUS':
          final message = decoded['message'] as String? ?? '';
          final platform = decoded['platform'] as String?;
          final tabUrl = decoded['tabUrl'] as String?;
          _addLog('[Chrome Extension] $message');
          if (platform != null || tabUrl != null) {
            state = state.copyWith(
              connectedPlatform: platform ?? state.connectedPlatform,
              connectedUrl: tabUrl ?? state.connectedUrl,
            );
          }
          break;

        case 'ERROR':
          _promptTimeoutTimer?.cancel();
          final errorMsg = decoded['error'] as String? ?? 'Unknown error from extension';
          _addLog('[ClipIt Bridge] Error from extension: $errorMsg');
          state = state.copyWith(
            promptStatus: BridgePromptStatus.error,
            lastError: errorMsg,
          );
          break;

        default:
          _addLog('[ClipIt Bridge] Unknown message type: $type');
      }
    } catch (e) {
      _addLog('[ClipIt Bridge] Failed to parse incoming JSON: $e');
    }
  }

  /// Sends a prompt to the extension to type into the active AI chatbot and return the response.
  Future<void> sendPrompt(String prompt) async {
    if (!state.isConnected || _socket == null) {
      _addLog('[ClipIt Bridge] Cannot send prompt: Bridge is not connected');
      state = state.copyWith(
        promptStatus: BridgePromptStatus.error,
        lastError: 'Cannot send prompt: Bridge is not connected to Chrome extension.',
      );
      return;
    }

    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return;

    final platformName = state.effectivePlatform;
    _addLog('[ClipIt Bridge] Sending message to $platformName: "$trimmed"');

    _promptTimeoutTimer?.cancel();
    _promptTimeoutTimer = Timer(const Duration(seconds: 90), () {
      if (state.isSending) {
        _addLog('[ClipIt Bridge] Prompt response timed out after 90s');
        state = state.copyWith(
          promptStatus: BridgePromptStatus.error,
          lastError: 'Timed out waiting for $platformName response. Please check the $platformName browser tab.',
        );
      }
    });

    state = state.copyWith(
      promptStatus: BridgePromptStatus.waiting,
      lastPrompt: trimmed,
      lastResponse: null,
      lastError: null,
      isResponseDisplayed: false,
    );

    final payload = {
      'type': 'SEND_PROMPT',
      'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
      'prompt': trimmed,
    };

    _sendRaw(payload);
  }

  void _sendRaw(Map<String, dynamic> data) {
    try {
      _socket?.add(jsonEncode(data));
    } catch (e) {
      _addLog('[ClipIt Bridge] Error sending raw payload: $e');
    }
  }

  // ── Pipeline-aware prompt delivery ────────────────────────────────────────

  /// Sends a prompt and returns a [Future<String>] that resolves when the
  /// extension delivers the full ChatGPT response.
  ///
  /// Used by the pipeline provider instead of watching state.
  /// Handles JSON code-fence stripping (Part 7 guard 1).
  Future<String> sendPromptAndWait(
    String prompt, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    if (!state.isConnected || _socket == null) {
      _addLog('[ClipIt Bridge] Error: Extension bridge is not connected (ws://127.0.0.1:$defaultPort).');
      throw StateError(
        'ClipIt Bridge is not connected to browser extension (ws://127.0.0.1:$defaultPort). '
        'Please ensure your AI tab (ChatGPT / Gemini / Claude) is open with the ClipIt extension enabled and connected.',
      );
    }

    final completer = Completer<String>();
    final id = 'pipeline_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}';

    _pendingPromptCompleters[id] = completer;
    _fallbackPromptCompleter = completer;

    Timer? localTimer;
    localTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        _pendingPromptCompleters.remove(id);
        if (_fallbackPromptCompleter == completer) {
          _fallbackPromptCompleter = null;
        }
        completer.completeError(
          TimeoutException('ChatGPT did not respond within ${timeout.inSeconds}s', timeout),
        );
      }
    });

    final payload = {
      'type': 'SEND_PROMPT',
      'id': id,
      'prompt': prompt.trim(),
    };
    _sendRaw(payload);

    state = state.copyWith(
      promptStatus: BridgePromptStatus.waiting,
      lastPrompt: prompt.trim(),
      lastResponse: null,
      lastError: null,
      isResponseDisplayed: false,
    );

    return completer.future.whenComplete(() {
      localTimer?.cancel();
    });
  }

  /// Strips markdown code fences from ChatGPT responses (Part 7 guard 1).
  /// Also extracts the JSON object from first { to last } as a fallback.
  static String stripAndExtractJson(String raw) => _stripCodeFence(raw);

  static String _stripCodeFence(String raw) {
    var s = raw.trim();
    // Remove ```json ... ``` or ``` ... ```
    if (s.startsWith('```')) {
      final firstNewline = s.indexOf('\n');
      if (firstNewline != -1) s = s.substring(firstNewline + 1);
      if (s.endsWith('```')) s = s.substring(0, s.length - 3).trim();
    }
    // Extract from first { to last }
    final firstBrace = s.indexOf('{');
    final lastBrace = s.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace > firstBrace) {
      s = s.substring(firstBrace, lastBrace + 1);
    }
    return s.trim();
  }

  /// Generates a valid JSON mock response for unit tests.
  @visibleForTesting
  String generateSimulatedResponseForPrompt(String prompt) {
    if (prompt.contains('[CHUNK_DATA]')) {
      return jsonEncode({
        "video_id": "vid_simulated",
        "chunk_id": "chunk_001",
        "title_prediction": "Podcast Highlights & High Stakes Story",
        "clips": [
          {
            "clip_id": "clip_001_001",
            "status": "FOR_SURE",
            "start": 1.0,
            "end": 19.5,
            "duration": 18.5,
            "clip_type": "HOT_TAKE",
            "hook_text": "Bhai aaj toh podcast mein sabse crazy scene",
            "reason": "Provocative premise opening within the first 3 seconds with high comedic energy.",
            "needs_validation": false,
            "validation_notes": null,
            "context_flags": [],
            "editing": {
              "visual_effects": [],
              "sound_effects": [],
              "transitions": [],
              "silence_removals": []
            }
          },
          {
            "clip_id": "clip_001_002",
            "status": "FOR_SURE",
            "start": 20.0,
            "end": 43.5,
            "duration": 23.5,
            "clip_type": "STORY_PAYOFF",
            "hook_text": "Maine seedha bola ki agar quality deliver",
            "reason": "Complete comedic unit with clear setup, escalation, and unexpected payoff.",
            "needs_validation": false,
            "validation_notes": null,
            "context_flags": [],
            "editing": {
              "visual_effects": [],
              "sound_effects": [],
              "transitions": [],
              "silence_removals": []
            }
          }
        ],
        "error": null
      });
    }

    if (prompt.contains('[VALIDATION_DATA]')) {
      return jsonEncode({
        "video_id": "vid_simulated",
        "validation_id": "val_001",
        "validations": []
      });
    }

    if (prompt.contains('[EDIT_PLANNER_DATA]')) {
      return jsonEncode({
        "edit_plans": [
          {
            "clip_id": "clip_001_001",
            "rating": 94,
            "visual_effects": [],
            "sound_effects": [],
            "transitions": [],
            "silence_shortenings": []
          },
          {
            "clip_id": "clip_001_002",
            "rating": 91,
            "visual_effects": [],
            "sound_effects": [],
            "transitions": [],
            "silence_shortenings": []
          }
        ]
      });
    }

    // Default: master prompt setup response per spec
    return jsonEncode({"status": "READY"});
  }

  /// Activates an extra 30-second pipeline keep-alive ping during long jobs.
  /// Call [stopPipelineKeepAlive] when the pipeline finishes.
  Timer? _pipelineKeepAliveTimer;

  void startPipelineKeepAlive() {
    _pipelineKeepAliveTimer?.cancel();
    _pipelineKeepAliveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_socket != null && _socket?.readyState == WebSocket.open) {
        _sendRaw({'type': 'PING', 'source': 'pipeline_keepalive'});
      }
    });
    _addLog('[ClipIt Bridge] Pipeline keep-alive started (30s interval)');
  }

  void stopPipelineKeepAlive() {
    _pipelineKeepAliveTimer?.cancel();
    _pipelineKeepAliveTimer = null;
    _addLog('[ClipIt Bridge] Pipeline keep-alive stopped');
  }

  void _closeSocketAndServerOnly() {
    _promptTimeoutTimer?.cancel();
    _heartbeatTimer?.cancel();
    _disconnectGraceTimer?.cancel();
    for (final c in _pendingPromptCompleters.values) {
      if (!c.isCompleted) {
        c.completeError(StateError('ClipIt Bridge socket closed'));
      }
    }
    _pendingPromptCompleters.clear();
    _fallbackPromptCompleter = null;
    _socket?.close();
    _socket = null;
    _server?.close(force: true);
    _server = null;
  }

  /// Cleanly closes the WebSocket server, client, and timers.
  Future<void> stop() async {
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    _promptTimeoutTimer?.cancel();
    _heartbeatTimer?.cancel();
    _disconnectGraceTimer?.cancel();
    _closeSocketAndServerOnly();

    if (state.connectionStatus != BridgeConnectionStatus.disconnected) {
      _addLog('[ClipIt Bridge] Bridge stopped cleanly');
      state = state.copyWith(
        connectionStatus: BridgeConnectionStatus.disconnected,
        promptStatus: BridgePromptStatus.idle,
      );
    }
  }
}

/// Riverpod provider exposing the ChatGPT Bridge service and state.
final chatGptBridgeProvider =
    NotifierProvider<ChatGptBridgeService, ChatGptBridgeState>(
  ChatGptBridgeService.new,
);
