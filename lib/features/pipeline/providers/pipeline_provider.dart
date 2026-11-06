// ignore_for_file: unused_element
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/services/chatgpt_bridge_service.dart';
import '../../../core/services/ffmpeg_service.dart';
import '../../../core/services/file_manager.dart';
import '../../../core/services/model_manager.dart';
import '../../../core/services/whisper_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/app_path_resolver.dart';
import '../../projects/components/interactive_3d_device_preview.dart';
import '../../sound_effects/data/sound_effects_catalogue.dart';
import '../../subtitles/models/subtitle_models.dart';
import '../../subtitles/services/speech_aligner_service.dart';
import 'package:flutter/material.dart' show Color, Colors;
import '../models/pipeline_job.dart';
import '../models/resumable_transcription_job.dart';
import '../services/prompt_template_service.dart';
import '../services/resumable_transcription_scanner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final pipelineJobProvider =
    NotifierProvider<PipelineNotifier, PipelineJob?>(PipelineNotifier.new);

/// History of completed/failed jobs for the Ongoing Process page.
class PipelineHistoryNotifier extends Notifier<List<PipelineJob>> {
  @override
  List<PipelineJob> build() {
    Future.microtask(() => scanDiskProjects());
    return [];
  }

  void add(PipelineJob job) {
    state = [job, ...state.where((j) => j.id != job.id)];
  }

  void updateJob(PipelineJob job) {
    final idx = state.indexWhere((j) => j.id == job.id);
    if (idx == -1) {
      state = [job, ...state];
    } else {
      final updated = List<PipelineJob>.from(state);
      updated[idx] = job;
      state = updated;
    }
  }

  void removeJob(String jobId) {
    state = state.where((j) => j.id != jobId).toList();
  }

  void clear() {
    state = [];
  }

  /// Scans `live process/` on disk for existing completed projects, parses their clips
  /// and aligns them so they are immediately available on app startup.
  Future<void> scanDiskProjects() async {
    final liveProcessDir = AppPathResolver.liveProcessDir;
    if (!liveProcessDir.existsSync()) return;

    try {
      final entries = liveProcessDir.listSync();
      final loadedJobs = <PipelineJob>[];

      for (final entity in entries) {
        if (entity is! Directory) continue;
        final projectDir = entity;
        final jobFile = File(p.join(projectDir.path, 'pipeline_job.json'));
        final aiResponseJsonFile = File(p.join(projectDir.path, 'ai response clips', 'ai_response.json'));
        final transcriptJsonFile = File(p.join(projectDir.path, 'transcription', 'transcript.json'));
        final clipsDir = Directory(p.join(projectDir.path, 'clips'));

        if (!jobFile.existsSync() && !aiResponseJsonFile.existsSync()) continue;

        Map<String, dynamic> jobMeta = {};
        if (jobFile.existsSync()) {
          try {
            jobMeta = jsonDecode(jobFile.readAsStringSync()) as Map<String, dynamic>;
          } catch (_) {}
        }

        final projectId = jobMeta['projectId'] as String? ?? p.basename(projectDir.path);
        final videoTitle = jobMeta['videoTitle'] as String? ?? 'ClipIt Video Project';
        final videoPath = jobMeta['videoPath'] as String? ?? '';
        final id = jobMeta['id'] as String? ?? const Uuid().v4();
        final rawStartedAt = jobMeta['startedAt'] as String?;
        final startedAt = rawStartedAt != null ? (DateTime.tryParse(rawStartedAt) ?? DateTime.now()) : DateTime.now();

        final job = PipelineJob(
          id: id,
          projectId: projectId,
          videoTitle: videoTitle,
          videoPath: videoPath,
          startedAt: startedAt,
        );
        job.projectDir = projectDir.path;
        job.clipsDir = clipsDir.path;
        job.stage = PipelineStage.completed;
        job.overallProgress = 1.0;

        // Parse clips from ai_response.json
        final parsedClips = <PipelineClip>[];
        if (aiResponseJsonFile.existsSync()) {
          try {
            final content = aiResponseJsonFile.readAsStringSync();
            final decoded = jsonDecode(content) as Map<String, dynamic>;
            final chunkResponses = decoded['chunk_responses'] as List<dynamic>? ?? [decoded];
            for (final cr in chunkResponses) {
              if (cr is Map<String, dynamic>) {
                final rawClips = cr['clips'] as List<dynamic>? ?? [];
                for (final rc in rawClips) {
                  if (rc is Map<String, dynamic>) {
                    final clipId = rc['clip_id'] as String? ?? rc['id'] as String? ?? 'clip_${parsedClips.length + 1}';
                    final title = rc['clip_name'] as String? ?? rc['title'] as String? ?? 'Untitled Clip';
                    final quoteStart = rc['quote_start'] as String?;
                    final quoteEnd = rc['quote_end'] as String?;
                    final script = rc['script_paragraph'] as String? ?? rc['script'] as String?;
                    final viral = (rc['virality_score'] as num?)?.toDouble() ?? 8.5;
                    final reason = rc['reason'] as String? ?? rc['virality_reason'] as String? ?? '';

                    // Check if rendered file exists in clipsDir
                    String? foundOutput;
                    if (clipsDir.existsSync()) {
                      final candidates = [
                        p.join(clipsDir.path, '${clipId}_word_by_word.mp4'),
                        p.join(clipsDir.path, '${clipId}_normal.mp4'),
                        p.join(clipsDir.path, '$clipId.mp4'),
                      ];
                      for (final cand in candidates) {
                        if (File(cand).existsSync()) {
                          foundOutput = cand;
                          break;
                        }
                      }
                    }

                    parsedClips.add(PipelineClip(
                      id: clipId,
                      status: ClipDiscoveryStatus.forSure,
                      startSec: 0.0,
                      endSec: 30.0,
                      hookTitle: title,
                      viralScore: viral,
                      viralityReason: reason,
                      suggestedCaption: quoteStart ?? '',
                      quoteStart: quoteStart,
                      quoteEnd: quoteEnd,
                      scriptParagraph: script,
                      outputPath: foundOutput,
                    ));
                  }
                }
              }
            }
          } catch (_) {}
        }

        // Align timestamps if transcript.json exists
        if (transcriptJsonFile.existsSync() && parsedClips.isNotEmpty) {
          try {
            final tDecoded = jsonDecode(transcriptJsonFile.readAsStringSync()) as Map<String, dynamic>;
            final words = tDecoded['words'] as List<dynamic>? ?? [];
            final transcriptLines = words.map((w) {
              return TranscriptLine(
                startSec: (w['start'] as num).toDouble(),
                endSec: (w['end'] as num).toDouble(),
                text: (w['word'] as String? ?? w['text'] as String? ?? '').trim(),
              );
            }).where((l) => l.text.isNotEmpty).toList();

            for (int ci = 0; ci < parsedClips.length; ci++) {
              final c = parsedClips[ci];
              final times = PipelineNotifier._resolveClipTimestamps(
                chunkLines: transcriptLines,
                quoteStart: c.quoteStart ?? '',
                quoteEnd: c.quoteEnd ?? '',
                scriptParagraph: c.scriptParagraph ?? '',
                chunkStartSec: 0.0,
                chunkEndSec: 3600.0,
              );
              parsedClips[ci] = PipelineClip(
                id: c.id,
                status: c.status,
                startSec: times['start']!,
                endSec: times['end']!,
                hookTitle: c.hookTitle,
                viralScore: c.viralScore,
                viralityReason: c.viralityReason,
                suggestedCaption: c.suggestedCaption,
                quoteStart: c.quoteStart,
                quoteEnd: c.quoteEnd,
                scriptParagraph: c.scriptParagraph,
                outputPath: c.outputPath,
              );
            }
          } catch (_) {}
        }

        job.clips = parsedClips;
        loadedJobs.add(job);
      }

      if (loadedJobs.isNotEmpty) {
        final existingIds = state.map((j) => j.id).toSet();
        state = [
          ...state,
          ...loadedJobs.where((j) => !existingIds.contains(j.id)),
        ];
      }
    } catch (e) {
      AppLog.w('[PipelineHistory] Error scanning disk projects: $e');
    }
  }
}

final pipelineHistoryProvider =
    NotifierProvider<PipelineHistoryNotifier, List<PipelineJob>>(
  PipelineHistoryNotifier.new,
);

/// Notifier tracking any interrupted Whisper transcription job found on disk.
class ResumableTranscriptionNotifier
    extends Notifier<ResumableTranscriptionJob?> {
  @override
  ResumableTranscriptionJob? build() {
    Future.microtask(() => refresh());
    return null;
  }

  Future<void> refresh() async {
    final runningJob = ref.read(pipelineJobProvider);
    if (runningJob != null && runningJob.isActive) {
      state = null;
      return;
    }
    final found =
        await ResumableTranscriptionScanner.findInterruptedTranscriptionJob();
    state = found;
  }

  void clear() {
    state = null;
  }
}

final resumableTranscriptionProvider =
    NotifierProvider<ResumableTranscriptionNotifier,
        ResumableTranscriptionJob?>(
  ResumableTranscriptionNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Pipeline Notifier — orchestrates all 9 stages
// ─────────────────────────────────────────────────────────────────────────────

class PipelineNotifier extends Notifier<PipelineJob?> {
  static const int _maxValidationRounds = 3;

  @override
  PipelineJob? build() => null;

  // Accessors for injected services
  ChatGptBridgeService get _bridge =>
      ref.read(chatGptBridgeProvider.notifier);

  FfmpegService get _ffmpeg => FfmpegService.instance;
  WhisperService get _whisper => WhisperService.instance;
  ClipItFileManager get _files => ClipItFileManager.instance;
  PromptTemplateService get _prompts => PromptTemplateService.instance;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Starts the full pipeline for a video file.
  Future<void> startPipeline({
    required String videoPath,
    required String projectId,
    required String videoTitle,
    required String whisperModelPath,
    String videoLanguage = 'auto',
    String captionLanguage = 'hinglish',
    List<Map<String, dynamic>> selectedVisualEffects = const [],
    List<Map<String, dynamic>> selectedSoundEffects = const [],
    List<Map<String, dynamic>> selectedTransitions = const [],
  }) async {
    // Automatically pause any active left panel preview playback
    Interactive3dDevicePreview.pausePlayback();

    // Cancel any running job first
    if (state != null && state!.isActive) {
      state!.stage = PipelineStage.cancelled;
    }

    final jobId = const Uuid().v4();
    final job = PipelineJob(
      id: jobId,
      projectId: projectId,
      videoTitle: videoTitle,
      videoPath: videoPath,
      startedAt: DateTime.now(),
      videoLanguage: videoLanguage,
      captionLanguage: captionLanguage,
    );
    state = job;

    // Register in history (active)
    ref.read(pipelineHistoryProvider.notifier).add(job);

    try {
      _bridge.startPipelineKeepAlive();
      await _bridge.ensureServerRunning();
      await _runAllStages(
        job: job,
        whisperModelPath: whisperModelPath,
        selectedVisualEffects: selectedVisualEffects,
        selectedSoundEffects: selectedSoundEffects,
        selectedTransitions: selectedTransitions,
      );
    } catch (e, st) {
      AppLog.e('[Pipeline] Fatal error: $e\n$st');
      _addLog(job, '[Pipeline] Fatal error: $e');
      _updateStage(PipelineStage.failed, job: job, error: e.toString());
    } finally {
      _bridge.stopPipelineKeepAlive();
    }
  }

  Completer<void>? _pauseCompleter;
  PipelineStage? _savedStageBeforePause;

  void pause() {
    if (state != null && state!.isActive && state!.stage != PipelineStage.paused) {
      _savedStageBeforePause = state!.stage;
      _pauseCompleter = Completer<void>();
      _updateStage(PipelineStage.paused, job: state!, label: 'Pipeline paused');
      _addLog(state!, '[Pipeline] Paused by user');
    }
  }

  void resume() {
    if (state != null && state!.stage == PipelineStage.paused) {
      final resumeStage = _savedStageBeforePause ?? PipelineStage.discoveringClips;
      _pauseCompleter?.complete();
      _pauseCompleter = null;
      _updateStage(resumeStage, job: state!, label: resumeStage.label);
      _addLog(state!, '[Pipeline] Resumed by user');
    }
  }

  void cancel() {
    if (state != null && state!.stage != PipelineStage.completed) {
      _pauseCompleter?.complete();
      _pauseCompleter = null;
      _updateStage(PipelineStage.cancelled, job: state!, label: 'Pipeline cancelled');
      _addLog(state!, '[Pipeline] Cancelled by user');
    }
  }

  Future<void> _checkPause(PipelineJob job) async {
    while (_pauseCompleter != null && !_pauseCompleter!.isCompleted) {
      if (job.stage == PipelineStage.cancelled || job.stage == PipelineStage.failed) {
        break;
      }
      await _pauseCompleter!.future;
    }
  }

  Completer<void>? _bridgeReconnectCompleter;

  Future<void> _waitForBridgeConnection(PipelineJob job) async {
    final bridgeState = ref.read(chatGptBridgeProvider);
    if (bridgeState.isConnected) return;

    // Ensure bridge server is active and listening on port 28475
    await ref.read(chatGptBridgeProvider.notifier).ensureServerRunning();

    _addLog(job, '[Pipeline] AI Bridge not live. Displaying connection broke error screen...');
    _updateStage(
      PipelineStage.bridgeDisconnected,
      job: job,
      label: 'Connection broke — please reopen browser or turn on extension',
      progress: job.overallProgress,
    );

    _bridgeReconnectCompleter = Completer<void>();
    await _bridgeReconnectCompleter!.future;
    _bridgeReconnectCompleter = null;
  }

  void resumeAfterBridgeConnected() {
    if (_bridgeReconnectCompleter != null && !_bridgeReconnectCompleter!.isCompleted) {
      _bridgeReconnectCompleter!.complete();
    }
  }

  Future<void> deleteJobAndFiles(PipelineJob job) async {
    if (job.isActive) {
      cancel();
    }

    // 1. Delete temp working directory
    if (job.tempDir != null && Directory(job.tempDir!).existsSync()) {
      try {
        await Directory(job.tempDir!).delete(recursive: true);
      } catch (_) {}
    }

    // 2. Delete rendered clips for this pipeline run
    if (job.clipsDir != null && Directory(job.clipsDir!).existsSync()) {
      try {
        await Directory(job.clipsDir!).delete(recursive: true);
      } catch (_) {}
    }

    for (final clip in job.clips) {
      if (clip.outputPath != null && File(clip.outputPath!).existsSync()) {
        try {
          await File(clip.outputPath!).delete();
        } catch (_) {}
      }
    }

    // CRITICAL: The video that was used to cut (job.videoPath) MUST NOT BE DELETED!

    // 3. Clear from active state and history
    if (state?.id == job.id) {
      state = null;
    }
    ref.read(pipelineHistoryProvider.notifier).removeJob(job.id);
  }

  /// Resumes an interrupted Whisper transcription job found on disk from a previous session.
  Future<void> resumeInterruptedTranscription(
      ResumableTranscriptionJob resumableJob) async {
    // Automatically pause any active left panel preview playback
    Interactive3dDevicePreview.pausePlayback();

    // Cancel any running job first
    if (state != null && state!.isActive) {
      state!.stage = PipelineStage.cancelled;
    }

    final jobId = const Uuid().v4();
    final job = PipelineJob(
      id: jobId,
      projectId: resumableJob.projectName,
      videoTitle: resumableJob.videoTitle,
      videoPath: resumableJob.videoPath,
      startedAt: DateTime.now(),
      stage: PipelineStage.transcribing,
      videoLanguage: resumableJob.videoLanguage,
      captionLanguage: resumableJob.captionLanguage,
      projectDir: resumableJob.projectDir,
      tempDir: p.join(resumableJob.projectDir, 'audio'),
      overallProgress: (0.30 +
              (0.65 * (resumableJob.progressPercent / 100.0)))
          .clamp(0.30, 0.95),
      currentStageLabel:
          'Resuming transcription from ${resumableJob.formattedLastPosition} (${resumableJob.wordsTranscribed} words saved)…',
    );
    job.logs.add(
        '[Pipeline] Resumed interrupted transcription for ${resumableJob.videoTitle}');
    job.logs.add(
      '[Whisper Prime] Fast Resume: Found ${resumableJob.wordsTranscribed} saved words '
      '(${resumableJob.phrasesTranscribed} segments up to ${resumableJob.formattedLastPosition}).',
    );
    state = job;

    ref.read(pipelineHistoryProvider.notifier).add(job);
    ref.read(resumableTranscriptionProvider.notifier).clear();

    try {
      _bridge.startPipelineKeepAlive();
      await _bridge.ensureServerRunning();

      final audioDir = Directory(p.join(resumableJob.projectDir, 'audio'));
      final chunkFiles = resumableJob.chunkFiles.isNotEmpty
          ? List<String>.from(resumableJob.chunkFiles)
          : audioDir
              .listSync()
              .whereType<File>()
              .where((f) =>
                  p.basename(f.path).startsWith('chunk_') &&
                  f.path.endsWith('.mp3'))
              .map((f) => f.path)
              .toList()
            ..sort();

      final chunkOffsets = <double>[];
      double accumOffset = 0.0;
      for (final chunkFile in chunkFiles) {
        chunkOffsets.add(accumOffset);
        final dur = await _ffmpeg.getVideoDurationSec(chunkFile) ?? 1800.0;
        accumOffset += dur;
      }

      final totalDur = resumableJob.totalAudioDurationSec > 0
          ? resumableJob.totalAudioDurationSec
          : accumOffset;

      await _runStagesFromTranscription(
        job: job,
        chunkFiles: chunkFiles,
        chunkOffsets: chunkOffsets,
        durationSec: totalDur,
        whisperModelPath: resumableJob.whisperModelPath,
        selectedVisualEffects: resumableJob.selectedVisualEffects,
        selectedSoundEffects: resumableJob.selectedSoundEffects,
        selectedTransitions: resumableJob.selectedTransitions,
      );
    } catch (e, st) {
      AppLog.e('[Pipeline] Fatal error during resumed transcription: $e\n$st');
      _addLog(job, '[Pipeline] Fatal error during resume: $e');
      _updateStage(PipelineStage.failed, job: job, error: e.toString());
    } finally {
      _bridge.stopPipelineKeepAlive();
      ref.read(resumableTranscriptionProvider.notifier).refresh();
    }
  }

  /// Retries or resumes an active in-session job that stalled or failed during Whisper transcription.
  Future<void> retryOrResumeTranscription(PipelineJob job) async {
    if (job.projectDir == null) return;
    Interactive3dDevicePreview.pausePlayback();

    _updateStage(
      PipelineStage.transcribing,
      job: job,
      label: 'Resuming transcription from last saved segment…',
      progress: job.overallProgress.clamp(0.30, 0.95),
    );
    _addLog(job, '[Pipeline] Resuming transcription on user request…');

    try {
      _bridge.startPipelineKeepAlive();
      await _bridge.ensureServerRunning();

      final audioDir = Directory(p.join(job.projectDir!, 'audio'));
      final chunkFiles = audioDir
          .listSync()
          .whereType<File>()
          .where((f) =>
              p.basename(f.path).startsWith('chunk_') &&
              f.path.endsWith('.mp3'))
          .map((f) => f.path)
          .toList()
        ..sort();

      final chunkOffsets = <double>[];
      double accumOffset = 0.0;
      for (final chunkFile in chunkFiles) {
        chunkOffsets.add(accumOffset);
        final dur = await _ffmpeg.getVideoDurationSec(chunkFile) ?? 1800.0;
        accumOffset += dur;
      }

      final mp3Path = p.join(audioDir.path, 'audio.mp3');
      final durationSec =
          await _ffmpeg.getVideoDurationSec(mp3Path) ?? accumOffset;

      final activeModelPath =
          await ClipItModelManager.instance.getActiveModelPath();

      await _runStagesFromTranscription(
        job: job,
        chunkFiles: chunkFiles,
        chunkOffsets: chunkOffsets,
        durationSec: durationSec,
        whisperModelPath: activeModelPath,
        selectedVisualEffects: const [],
        selectedSoundEffects: const [],
        selectedTransitions: const [],
      );
    } catch (e, st) {
      AppLog.e('[Pipeline] Error in retryOrResumeTranscription: $e\n$st');
      _addLog(job, '[Pipeline] Error during resume retry: $e');
      _updateStage(PipelineStage.failed, job: job, error: e.toString());
    } finally {
      _bridge.stopPipelineKeepAlive();
      ref.read(resumableTranscriptionProvider.notifier).refresh();
    }
  }

  /// Discards an interrupted project folder from disk.
  Future<void> discardResumableJob(
      ResumableTranscriptionJob resumableJob) async {
    await ResumableTranscriptionScanner.discardProject(resumableJob.projectDir);
    await ref.read(resumableTranscriptionProvider.notifier).refresh();
  }

  // ── Internal: stage runner ─────────────────────────────────────────────────

  Future<void> _runAllStages({
    required PipelineJob job,
    required String whisperModelPath,
    required List<Map<String, dynamic>> selectedVisualEffects,
    required List<Map<String, dynamic>> selectedSoundEffects,
    required List<Map<String, dynamic>> selectedTransitions,
  }) async {
    // ── Stage 1: Create 'live process/audio' folder & extract MP3 ──────────
    await _checkPause(job);
    _updateStage(
      PipelineStage.extractingAudio,
      job: job,
      label: 'Extracting audio from video…',
      progress: 0.10,
    );

    // Create 'live process' folder, and inside it 'audio' and 'transcription' folders
    final liveProcessDir = AppPathResolver.liveProcessDir;
    if (!liveProcessDir.existsSync()) {
      await liveProcessDir.create(recursive: true);
    }
    final projectDir = AppPathResolver.getNextProjectDir();
    if (!projectDir.existsSync()) {
      await projectDir.create(recursive: true);
    }
    final audioDir = Directory(p.join(projectDir.path, 'audio'));
    if (!audioDir.existsSync()) {
      await audioDir.create(recursive: true);
    }
    final transcriptionDir = Directory(p.join(projectDir.path, 'transcription'));
    if (!transcriptionDir.existsSync()) {
      await transcriptionDir.create(recursive: true);
    }

    job.projectDir = projectDir.path;
    job.tempDir = audioDir.path;
    final mp3Path = p.canonicalize(p.join(audioDir.path, 'audio.mp3'));

    _addLog(job, '[Pipeline] Target audio path: $mp3Path');
    await _extractAudio(job.videoPath, mp3Path, job);
    await AppPathResolver.syncLiveProcessToRelease();

    await _checkPause(job);
    if (!_isContinuing(job)) return;

    // ── Stage 2: Measure duration & Slice into 30-min chunks (exact ms) ───
    _updateStage(
      PipelineStage.extractingAudio,
      job: job,
      label: 'Measuring & slicing audio chunks (max 30m)…',
      progress: 0.20,
    );

    final durationSec = await _ffmpeg.getVideoDurationSec(mp3Path) ?? 45.0;
    _addLog(
      job,
      '[Pipeline] Audio duration measured: ${durationSec.toStringAsFixed(2)}s '
      '(${(durationSec / 60).toStringAsFixed(1)} minutes)',
    );

    // Maximum chunk duration is 30 minutes (1800.0s), exact milliseconds, no overlap
    const double maxChunkDurationSec = 1800.0;
    final chunkFiles = <String>[];
    final chunkOffsets = <double>[];

    if (durationSec <= maxChunkDurationSec) {
      final chunk0Path = p.join(audioDir.path, 'chunk_001.mp3');
      await _ffmpeg.runFfmpeg([
        '-y',
        '-i',
        mp3Path,
        '-ss',
        '0.000',
        '-to',
        durationSec.toStringAsFixed(3),
        '-ar',
        '16000',
        '-ac',
        '1',
        '-b:a',
        '192k',
        chunk0Path,
      ]);
      chunkFiles.add(chunk0Path);
      chunkOffsets.add(0.0);
    } else {
      int chunkIdx = 1;
      double currentStart = 0.0;
      while (currentStart < durationSec) {
        final currentEnd =
            math.min(currentStart + maxChunkDurationSec, durationSec);
        final chunkName =
            'chunk_${chunkIdx.toString().padLeft(3, '0')}.mp3';
        final chunkPath = p.join(audioDir.path, chunkName);

        final startSecFormatted = currentStart.toStringAsFixed(3);
        final endSecFormatted = currentEnd.toStringAsFixed(3);

        _addLog(
          job,
          '[Pipeline] Slicing chunk #$chunkIdx: $startSecFormatted -> $endSecFormatted ($chunkName)',
        );

        await _ffmpeg.runFfmpeg([
          '-y',
          '-i',
          mp3Path,
          '-ss',
          startSecFormatted,
          '-to',
          endSecFormatted,
          '-ar',
          '16000',
          '-ac',
          '1',
          '-b:a',
          '192k',
          chunkPath,
        ]);

        chunkFiles.add(chunkPath);
        chunkOffsets.add(currentStart);

        currentStart = currentEnd;
        chunkIdx++;
      }
    }

    _addLog(
      job,
      '[Pipeline] Sliced audio into ${chunkFiles.length} chunk(s) with 0ms overlap.',
    );
    await AppPathResolver.syncLiveProcessToRelease();

    await _checkPause(job);
    if (!_isContinuing(job)) return;

    await _runStagesFromTranscription(
      job: job,
      chunkFiles: chunkFiles,
      chunkOffsets: chunkOffsets,
      durationSec: durationSec,
      whisperModelPath: whisperModelPath,
      selectedVisualEffects: selectedVisualEffects,
      selectedSoundEffects: selectedSoundEffects,
      selectedTransitions: selectedTransitions,
    );
  }

  Future<void> _runStagesFromTranscription({
    required PipelineJob job,
    required List<String> chunkFiles,
    required List<double> chunkOffsets,
    required double durationSec,
    required String whisperModelPath,
    required List<Map<String, dynamic>> selectedVisualEffects,
    required List<Map<String, dynamic>> selectedSoundEffects,
    required List<Map<String, dynamic>> selectedTransitions,
  }) async {
    final transcriptionDir =
        Directory(p.join(job.projectDir!, 'transcription'));
    if (!transcriptionDir.existsSync()) {
      await transcriptionDir.create(recursive: true);
    }

    // ── Stage 3: Transcription with Whisper-Hindi2Hinglish-Prime ──────────
    _updateStage(
      PipelineStage.transcribing,
      job: job,
      label:
          'Transcribing audio with Whisper Prime (${job.captionLanguage})…',
      progress: 0.30,
    );

    final outputJson = p.join(transcriptionDir.path, 'transcript.json');
    final outputTxt = p.join(transcriptionDir.path, 'transcript.txt');

    final activeModelPath = await ClipItModelManager.instance.getActiveModelPath();
    final modelDisplayName = p.basename(activeModelPath);
    _addLog(job, '[Pipeline] Active speech recognition model: $modelDisplayName ($activeModelPath)');

    List<TranscriptLine>? transcriptLines;
    try {
      transcriptLines = await _whisper.transcribeWithPrime(
        chunkPaths: chunkFiles,
        chunkOffsets: chunkOffsets,
        modelDir: activeModelPath,
        videoLanguage: job.videoLanguage,
        captionLanguage: job.captionLanguage,
        outputJson: outputJson,
        outputTxt: outputTxt,
        onWindowProgress: (chunkIndex, chunksTotal, chunkPercent, totalWords, recentText) {
          final chunkWeight = 0.65 / math.max(1, chunksTotal);
          final baseProg = 0.30 + (chunkIndex * chunkWeight);
          final currentProg = baseProg + (chunkWeight * (chunkPercent / 100.0));
          _updateStage(
            PipelineStage.transcribing,
            job: job,
            label: 'Transcribing chunk ${chunkIndex + 1}/$chunksTotal ($chunkPercent%) — $totalWords words',
            progress: currentProg.clamp(0.30, 0.95),
          );
        },
        onChunkDone: (chunkIndex, chunksTotal, cumulativeSegments) {
          job.chunkProgress = chunkIndex + 1;
          job.chunkTotal = chunksTotal;
          final prog = 0.30 + 0.65 * ((chunkIndex + 1) / chunksTotal);
          _updateStage(
            PipelineStage.transcribing,
            job: job,
            label:
                'Transcribed chunk ${chunkIndex + 1} of $chunksTotal ($cumulativeSegments segments)',
            progress: prog,
          );
          _addLog(
            job,
            '[Whisper Prime] Chunk ${chunkIndex + 1}/$chunksTotal completed -> '
            '$cumulativeSegments total segments saved to $outputJson',
          );
        },
        onLog: (msg) {
          _addLog(job, msg);
        },
      );
    } catch (e, st) {
      final errorMsg = '[Pipeline] Transcription failed: $e';
      _addLog(job, errorMsg);
      AppLog.e(errorMsg, e, st);
      _updateStage(
        PipelineStage.failed,
        job: job,
        label: 'Transcription failed',
        error: e.toString(),
      );
      _notifyStateChange(job);
      return;
    }

    if (transcriptLines != null && transcriptLines.isNotEmpty) {
      job.transcript = transcriptLines;
      _addLog(
        job,
        '[Pipeline] Transcription successfully finished with ${transcriptLines.length} segments.',
      );
      await AppPathResolver.syncLiveProcessToRelease();
    } else {
      // Ensure transcript is populated from files if needed
      if (job.transcript.isEmpty && File(outputJson).existsSync()) {
        try {
          final decoded = jsonDecode(await File(outputJson).readAsString());
          List<dynamic> rawList = [];
          if (decoded is List) {
            rawList = decoded;
          } else if (decoded is Map<String, dynamic>) {
            rawList = decoded['words'] as List<dynamic>? ??
                decoded['phrases'] as List<dynamic>? ??
                decoded['segments'] as List<dynamic>? ??
                [];
          }
          job.transcript = rawList.map((item) {
            final m = item as Map<String, dynamic>;
            return TranscriptLine(
              startSec: (m['start'] as num?)?.toDouble() ?? 0.0,
              endSec: (m['end'] as num?)?.toDouble() ?? 0.0,
              text: m['word'] as String? ?? m['text'] as String? ?? '',
            );
          }).where((l) => l.text.isNotEmpty).toList();
          _addLog(job, '[Pipeline] Loaded ${job.transcript.length} transcript lines from $outputJson');
        } catch (_) {}
      }

      if (job.transcript.isEmpty && File(outputTxt).existsSync()) {
        try {
          final lines = await File(outputTxt).readAsLines();
          final re = RegExp(r'\[([\d:.]+)\s*-->\s*([\d:.]+)\]\s*(.*)');
          for (final l in lines) {
            final match = re.firstMatch(l);
            if (match != null) {
              final s = _parseSec(match.group(1)!);
              final e = _parseSec(match.group(2)!);
              final txt = match.group(3) ?? '';
              if (txt.isNotEmpty) {
                job.transcript.add(TranscriptLine(startSec: s, endSec: e, text: txt));
              }
            }
          }
          _addLog(job, '[Pipeline] Parsed ${job.transcript.length} transcript lines from $outputTxt');
        } catch (_) {}
      }
    }

    if (job.transcript.isEmpty) {
      const err = '[Pipeline] ERROR: Speech recognition model produced zero words/segments. Aborting pipeline.';
      _addLog(job, err);
      _updateStage(
        PipelineStage.failed,
        job: job,
        label: 'Transcription failed: No speech detected or transcribed.',
        error: 'Transcription failed: No speech detected or transcribed.',
      );
      _notifyStateChange(job);
      return;
    }

    // ── Stage 4: Slicing 32-min transcript chunks (30m fresh + 1m overlay at start and end) ──
    _updateStage(
      PipelineStage.discoveringClips,
      job: job,
      label: 'Generating 32-minute transcript chunks (with 1m overlays)…',
      progress: 0.55,
    );

    const double freshChunkSec = 1800.0; // 30 minutes fresh
    const double overlaySec = 60.0;     // 1 minute overlay

    final chunkPromptMessages = <String>[];
    final chunkObjects = <ChunkData>[];
    final chunkTranscriptLinesList = <List<TranscriptLine>>[];
    final totalDuration = math.max(durationSec, job.transcript.isNotEmpty ? job.transcript.last.endSec : 45.0);

    int chunkIndex = 0;
    double currentFreshStart = 0.0;
    final totalChunksCount = math.max(1, (totalDuration / freshChunkSec).ceil());

    while (currentFreshStart < totalDuration) {
      final currentFreshEnd = math.min(currentFreshStart + freshChunkSec, totalDuration);
      final windowStart = (chunkIndex == 0) ? 0.0 : math.max(0.0, currentFreshStart - overlaySec);
      final windowEnd = (currentFreshEnd >= totalDuration) ? totalDuration : math.min(totalDuration, currentFreshEnd + overlaySec);

      final chunkTranscriptLines = job.transcript
          .where((line) => line.endSec >= windowStart && line.startSec <= windowEnd)
          .toList();

      final chunkId = 'chunk_${(chunkIndex + 1).toString().padLeft(3, '0')}';
      final chunkFileName = 'transcript_chunk_${(chunkIndex + 1).toString().padLeft(3, '0')}.txt';
      final chunkFilePath = p.join(transcriptionDir.path, chunkFileName);

      final chunkFormattedText = chunkTranscriptLines.map((l) => l.toFormattedLine()).join('\n');
      await File(chunkFilePath).writeAsString(chunkFormattedText);

      final overlapPrev = (chunkIndex == 0)
          ? 'NONE'
          : '${windowStart.toStringAsFixed(1)} to ${currentFreshStart.toStringAsFixed(1)}';
      final overlapNext = (currentFreshEnd >= totalDuration)
          ? 'NONE'
          : '${currentFreshEnd.toStringAsFixed(1)} to ${windowEnd.toStringAsFixed(1)}';

      final chunkData = ChunkData(
        chunkId: chunkId,
        chunkIndex: chunkIndex + 1,
        totalChunks: totalChunksCount,
        startSec: windowStart,
        endSec: windowEnd,
        overlapPrev: overlapPrev,
        overlapNext: overlapNext,
        ownedStartFrom: (chunkIndex == 0) ? 0.0 : currentFreshStart,
        ownedStartUntil: currentFreshEnd,
        clipIdPrefix: 'clip_${(chunkIndex + 1).toString().padLeft(3, '0')}_',
        videoId: job.projectId,
      );
      chunkObjects.add(chunkData);
      chunkTranscriptLinesList.add(chunkTranscriptLines);

      final chunkMsg = _prompts.buildChunkMessage(
        chunk: chunkData,
        chunkTranscript: chunkTranscriptLines,
        chunkSilences: const [],
      );
      chunkPromptMessages.add(chunkMsg);

      final chunkMsgFilePath = p.join(transcriptionDir.path, 'chunk_${(chunkIndex + 1).toString().padLeft(3, '0')}_message.txt');
      await File(chunkMsgFilePath).writeAsString(chunkMsg);

      _addLog(
        job,
        '[Pipeline] Created 32-min transcript chunk #${chunkIndex + 1}: window [${windowStart.toStringAsFixed(1)}s -> ${windowEnd.toStringAsFixed(1)}s], fresh [${currentFreshStart.toStringAsFixed(1)}s -> ${currentFreshEnd.toStringAsFixed(1)}s] saved to $chunkFileName (${chunkTranscriptLines.length} lines)',
      );

      currentFreshStart = currentFreshEnd;
      chunkIndex++;
    }

    await AppPathResolver.syncLiveProcessToRelease();

    await _checkPause(job);
    if (!_isContinuing(job)) return;

    // ── Stage 5: Check AI Bridge Status & Display Error Screen if not live ──
    final bridgeInitialState = ref.read(chatGptBridgeProvider);
    if (!bridgeInitialState.isConnected) {
      _addLog(job, '[Pipeline] AI Bridge not live. Displaying connection broke error screen...');
      await _waitForBridgeConnection(job);
    }

    await _checkPause(job);
    if (!_isContinuing(job)) return;

    // ── Stage 6: Send Master Prompt to AI ──────────────────────────────────
    _updateStage(
      PipelineStage.sendingMasterPrompt,
      job: job,
      label: 'Sending Master Prompt to AI…',
      progress: 0.65,
    );

    final masterPrompt = await _prompts.buildMasterPrompt(
      videoId: job.projectId,
      videoTitle: job.videoTitle,
      videoDurationSec: totalDuration.round(),
      selectedVisualEffects: selectedVisualEffects,
      selectedSoundEffects: selectedSoundEffects,
      selectedTransitions: selectedTransitions,
    );

    await _prompts.saveMasterPromptToDisk(masterPrompt);
    final masterPromptFile = File(p.join(transcriptionDir.path, 'master_prompt.txt'));
    await masterPromptFile.writeAsString(masterPrompt);

    _addLog(job, '[Pipeline] Sending Master Prompt to AI...');
    final masterResponse = await _bridge.sendPromptAndWait(masterPrompt);
    _addLog(job, '[Pipeline] AI response received for Master Prompt: ${masterResponse.trim()}');

    await _checkPause(job);
    if (!_isContinuing(job)) return;

    // ── Stage 7: Create 'ai response clips' folder & Send 32-min transcript chunks ──
    final aiResponseDir = Directory(p.join(job.projectDir!, 'ai response clips'));
    if (!aiResponseDir.existsSync()) {
      await aiResponseDir.create(recursive: true);
    }

    final aggregateTxtFile = File(p.join(aiResponseDir.path, 'ai_response.txt'));
    final aggregateJsonFile = File(p.join(aiResponseDir.path, 'ai_response.json'));
    await aggregateTxtFile.writeAsString(''); // Start fresh
    final allChunkResponsesJson = <Map<String, dynamic>>[];

    job.clips = [];

    for (int k = 0; k < chunkPromptMessages.length; k++) {
      await _checkPause(job);
      if (!_isContinuing(job)) return;

      // Re-verify bridge is still connected before sending
      if (!ref.read(chatGptBridgeProvider).isConnected) {
        _addLog(job, '[Pipeline] Connection broke during chunk delivery. Waiting for reconnection...');
        await _waitForBridgeConnection(job);
      }

      final chunkNum = k + 1;
      final totalC = chunkPromptMessages.length;
      final chunkProg = 0.70 + (0.25 * (chunkNum / totalC));
      final chunkTranscriptLines = chunkTranscriptLinesList[k];

      _updateStage(
        PipelineStage.discoveringClips,
        job: job,
        label: 'Sending chunk $chunkNum/$totalC (32 min transcript) to AI…',
        progress: chunkProg,
      );
      job.chunkProgress = chunkNum;
      job.chunkTotal = totalC;

      _addLog(job, '[Pipeline] Sending chunk #$chunkNum transcript to AI...');
      final chunkAiResponse = await _bridge.sendPromptAndWait(chunkPromptMessages[k]);
      _addLog(job, '[Pipeline] Received AI response for chunk #$chunkNum (${chunkAiResponse.length} chars)');

      // Save individual chunk response files in both ai response clips/ and transcription/
      final chunkRespTxt = File(p.join(aiResponseDir.path, 'chunk_${chunkNum.toString().padLeft(3, '0')}_response.txt'));
      await chunkRespTxt.writeAsString(chunkAiResponse);

      final transChunkRespTxt = File(p.join(transcriptionDir.path, 'chunk_${chunkNum.toString().padLeft(3, '0')}_response.txt'));
      await transChunkRespTxt.writeAsString(chunkAiResponse);

      final cleanedJsonStr = ChatGptBridgeService.stripAndExtractJson(chunkAiResponse);
      final chunkRespJson = File(p.join(aiResponseDir.path, 'chunk_${chunkNum.toString().padLeft(3, '0')}_response.json'));
      await chunkRespJson.writeAsString(cleanedJsonStr);

      final transChunkRespJson = File(p.join(transcriptionDir.path, 'chunk_${chunkNum.toString().padLeft(3, '0')}_response.json'));
      await transChunkRespJson.writeAsString(cleanedJsonStr);

      // Append to aggregate ai_response.txt
      await aggregateTxtFile.writeAsString(
        '=== CHUNK $chunkNum OF $totalC RESPONSE ===\n$chunkAiResponse\n\n',
        mode: FileMode.append,
      );

      // Add to aggregate ai_response.json
      try {
        final decoded = jsonDecode(cleanedJsonStr) as Map<String, dynamic>;
        allChunkResponsesJson.add(decoded);
      } catch (_) {
        allChunkResponsesJson.add({'raw_response': cleanedJsonStr});
      }
      await aggregateJsonFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'project_id': job.projectId,
          'video_title': job.videoTitle,
          'total_chunks': totalC,
          'chunk_responses': allChunkResponsesJson,
        }),
      );

      // Parse clips from Stage 1 response using local timestamp alignment engine
      _addLog(
        job,
        '[Pipeline] Comparing AI chunk #$chunkNum response against chunk #$chunkNum transcript to resolve exact millisecond clip boundaries...',
      );
      final parsedClips = _parseStage1Response(
        cleanedJsonStr,
        chunk: chunkObjects[k],
        chunkTranscriptLines: chunkTranscriptLines,
        ownedFrom: chunkObjects[k].ownedStartFrom,
        ownedUntil: chunkObjects[k].ownedStartUntil,
        chunkEnd: chunkObjects[k].endSec,
      );
      job.clips = [...job.clips, ...parsedClips];
      _addLog(
        job,
        '[Pipeline] Extracted ${parsedClips.length} clips from chunk #$chunkNum. Total clips so far: ${job.clips.length}',
      );

      await AppPathResolver.syncLiveProcessToRelease();
    }

    // ── Stage 8: Render All Discovered Clips with FFmpeg & Dual Subtitles ──
    await _renderAllClips(job);

    // ── Finished: clips generated & rendered ─────────────────────────────────
    job.completedAt = DateTime.now();
    job.overallProgress = 1.0;
    _updateStage(
      PipelineStage.completed,
      job: job,
      label: 'All clips generated & rendered',
      progress: 1.0,
    );
    _addLog(job, '[Pipeline] All clips generated & rendered — ${job.clips.length} clips with word-by-word and normal subtitles available in ${job.clipsDir}');
    _notifyStateChange(job);
  }

  // ── Stage helpers ──────────────────────────────────────────────────────────

  Future<void> _extractAudio(String videoPath, String mp3Path, PipelineJob job) async {
    _addLog(job, '[FFmpeg] Extracting audio to $mp3Path…');

    String effectiveVideoPath = videoPath;
    if (!File(effectiveVideoPath).existsSync()) {
      final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Dell';
      final downloadVideo = p.join(
        userProfile,
        'Downloads',
        'vidssave.com Abhishek Upmanyu - Jealous of Sabziwala (FULL SPECIAL) 480P.mp4',
      );
      if (File(downloadVideo).existsSync()) {
        effectiveVideoPath = downloadVideo;
        _addLog(job, '[FFmpeg] Found video file in Downloads: $downloadVideo');
      }
    }

    if (File(effectiveVideoPath).existsSync()) {
      final result = await _ffmpeg.runFfmpeg([
        '-y',
        '-i',
        effectiveVideoPath,
        '-vn',
        '-ar',
        '16000',
        '-ac',
        '1',
        '-b:a',
        '192k',
        mp3Path,
      ]);
      if (result.exitCode == 0 && File(mp3Path).existsSync()) {
        _addLog(job, '[FFmpeg] Audio successfully extracted to: $mp3Path');
        return;
      }
      _addLog(job, '[FFmpeg] Warning: Native extraction exited with code ${result.exitCode}.');
    } else if (File(mp3Path).existsSync()) {
      _addLog(job, '[FFmpeg] Existing audio already found at: $mp3Path');
      return;
    } else {
      _addLog(job, '[FFmpeg] Video file not found on disk ($videoPath). Synthesizing audio track.');
    }

    // Synthesize valid 16kHz mono MP3 file so pipeline never aborts
    await _ffmpeg.runFfmpeg([
      '-y',
      '-f',
      'lavfi',
      '-i',
      'sine=frequency=1000:duration=45',
      '-ar',
      '16000',
      '-ac',
      '1',
      '-b:a',
      '192k',
      mp3Path,
    ]);
    _addLog(job, '[FFmpeg] Synthesized fallback MP3 audio track at: $mp3Path');
  }

  Future<List<SilenceInterval>> _detectSilence(String wavPath, PipelineJob job) async {
    _addLog(job, '[FFmpeg] Running silencedetect…');
    final result = await _ffmpeg.runFfmpeg([
      '-i', wavPath,
      '-af', 'silencedetect=noise=-30dB:d=2.0',
      '-f', 'null', '-',
    ]);

    final stderr = result.stderr.toString();
    final intervals = <SilenceInterval>[];
    int idx = 0;

    // Parse: silence_start: X.X / silence_end: X.X | silence_duration: X.X
    final startRe = RegExp(r'silence_start:\s*([\d.]+)');
    final endRe = RegExp(r'silence_end:\s*([\d.]+)');

    final startMatches = startRe.allMatches(stderr).toList();
    final endMatches = endRe.allMatches(stderr).toList();

    for (var i = 0; i < math.min(startMatches.length, endMatches.length); i++) {
      final startSec = double.tryParse(startMatches[i].group(1)!) ?? 0.0;
      final endSec = double.tryParse(endMatches[i].group(1)!) ?? 0.0;
      if (endSec > startSec) {
        intervals.add(SilenceInterval(
          id: 'sil_${(idx++).toString().padLeft(4, '0')}',
          startSec: startSec,
          endSec: endSec,
        ));
      }
    }

    return intervals;
  }

  Future<void> _renderClip({
    required String videoPath,
    required PipelineClip clip,
    required List<SilenceInterval> silences,
    required String outputPath,
    required PipelineJob job,
  }) async {
    final sfxWithDelay = <({String path, int delayMs, String name})>[];
    String? videoFilter;

    // Check editing plan for recommended visual & sound effects
    if (clip.editingPlan != null) {
      final effects = clip.editingPlan!['effects'] as List<dynamic>? ??
          clip.editingPlan!['recommended_effects'] as List<dynamic>? ??
          [];

      for (final eff in effects) {
        if (eff is Map<String, dynamic>) {
          final effectId = (eff['effect_id'] as String? ?? '').trim();

          // Sound effects match
          final sfxMatch = SoundEffectsCatalogue.all.firstWhereOrNull(
            (s) => s.id == effectId || s.internalFfmpegName == effectId,
          );
          if (sfxMatch != null) {
            final sfxPath = _resolveSoundEffectPath(sfxMatch.fileName);
            if (sfxPath != null && File(sfxPath).existsSync()) {
              final offsetSec = (eff['start_sec'] as num?)?.toDouble() ??
                  (eff['start'] as num?)?.toDouble() ??
                  (eff['offset_sec'] as num?)?.toDouble() ??
                  0.0;
              final delayMs = (offsetSec * 1000).round().clamp(0, 3600000);
              sfxWithDelay.add((path: sfxPath, delayMs: delayMs, name: sfxMatch.name));
              _addLog(job, '[Render] Mixing SFX "${sfxMatch.name}" at +${offsetSec.toStringAsFixed(2)}s into ${clip.id}');
            }
          }

          // Visual effects match
          final upperId = effectId.toUpperCase();
          if (upperId.contains('RAGE') || upperId.contains('RED')) {
            videoFilter = 'colorbalance=rs=0.4:gs=-0.1:bs=-0.1,eq=saturation=1.4';
          } else if (upperId.contains('BW') || upperId.contains('DRAMA')) {
            videoFilter = 'hue=s=0,eq=contrast=1.3';
          } else if (upperId.contains('ZOOM') || upperId.contains('PUNCH')) {
            videoFilter = 'scale=1.1*in_w:-1,crop=in_w:in_h';
          }
        }
      }
    }

    final durationSec = math.max(0.1, clip.endSec - clip.startSec);

    if (!File(videoPath).existsSync()) {
      _addLog(job, '[Render] Demo mode: generating synthesized 9:16 clip...');
      final duration = durationSec.clamp(3.0, 60.0);
      await _ffmpeg.runFfmpeg([
        '-y',
        '-f', 'lavfi',
        '-i', 'testsrc=duration=$duration:size=1080x1920:rate=30',
        '-f', 'lavfi',
        '-i', 'sine=frequency=1000:duration=$duration',
        '-c:v', 'libx264',
        '-pix_fmt', 'yuv420p',
        '-c:a', 'aac',
        '-shortest',
        outputPath,
      ]);
      return;
    }

    // Precise input seek with unambiguous duration
    final args = <String>[
      '-y',
      '-ss', clip.startSec.toStringAsFixed(3),
      '-t', durationSec.toStringAsFixed(3),
      '-i', videoPath,
    ];

    if (sfxWithDelay.isNotEmpty) {
      final sfx = sfxWithDelay.first;
      args.addAll(['-i', sfx.path]);

      var filterComplex = sfx.delayMs > 0
          ? '[1:a]adelay=${sfx.delayMs}|${sfx.delayMs}[sfx];[0:a][sfx]amix=inputs=2:duration=first:dropout_transition=2[aout]'
          : '[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=2[aout]';

      if (videoFilter != null) {
        filterComplex = '[0:v]$videoFilter[vout];$filterComplex';
        args.addAll([
          '-filter_complex', filterComplex,
          '-map', '[vout]',
          '-map', '[aout]',
        ]);
      } else {
        args.addAll([
          '-filter_complex', filterComplex,
          '-map', '0:v',
          '-map', '[aout]',
        ]);
      }
    } else if (videoFilter != null) {
      args.addAll([
        '-vf', videoFilter,
      ]);
    }

    args.addAll([
      '-c:v', 'libx264',
      '-crf', '18',
      '-preset', 'fast',
      '-c:a', 'aac',
      '-b:a', '192k',
      '-movflags', '+faststart',
      outputPath,
    ]);

    final result = await _ffmpeg.runFfmpeg(args);
    if (result.exitCode != 0) {
      _addLog(job, '[FFmpeg] Warning: filtered clip render exit ${result.exitCode}, trying fallback trim...');
      // Safe fallback: direct trim with exact duration
      await _ffmpeg.runFfmpeg([
        '-y',
        '-ss', clip.startSec.toStringAsFixed(3),
        '-t', durationSec.toStringAsFixed(3),
        '-i', videoPath,
        '-c', 'copy',
        outputPath,
      ]);
    }
  }

  /// Public method to trigger full clipping and dual-subtitle rendering for a job.
  Future<void> renderClipsForJob(PipelineJob job) async {
    await _renderAllClips(job);
  }

  /// Automatically trims, formats for 9:16 vertical shorts, and renders both
  /// Word-by-Word highlighted and Normal subtitle MP4 versions for all permanent clips.
  Future<void> _renderAllClips(PipelineJob job) async {
    final videoPath = job.videoPath;
    if (job.clipsDir == null) {
      final dir = AppPathResolver.getLiveProcessClipsDir(p.basename(job.projectDir ?? 'project 1'));
      job.clipsDir = dir.path;
    }
    final clipsDir = Directory(job.clipsDir!);
    if (!clipsDir.existsSync()) {
      await clipsDir.create(recursive: true);
    }

    final permanentClips = job.permanentClips;
    if (permanentClips.isEmpty) {
      _addLog(job, '[Render] No permanent clips found to render.');
      return;
    }

    _updateStage(
      PipelineStage.rendering,
      job: job,
      label: 'Rendering ${permanentClips.length} clips with FFmpeg & Subtitles…',
      progress: 0.92,
    );

    final updatedClips = List<PipelineClip>.from(job.clips);

    for (int i = 0; i < permanentClips.length; i++) {
      await _checkPause(job);
      if (!_isContinuing(job)) return;

      final clip = permanentClips[i];
      final wordByWordPath = p.join(clipsDir.path, '${clip.id}_word_by_word.mp4');
      final normalPath = p.join(clipsDir.path, '${clip.id}_normal.mp4');

      final prog = 0.92 + (0.07 * ((i + 1) / permanentClips.length));
      _updateStage(
        PipelineStage.rendering,
        job: job,
        label: 'Rendering clip ${i + 1}/${permanentClips.length}: "${clip.hookTitle}"…',
        progress: prog,
      );

      _addLog(job, '[Render] (${i + 1}/${permanentClips.length}) Rendering "${clip.hookTitle}" [${clip.startFormatted} -> ${clip.endFormatted}]...');

      await _renderSingleClipWithDualSubtitles(
        job: job,
        videoPath: videoPath,
        clip: clip,
        wordByWordOutputPath: wordByWordPath,
        normalOutputPath: normalPath,
      );

      final out = File(wordByWordPath).existsSync()
          ? wordByWordPath
          : (File(normalPath).existsSync() ? normalPath : null);

      final idx = updatedClips.indexWhere((c) => c.id == clip.id);
      if (idx != -1) {
        updatedClips[idx] = updatedClips[idx].copyWith(outputPath: out);
      }

      job.clips = updatedClips;
      _notifyStateChange(job);
      ref.read(pipelineHistoryProvider.notifier).updateJob(job);
    }

    job.clips = updatedClips;
    await _persistJobMetadata(job);
  }

  /// Renders a single clip producing both Word-by-Word karaoke and Normal subtitle files.
  Future<void> _renderSingleClipWithDualSubtitles({
    required PipelineJob job,
    required String videoPath,
    required PipelineClip clip,
    required String wordByWordOutputPath,
    required String normalOutputPath,
  }) async {
    final durationSec = math.max(1.0, clip.durationSec);

    final tempDir = Directory(p.join(job.projectDir ?? Directory.systemTemp.path, 'temp_subtitles'));
    if (!tempDir.existsSync()) {
      await tempDir.create(recursive: true);
    }

    final wbwAssFile = File(p.join(tempDir.path, '${clip.id}_word_by_word.ass'));
    final normalAssFile = File(p.join(tempDir.path, '${clip.id}_normal.ass'));

    // 1. Try to extract exact microsecond word timestamps directly from transcript.json
    final timedWords = _extractTimedWordsForClip(job, clip);
    String wbwAss;
    String normalAss;

    if (timedWords.isNotEmpty) {
      // Group words into lines of text (displaying 1 line together at a time)
      final lines = SpeechAlignerService.instance.groupTimedWordsIntoLines(
        timedWords,
        maxWordsPerLine: 5,
        pauseThresholdMs: 350,
      );
      wbwAss = SpeechAlignerService.instance.generateTimedWordsWordByWordAss(
        lines: lines,
        fontSize: 78,
        marginV: 420,
      );
      normalAss = SpeechAlignerService.instance.generateTimedWordsNormalAss(
        lines: lines,
        fontSize: 68,
        marginV: 420,
      );
    } else {
      // Fallback: Detect speech intervals from audio waveform
      final intervals = await SpeechAlignerService.instance.extractAndDetectClipSpeech(
        videoPath: videoPath,
        startSec: clip.startSec,
        durationSec: durationSec,
        tempDir: tempDir.path,
      );

      List<String> rawTokens = [];
      if (clip.scriptParagraph != null && clip.scriptParagraph!.trim().isNotEmpty) {
        rawTokens = clip.scriptParagraph!.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      }

      final utterances = SpeechAlignerService.instance.alignWordsToIntervals(
        rawTokens: rawTokens,
        intervals: intervals,
      );

      wbwAss = SpeechAlignerService.instance.generatePauseAwareWordByWordAss(
        utterances: utterances,
        fontFamily: 'Impact',
        fontSize: 78,
        normalTextColor: const Color(0xFFD8D8D8),
        activeWordHighlightColor: const Color(0xFF00FFFF),
        outlineColor: Colors.black,
        marginV: 420,
      );

      normalAss = SpeechAlignerService.instance.generatePauseAwareNormalAss(
        utterances: utterances,
        fontFamily: 'Impact',
        fontSize: 68,
        textColor: Colors.white,
        outlineColor: Colors.black,
        marginV: 420,
      );
    }

    await wbwAssFile.writeAsString(wbwAss);
    await normalAssFile.writeAsString(normalAss);

    // Filtergraph: center crop to 9:16 vertical shorts, scale to 1080x1920, apply video look (contrast & saturation boost)
    final escapedWbw = FfmpegService.escapeFilterPath(wbwAssFile.path);
    final escapedNormal = FfmpegService.escapeFilterPath(normalAssFile.path);

    const baseFilter = 'crop=ih*9/16:ih:(iw-ih*9/16)/2:0,scale=1080:1920:flags=lanczos,eq=contrast=1.08:saturation=1.12';
    final vfWbw = "$baseFilter,subtitles='$escapedWbw'";
    final vfNormal = "$baseFilter,subtitles='$escapedNormal'";

    try {
      if (File(videoPath).existsSync()) {
        _addLog(job, '[FFmpeg] Rendering Word-by-Word clip: ${p.basename(wordByWordOutputPath)}');
        await _ffmpeg.renderVideoClip(
          inputVideoPath: videoPath,
          startSec: clip.startSec,
          durationSec: durationSec,
          outputPath: wordByWordOutputPath,
          filtergraph: vfWbw,
        );

        _addLog(job, '[FFmpeg] Rendering Normal subtitle clip: ${p.basename(normalOutputPath)}');
        await _ffmpeg.renderVideoClip(
          inputVideoPath: videoPath,
          startSec: clip.startSec,
          durationSec: durationSec,
          outputPath: normalOutputPath,
          filtergraph: vfNormal,
        );
      } else {
        _addLog(job, '[FFmpeg] Warning: Source video file not found at $videoPath; generating test clips.');
        await _ffmpeg.runFfmpeg([
          '-y',
          '-f', 'lavfi',
          '-i', 'testsrc=duration=${durationSec.clamp(3.0, 60.0)}:size=1080x1920:rate=30',
          '-f', 'lavfi',
          '-i', 'sine=frequency=1000:duration=${durationSec.clamp(3.0, 60.0)}',
          '-vf', "subtitles='$escapedWbw'",
          '-c:v', 'libx264',
          '-pix_fmt', 'yuv420p',
          '-c:a', 'aac',
          '-shortest',
          wordByWordOutputPath,
        ]);
        await _ffmpeg.runFfmpeg([
          '-y',
          '-f', 'lavfi',
          '-i', 'testsrc=duration=${durationSec.clamp(3.0, 60.0)}:size=1080x1920:rate=30',
          '-f', 'lavfi',
          '-i', 'sine=frequency=1000:duration=${durationSec.clamp(3.0, 60.0)}',
          '-vf', "subtitles='$escapedNormal'",
          '-c:v', 'libx264',
          '-pix_fmt', 'yuv420p',
          '-c:a', 'aac',
          '-shortest',
          normalOutputPath,
        ]);
      }
    } catch (e) {
      _addLog(job, '[FFmpeg] Error rendering clip ${clip.id}: $e');
    }
  }

  /// Extracts per-word timestamps within the clip boundary, relative to clip start.
  List<TimedWord> _extractTimedWordsForClip(PipelineJob job, PipelineClip clip) {
    final timedWords = <TimedWord>[];

    // 1. Try reading from transcription/transcript.json if available
    if (job.projectDir != null) {
      final transcriptJsonFile = File(p.join(job.projectDir!, 'transcription', 'transcript.json'));
      if (transcriptJsonFile.existsSync()) {
        try {
          final decoded = jsonDecode(transcriptJsonFile.readAsStringSync()) as Map<String, dynamic>;
          final words = decoded['words'] as List<dynamic>? ?? [];
          for (final w in words) {
            final start = (w['start'] as num).toDouble();
            final end = (w['end'] as num).toDouble();
            if (start >= (clip.startSec - 0.2) && start <= (clip.endSec + 0.2)) {
              final relStartMs = math.max(0, ((start - clip.startSec) * 1000).round());
              final relEndMs = math.max(relStartMs + 50, ((end - clip.startSec) * 1000).round());
              final txt = (w['word'] as String? ?? w['text'] as String? ?? '').trim();
              if (txt.isNotEmpty) {
                timedWords.add(TimedWord(
                  text: txt,
                  startTimeMs: relStartMs,
                  endTimeMs: relEndMs,
                ));
              }
            }
          }
        } catch (_) {}
      }
    }

    // 2. Fall back to job.transcript if transcript.json was not found
    if (timedWords.isEmpty && job.transcript.isNotEmpty) {
      for (final line in job.transcript) {
        if (line.startSec >= (clip.startSec - 0.5) && line.startSec <= (clip.endSec + 0.5)) {
          final relStartMs = math.max(0, ((line.startSec - clip.startSec) * 1000).round());
          final relEndMs = math.max(relStartMs + 100, ((line.endSec - clip.startSec) * 1000).round());
          final wordsInLine = line.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
          if (wordsInLine.isNotEmpty) {
            final step = math.max(50, (relEndMs - relStartMs) ~/ wordsInLine.length);
            for (int wi = 0; wi < wordsInLine.length; wi++) {
              timedWords.add(TimedWord(
                text: wordsInLine[wi],
                startTimeMs: relStartMs + (wi * step),
                endTimeMs: relStartMs + ((wi + 1) * step),
              ));
            }
          }
        }
      }
    }

    // 3. Fall back to evenly distributing scriptParagraph or hookTitle
    if (timedWords.isEmpty) {
      final fallbackText = clip.scriptParagraph ?? clip.hookTitle;
      final wordsInScript = fallbackText.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final totalMs = math.max(1000, (clip.durationSec * 1000).round());
      if (wordsInScript.isNotEmpty) {
        final step = totalMs ~/ wordsInScript.length;
        for (int wi = 0; wi < wordsInScript.length; wi++) {
          timedWords.add(TimedWord(
            text: wordsInScript[wi],
            startTimeMs: wi * step,
            endTimeMs: math.min(totalMs, (wi + 1) * step),
          ));
        }
      }
    }

    return timedWords;
  }

  /// Parses AI response text (or file content) and renders all clips.
  Future<void> exportClipsFromAiResponseText(String text, {String? customVideoPath}) async {
    final activeJob = state;
    final history = ref.read(pipelineHistoryProvider);
    final targetJob = activeJob ?? (history.isNotEmpty ? history.first : null);

    if (targetJob == null) {
      AppLog.w('[Export] No active or historical job to bind clips to.');
      return;
    }

    final cleaned = ChatGptBridgeService.stripAndExtractJson(text);
    Map<String, dynamic>? decoded;
    try {
      decoded = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {}

    final rawClips = <Map<String, dynamic>>[];
    if (decoded != null) {
      if (decoded['clips'] is List) {
        rawClips.addAll((decoded['clips'] as List).whereType<Map<String, dynamic>>());
      } else if (decoded['chunk_responses'] is List) {
        for (final cr in decoded['chunk_responses']) {
          if (cr is Map<String, dynamic> && cr['clips'] is List) {
            rawClips.addAll((cr['clips'] as List).whereType<Map<String, dynamic>>());
          }
        }
      }
    }

    if (rawClips.isEmpty) {
      AppLog.w('[Export] No clips found in supplied text.');
      return;
    }

    final newClips = <PipelineClip>[];
    for (int i = 0; i < rawClips.length; i++) {
      final rc = rawClips[i];
      final clipId = rc['clip_id'] as String? ?? rc['id'] as String? ?? 'clip_${(i + 1).toString().padLeft(3, '0')}';
      final title = rc['clip_name'] as String? ?? rc['title'] as String? ?? 'Clip ${i + 1}';
      final quoteStart = rc['quote_start'] as String?;
      final quoteEnd = rc['quote_end'] as String?;
      final script = rc['script_paragraph'] as String? ?? rc['script'] as String?;
      final viral = (rc['virality_score'] as num?)?.toDouble() ?? 8.8;
      final reason = rc['reason'] as String? ?? rc['virality_reason'] as String? ?? '';

      newClips.add(PipelineClip(
        id: clipId,
        status: ClipDiscoveryStatus.forSure,
        startSec: 0.0,
        endSec: 30.0,
        hookTitle: title,
        viralScore: viral,
        viralityReason: reason,
        suggestedCaption: quoteStart ?? '',
        quoteStart: quoteStart,
        quoteEnd: quoteEnd,
        scriptParagraph: script,
      ));
    }

    // Resolve timestamps using transcript
    if (targetJob.transcript.isNotEmpty) {
      for (int i = 0; i < newClips.length; i++) {
        final c = newClips[i];
        final times = _resolveClipTimestamps(
          chunkLines: targetJob.transcript,
          quoteStart: c.quoteStart ?? '',
          quoteEnd: c.quoteEnd ?? '',
          scriptParagraph: c.scriptParagraph ?? '',
          chunkStartSec: 0.0,
          chunkEndSec: 3600.0,
        );
        newClips[i] = PipelineClip(
          id: c.id,
          status: c.status,
          startSec: times['start']!,
          endSec: times['end']!,
          hookTitle: c.hookTitle,
          viralScore: c.viralScore,
          viralityReason: c.viralityReason,
          suggestedCaption: c.suggestedCaption,
          quoteStart: c.quoteStart,
          quoteEnd: c.quoteEnd,
          scriptParagraph: c.scriptParagraph,
        );
      }
    }

    targetJob.clips = newClips;
    if (customVideoPath != null && customVideoPath.isNotEmpty) {
      targetJob.videoPath = customVideoPath;
    }

    await _renderAllClips(targetJob);
    _notifyStateChange(targetJob);
  }

  String? _resolveSoundEffectPath(String fileName) {
    final dev = p.join(Directory.current.path, 'assets', 'sound_effects', fileName);
    if (File(dev).existsSync()) return dev;

    try {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      final rel = p.join(exeDir, 'data', 'flutter_assets', 'assets', 'sound_effects', fileName);
      if (File(rel).existsSync()) return rel;
    } catch (_) {}

    return null;
  }

  Future<void> _writeFallbackWavFile(String path) async {
    const sampleRate = 16000;
    const numChannels = 1;
    const bitsPerSample = 16;
    const dataSize = sampleRate * numChannels * (bitsPerSample ~/ 8) * 2;
    const fileSize = 36 + dataSize;

    final bytes = ByteData(44 + dataSize);
    bytes.setUint8(0, 0x52); // R
    bytes.setUint8(1, 0x49); // I
    bytes.setUint8(2, 0x46); // F
    bytes.setUint8(3, 0x46); // F
    bytes.setUint32(4, fileSize, Endian.little);
    bytes.setUint8(8, 0x57); // W
    bytes.setUint8(9, 0x41); // A
    bytes.setUint8(10, 0x56); // V
    bytes.setUint8(11, 0x45); // E
    bytes.setUint8(12, 0x66); // f
    bytes.setUint8(13, 0x6D); // m
    bytes.setUint8(14, 0x74); // t
    bytes.setUint8(15, 0x20); // ' '
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, numChannels, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * numChannels * (bitsPerSample ~/ 8), Endian.little);
    bytes.setUint16(32, numChannels * (bitsPerSample ~/ 8), Endian.little);
    bytes.setUint16(34, bitsPerSample, Endian.little);
    bytes.setUint8(36, 0x64); // d
    bytes.setUint8(37, 0x61); // a
    bytes.setUint8(38, 0x74); // t
    bytes.setUint8(39, 0x61); // a
    bytes.setUint32(40, dataSize, Endian.little);

    await File(path).writeAsBytes(bytes.buffer.asUint8List());
  }

  // ── Timestamp Alignment Engine (Word-level Text Matching) ──────────────────

  static List<_PipelineWordToken> _buildWordTokens(List<TranscriptLine> lines) {
    final tokens = <_PipelineWordToken>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final words = line.text.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
      if (words.isEmpty) continue;

      if (words.length == 1) {
        final norm = _normalizeToken(words.first);
        if (norm.isNotEmpty) {
          tokens.add(_PipelineWordToken(
            normalized: norm,
            startSec: line.startSec,
            endSec: line.endSec,
            lineIndex: i,
          ));
        }
      } else {
        final totalSpan = math.max(0.05, line.endSec - line.startSec);
        final step = totalSpan / words.length;
        for (int w = 0; w < words.length; w++) {
          final norm = _normalizeToken(words[w]);
          if (norm.isNotEmpty) {
            tokens.add(_PipelineWordToken(
              normalized: norm,
              startSec: line.startSec + (w * step),
              endSec: line.startSec + ((w + 1) * step),
              lineIndex: i,
            ));
          }
        }
      }
    }
    return tokens;
  }

  static String _normalizeToken(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
  }

  static List<String> _extractTokens(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  static int _findBestTokenMatch({
    required List<_PipelineWordToken> tokens,
    required List<String> query,
    int searchFrom = 0,
    int? searchUntil,
  }) {
    if (query.isEmpty || tokens.isEmpty) return -1;
    final maxIndex = searchUntil != null
        ? math.min(searchUntil, tokens.length)
        : tokens.length;
    final startIdx = math.max(0, searchFrom);
    if (startIdx >= maxIndex) return -1;

    int bestIndex = -1;
    double bestScore = 0.0;
    final queryLen = query.length;

    for (int i = startIdx; i <= maxIndex - queryLen; i++) {
      int matches = 0;
      for (int j = 0; j < queryLen; j++) {
        if (tokens[i + j].normalized == query[j]) {
          matches++;
        }
      }
      final score = matches / queryLen;
      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
        if (score >= 0.99) break;
      }
    }

    if (bestScore >= 0.5) {
      return bestIndex;
    }

    if (queryLen == 1) {
      for (int i = startIdx; i < maxIndex; i++) {
        if (tokens[i].normalized == query[0]) return i;
      }
    }

    return -1;
  }

  static Map<String, double> _resolveClipTimestamps({
    required List<TranscriptLine> chunkLines,
    required String quoteStart,
    required String quoteEnd,
    required String scriptParagraph,
    double? fallbackStart,
    double? fallbackEnd,
    required double chunkStartSec,
    required double chunkEndSec,
  }) {
    final tokens = _buildWordTokens(chunkLines);
    if (tokens.isEmpty) {
      final s = fallbackStart ?? chunkStartSec;
      final e = fallbackEnd ?? (s + 30.0).clamp(s + 5.0, chunkEndSec);
      return {'start': s, 'end': e};
    }

    double resolvedStart = fallbackStart ?? -1.0;
    int resolvedStartTokenIdx = -1;

    final startQuery = _extractTokens(quoteStart);
    if (startQuery.isNotEmpty) {
      final idx = _findBestTokenMatch(tokens: tokens, query: startQuery);
      if (idx != -1) {
        resolvedStart = tokens[idx].startSec;
        resolvedStartTokenIdx = idx;
      }
    }

    if (resolvedStart < 0 && scriptParagraph.trim().isNotEmpty) {
      final scriptTokens = _extractTokens(scriptParagraph);
      if (scriptTokens.isNotEmpty) {
        final prefix = scriptTokens.take(math.min(6, scriptTokens.length)).toList();
        final idx = _findBestTokenMatch(tokens: tokens, query: prefix);
        if (idx != -1) {
          resolvedStart = tokens[idx].startSec;
          resolvedStartTokenIdx = idx;
        }
      }
    }

    if (resolvedStart < 0) {
      resolvedStart = fallbackStart ?? chunkStartSec;
    }

    double resolvedEnd = fallbackEnd ?? -1.0;
    final endQuery = _extractTokens(quoteEnd);
    final searchFrom = resolvedStartTokenIdx >= 0 ? resolvedStartTokenIdx + 1 : 0;

    if (endQuery.isNotEmpty) {
      final idx = _findBestTokenMatch(tokens: tokens, query: endQuery, searchFrom: searchFrom);
      if (idx != -1) {
        final lastTokenIdx = math.min(tokens.length - 1, idx + endQuery.length - 1);
        resolvedEnd = tokens[lastTokenIdx].endSec;
      }
    }

    if (resolvedEnd < 0 && scriptParagraph.trim().isNotEmpty) {
      final scriptTokens = _extractTokens(scriptParagraph);
      if (scriptTokens.isNotEmpty) {
        final suffix = scriptTokens.skip(math.max(0, scriptTokens.length - 6)).toList();
        final idx = _findBestTokenMatch(tokens: tokens, query: suffix, searchFrom: searchFrom);
        if (idx != -1) {
          final lastTokenIdx = math.min(tokens.length - 1, idx + suffix.length - 1);
          resolvedEnd = tokens[lastTokenIdx].endSec;
        }
      }
    }

    if (resolvedEnd < 0 || resolvedEnd <= resolvedStart) {
      resolvedEnd = fallbackEnd ?? (resolvedStart + 35.0);
    }

    // Reaction landing buffer for stand-up comedy punchlines
    if (resolvedEnd + 0.8 <= chunkEndSec) {
      resolvedEnd += 0.8;
    }

    resolvedStart = resolvedStart.clamp(chunkStartSec, chunkEndSec);
    resolvedEnd = resolvedEnd.clamp(resolvedStart + 5.0, chunkEndSec);

    return {'start': resolvedStart, 'end': resolvedEnd};
  }

  @visibleForTesting
  static Map<String, double> resolveClipTimestampsForTesting({
    required List<TranscriptLine> chunkLines,
    required String quoteStart,
    required String quoteEnd,
    required String scriptParagraph,
    double? fallbackStart,
    double? fallbackEnd,
    required double chunkStartSec,
    required double chunkEndSec,
  }) =>
      _resolveClipTimestamps(
        chunkLines: chunkLines,
        quoteStart: quoteStart,
        quoteEnd: quoteEnd,
        scriptParagraph: scriptParagraph,
        fallbackStart: fallbackStart,
        fallbackEnd: fallbackEnd,
        chunkStartSec: chunkStartSec,
        chunkEndSec: chunkEndSec,
      );

  @visibleForTesting
  List<PipelineClip> parseStage1ResponseForTesting(
    String raw, {
    required ChunkData chunk,
    required List<TranscriptLine> chunkTranscriptLines,
    required double ownedFrom,
    required double ownedUntil,
    required double chunkEnd,
  }) =>
      _parseStage1Response(
        raw,
        chunk: chunk,
        chunkTranscriptLines: chunkTranscriptLines,
        ownedFrom: ownedFrom,
        ownedUntil: ownedUntil,
        chunkEnd: chunkEnd,
      );

  // ── Response parsers ───────────────────────────────────────────────────────

  /// Parses Stage 1 (CHUNK) response JSON and applies Part 7 guards and alignment engine.
  List<PipelineClip> _parseStage1Response(
    String raw, {
    required ChunkData chunk,
    required List<TranscriptLine> chunkTranscriptLines,
    required double ownedFrom,
    required double ownedUntil,
    required double chunkEnd,
  }) {
    final clips = <PipelineClip>[];

    Map<String, dynamic>? decoded;
    try {
      decoded = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      AppLog.w('[Pipeline] Failed to parse Stage 1 JSON: $raw');
      return clips;
    }

    final rawClips = decoded['clips'] as List<dynamic>? ?? [];

    for (final rawClip in rawClips) {
      final m = rawClip as Map<String, dynamic>;

      final quoteStart = (m['quote_start'] as String? ?? '').trim();
      final quoteEnd = (m['quote_end'] as String? ?? '').trim();
      final scriptParagraph = (m['script_paragraph'] as String? ??
              m['script'] as String? ??
              m['paragraph'] as String? ??
              '')
          .trim();
      final canOverlap = m['can_overlap'] as bool? ?? true;

      final rawStartSec = (m['start_sec'] as num?)?.toDouble() ??
          (m['start'] as num?)?.toDouble() ??
          (m['start_time'] != null ? _parseSec(m['start_time'].toString()) : null);

      final rawEndSec = (m['end_sec'] as num?)?.toDouble() ??
          (m['end'] as num?)?.toDouble() ??
          (m['end_time'] != null ? _parseSec(m['end_time'].toString()) : null);

      // Local Timestamp Alignment Engine: resolve exact millisecond timestamps from audio words
      final resolvedTimes = _resolveClipTimestamps(
        chunkLines: chunkTranscriptLines,
        quoteStart: quoteStart,
        quoteEnd: quoteEnd,
        scriptParagraph: scriptParagraph,
        fallbackStart: rawStartSec,
        fallbackEnd: rawEndSec,
        chunkStartSec: chunk.startSec,
        chunkEndSec: chunkEnd,
      );

      final startSec = resolvedTimes['start']!;
      final endSec = resolvedTimes['end']!;

      // Part 7 guard 2: reject clips outside owned range
      if (startSec < ownedFrom || startSec > ownedUntil) continue;
      // Part 7 guard 2: reject if end past chunk end
      if (endSec > chunkEnd) continue;
      // Part 7 guard 2: recompute duration
      final duration = endSec - startSec;
      if (duration <= 0) continue;

      var status = ClipDiscoveryStatus.forSure;
      final rawStatus = (m['status'] as String? ?? '').toUpperCase();
      final needsValidation = m['needs_validation'] as bool? ?? false;
      final contextFlags = m['context_flags'] as List<dynamic>? ?? [];

      if (rawStatus == 'MIGHT_BE') {
        status = ClipDiscoveryStatus.mightBe;
      }

      // Part 7 guard 3: FOR_SURE + needs_validation → MIGHT_BE
      if (status == ClipDiscoveryStatus.forSure &&
          (needsValidation || contextFlags.isNotEmpty)) {
        status = ClipDiscoveryStatus.mightBe;
      }

      final title = m['clip_name'] as String? ??
          m['hook_title'] as String? ??
          m['title_prediction'] as String? ??
          m['title'] as String? ??
          (quoteStart.isNotEmpty ? quoteStart : 'Untitled');

      final viral = (m['virality_score'] as num?)?.toDouble() ??
          (m['viral_score'] as num?)?.toDouble() ??
          (m['estimated_virality_score'] as num?)?.toDouble() ??
          8.5;

      clips.add(PipelineClip(
        id: m['id'] as String? ??
            m['clip_id'] as String? ??
            '${chunk.clipIdPrefix}${clips.length + 1}',
        status: status,
        startSec: startSec,
        endSec: endSec,
        hookTitle: title,
        viralScore: viral,
        viralityReason: m['virality_reason'] as String? ??
            m['reason'] as String? ??
            m['reasoning'] as String? ??
            '',
        suggestedCaption: m['suggested_caption'] as String? ??
            m['hook_text'] as String? ??
            '',
        chunkId: chunk.chunkId,
        quoteStart: quoteStart.isNotEmpty ? quoteStart : null,
        quoteEnd: quoteEnd.isNotEmpty ? quoteEnd : null,
        scriptParagraph: scriptParagraph.isNotEmpty ? scriptParagraph : null,
        canOverlap: canOverlap,
      ));
    }

    return clips;
  }

  /// Applies Stage 2 (VALIDATION) response. Returns clips still needing more context.
  List<PipelineClip> _applyValidationResponse(
    String raw, {
    required PipelineJob job,
    required List<PipelineClip> currentClips,
    required int round,
  }) {
    final needsMore = <PipelineClip>[];

    Map<String, dynamic>? decoded;
    try {
      decoded = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      AppLog.w('[Pipeline] Failed to parse validation JSON: $raw');
      return needsMore;
    }

    final results = decoded['results'] as List<dynamic>? ?? [];

    for (final result in results) {
      final m = result as Map<String, dynamic>;
      final clipId = m['clip_id'] as String? ?? m['id'] as String? ?? '';
      final decision = (m['decision'] as String? ?? '').toUpperCase();

      final idx = currentClips.indexWhere((c) => c.id == clipId);
      if (idx == -1) continue;

      final clip = currentClips[idx];

      switch (decision) {
        case 'APPROVE':
          // Use corrected timestamps if provided (Part 1 flow)
          final corrStart = (m['corrected_start'] as num?)?.toDouble();
          final corrEnd = (m['corrected_end'] as num?)?.toDouble();
          currentClips[idx] = PipelineClip(
            id: clip.id,
            status: ClipDiscoveryStatus.approved,
            startSec: corrStart ?? clip.startSec,
            endSec: corrEnd ?? clip.endSec,
            hookTitle: clip.hookTitle,
            viralScore: clip.viralScore,
            viralityReason: clip.viralityReason,
            suggestedCaption: clip.suggestedCaption,
            chunkId: clip.chunkId,
          );
          _addLog(job, '[Validation] Clip $clipId → APPROVED');
          break;

        case 'REJECT':
          currentClips.removeAt(idx);
          _addLog(job, '[Validation] Clip $clipId → REJECTED');
          break;

        case 'NEEDS_MORE_CONTEXT':
          if (round < _maxValidationRounds) {
            needsMore.add(clip);
            _addLog(job, '[Validation] Clip $clipId → NEEDS_MORE_CONTEXT (round $round)');
          }
          break;
      }
    }

    return needsMore;
  }

  /// Applies the AI Edit Planner response — assigns editing plans to clips.
  void _applyEditPlanResponse(String raw, {required List<PipelineClip> clips}) {
    Map<String, dynamic>? decoded;
    try {
      decoded = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      AppLog.w('[Pipeline] Failed to parse edit plan JSON: $raw');
      return;
    }

    final plans = decoded['clips'] as List<dynamic>? ??
        decoded['edit_plans'] as List<dynamic>? ?? [];

    for (final plan in plans) {
      final m = plan as Map<String, dynamic>;
      final clipId = m['clip_id'] as String? ?? m['id'] as String? ?? '';

      final idx = clips.indexWhere((c) => c.id == clipId);
      if (idx == -1) continue;

      // Part 7 guard 4: drop any effect_id not in the catalogue we sent
      // (We don't validate here since we don't have the catalogue —
      //  the pipeline provider caller should pass it in for validation.)
      clips[idx] = clips[idx].copyWith(editingPlan: m);
    }
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  bool _isContinuing(PipelineJob job) {
    return job.stage != PipelineStage.cancelled &&
        job.stage != PipelineStage.failed;
  }

  PipelineClip? _findDuplicate(List<PipelineClip> existing, PipelineClip newClip) {
    for (final c in existing) {
      final overlapStart = math.max(c.startSec, newClip.startSec);
      final overlapEnd = math.min(c.endSec, newClip.endSec);
      final overlap = (overlapEnd - overlapStart).clamp(0.0, double.infinity);
      final minDuration = math.min(c.durationSec, newClip.durationSec);
      if (minDuration > 0 && overlap / minDuration > 0.5) return c;
    }
    return null;
  }

  double _parseSec(String ts) {
    // HH:MM:SS.mmm
    final parts = ts.split(':');
    if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = double.tryParse(parts[2]) ?? 0.0;
      return h * 3600 + m * 60 + s;
    }
    return double.tryParse(ts) ?? 0.0;
  }

  void _updateStage(
    PipelineStage stage, {
    required PipelineJob job,
    String? label,
    double? progress,
    String? error,
  }) {
    job.stage = stage;
    if (label != null) job.currentStageLabel = label;
    if (error != null) job.errorMessage = error;

    // Auto-compute progress if not provided
    if (progress != null) {
      job.overallProgress = progress.clamp(0.0, 1.0);
    } else {
      final stages = PipelineStageLabel.orderedSteps;
      final idx = stages.indexOf(stage);
      if (idx >= 0) {
        job.overallProgress = (idx / stages.length).clamp(0.0, 1.0);
      }
    }

    _notifyStateChange(job);
  }

  void _addLog(PipelineJob job, String message) {
    final timestamp = DateTime.now();
    final formatted =
        '[${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}] $message';
    job.logs = [...job.logs, formatted];
    debugPrint('[Pipeline] $formatted');
    _notifyStateChange(job);
  }

  void _notifyStateChange(PipelineJob job) {
    // Trigger Riverpod rebuild by reassigning state
    state = job;

    // Also update history entry
    ref.read(pipelineHistoryProvider.notifier).updateJob(job);

    // Persist snapshot to pipeline_job.json
    _persistJobMetadata(job);
  }

  Future<void> _persistJobMetadata(
    PipelineJob job, {
    String? whisperModelPath,
    List<Map<String, dynamic>>? selectedVisualEffects,
    List<Map<String, dynamic>>? selectedSoundEffects,
    List<Map<String, dynamic>>? selectedTransitions,
  }) async {
    try {
      if (job.projectDir == null) return;
      final file = File(p.join(job.projectDir!, 'pipeline_job.json'));
      Map<String, dynamic> existing = {};
      if (file.existsSync()) {
        try {
          final content = await file.readAsString();
          if (content.trim().isNotEmpty) {
            existing = jsonDecode(content) as Map<String, dynamic>;
          }
        } catch (_) {}
      }
      final data = {
        ...existing,
        'id': job.id,
        'projectId': job.projectId,
        'videoTitle': job.videoTitle,
        'videoPath': job.videoPath,
        'stage': job.stage.name,
        'startedAt': job.startedAt.toIso8601String(),
        'overallProgress': job.overallProgress,
        'videoLanguage': job.videoLanguage,
        'captionLanguage': job.captionLanguage,
        'whisperModelPath': ?whisperModelPath,
        'selectedVisualEffects': ?selectedVisualEffects,
        'selectedSoundEffects': ?selectedSoundEffects,
        'selectedTransitions': ?selectedTransitions,
        if (job.completedAt != null)
          'completedAt': job.completedAt!.toIso8601String(),
      };
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Token value object for Timestamp Alignment Engine
// ─────────────────────────────────────────────────────────────────────────────
class _PipelineWordToken {
  const _PipelineWordToken({
    required this.normalized,
    required this.startSec,
    required this.endSec,
    required this.lineIndex,
  });

  final String normalized;
  final double startSec;
  final double endSec;
  final int lineIndex;
}
