import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_logger.dart';

/// Central resolver for directory paths across ClipIt.
///
/// Ensures consistent resolution whether running from:
/// - `flutter run` / development root (`c:\Users\Dell\Desktop\CLIP-IT`)
/// - Windows Release build (`build\windows\x64\runner\Release\clipit.exe`)
/// - Any relative subfolder
class AppPathResolver {
  AppPathResolver._();

  static Directory? _cachedProjectRoot;

  /// Resolves the root project directory (where pubspec.yaml lives).
  static Directory get projectRoot {
    if (_cachedProjectRoot != null && _cachedProjectRoot!.existsSync()) {
      return _cachedProjectRoot!;
    }

    // 1. Check Directory.current
    final current = Directory.current;
    if (File(p.join(current.path, 'pubspec.yaml')).existsSync()) {
      _cachedProjectRoot = current;
      return current;
    }

    // 2. Traverse parent directories from Platform.resolvedExecutable
    try {
      var dir = File(Platform.resolvedExecutable).parent;
      for (int i = 0; i < 7; i++) {
        if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
          _cachedProjectRoot = dir;
          return dir;
        }
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    } catch (_) {}

    // 3. Known project workspace location
    final knownRoot = Directory(r'C:\Users\Dell\Desktop\CLIP-IT');
    if (knownRoot.existsSync()) {
      _cachedProjectRoot = knownRoot;
      return knownRoot;
    }

    // Fallback to Directory.current
    _cachedProjectRoot = current;
    return current;
  }

  /// Returns the base directory for 'live process' files.
  /// Always points to `<projectRoot>/live process`.
  static Directory get liveProcessDir {
    return Directory(p.join(projectRoot.path, 'live process'));
  }

  /// Finds or creates the next sequential project folder:
  /// e.g. 'project 1', 'project 2', 'project 3', etc.
  static Directory getNextProjectDir() {
    final base = liveProcessDir;
    if (!base.existsSync()) {
      base.createSync(recursive: true);
    }

    int nextIndex = 1;
    while (true) {
      final candidate = Directory(p.join(base.path, 'project $nextIndex'));
      if (!candidate.existsSync()) {
        return candidate;
      }
      final audioDir = Directory(p.join(candidate.path, 'audio'));
      final transcriptionDir = Directory(p.join(candidate.path, 'transcription'));
      final hasAudioFiles = audioDir.existsSync() && audioDir.listSync().isNotEmpty;
      final hasTranscriptFiles = transcriptionDir.existsSync() && transcriptionDir.listSync().isNotEmpty;
      if (!hasAudioFiles && !hasTranscriptFiles) {
        return candidate;
      }
      nextIndex++;
    }
  }

  /// Returns the project directory for the given project name/number or resolves the latest/next.
  static Directory getProjectDir([String? projectName]) {
    if (projectName != null && projectName.isNotEmpty) {
      return Directory(p.join(liveProcessDir.path, projectName));
    }
    return getNextProjectDir();
  }

  /// Returns the `<projectRoot>/live process/<projectName>/audio` directory.
  static Directory getLiveProcessAudioDir([String? projectName]) {
    final projDir = projectName != null ? getProjectDir(projectName) : getNextProjectDir();
    return Directory(p.join(projDir.path, 'audio'));
  }

  /// Returns the `<projectRoot>/live process/<projectName>/transcription` directory.
  static Directory getLiveProcessTranscriptionDir([String? projectName]) {
    final projDir = projectName != null ? getProjectDir(projectName) : getNextProjectDir();
    return Directory(p.join(projDir.path, 'transcription'));
  }

  /// Returns the `<projectRoot>/live process/<projectName>/clips` directory.
  static Directory getLiveProcessClipsDir([String? projectName]) {
    final projDir = projectName != null ? getProjectDir(projectName) : getNextProjectDir();
    final clips = Directory(p.join(projDir.path, 'clips'));
    if (!clips.existsSync()) {
      clips.createSync(recursive: true);
    }
    return clips;
  }

  /// Returns the `<projectRoot>/live process/project 1/audio` directory (default legacy accessor).
  static Directory get liveProcessAudioDir {
    return getLiveProcessAudioDir('project 1');
  }

  /// Returns the `<projectRoot>/live process/project 1/transcription` directory (default legacy accessor).
  static Directory get liveProcessTranscriptionDir {
    return getLiveProcessTranscriptionDir('project 1');
  }

  /// Resolves the absolute path to `tool/transcribe_hinglish.py`.
  static String? resolveTranscribeScript() {
    final candidates = <String>[
      p.join(projectRoot.path, 'tool', 'transcribe_hinglish.py'),
      p.join(Directory.current.path, 'tool', 'transcribe_hinglish.py'),
      r'C:\Users\Dell\Desktop\CLIP-IT\tool\transcribe_hinglish.py',
    ];

    try {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      candidates.insert(1, p.join(exeDir, 'tool', 'transcribe_hinglish.py'));
      candidates.insert(2, p.join(exeDir, 'transcribe_hinglish.py'));
    } catch (_) {}

    for (final cand in candidates) {
      try {
        if (File(cand).existsSync()) {
          final canon = p.canonicalize(cand);
          AppLog.i('[AppPathResolver] Found transcribe script at: $canon');
          return canon;
        }
      } catch (_) {}
    }

    AppLog.w('[AppPathResolver] transcribe_hinglish.py not found in candidates: $candidates');
    return null;
  }

  /// Resolves the absolute path to the Whisper model directory or file.
  static String resolveModelDir(String modelRelativeOrAbs) {
    if (Directory(modelRelativeOrAbs).existsSync() ||
        File(modelRelativeOrAbs).existsSync()) {
      return p.canonicalize(modelRelativeOrAbs);
    }

    final base = p.basename(modelRelativeOrAbs);
    final candidates = <String>[
      p.join(projectRoot.path, modelRelativeOrAbs),
      p.join(projectRoot.path, 'models', base),
      p.join(Directory.current.path, modelRelativeOrAbs),
      p.join(Directory.current.path, 'models', base),
      p.join(r'C:\Users\Dell\Desktop\CLIP-IT', modelRelativeOrAbs),
      p.join(r'C:\Users\Dell\Desktop\CLIP-IT\models', base),
    ];

    try {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      candidates.insert(1, p.join(exeDir, modelRelativeOrAbs));
      candidates.insert(2, p.join(exeDir, 'models', base));
    } catch (_) {}

    for (final cand in candidates) {
      try {
        if (Directory(cand).existsSync() || File(cand).existsSync()) {
          final canon = p.canonicalize(cand);
          AppLog.i('[AppPathResolver] Resolved model path: $canon');
          return canon;
        }
      } catch (_) {}
    }

    return modelRelativeOrAbs;
  }

  /// Mirrors any files in `<projectRoot>/live process` to `<currentDir>/live process`
  /// if running outside the project root (e.g. from the Release directory).
  static Future<void> syncLiveProcessToRelease() async {
    final rootLive = liveProcessDir;
    final currentLive = Directory(p.join(Directory.current.path, 'live process'));

    if (p.canonicalize(rootLive.path) == p.canonicalize(currentLive.path)) {
      return;
    }

    if (!rootLive.existsSync()) return;

    try {
      await _copyDirectory(rootLive, currentLive);
    } catch (e) {
      AppLog.w('[AppPathResolver] Could not sync live process to Release: $e');
    }
  }

  static Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!destination.existsSync()) {
      await destination.create(recursive: true);
    }

    await for (final entity in source.list(recursive: false)) {
      final newPath = p.join(destination.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      } else if (entity is File) {
        try {
          await entity.copy(newPath);
        } catch (_) {}
      }
    }
  }
}
