import '../../subtitles/widgets/immovable_subtitle_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/ffmpeg_diagnostics_dialog.dart';

import '../../home/providers/video_upload_provider.dart';
import '../../projects/components/interactive_3d_device_preview.dart';
import '../../projects/components/workflow_progress_stepper.dart';
import '../../projects/providers/project_workflow_provider.dart';
import '../models/sound_effect_item.dart';
import '../providers/sound_effects_provider.dart';
import '../widgets/sound_effect_card.dart';
import '../widgets/sound_effects_usage_pill.dart';
import '../widgets/audio_effects_section.dart';
import '../widgets/custom_music_section.dart';
import '../widgets/three_channel_mixer_widget.dart';

/// Stage 4 — Sound Effect Library Page
///
/// Features:
/// - Reuses stationary interactive 3D device preview on the LEFT.
/// - Clean video display: no visual distortion or video effects applied.
/// - Dynamic real-time usage status pill under the preview: X of Y used with real percentage.
/// - Block-like sound effect cards with instant Play / Stop button (no scrubbers or seek bars).
/// - Proper visual naming and internal FFmpeg identifiers.
/// - Multi-effect selection via dedicated checkboxes.
/// - Category filtering: ALL, MEME, DESI / BOLLYWOOD, REACTION, IMPACT, COMEDY, ANIME.
/// - Search bar and quick Select All / Clear All controls.
class SoundEffectsLibraryPage extends ConsumerStatefulWidget {
  const SoundEffectsLibraryPage({
    this.onBack,
    this.onNext,
    this.onStepTapped,
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final ValueChanged<int>? onStepTapped;

  @override
  ConsumerState<SoundEffectsLibraryPage> createState() =>
      _SoundEffectsLibraryPageState();
}

class _SoundEffectsLibraryPageState
    extends ConsumerState<SoundEffectsLibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  int _activeAudioTab = 0;

  final List<String> _categories = const [
    'ALL',
    'ENGLISH',
    'HINDI',
    'ONLY SOUND',
    'MEME',
    'IMPACT',
    'COMEDY',
    'ANIME',
    'GAMING',
    'REACTION',
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
    final soundState = ref.watch(soundEffectsProvider);
    final filteredEffects = ref.watch(filteredSoundEffectsProvider);
    final notifier = ref.read(soundEffectsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C14),
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Top Navigation Bar ───────────────────────────────────────
            _buildTopNavBar(context, soundState),

            // ── 2. Main Two-Column Studio Body ──────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left Column: Clean Stationary Video Preview (No Video FX)
                  Expanded(
                    flex: 5,
                    child: Interactive3dDevicePreview(
                      overlayContent: const ImmovableSubtitleOverlay(),
                      deviceType: workflowState.selectedDevice,
                      aspectRatio: workflowState.selectedRatio,
                      previewPlatformBlocks:
                          workflowState.previewPlatformBlocks,
                      videoFilePath: uploadState.filePath,
                      onTogglePlatformBlocks: () => ref
                          .read(projectWorkflowProvider.notifier)
                          .togglePreviewPlatformBlocks(),
                      isFrozen: false,
                      showScrubber: true,
                      isMuted: workflowState.isVideoMuted,
                      onToggleMute: () => ref
                          .read(projectWorkflowProvider.notifier)
                          .toggleVideoMuted(),
                      bottomWidget: const SoundEffectsUsagePill(),
                    ),
                  ),

                  // Subtle Vertical Divider
                  Container(
                    width: 1.0,
                    color: const Color(0xFF1F2233),
                  ),

                  // ── Right Column: Sound Effect Library Editor ─────────────
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
                          // ── Title & Selection Count Badge ──────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      switch (_activeAudioTab) {
                                        0 => '4 — SOUND EFFECT LIBRARY',
                                        1 => '4 — AUDIO EFFECTS & ACOUSTICS',
                                        2 => '4 — BACKGROUND MUSIC & DUCKING',
                                        3 => '4 — THREE-CHANNEL VOLUME MIXER',
                                        _ => '4 — AUDIO STUDIO',
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
                                      switch (_activeAudioTab) {
                                        0 =>
                                          'Auditory punchlines, memes, and impact sound effects automatically placed during high-action video moments.',
                                        1 =>
                                          'Configure audio fade in/out transitions, room reverb acoustics, and intelligent silence removal.',
                                        2 =>
                                          'Import local background MP3 audio, configure fade envelopes, and set speech peak auto ducking.',
                                        3 =>
                                          'Adjust master channel balance independently across primary video speech, music, and sound effects.',
                                        _ => 'Comprehensive audio suite for ClipIt.',
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

                              // Real Allocation Pill
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
                                      Icons.graphic_eq_rounded,
                                      size: 14,
                                      color: Color(0xFFC4B5FD),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${soundState.selectedCount} / ${soundState.totalCount} selected (${soundState.usagePercentage.toStringAsFixed(0)}%)',
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

                          // ── 4-Sub-Tab Switcher ────────────────────────────
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
                                    title: 'Sound Effects',
                                    icon: Icons.surround_sound_rounded,
                                    isSelected: _activeAudioTab == 0,
                                    onTap: () => setState(() => _activeAudioTab = 0),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _buildSubTabButton(
                                    title: 'Audio Effects',
                                    icon: Icons.graphic_eq_rounded,
                                    isSelected: _activeAudioTab == 1,
                                    onTap: () => setState(() => _activeAudioTab = 1),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _buildSubTabButton(
                                    title: 'Music & Ducking',
                                    icon: Icons.music_note_rounded,
                                    isSelected: _activeAudioTab == 2,
                                    onTap: () => setState(() => _activeAudioTab = 2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _buildSubTabButton(
                                    title: 'Volume Mixer',
                                    icon: Icons.equalizer_rounded,
                                    isSelected: _activeAudioTab == 3,
                                    onTap: () => setState(() => _activeAudioTab = 3),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Conditional Body based on _activeAudioTab ─────
                          if (_activeAudioTab == 0) ...[
                            // Category Filter Tabs
                            _buildCategoryTabs(soundState, notifier),

                            const SizedBox(height: 14),

                            // Search & Bulk Action Bar
                            _buildSearchAndActionsRow(
                              soundState,
                              notifier,
                              filteredEffects,
                            ),

                            const SizedBox(height: 16),

                            // Sound Effects Grid (Block Structure)
                            if (filteredEffects.isEmpty)
                              _buildEmptyState()
                            else
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final crossAxisCount =
                                      constraints.maxWidth < 500 ? 1 : 2;
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisExtent: 72,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: filteredEffects.length,
                                    itemBuilder: (context, index) {
                                      return SoundEffectCard(
                                        effect: filteredEffects[index],
                                      );
                                    },
                                  );
                                },
                              ),
                          ] else if (_activeAudioTab == 1) ...[
                            // Audio Effects: Fade In/Out, Reverb, Silence Removal
                            const AudioEffectsSection(),
                          ] else if (_activeAudioTab == 2) ...[
                            // Background Music & Auto Ducking
                            const CustomMusicSection(),
                          ] else if (_activeAudioTab == 3) ...[
                            // 3-Channel Master Volume Mixer
                            const ThreeChannelMixerWidget(),
                          ],

                          const SizedBox(height: 32),

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
                                            'Selected ${soundState.selectedCount} sound effects queued for final video rendering!',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                icon: const Text(
                                  'Next: Branding Studio',
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

  Widget _buildTopNavBar(BuildContext context, SoundEffectsState state) {
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

          // Central Progress Stepper (Step 4 active of 5)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              WorkflowProgressStepper(
                currentStep: 4,
                totalSteps: 6,
                onStepTapped: widget.onStepTapped,
              ),
            ],
          ),

          // Right Info Pill & FFmpeg Engine Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF161826),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF262A3E),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.audiotrack_rounded,
                      size: 14,
                      color: Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${state.selectedCount} FX Queued',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE2E8F0),
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

  Widget _buildCategoryTabs(
    SoundEffectsState state,
    SoundEffectsNotifier notifier,
  ) {
    final showClearAll = state.selectedFilters.length >= 2;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // ── If 2 or more filters are selected, show CLEAR ALL option prominently ──
          if (showClearAll) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  key: const Key('sound_effects_clear_filters_button'),
                  onTap: () => notifier.clearFilters(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Color(0xFFF87171),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'CLEAR ALL (${state.selectedFilters.length})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF87171),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          ..._categories.map((cat) {
            final isSelected = state.isFilterActive(cat);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => notifier.toggleFilter(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF141724),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFA78BFA)
                            : const Color(0xFF222638),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected && cat != 'ALL') ...[
                          const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF9CA3AF),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSearchAndActionsRow(
    SoundEffectsState state,
    SoundEffectsNotifier notifier,
    List<SoundEffectItem> visibleEffects,
  ) {
    return Row(
      children: [
        // Search Input Field
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10121D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF222638),
                width: 1.0,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: notifier.setSearchQuery,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFFF3F4F8),
              ),
              decoration: InputDecoration(
                hintText:
                    'Search sound effects by name, tag, or reaction...',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5A6076),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          size: 16,
                          color: Color(0xFF9CA3AF),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setSearchQuery('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Select All Button
        TextButton.icon(
          onPressed: () => notifier.selectAll(visibleEffects),
          icon: const Icon(Icons.done_all_rounded, size: 14),
          label: const Text('Select All'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF8B5CF6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),

        // Clear Selection Button
        TextButton.icon(
          onPressed: notifier.clearAll,
          icon: const Icon(Icons.deselect_rounded, size: 14),
          label: const Text('Clear'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF9CA3AF),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildSubTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E2238) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFFC4B5FD) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? const Color(0xFFF3F4F8) : const Color(0xFF9CA3AF),
                ),
                overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: const Color(0xFF0F111A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2232), width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.music_off_rounded,
            size: 38,
            color: Color(0xFF4B5563),
          ),
          SizedBox(height: 12),
          Text(
            'No matching sound effects found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try adjusting your search query or switching category filters.',
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
