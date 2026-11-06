import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/features/messages/providers/messages_provider.dart';
import 'package:clipit/features/profile/providers/storage_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStorage & Notifications Integration Tests', () {
    test('Initial storage state defaults to 10 GB limit', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(localStorageProvider);
      expect(state.allocatedLimitGb, 10.0);
      expect(state.isLoading, true);
    });

    test('addStorageWarning adds warning thread to messagesProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialThreads = container.read(messagesProvider);
      expect(
        initialThreads.any((t) => t.id == 'storage_warning'),
        isFalse,
      );

      container.read(messagesProvider.notifier).addStorageWarning(
            usedGb: 5.87,
            allocatedGb: 5.0,
          );

      final updatedThreads = container.read(messagesProvider);
      final warningThread =
          updatedThreads.firstWhere((t) => t.id == 'storage_warning');

      expect(warningThread.isWarning, isTrue);
      expect(warningThread.unread, isTrue);
      expect(warningThread.title, contains('Storage Warning'));
      expect(warningThread.preview, contains('5.9 GB / 5 GB used'));

      // Test markAsRead
      container.read(messagesProvider.notifier).markAsRead('storage_warning');
      final readThreads = container.read(messagesProvider);
      final readWarning =
          readThreads.firstWhere((t) => t.id == 'storage_warning');
      expect(readWarning.unread, isFalse);
    });

    test('Lowering allocated limit below used storage triggers warning', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for initial scan to complete
      await container.read(localStorageProvider.notifier).refreshUsage();
      final scannedState = container.read(localStorageProvider);

      expect(scannedState.isLoading, isFalse);
      expect(scannedState.usedBytes, greaterThan(0));

      final usedGb = scannedState.usedGb;
      // When limit is set below usedGb (e.g. 5.0 GB if used is ~5.87 GB)
      container.read(localStorageProvider.notifier).setAllocatedLimit(5.0);

      final afterLimitState = container.read(localStorageProvider);
      expect(afterLimitState.allocatedLimitGb, 5.0);

      if (usedGb >= 5.0) {
        expect(afterLimitState.isStorageFull, isTrue);
        final threads = container.read(messagesProvider);
        expect(threads.any((t) => t.id == 'storage_warning'), isTrue);
      }
    });
  });
}
