import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class NotificationThread {
  const NotificationThread({
    required this.id,
    required this.sender,
    required this.title,
    required this.preview,
    required this.time,
    required this.unread,
    this.isWarning = false,
    required this.messages,
  });

  final String id;
  final String sender;
  final String title;
  final String preview;
  final String time;
  final bool unread;
  final bool isWarning;
  final List<Map<String, String>> messages;

  NotificationThread copyWith({
    bool? unread,
  }) {
    return NotificationThread(
      id: id,
      sender: sender,
      title: title,
      preview: preview,
      time: time,
      unread: unread ?? this.unread,
      isWarning: isWarning,
      messages: messages,
    );
  }
}

class MessagesNotifier extends Notifier<List<NotificationThread>> {
  @override
  List<NotificationThread> build() {
    return [
      const NotificationThread(
        id: 'thread_export_ready',
        sender: 'ClipIt AI Assistant',
        title: 'Export ready: 12 clips from AI Podcast #42',
        preview:
            'All 12 viral clips have finished processing and are ready for preview and download.',
        time: '18:24',
        unread: false,
        messages: [
          {
            'sender': 'ClipIt System',
            'time': '18:20',
            'text':
                'Your job "AI & Creative Tools Podcast #42.mp4" has completed rendering with 1080p60 presets.',
          },
          {
            'sender': 'ClipIt System',
            'time': '18:24',
            'text':
                '12 vertical clips have been saved to your library. 3 clips were scored above 90 Viral Index based on pacing and hook quality.',
          },
        ],
      ),
      const NotificationThread(
        id: 'thread_product_update',
        sender: 'Product Updates',
        title: 'New Feature: Multi-Speaker Active Auto-Tracking',
        preview:
            'ClipIt now automatically switches camera angles when speakers take turns talking.',
        time: 'Oct 14',
        unread: false,
        messages: [
          {
            'sender': 'ClipIt Team',
            'time': 'Oct 14 10:00',
            'text':
                'Introducing Active Auto-Tracking: ClipIt can now detect when two speakers are talking and automatically split or switch the 9:16 frame between them.',
          },
        ],
      ),
      const NotificationThread(
        id: 'thread_welcome',
        sender: 'Account & Subscription',
        title: 'Welcome to ClipIt Studio',
        preview:
            'Your account has been setup with unlimited basic clips and exports.',
        time: 'Oct 10',
        unread: false,
        messages: [
          {
            'sender': 'ClipIt Support',
            'time': 'Oct 10 09:30',
            'text':
                'Welcome to ClipIt! Start by uploading your first long-form video or importing from YouTube on the Home screen.',
          },
        ],
      ),
    ];
  }

  void markAsRead(String threadId) {
    state = [
      for (final thread in state)
        if (thread.id == threadId) thread.copyWith(unread: false) else thread,
    ];
  }

  void addStorageWarning({
    required double usedGb,
    required double allocatedGb,
  }) {
    final existingIdx = state.indexWhere((t) => t.id == 'storage_warning');
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final warningThread = NotificationThread(
      id: 'storage_warning',
      sender: 'System Storage Monitor',
      title: 'Storage Warning: Allocated Local Storage Full',
      preview:
          'Your allocated local storage is full (${usedGb.toStringAsFixed(1)} GB / ${allocatedGb.round()} GB used).',
      time: timeStr,
      unread: true,
      isWarning: true,
      messages: [
        {
          'sender': 'Storage Monitor',
          'time': timeStr,
          'text':
              'WARNING: You have used ${usedGb.toStringAsFixed(2)} GB of your ${allocatedGb.round()} GB allocated storage limit.',
        },
        {
          'sender': 'Storage Monitor',
          'time': timeStr,
          'text':
              'Your allocated storage is full. Please delete unneeded clips or increase your allocation in Account & Profile to avoid export interruptions.',
        },
      ],
    );

    if (existingIdx != -1) {
      final updated = List<NotificationThread>.from(state);
      updated[existingIdx] = warningThread;
      state = updated;
    } else {
      state = [warningThread, ...state];
    }
  }
}

final messagesProvider =
    NotifierProvider<MessagesNotifier, List<NotificationThread>>(
  MessagesNotifier.new,
);
