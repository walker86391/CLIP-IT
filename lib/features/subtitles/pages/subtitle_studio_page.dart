import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/providers/video_upload_provider.dart';
import '../../projects/components/interactive_3d_device_preview.dart';
import '../../projects/components/workflow_progress_stepper.dart';
import '../../projects/providers/project_workflow_provider.dart';
import '../providers/subtitle_studio_provider.dart';
import '../widgets/subtitle_accordion_sections.dart';
import '../widgets/subtitle_canvas_overlay.dart';

/// Stage 2: Subtitle Studio Page.
///
/// Layout:
/// - TOP: Navigation bar with Back, WorkflowProgressStepper (Step 2 active),
///   lightweight preview status badge, and Next button.
/// - LEFT: Compact stationary phone preview (unscaled 252x495, no tilt, isFrozen: true),
///   hosting the interactive SubtitleCanvasOverlay with blue snapping guidelines.
/// - RIGHT: Subtitle Studio Editor with Heading, Subheading, and 3 Expandable Accordions:
///   1. STYLE (60 viral presets, categories, search, hover-to-preview)
///   2. SETTINGS (Segmented color capsule, typography, conditional sliders, position)
///   3. EFFECTS (Entrance/exit animations, active-word emphasis, box/underline controls)
class SubtitleStudioPage extends ConsumerStatefulWidget {
  const SubtitleStudioPage({
    this.onBack,
    this.onNext,
    this.onStepTapped,
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final ValueChanged<int>? onStepTapped;

  @override
  ConsumerState<SubtitleStudioPage> createState() => _SubtitleStudioPageState();
}

class _SubtitleStudioPageState extends ConsumerState<SubtitleStudioPage> {
  @override
  Widget build(BuildContext context) {
    final workflowState = ref.watch(projectWorkflowProvider);
    final uploadState = ref.watch(videoUploadProvider);

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
                // ── Left Column: 3D Device Viewport & Media Player ─────────
                Expanded(
                  flex: 5,
                  child: Interactive3dDevicePreview(
                    deviceType: workflowState.selectedDevice,
                    aspectRatio: workflowState.selectedRatio,
                    previewPlatformBlocks:
                        workflowState.previewPlatformBlocks,
                    videoFilePath: uploadState.filePath,
                    isFrozen: false,
                    showScrubber: true,
                    isMuted: workflowState.isVideoMuted,
                    onToggleMute: () {
                      ref
                          .read(projectWorkflowProvider.notifier)
                          .toggleVideoMuted();
                    },
                    onPlayPauseChanged: (isPlaying) {
                      ref
                          .read(subtitleStudioProvider.notifier)
                          .setIsPlayingPreview(isPlaying);
                    },
                    onTogglePlatformBlocks: () {
                      ref
                          .read(projectWorkflowProvider.notifier)
                          .togglePreviewPlatformBlocks();
                    },
                    overlayContent: const SubtitleCanvasOverlay(),
                    bottomWidget: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131522),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF232536),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Drag subtitle to position • Center snaps blue',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Subtle Vertical Divider
                Container(
                  width: 1.0,
                  color: const Color(0xFF1E2030),
                ),

                // ── Right Column: Subtitle Studio Editor ───────────────────
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
                        // Studio Heading & Subheading
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Subtitles',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                      color: Color(0xFFF3F4F8),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Choose your caption style, customize its appearance, and control how every word appears.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Selected preset badge
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
                                  const Icon(
                                    Icons.auto_awesome,
                                    size: 14,
                                    color: Color(0xFFC4B5FD),
                                  ),
                                  const SizedBox(width: 6),
                                  Consumer(
                                    builder: (context, ref, _) {
                                      final presetName = ref.watch(
                                        subtitleStudioProvider.select(
                                          (s) => s.selectedPreset.name,
                                        ),
                                      );
                                      return Text(
                                        presetName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFF3F4F8),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // The Three Main Expandable Sections (Style, Settings, Effects)
                        const SubtitleAccordionSections(),

                        const SizedBox(height: 24),

                        // Bottom Actions: Previous & Next Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton.icon(
                              onPressed: widget.onBack,
                              icon: const Icon(Icons.arrow_back_rounded, size: 16),
                              label: const Text('Previous: Reframing'),
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
                                          'Subtitle styling saved! Proceeding to Step 3: Video Look.',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    );
                                  },
                              icon: const Text(
                                'Next: Video Look',
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

  /// Top navigation bar matching existing design tokens:
  /// `< Back`   `Subtitle Studio`   `Stepper: (✓) [2] 3 4`   `Lightweight Style Preview Pill`
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
                'Subtitle Studio',
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
            currentStep: 2,
            totalSteps: 6,
            onStepTapped: widget.onStepTapped,
          ),

          // Right: ENABLE/DISABLE Subtitle Toggle & Preview Status Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ENABLE/DISABLE SUBTITLE Toggle Switch Slider
              Consumer(
                builder: (context, ref, _) {
                  final enabled = ref.watch(
                    subtitleStudioProvider.select(
                      (s) => s.activeConfig.subtitlesEnabled,
                    ),
                  );
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141624),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: enabled
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
                            : const Color(0xFF282B3E),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ENABLE/DISABLE SUBTITLE',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: enabled
                                ? const Color(0xFFC4B5FD)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 20,
                          width: 34,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Switch(
                              value: enabled,
                              activeThumbColor: const Color(0xFF8B5CF6),
                              activeTrackColor: const Color(0xFF4C1D95),
                              inactiveThumbColor: const Color(0xFF6B7280),
                              inactiveTrackColor: const Color(0xFF1F2233),
                              onChanged: (val) {
                                ref
                                    .read(subtitleStudioProvider.notifier)
                                    .setSubtitlesEnabled(val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(width: 14),

              // Small preview-status label indicating lightweight style preview
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
                      'Interactive Style Preview',
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
