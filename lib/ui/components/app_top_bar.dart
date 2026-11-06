import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';

/// Desktop application top bar (60px height).
///
/// Contains:
/// - Left: Current page title
/// - Center: Real-time search bar that filters items across titles
/// - Right: Active jobs status indicator (clickable to switch to Processing tab)
class AppTopBar extends ConsumerStatefulWidget {
  const AppTopBar({
    required this.title,
    this.jobStatus = 'No active jobs',
    this.hasActiveJobs = false,
    this.onSearchTap,
    this.onNotificationTap,
    super.key,
  });

  final String title;
  final String jobStatus;
  final bool hasActiveJobs;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;

  @override
  ConsumerState<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends ConsumerState<AppTopBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(globalSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(globalSearchQueryProvider);
    if (_searchController.text != query) {
      _searchController.text = query;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: query.length),
      );
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF101118),
        border: Border(
          bottom: BorderSide(color: Color(0xFF222432), width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Current Page Title only (Personal pill removed)
          Text(
            widget.title.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFFF3F4F8),
            ),
          ),

          const SizedBox(width: 16),

          // Center: Functional Search Bar
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF161722),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: query.isNotEmpty
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF262838),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: Color(0xFF8E92A6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          ref.read(globalSearchQueryProvider.notifier).setQuery(val);
                        },
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFFF3F4F8),
                        ),
                        cursorColor: const Color(0xFF8B5CF6),
                        decoration: const InputDecoration(
                          hintText: 'Search whole title…',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B6E82),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          ref.read(globalSearchQueryProvider.notifier).clear();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: Color(0xFF8E92A6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Right: Active jobs indicator only (Notification and Name removed)
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              // Clicking active job indicator navigates directly to the Processing tab (index 5)
              ref.read(shellNavigationIndexProvider.notifier).setIndex(5);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF151621),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: widget.hasActiveJobs
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
                      : const Color(0xFF242636),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: widget.hasActiveJobs
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6B6E82),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.jobStatus,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: widget.hasActiveJobs
                          ? const Color(0xFFF3F4F8)
                          : const Color(0xFF8E92A6),
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
