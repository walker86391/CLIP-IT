import '../../subtitles/widgets/immovable_subtitle_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/ffmpeg_diagnostics_dialog.dart';

import '../../home/providers/video_upload_provider.dart';
import '../../projects/components/interactive_3d_device_preview.dart';
import '../../projects/components/workflow_progress_stepper.dart';
import '../../projects/providers/project_workflow_provider.dart';
import '../data/effect_catalogue.dart';
import '../models/editing_effect.dart';
import '../providers/effects_provider.dart';
import '../widgets/effect_card.dart';
import '../widgets/effects_top_banner_preview.dart';
import '../widgets/effects_video_overlay.dart';
import '../widgets/advanced_video_effects_section.dart';
import '../widgets/video_repair_section.dart';

/// Step 4 — Effects Page
///
/// Features:
/// - Reuses stationary interactive 3D device preview on the LEFT.
/// - Demonstrates selected effects visually in real-time over the video.
/// - Top large preview area showing focused effect details and live mini simulation.
/// - Category filtering: ALL, TRENDING, IMPACT, GAMING, MEME, AURA, GLITCH.
/// - Multi-effect selection via dedicated CHECKBOXES (no apply button!).
/// - Selected effects count indicator.
/// - Internal effect codes (CLP_FX_XXX) are strictly hidden from UI.
class Step4EffectsPage extends ConsumerStatefulWidget {
  const Step4EffectsPage({
    this.onBack,
    this.onNext,
    this.onStepTapped,
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final ValueChanged<int>? onStepTapped;

  @override
  ConsumerState<Step4EffectsPage> createState() => _Step4EffectsPageState();
}

class _Step4EffectsPageState extends ConsumerState<Step4EffectsPage> {
  final TextEditingController _searchController = TextEditingController();
  int _activeSectionIndex = 0; // 0: Video Effects, 1: Video Repair

  final List<String> _categories = const [
    'ALL',
    'TRENDING',
    'CHARACTER',
    'AURA',
    'FACE',
    'MEME',
    'DIGITAL',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workflowState = ref.watch(projectWorkflowProvider);
    final uploadState = ref.watch(videoUploadProvider);
    final effectsState = ref.watch(effectsProvider);
    final filteredEffects = ref.watch(filteredEffectsProvider);
    final notifier = ref.read(effectsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C14),
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Top Navigation Bar ───────────────────────────────────────
            _buildTopNavBar(context, effectsState),

            // ── 2. Main Two-Column Studio Body ──────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left Column: Stationary Video Preview with Effects Overlay
                  Container(
                    width: 320,
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
                      vertical: 18,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Interactive3dDevicePreview(
                            overlayContent: const ImmovableSubtitleOverlay(),
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
                            screenContentWrapper: (child) =>
                                EffectsVideoOverlay(child: child),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Live Effects Engine Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
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
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 13,
                                color: Color(0xFFC4B5FD),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Live Preview (${effectsState.selectedCount} Active)',
                                  style: const TextStyle(
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
                      ],
                    ),
                  ),

                  // ── Right Column: Step 4 Effects Studio ───────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 22,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Step Title & Description ──────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      switch (_activeSectionIndex) {
                                        0 => '4 — EFFECTS LIBRARY',
                                        1 => '4 — ADVANCED VIDEO EFFECTS',
                                        2 => '4 — VIDEO REPAIR & DENOISING',
                                        _ => '4 — VIDEO EFFECTS STUDIO',
                                      },
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                        color: Color(0xFFF3F4F8),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      switch (_activeSectionIndex) {
                                        0 =>
                                          'Select and composite overlay effects and creator motion recipes.',
                                        1 =>
                                          'Configure 10 professional motion, optical, and camera effects with dedicated controls.',
                                        2 =>
                                          'Apply advanced video denoising, blur detection frame analysis, and noise reduction.',
                                        _ => 'Video effects & repair studio.',
                                      },
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF8B92A8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Selected Count Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.4),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.checklist_rounded,
                                      size: 14,
                                      color: Color(0xFFC4B5FD),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${effectsState.selectedCount} selected',
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

                          const SizedBox(height: 18),

                          // ── Sub-Navigation: [ Effects Library ] | [ Advanced FX ] | [ Video Repair ] ──
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF131522),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF26293D)),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildSubTabButton(
                                    title: 'Effects Library',
                                    subtitle: 'Creator Recipes & Packs',
                                    icon: Icons.auto_awesome_rounded,
                                    isSelected: _activeSectionIndex == 0,
                                    onTap: () => setState(() => _activeSectionIndex = 0),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _buildSubTabButton(
                                    title: 'Advanced FX',
                                    subtitle: '10 Motion & Optical Effects',
                                    icon: Icons.auto_fix_high_rounded,
                                    isSelected: _activeSectionIndex == 1,
                                    onTap: () => setState(() => _activeSectionIndex = 1),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _buildSubTabButton(
                                    title: 'Video Repair',
                                    subtitle: 'Denoising, Blur & Quality',
                                    icon: Icons.build_circle_outlined,
                                    isSelected: _activeSectionIndex == 2,
                                    onTap: () => setState(() => _activeSectionIndex = 2),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Conditional Body ──────────────────────────────
                          if (_activeSectionIndex == 0) ...[
                            // Large Focused Effect Preview at Top
                            const EffectsTopBannerPreview(),

                            const SizedBox(height: 20),

                            // Category Filter Tabs
                            _buildCategoryTabs(effectsState, notifier),

                            const SizedBox(height: 14),

                            // Search & Bulk Action Bar
                            _buildSearchAndActionsRow(
                              effectsState,
                              notifier,
                              filteredEffects.length,
                              uploadState.filePath,
                            ),

                            const SizedBox(height: 16),

                            // Effect Catalogue Grid
                            if (filteredEffects.isEmpty)
                              _buildEmptyState()
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 380,
                                  mainAxisExtent: 68,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: filteredEffects.length,
                                itemBuilder: (context, index) {
                                  return EffectCard(
                                    effect: filteredEffects[index],
                                  );
                                },
                              ),
                          ] else if (_activeSectionIndex == 1) ...[
                            // 10 Advanced Video Effects Controls
                            const AdvancedVideoEffectsSection(),
                          ] else ...[
                            // Dedicated Video Repair Section
                            const VideoRepairSection(),
                          ],

                          const SizedBox(height: 28),

                          // ── Bottom Navigation Actions ──────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OutlinedButton.icon(
                                onPressed: widget.onBack,
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 16,
                                ),
                                label: const Text('Previous: Video Look'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFD1D5DB),
                                  side: const BorderSide(
                                    color: Color(0xFF2C2F44),
                                  ),
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
                                        SnackBar(
                                          backgroundColor:
                                              const Color(0xFF1E2032),
                                          content: Text(
                                            'Selected ${effectsState.selectedCount} effects saved for AI placement and final render!',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                icon: const Text(
                                  'Next: Export & Render',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                label: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B5CF6),
                                  foregroundColor: Colors.white,
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
      ),
    );
  }

  Widget _buildTopNavBar(BuildContext context, EffectsState state) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F101A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1F2233), width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          TextButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
            label: const Text(
              'Back',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD1D5DB),
              ),
            ),
          ),

          // Central Progress Stepper (Step 5 active)
          WorkflowProgressStepper(
            currentStep: 5,
            totalSteps: 6,
            onStepTapped: widget.onStepTapped,
          ),

          // Right: FFmpeg Engine, Status Badge & Next Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // FFmpeg Engine Diagnostics
              OutlinedButton.icon(
                onPressed: () => FfmpegDiagnosticsDialog.show(context),
                icon: const Icon(
                  Icons.terminal_rounded,
                  size: 13,
                  color: Color(0xFF10B981),
                ),
                label: const Text(
                  'FFmpeg Engine',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE5E7EB),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF141624),
                  side: const BorderSide(
                    color: Color(0xFF282B3E),
                    width: 1.0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Status Badge
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B5CF6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Visual Effects (${state.selectedCount} Active)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD1D5DB),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Next Step button (leads to Step 6: Overlays)
              TextButton.icon(
                onPressed: widget.onNext,
                icon: const Text(
                  'Next: Overlays',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                label: const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(EffectsState state, EffectsNotifier notifier) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = state.activeCategory == cat;
          final count = _getCategoryCount(cat);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => notifier.setActiveCategory(cat),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFF141624),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFF24273A),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cat,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: 0.5,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : const Color(0xFF1E2135),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF8B92A8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  int _getCategoryCount(String cat) {
    if (cat == 'ALL') return EffectCatalogue.allEffects.length;
    if (cat == 'TRENDING') {
      return EffectCatalogue.allEffects.where((e) => e.isTrending).length;
    }
    return EffectCatalogue.allEffects.where((e) {
      final cName = e.category.name.toUpperCase();
      return cName == cat || cat.contains(cName);
    }).length;
  }

  Widget _buildSearchAndActionsRow(
    EffectsState state,
    EffectsNotifier notifier,
    int visibleCount,
    String? videoFilePath,
  ) {
    return Row(
      children: [
        // Search Input Field
        Expanded(
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF121422),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF24273A),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: notifier.setSearchQuery,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search creator effect recipes (e.g. Sigma, Crown, Red Eyes, 4K)...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5B627A),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      notifier.setSearchQuery('');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Select All Visible Button
        OutlinedButton.icon(
          onPressed: () => notifier.selectAll(videoFilePath: videoFilePath),
          icon: const Icon(Icons.done_all_rounded, size: 14),
          label: const Text('Select All'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC4B5FD),
            side: const BorderSide(color: Color(0xFF2E334D)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Clear All Button
        if (state.selectedCount > 0)
          TextButton.icon(
            onPressed: notifier.clearAll,
            icon: const Icon(Icons.clear_rounded, size: 14, color: Color(0xFFEF4444)),
            label: const Text(
              'Clear',
              style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
      ],
    );
  }

  Widget _buildSubTabButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E2238) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFFC4B5FD) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? const Color(0xFFF3F4F8) : const Color(0xFF9CA3AF),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? const Color(0xFFC4B5FD) : const Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: const [
          Icon(
            Icons.search_off_rounded,
            size: 36,
            color: Color(0xFF4B5563),
          ),
          SizedBox(height: 10),
          Text(
            'No effects match your search',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try adjusting your search terms or filter category.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
