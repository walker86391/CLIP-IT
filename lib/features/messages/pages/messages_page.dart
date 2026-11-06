import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/messages_provider.dart';

/// Professional Inbox & Notification Center for ClipIt.
class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  String? _selectedThreadId;

  @override
  Widget build(BuildContext context) {
    final threads = ref.watch(messagesProvider);

    // Determine current active thread safely
    final int activeIndex;
    if (threads.isEmpty) {
      activeIndex = 0;
    } else if (_selectedThreadId != null) {
      final found = threads.indexWhere((t) => t.id == _selectedThreadId);
      activeIndex = found != -1 ? found : 0;
    } else {
      activeIndex = 0;
    }

    final NotificationThread? activeThread =
        threads.isNotEmpty ? threads[activeIndex] : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1016),
      body: Row(
        children: [
          // Left Pane: Thread List (width ~340)
          Container(
            width: 340,
            decoration: const BoxDecoration(
              color: Color(0xFF13141E),
              border: Border(
                right: BorderSide(color: Color(0xFF222432), width: 1.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'INBOX & NOTIFICATIONS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: Color(0xFFF3F4F8),
                        ),
                      ),
                      Icon(
                        Icons.mark_email_read_outlined,
                        size: 16,
                        color: Color(0xFF7E8299),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF202230), height: 1),
                Expanded(
                  child: threads.isEmpty
                      ? const Center(
                          child: Text(
                            'No notifications',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B6E82),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: threads.length,
                          separatorBuilder: (_, _) => const Divider(
                            color: Color(0xFF1A1C28),
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final item = threads[index];
                            final isSelected =
                                activeThread != null && activeThread.id == item.id;

                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedThreadId = item.id;
                                  });
                                  if (item.unread) {
                                    ref
                                        .read(messagesProvider.notifier)
                                        .markAsRead(item.id);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  color: isSelected
                                      ? const Color(0xFF1C1E2C)
                                      : Colors.transparent,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                if (item.unread) ...[
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      color: item.isWarning
                                                          ? const Color(0xFFEF4444)
                                                          : const Color(0xFF8B5CF6),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                ],
                                                if (item.isWarning) ...[
                                                  const Icon(
                                                    Icons.warning_amber_rounded,
                                                    size: 14,
                                                    color: Color(0xFFEF4444),
                                                  ),
                                                  const SizedBox(width: 4),
                                                ],
                                                Flexible(
                                                  child: Text(
                                                    item.sender,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w700
                                                          : FontWeight.w600,
                                                      color: item.isWarning
                                                          ? const Color(0xFFFCA5A5)
                                                          : (isSelected
                                                              ? Colors.white
                                                              : const Color(0xFFD1D5E5)),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            item.time,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              color: Color(0xFF6B6E82),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: item.isWarning
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFFF3F4F8),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.preview,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF7E8299),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Right Pane: Active Thread Content
          Expanded(
            child: activeThread == null
                ? const Center(
                    child: Text(
                      'Select a notification to view details',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6E82),
                      ),
                    ),
                  )
                : Container(
                    color: const Color(0xFF0F1016),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thread Header
                        Container(
                          height: 58,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFF222432),
                                width: 1.0,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (activeThread.isWarning) ...[
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          size: 16,
                                          color: Color(0xFFEF4444),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        activeThread.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: activeThread.isWarning
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFFF3F4F8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'From: ${activeThread.sender}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF7E8299),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: const [
                                  Icon(
                                    Icons.archive_outlined,
                                    size: 18,
                                    color: Color(0xFF7E8299),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Color(0xFF7E8299),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Message List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            itemCount: activeThread.messages.length +
                                (activeThread.isWarning ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (activeThread.isWarning && index == 0) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFEF4444)
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.warning_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Allocated local storage limit exceeded. Increase your allocation in Account & Profile or free up clips to avoid render failures.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFFCA5A5),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final msgIndex = activeThread.isWarning
                                  ? index - 1
                                  : index;
                              final msg = activeThread.messages[msgIndex];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF161722),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: activeThread.isWarning
                                          ? const Color(0xFFEF4444)
                                              .withValues(alpha: 0.3)
                                          : const Color(0xFF242636),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            msg['sender']!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: activeThread.isWarning
                                                  ? const Color(0xFFEF4444)
                                                  : const Color(0xFF8B5CF6),
                                            ),
                                          ),
                                          Text(
                                            msg['time']!,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              color: Color(0xFF6B6E82),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        msg['text']!,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFFDCE0EE),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
