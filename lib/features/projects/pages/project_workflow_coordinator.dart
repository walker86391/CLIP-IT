import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/providers/core_providers.dart';
import '../../branding/pages/step5_branding_page.dart';
import '../../clips/pages/genre_selection_page.dart';
import '../../effects/data/effect_catalogue.dart';
import '../../effects/pages/step4_effects_page.dart';
import '../../effects/providers/effects_provider.dart';
import '../../home/providers/video_upload_provider.dart';
import '../../pipeline/models/resumable_transcription_job.dart';
import '../../pipeline/pages/pipeline_progress_page.dart';
import '../../pipeline/providers/pipeline_provider.dart';
import '../../sound_effects/data/sound_effects_catalogue.dart';
import '../../sound_effects/pages/sound_effects_library_page.dart';
import '../../sound_effects/providers/sound_effects_provider.dart';
import '../../subtitles/pages/subtitle_studio_page.dart';
import '../../video_look/pages/video_look_page.dart';
import '../components/interactive_3d_device_preview.dart';
import '../models/project_workflow_state.dart';
import '../providers/project_workflow_provider.dart';
import 'chatgpt_bridge_connect_page.dart';
import 'project_preloader_screen.dart';
import 'project_settings_page.dart';

/// ProjectWorkflowCoordinator manages the smooth transition between:
/// 1. Connect to your AI chatbot (local Chrome Extension bridge test)
/// 2. Genre Selection (10 genre choices with inbuilt AI prompts)
/// 3. Preloader (Typewriter animations + 3D model preloading)
/// 4. Project Settings / Reframing (Step 1)
/// 5. Subtitle Studio (Step 2)
/// 6. Video Look (Step 3)
/// 7. Sound Effects (Step 4)
/// 8. Effects Library (Step 5)
/// 9. Branding & Overlays (Step 6)
/// 10. Generate Clips Pipeline (Full automated extraction, transcription, discovery, validation, and rendering)
class ProjectWorkflowCoordinator extends ConsumerStatefulWidget {
  const ProjectWorkflowCoordinator({
    this.initialStage,
    this.onBackToHome,
    super.key,
  });

  final WorkflowStage? initialStage;
  final VoidCallback? onBackToHome;

  @override
  ConsumerState<ProjectWorkflowCoordinator> createState() =>
      _ProjectWorkflowCoordinatorState();
}

class _ProjectWorkflowCoordinatorState
    extends ConsumerState<ProjectWorkflowCoordinator> {
  @override
  void initState() {
    super.initState();
    if (widget.initialStage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(projectWorkflowProvider.notifier).setStage(widget.initialStage!);
      });
    }
  }

  @override
  void dispose() {
    Interactive3dDevicePreview.pausePlayback();
    super.dispose();
  }

  void _goToStage(WorkflowStage stage) {
    ref.read(projectWorkflowProvider.notifier).setStage(stage);

    if (stage == WorkflowStage.generateClips) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startPipelineIfIdle();
        }
      });
    }
  }

  void _startPipelineAndNavigateToProcessing() {
    Interactive3dDevicePreview.pausePlayback();
    _startPipelineIfIdle();
    ref.read(shellNavigationIndexProvider.notifier).setIndex(5);
  }

  void _startPipelineIfIdle() async {
    Interactive3dDevicePreview.pausePlayback();
    try {
      final activeJob = ref.read(pipelineJobProvider);
      if (activeJob != null && activeJob.isActive) return;

      final uploadState = ref.read(videoUploadProvider);
      final workflowState = ref.read(projectWorkflowProvider);
      final effectsState = ref.read(effectsProvider);
      final soundEffectsState = ref.read(soundEffectsProvider);

      // Collect ONLY user-selected visual effects (Critical architecture rule: never send unselected)
      final selectedVisualEffects = <Map<String, dynamic>>[];
      for (final id in effectsState.selectedEffectIds) {
        final eff = EffectCatalogue.allEffects.firstWhereOrNull((e) => e.id == id);
        if (eff != null) {
          selectedVisualEffects.add({
            'effect_id': eff.id,
            'name': eff.name,
            'description': eff.shortDescription,
            'type': eff.category.name,
            'duration_sec': 1.0,
          });
        }
      }

      // Collect ONLY user-selected sound effects
      final selectedSoundEffects = <Map<String, dynamic>>[];
      for (final id in soundEffectsState.selectedEffectIds) {
        final sfx = SoundEffectsCatalogue.all.firstWhereOrNull((s) => s.id == id);
        if (sfx != null) {
          selectedSoundEffects.add({
            'effect_id': sfx.id,
            'name': sfx.name,
            'description': sfx.description,
            'type': sfx.category,
            'duration_sec': sfx.durationSeconds,
          });
        }
      }

      final videoPath = workflowState.videoPath ?? uploadState.filePath ?? 'sample_video.mp4';
      final videoTitle = workflowState.videoTitle.isNotEmpty
          ? workflowState.videoTitle
          : (workflowState.videoFileName ?? uploadState.fileName ?? 'ClipIt Video Project');

      String defaultModelPath;
      try {
        final appSupport = await getApplicationSupportDirectory();
        final modelDir = Directory(p.join(appSupport.path, '..', 'clipit', 'models'));
        await modelDir.create(recursive: true);
        defaultModelPath = p.join(modelDir.path, 'whisper-hindi2hinglish.bin');
      } catch (_) {
        final localApp = Platform.environment['LOCALAPPDATA'] ?? '';
        defaultModelPath = p.join(localApp, 'clipit', 'models', 'whisper-hindi2hinglish.bin');
      }

      ref.read(pipelineJobProvider.notifier).startPipeline(
        videoPath: videoPath,
        projectId: 'proj_${DateTime.now().millisecondsSinceEpoch}',
        videoTitle: videoTitle,
        whisperModelPath: defaultModelPath,
        videoLanguage: workflowState.videoLanguage,
        captionLanguage: workflowState.captionLanguage,
        selectedVisualEffects: selectedVisualEffects,
        selectedSoundEffects: selectedSoundEffects,
        selectedTransitions: const [],
      );
    } catch (e, st) {
      debugPrint('[WorkflowCoordinator] Failed to launch pipeline: $e\n$st');
    }
  }

  void _handleStepTapped(int step) {
    switch (step) {
      case 1:
        _goToStage(WorkflowStage.projectSettings);
        break;
      case 2:
        _goToStage(WorkflowStage.subtitleStudio);
        break;
      case 3:
        _goToStage(WorkflowStage.videoLook);
        break;
      case 4:
        _goToStage(WorkflowStage.soundEffects);
        break;
      case 5:
        _goToStage(WorkflowStage.effects);
        break;
      case 6:
        _goToStage(WorkflowStage.branding);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final workflowState = ref.watch(projectWorkflowProvider);
    final activeJob = ref.watch(pipelineJobProvider);

    // If an active pipeline job is currently running or paused, prioritize showing its progress
    if (activeJob != null && activeJob.isActive) {
      return PipelineProgressPage(
        onDone: () {
          ref.read(shellNavigationIndexProvider.notifier).setIndex(2);
        },
      );
    }

    if (!workflowState.hasActiveSession) {
      return _buildNoVideosView(context);
    }

    switch (workflowState.currentStage) {
      case WorkflowStage.aiChatbotBridge:
        return ChatGptBridgeConnectPage(
          onBack: widget.onBackToHome ??
              () {
                ref.read(shellNavigationIndexProvider.notifier).setIndex(0);
              },
          onContinue: () {
            _goToStage(WorkflowStage.genreSelection);
          },
        );

      case WorkflowStage.genreSelection:
        return GenreSelectionPage(
          onContinue: (genreIndex) {
            _goToStage(WorkflowStage.preloader);
          },
        );

      case WorkflowStage.preloader:
        return ProjectPreloaderScreen(
          onComplete: () {
            _goToStage(WorkflowStage.projectSettings);
          },
        );

      case WorkflowStage.projectSettings:
        return ProjectSettingsPage(
          onBack: () {
            _goToStage(WorkflowStage.genreSelection);
          },
          onProceed: () {
            _goToStage(WorkflowStage.subtitleStudio);
          },
          onStepTapped: _handleStepTapped,
        );

      case WorkflowStage.subtitleStudio:
        return SubtitleStudioPage(
          onBack: () {
            _goToStage(WorkflowStage.projectSettings);
          },
          onNext: () {
            _goToStage(WorkflowStage.videoLook);
          },
          onStepTapped: _handleStepTapped,
        );

      case WorkflowStage.videoLook:
        return VideoLookPage(
          onBack: () {
            _goToStage(WorkflowStage.subtitleStudio);
          },
          onNext: () {
            _goToStage(WorkflowStage.soundEffects);
          },
          onStepTapped: _handleStepTapped,
        );

      case WorkflowStage.soundEffects:
        return SoundEffectsLibraryPage(
          onBack: () {
            _goToStage(WorkflowStage.videoLook);
          },
          onNext: () {
            _goToStage(WorkflowStage.effects);
          },
          onStepTapped: _handleStepTapped,
        );

      case WorkflowStage.effects:
        return Step4EffectsPage(
          onBack: () {
            _goToStage(WorkflowStage.soundEffects);
          },
          onNext: () {
            _goToStage(WorkflowStage.branding);
          },
          onStepTapped: _handleStepTapped,
        );

      case WorkflowStage.branding:
        return Step5BrandingPage(
          onBack: () {
            _goToStage(WorkflowStage.effects);
          },
          onNext: () {
            _startPipelineAndNavigateToProcessing();
          },
          onStepTapped: _handleStepTapped,
        );

      case WorkflowStage.generateClips:
        return PipelineProgressPage(
          onDone: () {
            // Navigate directly to the Clips tab in the main sidebar
            ref.read(shellNavigationIndexProvider.notifier).setIndex(2);
          },
        );
    }
  }

  /// Empty state displayed when no active editing session is currently in progress.
  Widget _buildNoVideosView(BuildContext context) {
    final resumableJob = ref.watch(resumableTranscriptionProvider);
    if (resumableJob != null) {
      return _buildResumableJobView(context, resumableJob);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 44),
          decoration: BoxDecoration(
            color: const Color(0xFF161722),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF26283B),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.video_library_outlined,
                  size: 38,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No videos to customise',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add a video?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9EA1B5),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(shellNavigationIndexProvider.notifier).setIndex(0);
                  },
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text(
                    'Add Video',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card view displayed when an interrupted Whisper transcription was detected on disk.
  Widget _buildResumableJobView(
    BuildContext context,
    ResumableTranscriptionJob resumableJob,
  ) {
    final pct = resumableJob.progressPercent.clamp(0.0, 100.0);
    final pctString = pct.toStringAsFixed(1);
    final title = resumableJob.videoTitle.isNotEmpty
        ? resumableJob.videoTitle
        : (resumableJob.videoFileName.isNotEmpty
            ? resumableJob.videoFileName
            : resumableJob.projectName);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 580),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF161722),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with badge and icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.restore_page_rounded,
                      size: 28,
                      color: Color(0xFFA78BFA),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Text(
                                'INTERRUPTED SESSION FOUND',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFA78BFA),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                '$pctString% SAVED',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF34D399),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A Whisper transcription was in progress and saved progress to disk. You can resume immediately from where it stopped without repeating completed audio.',
                          style: TextStyle(
                            color: const Color(0xFF9EA1B5).withValues(alpha: 0.9),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (pct / 100.0).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: const Color(0xFF26283B),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Progress details
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F101A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF262838),
                    width: 1.0,
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 15,
                          color: Color(0xFF8E92A6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${resumableJob.formattedLastPosition} / ${resumableJob.formattedTotalDuration}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE2E4EC),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.record_voice_over_outlined,
                          size: 15,
                          color: Color(0xFF8E92A6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${resumableJob.wordsTranscribed} words saved (${resumableJob.phrasesTranscribed} segments)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFA78BFA),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // Action buttons
              Row(
                children: [
                  // Resume Transcription Button (Primary)
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: ElevatedButton.icon(
                        key: const Key('resume_workflow_transcription_button'),
                        onPressed: () {
                          ref.read(projectWorkflowProvider.notifier).startNewSession(
                            videoPath: resumableJob.videoPath,
                            fileName: resumableJob.videoFileName,
                          );
                          if (resumableJob.videoTitle.isNotEmpty) {
                            ref
                                .read(projectWorkflowProvider.notifier)
                                .updateVideoTitle(resumableJob.videoTitle);
                          }
                          ref
                              .read(projectWorkflowProvider.notifier)
                              .setStage(WorkflowStage.generateClips);
                          ref
                              .read(pipelineJobProvider.notifier)
                              .resumeInterruptedTranscription(resumableJob);
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text(
                          'Resume Transcription',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor:
                              const Color(0xFF10B981).withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Discard Button
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: OutlinedButton.icon(
                      key: const Key('discard_workflow_transcription_button'),
                      onPressed: () async {
                        await ref
                            .read(pipelineJobProvider.notifier)
                            .discardResumableJob(resumableJob);
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      label: const Text(
                        'Discard',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    ref.read(shellNavigationIndexProvider.notifier).setIndex(0);
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text(
                    'Or start a brand new video instead',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8E92A6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
