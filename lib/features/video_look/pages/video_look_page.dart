import '../../subtitles/widgets/immovable_subtitle_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/providers/video_upload_provider.dart';
import '../../projects/components/interactive_3d_device_preview.dart';
import '../../projects/components/workflow_progress_stepper.dart';
import '../../projects/providers/project_workflow_provider.dart';
import '../providers/video_look_provider.dart';
import '../widgets/video_look_accordion_sections.dart';
import '../widgets/video_look_preview_filter.dart';
import '../widgets/video_look_quick_bar.dart';

/// Step 3 — Video Look Page.
///
/// Layout:
/// - TOP: Navigation bar with Back, Title "3 — VIDEO LOOK",
///   WorkflowProgressStepper (Step 3 active), Live Look Preview Badge, and Preview button.
/// - LEFT: Stationary compact device preview (identical to Step 2, width 320px),
///   running the live video playback with real-time [VideoLookPreviewFilter] hardware color grading.
/// - RIGHT: Main Content Area hosting:
///   1. Header with "3 — VIDEO LOOK" and clear descriptive guidance
///   2. Global Look Switches ("Quick Looks" top shortcut bar)
///   3. 15 Expandable Accordion Categories (Strictly ONE open at a time, Icon-only reset)
///   4. Bottom navigation buttons (Previous: Subtitles, Next: Export & Render).
class VideoLookPage extends ConsumerStatefulWidget {
  const VideoLookPage({
    this.onBack,
    this.onNext,
    this.onStepTapped,
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final ValueChanged<int>? onStepTapped;

  @override
  ConsumerState<VideoLookPage> createState() => _VideoLookPageState();
}

class _VideoLookPageState extends ConsumerState<VideoLookPage> {
  @override
  Widget build(BuildContext context) {
    final workflowState = ref.watch(projectWorkflowProvider);
    final uploadState = ref.watch(videoUploadProvider);
    final activeQuickLook = ref.watch(
      videoLookProvider.select((s) => s.activeQuickLook),
    );
    final lookNotifier = ref.read(videoLookProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      body: Column(
        children: [
          // ── Top Navigation Bar ───────────────────────────────────────────
          _buildTopBar(context),

          // ── Main Content Split View ──────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left Column: Stationary Phone Canvas Preview ───
                Expanded(
                  flex: 5,
                  child: Interactive3dDevicePreview(
                    overlayContent: const ImmovableSubtitleOverlay(),
                    deviceType: workflowState.selectedDevice,
                    aspectRatio: workflowState.selectedRatio,
                    previewPlatformBlocks:
                        workflowState.previewPlatformBlocks,
                    onTogglePlatformBlocks: () {
                      ref
                          .read(projectWorkflowProvider.notifier)
                          .togglePreviewPlatformBlocks();
                    },
                    videoFilePath: uploadState.filePath,
                    isFrozen: false,
                    showScrubber: true,
                    isMuted: workflowState.isVideoMuted,
                    onToggleMute: () {
                      ref
                          .read(projectWorkflowProvider.notifier)
                          .toggleVideoMuted();
                    },
                    screenContentWrapper: (coreMedia) {
                      return Consumer(
                        builder: (context, ref, _) {
                          final lookState = ref.watch(videoLookProvider);
                          return VideoLookPreviewFilter(
                            state: lookState,
                            child: coreMedia,
                          );
                        },
                      );
                    },
                    bottomWidget: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131522),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF232536),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 13,
                            color: Color(0xFFC4B5FD),
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Live Look Engine • Real-time Hardware Filters',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF9CA3AF),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Right Column: Video Look Controls ──────────────────────
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 22,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Heading & Subheading
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    '3 — VIDEO LOOK',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                      color: Color(0xFFF3F4F8),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Customize how your video looks — color grading, light treatments, film grain, tones, curves, and creative aesthetic styling.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Active Look Pill Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161528),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.5),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    activeQuickLook.icon,
                                    size: 14,
                                    color: const Color(0xFFC4B5FD),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    activeQuickLook.displayName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFF3F4F8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Global Look Switches: Quick Looks Area ─────────
                        VideoLookQuickBar(
                          selectedQuickLook: activeQuickLook,
                          onSelectQuickLook: lookNotifier.applyQuickLook,
                        ),

                        const SizedBox(height: 18),

                        // ── 15 Accordion Categories (One open at a time) ────
                        const VideoLookAccordionSections(),

                        const SizedBox(height: 24),

                        // ── Bottom Actions: Previous & Next Buttons ────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton.icon(
                              onPressed: widget.onBack,
                              icon: const Icon(Icons.arrow_back_rounded, size: 16),
                              label: const Text('Previous: Subtitles'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFD1D5DB),
                                side: const BorderSide(color: Color(0xFF2C2F44)),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: widget.onNext ??
                                  () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: Color(0xFF1E2032),
                                        content: Text(
                                          'Video Look settings saved! FFmpeg filtergraph is prepared for final rendering.',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    );
                                  },
                              icon: const Text(
                                'Next: Sound Effects',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              label: const Icon(Icons.arrow_forward_rounded, size: 16),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Top navigation bar matching Step 2:
  /// `< Back`   `3 — Video Look`   `Stepper: (✓) (✓) [3] 4`   `Live Look Preview Pill`
  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF10111A),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF1D1F2D),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Back button & Title
          Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onBack,
                  child: Row(
                    children: const [
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: Color(0xFFD1D5DB),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD1D5DB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 28),
              const Text(
                '3 — Video Look',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Color(0xFFF3F4F8),
                ),
              ),
            ],
          ),

          // Center: Standardized 6-Step Workflow Stepper (Always fully visible across steps 1-6)
          WorkflowProgressStepper(
            currentStep: 3,
            totalSteps: 6,
            onStepTapped: widget.onStepTapped,
          ),

          // Right: Live Look Preview Status Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live Look Preview Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF141624),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF282B3E),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Live Look Preview',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD1D5DB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
