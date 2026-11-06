import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/providers/video_upload_provider.dart';
import '../../projects/components/interactive_3d_device_preview.dart';
import '../../projects/components/workflow_progress_stepper.dart';
import '../../projects/providers/project_workflow_provider.dart';
import '../models/branding_models.dart';
import '../providers/branding_provider.dart';
import '../widgets/branding_preview_overlay.dart';
import '../widgets/permanent_branding_panel.dart';
import '../widgets/temporary_overlays_panel.dart';

/// Step 5 — Branding & Overlay Studio Page
///
/// Features:
/// - Reuses stationary interactive 3D device preview on the LEFT.
/// - Demonstrates permanent branding and temporary overlays live in real time.
/// - Subtitles rendered immovably on preview (no dragging, strictly isolated).
/// - Interactive Timeline Scrubber under preview to test appear & disappear timing.
/// - Two main tabs on the RIGHT:
///   1. [ PERMANENT BRANDING ] (Text + Typography + Effects + Opacity)
///   2. [ TEMPORARY OVERLAYS ] (Structure First + Shapes + Typography + Timing + Layers)
/// - Instant live preview with NO "Apply" or "Preview" buttons.
class Step5BrandingPage extends ConsumerStatefulWidget {
  const Step5BrandingPage({
    this.onBack,
    this.onNext,
    this.onStepTapped,
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final ValueChanged<int>? onStepTapped;

  @override
  ConsumerState<Step5BrandingPage> createState() => _Step5BrandingPageState();
}

class _Step5BrandingPageState extends ConsumerState<Step5BrandingPage> {
  @override
  Widget build(BuildContext context) {
    final workflowState = ref.watch(projectWorkflowProvider);
    final uploadState = ref.watch(videoUploadProvider);
    final brandingState = ref.watch(brandingProvider);
    final notifier = ref.read(brandingProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C14),
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Top Navigation Bar ───────────────────────────────────────
            _buildTopNavBar(context, brandingState),

            // ── 2. Main Two-Column Studio Body ──────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left Column: Stationary Video Preview with Branding Overlay
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F101A),
                        border: Border(
                          right: BorderSide(
                            color: Color(0xFF1F2233),
                            width: 1.0,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Interactive3dDevicePreview(
                              deviceType: workflowState.selectedDevice,
                              aspectRatio: workflowState.selectedRatio,
                              previewPlatformBlocks:
                                  workflowState.previewPlatformBlocks,
                              videoFilePath: uploadState.filePath,
                              isMuted: workflowState.isVideoMuted,
                              onToggleMute: () => ref
                                  .read(projectWorkflowProvider.notifier)
                                  .toggleVideoMuted(),
                              onTogglePlatformBlocks: () => ref
                                  .read(projectWorkflowProvider.notifier)
                                  .togglePreviewPlatformBlocks(),
                              isFrozen: false,
                              showScrubber: true,
                              overlayContent: const BrandingPreviewOverlay(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Right Column: Stage 5 Control Panel ────────────────────
                  Expanded(
                    flex: 6,
                    child: Container(
                      color: const Color(0xFF0B0C14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Studio Tabs: [ PERMANENT BRANDING ] [ TEMPORARY OVERLAYS ]
                          _buildStudioTabs(brandingState, notifier),

                          // Active Tab Content
                          Expanded(
                            child: brandingState.activeTab ==
                                    BrandingTab.permanent
                                ? const PermanentBrandingPanel()
                                : const TemporaryOverlaysPanel(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Navigation Bar ─────────────────────────────────────────────────────

  Widget _buildTopNavBar(
    BuildContext context,
    BrandingStudioState brandingState,
  ) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F101A),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF1F2233),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
            tooltip: 'Back to Sound Effects',
          ),
          const SizedBox(width: 8),

          // Title & Badge
          Row(
            children: [
              const Text(
                'ClipIt',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: const Text(
                  'STAGE 6: OVERLAYS & BRANDING',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Color(0xFFC4B5FD),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Centered 5-Step Workflow Stepper
          WorkflowProgressStepper(
            currentStep: 6,
            totalSteps: 6,
            onStepTapped: widget.onStepTapped,
          ),

          const Spacer(),

          // Finish Project & Generate Clips Pipeline Button (Step 6)
          Tooltip(
            message: 'Finish Project and Generate Clips',
            child: ElevatedButton.icon(
              key: const Key('finish_project_button'),
              onPressed: widget.onNext,
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: const Text(
                'Finish Project & Generate Clips →',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                elevation: 4,
                shadowColor: const Color(0x668B5CF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Two Studio Tabs ────────────────────────────────────────────────────────

  Widget _buildStudioTabs(
    BrandingStudioState state,
    BrandingNotifier notifier,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF11121E),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF1F2233),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'PERMANENT BRANDING',
              sublabel: 'Watermarks, Social Handles & Creator Identity',
              icon: Icons.verified_rounded,
              isSelected: state.activeTab == BrandingTab.permanent,
              badgeCount: state.permanentLayers.length,
              onTap: () => notifier.setTab(BrandingTab.permanent),
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: const Color(0xFF1F2233),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'TEMPORARY OVERLAYS',
              sublabel: 'Dynamic Shapes, Callouts & Animated Hooks',
              icon: Icons.layers_rounded,
              isSelected: state.activeTab == BrandingTab.temporary,
              badgeCount: state.temporaryOverlays.length,
              onTap: () => notifier.setTab(BrandingTab.temporary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required String sublabel,
    required IconData icon,
    required bool isSelected,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFFC4B5FD) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF1E2032),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    sublabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isSelected
                          ? const Color(0xFFC4B5FD).withValues(alpha: 0.8)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
