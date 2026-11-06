import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/core/services/chatgpt_bridge_service.dart';

void main() {
  test('Local WebSocket server starts, accepts connection, exchanges messages, and stops cleanly', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 28476);
    final completer = Completer<String>();

    server.listen((HttpRequest request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        socket.listen((data) {
          final decoded = jsonDecode(data as String) as Map<String, dynamic>;
          if (decoded['type'] == 'HELLO') {
            socket.add(jsonEncode({'type': 'WELCOME', 'status': 'connected'}));
          } else if (decoded['type'] == 'SEND_PROMPT') {
            socket.add(jsonEncode({'type': 'RESPONSE', 'id': decoded['id'], 'text': 'Echo: ${decoded['prompt']}'}));
          }
        });
      }
    });

    final client = await WebSocket.connect('ws://127.0.0.1:28476');
    client.listen((data) {
      final decoded = jsonDecode(data as String) as Map<String, dynamic>;
      if (decoded['type'] == 'RESPONSE') {
        completer.complete(decoded['text'] as String);
      }
    });

    client.add(jsonEncode({'type': 'HELLO', 'client': 'test'}));
    client.add(jsonEncode({'type': 'SEND_PROMPT', 'id': '1', 'prompt': 'hi there'}));

    final response = await completer.future.timeout(const Duration(seconds: 5));
    expect(response, 'Echo: hi there');

    await client.close();
    await server.close(force: true);
  });

  test('sendPromptAndWait handles response without Stream already listened to exception', () async {
    final container = ProviderContainer();
    final service = container.read(chatGptBridgeProvider.notifier);
    await service.startConnection(port: 28477, timeoutSeconds: 30);

    // Connect dummy extension client
    final extensionSocket = await WebSocket.connect('ws://127.0.0.1:28477');
    extensionSocket.listen((data) {
      final decoded = jsonDecode(data as String) as Map<String, dynamic>;
      if (decoded['type'] == 'SEND_PROMPT') {
        extensionSocket.add(jsonEncode({
          'type': 'RESPONSE',
          'id': decoded['id'],
          'text': '{"status":"READY"}',
        }));
      }
    });

    extensionSocket.add(jsonEncode({
      'type': 'HELLO',
      'tabUrl': 'https://chatgpt.com',
      'platform': 'ChatGPT',
    }));

    // Wait briefly for handshake
    await Future.delayed(const Duration(milliseconds: 150));

    final res = await service.sendPromptAndWait('hello prompt');
    expect(res, '{"status":"READY"}');

    await extensionSocket.close();
    await service.stop();
    container.dispose();
  });
}
