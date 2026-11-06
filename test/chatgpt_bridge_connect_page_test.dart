import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/core/services/chatgpt_bridge_service.dart';
import 'package:clipit/features/projects/pages/chatgpt_bridge_connect_page.dart';

void main() {
  const testWindowSize = Size(1280, 850);

  Widget createSubject({
    VoidCallback? onContinue,
    VoidCallback? onBack,
    ProviderContainer? container,
  }) {
    final page = ChatGptBridgeConnectPage(
      onContinue: onContinue,
      onBack: onBack,
    );

    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: page),
      );
    }
    return ProviderScope(
      child: MaterialApp(home: page),
    );
  }

  testWidgets(
    'ChatGptBridgeConnectPage renders initial UI, hides test chat before connect, and shows How to connect',
    (tester) async {
      tester.view.physicalSize = testWindowSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Heading & Description
      expect(find.text('Connect to your AI chatbot'), findsOneWidget);
      expect(
        find.text(
          'Connect ClipIt to your browser-based AI chatbot to enable automated AI processing.',
        ),
        findsOneWidget,
      );

      // Main Button is initially 'Connect'
      expect(find.text('Connect'), findsOneWidget);
      expect(find.byKey(const Key('chatgpt_bridge_connect_button')), findsOneWidget);

      // How to connect section
      expect(find.text('How to connect'), findsOneWidget);
      expect(find.textContaining('Press Start in the ClipIt Chrome extension'), findsOneWidget);
      expect(find.textContaining('Return to ClipIt'), findsOneWidget);
      expect(find.textContaining('Press Connect here'), findsOneWidget);
      expect(find.textContaining('Wait while ClipIt establishes the local connection bridge'), findsOneWidget);

      // Continue button exists at bottom-right
      expect(find.byKey(const Key('bridge_continue_button')), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Test chat box is NOT visible before connection
      expect(find.text('Test browser connection'), findsNothing);
      expect(find.byKey(const Key('chatgpt_test_send_button')), findsNothing);
    },
  );

  testWidgets(
    'Connected state reveals test chat box and sends message',
    (tester) async {
      tester.view.physicalSize = testWindowSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createSubject(container: container));
      await tester.pumpAndSettle();

      // Manually set connected state on the provider to test UI reactive rendering
      container.read(chatGptBridgeProvider.notifier).state = const ChatGptBridgeState(
        connectionStatus: BridgeConnectionStatus.connected,
        connectedUrl: 'https://chatgpt.com',
      );
      await tester.pump();

      // Now Connected!
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Test browser connection'), findsOneWidget);
      expect(find.text('hi there'), findsOneWidget);
      expect(find.byKey(const Key('chatgpt_test_send_button')), findsOneWidget);

      // Simulate sending and receiving response
      container.read(chatGptBridgeProvider.notifier).state = const ChatGptBridgeState(
        connectionStatus: BridgeConnectionStatus.connected,
        connectedUrl: 'https://chatgpt.com',
        promptStatus: BridgePromptStatus.completed,
        lastPrompt: 'hi there',
        lastResponse: 'Hello! How can I help you today?',
      );
      await tester.pump();

      expect(find.text('Response from ChatGPT:'), findsOneWidget);
      expect(find.byKey(const Key('chatgpt_response_displayed_badge')), findsOneWidget);
      expect(find.text('RESPONSE DISPLAYED'), findsOneWidget);
      expect(find.text('Hello! How can I help you today?'), findsOneWidget);
      expect(find.byKey(const Key('chatgpt_copy_response_button')), findsOneWidget);
      expect(find.text('Copied!'), findsOneWidget);

      // Settle feedback timer
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Copy Response'), findsOneWidget);
    },
  );

  test('ChatGptBridgeService sends ACK_RESPONSE when RESPONSE is received over WebSocket', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = container.read(chatGptBridgeProvider.notifier);
    const testPort = 28489;
    await service.startConnection(port: testPort, timeoutSeconds: 10);

    // Connect client WebSocket simulating Chrome extension
    final clientSocket = await WebSocket.connect('ws://127.0.0.1:$testPort');
    addTearDown(clientSocket.close);

    final receivedMessages = <Map<String, dynamic>>[];
    clientSocket.listen((data) {
      try {
        final decoded = jsonDecode(data as String) as Map<String, dynamic>;
        receivedMessages.add(decoded);
      } catch (_) {}
    });

    // Send HELLO handshake
    clientSocket.add(jsonEncode({
      'type': 'HELLO',
      'client': 'test-extension',
      'tabUrl': 'https://chatgpt.com',
    }));

    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(container.read(chatGptBridgeProvider).isConnected, isTrue);

    // Send RESPONSE from extension
    clientSocket.add(jsonEncode({
      'type': 'RESPONSE',
      'id': 'test_prompt_123',
      'text': 'Here is the real generated response.',
      'status': 'success',
    }));

    await Future<void>.delayed(const Duration(milliseconds: 250));

    // Verify ClipIt updated state with response
    final state = container.read(chatGptBridgeProvider);
    expect(state.promptStatus, equals(BridgePromptStatus.completed));
    expect(state.lastResponse, equals('Here is the real generated response.'));
    expect(state.isResponseDisplayed, isTrue);

    // Verify ACK_RESPONSE was sent back to client
    final ackMessage = receivedMessages.firstWhere(
      (m) => m['type'] == 'ACK_RESPONSE',
      orElse: () => {},
    );
    expect(ackMessage['type'], equals('ACK_RESPONSE'));
    expect(ackMessage['status'], equals('displayed'));
    expect(ackMessage['id'], equals('test_prompt_123'));
    expect(ackMessage['textLength'], equals(36));

    await service.stop();
  });

  testWidgets(
    'Connected state adapts to Claude, Gemini, and Arena AI platforms',
    (tester) async {
      tester.view.physicalSize = testWindowSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createSubject(container: container));
      await tester.pumpAndSettle();

      // Test Claude
      container.read(chatGptBridgeProvider.notifier).state = const ChatGptBridgeState(
        connectionStatus: BridgeConnectionStatus.connected,
        connectedUrl: 'https://claude.ai',
        connectedPlatform: 'Claude',
        promptStatus: BridgePromptStatus.completed,
        lastPrompt: 'hi there',
        lastResponse: 'Hello from Claude!',
      );
      await tester.pump();

      expect(find.text('Claude'), findsOneWidget);
      expect(find.text('Response from Claude:'), findsOneWidget);
      expect(find.text('Hello from Claude!'), findsOneWidget);

      // Test Gemini
      container.read(chatGptBridgeProvider.notifier).state = const ChatGptBridgeState(
        connectionStatus: BridgeConnectionStatus.connected,
        connectedUrl: 'https://gemini.google.com',
        connectedPlatform: 'Gemini',
        promptStatus: BridgePromptStatus.completed,
        lastPrompt: 'hi there',
        lastResponse: 'Greetings from Gemini!',
      );
      await tester.pump();

      expect(find.text('Gemini'), findsOneWidget);
      expect(find.text('Response from Gemini:'), findsOneWidget);
      expect(find.text('Greetings from Gemini!'), findsOneWidget);

      // Test Arena AI (Direct Chat)
      container.read(chatGptBridgeProvider.notifier).state = const ChatGptBridgeState(
        connectionStatus: BridgeConnectionStatus.connected,
        connectedUrl: 'https://lmarena.ai/?mode=direct',
        connectedPlatform: 'Arena AI',
        promptStatus: BridgePromptStatus.completed,
        lastPrompt: 'hi there',
        lastResponse: 'Arena AI Direct Chat response.',
      );
      await tester.pump();

      expect(find.text('Arena AI'), findsOneWidget);
      expect(find.text('Response from Arena AI:'), findsOneWidget);
      expect(find.text('Arena AI Direct Chat response.'), findsOneWidget);
    },
  );

  testWidgets(
    'Error state shows Retry button and enables resending test message',
    (tester) async {
      tester.view.physicalSize = testWindowSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createSubject(container: container));
      await tester.pumpAndSettle();

      container.read(chatGptBridgeProvider.notifier).state = const ChatGptBridgeState(
        connectionStatus: BridgeConnectionStatus.connected,
        connectedUrl: 'https://chatgpt.com',
        promptStatus: BridgePromptStatus.error,
        lastPrompt: 'hi there',
        lastError: 'Timed out waiting for response.',
      );
      await tester.pump();

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Timed out waiting for response.'), findsOneWidget);
      expect(find.byKey(const Key('chatgpt_test_send_button')), findsOneWidget);

      // Tap Retry to re-send (which invokes sendPrompt)
      await tester.tap(find.byKey(const Key('chatgpt_test_send_button')));
      await tester.pump();
      // Since no real socket is connected in this widget test, sendPrompt caught the missing socket
      expect(
        container.read(chatGptBridgeProvider).lastError,
        contains('not connected to Chrome extension'),
      );
    },
  );
}
