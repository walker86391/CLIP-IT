import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;

import '../../../core/services/ffmpeg_service.dart';
import '../../../core/services/model_manager.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/app_path_resolver.dart';
import '../models/resumable_transcription_job.dart';

/// Scans the `live process` directory to locate any interrupted Whisper
/// transcription sessions from a prior app execution.
class ResumableTranscriptionScanner {
  ResumableTranscriptionScanner._();

  /// Scans `live process/` directories in reverse numerical order and returns
  /// the most relevant interrupted transcription job, or `null` if none exist.
  static Future<ResumableTranscriptionJob?> findInterruptedTranscriptionJob() async {
    final liveProcessDir = AppPathResolver.liveProcessDir;
    if (!liveProcessDir.existsSync()) {
      return null;
    }

    try {
      final entities = liveProcessDir.listSync();
      final projectDirs = <Directory>[];

      for (final entity in entities) {
        if (entity is Directory) {
          final baseName = p.basename(entity.path).toLowerCase();
          if (baseName.startsWith('project')) {
            projectDirs.add(entity);
          }
        }
      }

      // Sort in descending order: project 2, project 1, etc.
      projectDirs.sort((a, b) {
        final aNum = _extractProjectNumber(p.basename(a.path));
        final bNum = _extractProjectNumber(p.basename(b.path));
        return bNum.compareTo(aNum);
      });

      for (final projectDir in projectDirs) {
        final candidate = await _inspectProjectDir(projectDir);
        if (candidate != null) {
          return candidate;
        }
      }
    } catch (e, st) {
      AppLog.e('[ResumableScanner] Error scanning live process directory: $e\n$st');
    }

    return null;
  }

  static int _extractProjectNumber(String name) {
    final match = RegExp(r'\d+').firstMatch(name);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 0;
    }
    return 0;
  }

  /// Inspects a single project directory to determine if it holds an interrupted
  /// transcription.
  static Future<ResumableTranscriptionJob?> _inspectProjectDir(
      Directory projectDir) async {
    final transcriptionDir =
        Directory(p.join(projectDir.path, 'transcription'));
    final transcriptJsonFile =
        File(p.join(transcriptionDir.path, 'transcript.json'));
    final transcriptTxtFile =
        File(p.join(transcriptionDir.path, 'transcript.txt'));

    // Check if transcript file exists
    if (!transcriptJsonFile.existsSync()) {
      return null;
    }

    // Check if clips were ALREADY completed for this project
    final clipsDir = Directory(p.join(projectDir.path, 'clips'));
    if (clipsDir.existsSync()) {
      final mp4Clips = clipsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.mp4'))
          .toList();
      if (mp4Clips.isNotEmpty) {
        // Clips already generated and finalized - not an interrupted transcription
        return null;
      }
    }

    // Check audio files
    final audioDir = Directory(p.join(projectDir.path, 'audio'));
    if (!audioDir.existsSync()) {
      return null;
    }

    final audioFiles = audioDir.listSync().whereType<File>().toList();
    final chunkFiles = audioFiles
        .where((f) =>
            p.basename(f.path).startsWith('chunk_') &&
            f.path.toLowerCase().endsWith('.mp3'))
        .map((f) => f.path)
        .toList()
      ..sort();

    final mainAudioMp3 = File(p.join(audioDir.path, 'audio.mp3'));
    if (chunkFiles.isEmpty && !mainAudioMp3.existsSync()) {
      return null;
    }

    // Parse transcript JSON
    Map<String, dynamic> transcriptData = {};
    try {
      final content = await transcriptJsonFile.readAsString();
      if (content.trim().isNotEmpty) {
        transcriptData = jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      AppLog.w('[ResumableScanner] Failed to read transcript.json in ${projectDir.path}: $e');
      return null;
    }

    final rawWords = (transcriptData['words'] as List<dynamic>?) ?? [];
    final rawPhrases = (transcriptData['phrases'] as List<dynamic>?) ?? [];

    final totalWords = (transcriptData['total_words'] as num?)?.toInt() ??
        rawWords.length;
    final totalPhrases = (transcriptData['total_phrases'] as num?)?.toInt() ??
        rawPhrases.length;

    // Determine furthest timestamp
    double lastTranscribedSec = 0.0;
    for (final w in rawWords) {
      if (w is Map) {
        final end = (w['end'] as num?)?.toDouble() ?? 0.0;
        if (end > lastTranscribedSec) lastTranscribedSec = end;
      }
    }
    for (final pItem in rawPhrases) {
      if (pItem is Map) {
        final end = (pItem['end'] as num?)?.toDouble() ?? 0.0;
        if (end > lastTranscribedSec) lastTranscribedSec = end;
      }
    }

    // Measure total audio duration
    double totalAudioSec = 0.0;
    if (mainAudioMp3.existsSync()) {
      try {
        final measured =
            await FfmpegService.instance.getVideoDurationSec(mainAudioMp3.path);
        if (measured != null && measured > 0) {
          totalAudioSec = measured;
        }
      } catch (_) {}
    }

    if (totalAudioSec <= 0.0) {
      // Estimate by summing chunks or measuring chunk 1 + chunk 2
      for (final chunk in chunkFiles) {
        try {
          final chunkDur =
              await FfmpegService.instance.getVideoDurationSec(chunk);
          if (chunkDur != null && chunkDur > 0) {
            totalAudioSec += chunkDur;
          }
        } catch (_) {}
      }
    }

    if (totalAudioSec <= 0.0 && mainAudioMp3.existsSync()) {
      // Approximate fallback from MP3 file size @ 192kbps (24 KB/s)
      final sizeBytes = mainAudioMp3.lengthSync();
      totalAudioSec = sizeBytes / 24000.0;
    }

    if (totalAudioSec <= 0.0) {
      totalAudioSec = math.max(lastTranscribedSec, 60.0);
    }

    // Compute progress
    final double progressPercent = totalAudioSec > 0
        ? ((lastTranscribedSec / totalAudioSec) * 100.0).clamp(0.0, 99.0)
        : 0.0;

    // Check optional pipeline_job.json saved previously
    final jobJsonFile = File(p.join(projectDir.path, 'pipeline_job.json'));
    Map<String, dynamic> jobMeta = {};
    if (jobJsonFile.existsSync()) {
      try {
        final metaContent = await jobJsonFile.readAsString();
        jobMeta = jsonDecode(metaContent) as Map<String, dynamic>;
        // If explicitly completed, ignore
        if (jobMeta['stage'] == 'completed') {
          return null;
        }
      } catch (_) {}
    }

    final projectName = p.basename(projectDir.path);
    final videoTitle = jobMeta['videoTitle'] as String? ??
        (projectName.toUpperCase());
    final videoPath = jobMeta['videoPath'] as String? ??
        (mainAudioMp3.existsSync() ? mainAudioMp3.path : '');

    String activeModelPath = 'models/Whisper-Hindi2Hinglish-Prime';
    try {
      activeModelPath = await ClipItModelManager.instance.getActiveModelPath();
    } catch (_) {}
    final whisperModelPath =
        jobMeta['whisperModelPath'] as String? ?? activeModelPath;

    final videoLanguage = (jobMeta['videoLanguage'] as String?) ??
        (transcriptData['video_language'] as String?) ??
        'auto';
    final captionLanguage = (jobMeta['captionLanguage'] as String?) ??
        (transcriptData['caption_language'] as String?) ??
        'hinglish';

    final totalChunks = chunkFiles.isNotEmpty ? chunkFiles.length : 1;

    final lastModified = transcriptJsonFile.lastModifiedSync();

    // Verify this is genuinely an interrupted transcription:
    // Either we have words already transcribed, or chunks exist waiting to be transcribed.
    return ResumableTranscriptionJob(
      projectDir: projectDir.path,
      projectName: projectName,
      videoTitle: videoTitle,
      videoPath: videoPath,
      whisperModelPath: whisperModelPath,
      videoLanguage: videoLanguage,
      captionLanguage: captionLanguage,
      wordsTranscribed: totalWords,
      phrasesTranscribed: totalPhrases,
      lastTranscribedSec: lastTranscribedSec,
      totalAudioDurationSec: totalAudioSec,
      progressPercent: progressPercent,
      totalChunks: totalChunks,
      chunkFiles: chunkFiles.isNotEmpty
          ? chunkFiles
          : [if (mainAudioMp3.existsSync()) mainAudioMp3.path],
      outputJsonPath: transcriptJsonFile.path,
      outputTxtPath: transcriptTxtFile.path,
      lastModified: lastModified,
      selectedVisualEffects:
          (jobMeta['selectedVisualEffects'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              const [],
      selectedSoundEffects:
          (jobMeta['selectedSoundEffects'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              const [],
      selectedTransitions:
          (jobMeta['selectedTransitions'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              const [],
    );
  }

  /// Safely deletes an interrupted project folder from disk when the user
  /// clicks "Discard".
  static Future<void> discardProject(String projectDirPath) async {
    try {
      final dir = Directory(projectDirPath);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
        AppLog.i('[ResumableScanner] Discarded project directory: $projectDirPath');
      }
    } catch (e) {
      AppLog.e('[ResumableScanner] Failed to delete project directory: $e');
    }
  }
}
