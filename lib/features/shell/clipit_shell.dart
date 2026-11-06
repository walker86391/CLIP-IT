import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/core_providers.dart';
import '../../core/services/system_metrics_service.dart';
import '../../ui/components/app_top_bar.dart';
import '../clips/pages/clips_page.dart';
import '../downloads/pages/downloads_page.dart';
import '../home/pages/home_page.dart';
import '../messages/pages/messages_page.dart';
import '../pipeline/pages/ongoing_process_page.dart';
import '../pipeline/providers/pipeline_provider.dart';
import '../profile/pages/profile_page.dart';
import '../projects/components/interactive_3d_device_preview.dart';
import '../projects/pages/project_workflow_coordinator.dart';
import '../repurpose/pages/repurpose_page.dart';
import '../settings/pages/settings_page.dart';

/// Destination item data for the left sidebar.
class _SidebarItemData {
  const _SidebarItemData({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

/// ClipIt Application Shell:
/// - Desktop-first expandable/collapsible sidebar (~68px collapsed, ~240px expanded).
/// - Responsive main workspace where content resizes & reflows alongside the sidebar.
/// - Desktop application top bar with page title, search shortcut, and status.
/// - Bottom system status bar with live CPU/GPU/RAM metrics and version.
class ClipItShell extends ConsumerStatefulWidget {
  const ClipItShell({this.navigationShell, super.key});

  final StatefulNavigationShell? navigationShell;

  @override
  ConsumerState<ClipItShell> createState() => _ClipItShellState();
}

class _ClipItShellState extends ConsumerState<ClipItShell> {
  int _selectedIndex = 0;
  bool _isExpanded = false;

  static const List<_SidebarItemData> _items = [
    _SidebarItemData(label: 'Home', icon: Icons.home_rounded),
    _SidebarItemData(label: 'Clip Editor', icon: Icons.auto_fix_high_rounded),
    _SidebarItemData(label: 'Clips', icon: Icons.movie_creation_outlined),
    _SidebarItemData(label: 'Repurpose', icon: Icons.auto_awesome_motion_outlined),
    _SidebarItemData(label: 'Downloads', icon: Icons.download_outlined),
    _SidebarItemData(label: 'Ongoing Process', icon: Icons.bolt_rounded),
    _SidebarItemData(label: 'Messages', icon: Icons.mail_outline_rounded),
    _SidebarItemData(label: 'Profile', icon: Icons.person_outline_rounded),
    _SidebarItemData(label: 'Settings', icon: Icons.settings_outlined),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == 1 && index != 1) {
      // Exiting 'Clip Editor' tab: automatically pause video playback in left panel
      Interactive3dDevicePreview.pausePlayback();
    }

    setState(() {
      _selectedIndex = index;
    });

    if (ref.read(shellNavigationIndexProvider) != index) {
      ref.read(shellNavigationIndexProvider.notifier).setIndex(index);
    }

    if (widget.navigationShell != null) {
      widget.navigationShell!.goBranch(index);
    }
  }

  void _navigateToClipEditor() {
    _onItemTapped(1);
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Widget _buildActivePage(int index) {
    switch (index) {
      case 0:
        return HomePage(
          onLongFormContentTap: _navigateToClipEditor,
          onNextTap: _navigateToClipEditor,
        );
      case 1:
        return ProjectWorkflowCoordinator(
          onBackToHome: () => _onItemTapped(0),
        );
      case 2:
        return const ClipsPage();
      case 3:
        return const RepurposePage();
      case 4:
        return const DownloadsPage();
      case 5:
        return const OngoingProcessPage();
      case 6:
        return const MessagesPage();
      case 7:
        return const ProfilePage();
      case 8:
        return const SettingsPage();
      default:
        return HomePage(
          onLongFormContentTap: _navigateToClipEditor,
          onNextTap: _navigateToClipEditor,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetIndex = ref.watch(shellNavigationIndexProvider);
    if (targetIndex != _selectedIndex) {
      if (_selectedIndex == 1 && targetIndex != 1) {
        // Exiting 'Clip Editor' tab: automatically pause video playback in left panel
        Interactive3dDevicePreview.pausePlayback();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedIndex != targetIndex) {
          _onItemTapped(targetIndex);
        }
      });
    }

    final currentItem = _items[_selectedIndex.clamp(0, _items.length - 1)];

    return Scaffold(
      backgroundColor: const Color(0xFF0F1016),
      body: Column(
        children: [
          // ── Main workspace row: Sidebar + Content ─────────────────────
          Expanded(
            child: Row(
              children: [
                // 1. Expandable / Collapsible Desktop Sidebar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: _isExpanded ? 240 : 68,
                  decoration: const BoxDecoration(
                    color: Color(0xFF13141E),
                    border: Border(
                      right: BorderSide(
                        color: Color(0xFF222432),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: 68,
                      maxWidth: 240,
                      child: SizedBox(
                        width: _isExpanded ? 240 : 68,
                        child: Column(
                          children: [
                            const SizedBox(height: 14),
                            // Top Logo
                            _BrandLogoHeader(isExpanded: _isExpanded),
                            const SizedBox(height: 14),

                            // Navigation items list
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                  final item = _items[index];
                                  final isSelected = _selectedIndex == index;

                                  return _SidebarButton(
                                    item: item,
                                    isSelected: isSelected,
                                    isExpanded: _isExpanded,
                                    onTap: () => _onItemTapped(index),
                                  );
                                },
                              ),
                            ),

                            // Bottom Collapse / Expand Button
                            _ExpandCollapseButton(
                              isExpanded: _isExpanded,
                              onToggle: _toggleExpanded,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Main Content Area (resizes / reflows alongside sidebar)
                Expanded(
                  child: Column(
                    children: [
                      // Desktop Top Bar Header (omitted on Home and Genre Selection to match user design)
                      if (_selectedIndex != 0 && _selectedIndex != 1) ...[
                        Builder(
                          builder: (context) {
                            final activeJob = ref.watch(pipelineJobProvider);
                            final isRunning = activeJob != null && activeJob.isActive;
                            final status = isRunning
                                ? '${activeJob.currentStageLabel} (${(activeJob.overallProgress * 100).round()}%)'
                                : 'No active jobs';
                            return AppTopBar(
                              title: currentItem.label,
                              jobStatus: status,
                              hasActiveJobs: isRunning,
                            );
                          },
                        ),
                      ],

                      // Active View
                      Expanded(
                        child: widget.navigationShell != null
                            ? widget.navigationShell!
                            : _buildActivePage(_selectedIndex),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Status Bar ──────────────────────────────────────────
          const _SystemStatusBar(),
        ],
      ),
    );
  }
}

/// Logo header at the top of the sidebar.
class _BrandLogoHeader extends StatelessWidget {
  const _BrandLogoHeader({required this.isExpanded});

  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    if (isExpanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _logoBox(),
              const SizedBox(width: 10),
              const Text(
                'CLIP-IT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: Color(0xFFF3F4F8),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF221F33),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'STUDIO',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _logoBox(),
        const SizedBox(height: 4),
        const Text(
          'CLIP-IT',
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: Color(0xFFF3F4F8),
          ),
        ),
      ],
    );
  }

  Widget _logoBox() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF191A25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF282A3A), width: 1.0),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.smart_display_rounded,
            size: 17,
            color: Colors.white,
          ),
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single interactive sidebar button with active pill and hover brightness.
class _SidebarButton extends StatefulWidget {
  const _SidebarButton({
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  final _SidebarItemData item;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isSelected = widget.isSelected;
    final isExpanded = widget.isExpanded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          key: Key('sidebar_item_${item.label}'),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            height: 40,
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 10 : 0,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF201D30)
                  : (_hovered
                      ? const Color(0xFF1A1B26)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: const Color(0xFF383254), width: 1.0)
                  : null,
            ),
            child: Row(
              mainAxisAlignment:
                  isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                // Thin purple accent indicator on active item
                if (isSelected && isExpanded) ...[
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  item.icon,
                  size: 19,
                  color: isSelected
                      ? const Color(0xFF8B5CF6)
                      : (_hovered
                          ? const Color(0xFFE2E4ED)
                          : const Color(0xFF7E8299)),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (_hovered
                                ? const Color(0xFFE2E4ED)
                                : const Color(0xFF9EA1B5)),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The bottom Expand / Collapse Chevron Button
class _ExpandCollapseButton extends StatelessWidget {
  const _ExpandCollapseButton({
    required this.isExpanded,
    required this.onToggle,
  });

  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: const Key('sidebar_toggle_button'),
        onTap: onToggle,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF161722),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF262838), width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isExpanded
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 20,
                color: const Color(0xFF8E92A6),
              ),
              if (isExpanded) ...[
                const SizedBox(width: 8),
                const Text(
                  'Collapse',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E92A6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fixed bottom status bar across the bottom of the window.
class _SystemStatusBar extends ConsumerStatefulWidget {
  const _SystemStatusBar();

  @override
  ConsumerState<_SystemStatusBar> createState() => _SystemStatusBarState();
}

class _SystemStatusBarState extends ConsumerState<_SystemStatusBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(systemMetricsProvider.notifier).fetchOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(systemMetricsProvider);

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0D12),
        border: Border(
          top: BorderSide(color: Color(0xFF1B1C26), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Live status dot
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          const Text(
            'Clip-It running!',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            metrics.displayText,
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF72758A),
            ),
          ),
          const Spacer(),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'V26.4 ',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF72758A),
                  ),
                ),
                TextSpan(
                  text: 'running',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
