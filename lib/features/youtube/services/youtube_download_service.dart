import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/services/cookie_settings_service.dart';
import '../../../core/services/ffmpeg_service.dart';
import '../../../core/utils/app_logger.dart';

/// Event emitted during yt-dlp execution.
sealed class YtDlpEvent {
  const YtDlpEvent();
}

class YtDlpLogEvent extends YtDlpEvent {
  const YtDlpLogEvent(this.line);
  final String line;
}

class YtDlpProgressEvent extends YtDlpEvent {
  const YtDlpProgressEvent({
    required this.percent,
    this.speed,
    this.eta,
  });
  final double percent;
  final String? speed;
  final String? eta;
}

class YtDlpMetadataEvent extends YtDlpEvent {
  const YtDlpMetadataEvent({
    required this.title,
    this.duration,
    this.resolution,
  });
  final String title;
  final String? duration;
  final String? resolution;
}

class YtDlpCompletedEvent extends YtDlpEvent {
  const YtDlpCompletedEvent({
    required this.filePath,
    required this.fileSizeBytes,
    this.title,
    this.duration,
    this.resolution,
  });
  final String filePath;
  final int fileSizeBytes;
  final String? title;
  final String? duration;
  final String? resolution;
}

class YtDlpErrorEvent extends YtDlpEvent {
  const YtDlpErrorEvent(this.message);
  final String message;
}

/// Service handling discovery of yt-dlp executable, local config persistence,
/// opening folder in explorer, folder picker, and streaming execution.
class YoutubeDownloadService {
  YoutubeDownloadService._();

  static final YoutubeDownloadService instance = YoutubeDownloadService._();

  String? _cachedYtDlpPath;
  String? _cachedDownloadDir;
  Process? _activeProcess;

  static const String _configFileName = 'youtube_config.json';

  /// Candidate paths for yt-dlp binary on Windows.
  List<String> _getCandidatePaths() {
    final candidates = <String>[];

    // 1. Production bundle adjacent path
    try {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      candidates.add(p.join(exeDir, 'yt-dlp', 'yt-dlp.exe'));
      candidates.add(p.join(exeDir, 'yt-dlp.exe'));
    } catch (_) {}

    // 2. Development project root
    final current = Directory.current.path;
    candidates.add(p.join(current, 'windows', 'yt-dlp', 'yt-dlp.exe'));
    candidates.add(p.join(current, 'bin', 'yt-dlp.exe'));

    // 3. User LocalAppData Python Scripts directory
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null && localAppData.isNotEmpty) {
      final pyBase = p.join(localAppData, 'Programs', 'Python');
      final pyDir = Directory(pyBase);
      if (pyDir.existsSync()) {
        try {
          for (final versionDir in pyDir.listSync()) {
            if (versionDir is Directory) {
              final scriptExe = p.join(versionDir.path, 'Scripts', 'yt-dlp.exe');
              if (File(scriptExe).existsSync()) {
                candidates.add(scriptExe);
              }
            }
          }
        } catch (_) {}
      }

      // AppData/Local/Programs/yt-dlp/yt-dlp.exe
      final ytProgDir = p.join(localAppData, 'Programs', 'yt-dlp', 'yt-dlp.exe');
      if (File(ytProgDir).existsSync()) {
        candidates.add(ytProgDir);
      }
    }

    // 4. Default system command
    candidates.add('yt-dlp.exe');
    candidates.add('yt-dlp');

    return candidates;
  }

  /// Locates and returns absolute path or command name to yt-dlp executable.
  Future<String> getYtDlpPath() async {
    if (_cachedYtDlpPath != null) return _cachedYtDlpPath!;

    // First try candidate files that physically exist
    for (final candidate in _getCandidatePaths()) {
      if (candidate.contains(Platform.pathSeparator) &&
          File(candidate).existsSync()) {
        _cachedYtDlpPath = p.canonicalize(candidate);
        AppLog.i('Found yt-dlp at: $_cachedYtDlpPath');
        return _cachedYtDlpPath!;
      }
    }

    // Try `where.exe yt-dlp` on Windows
    if (!kIsWeb && Platform.isWindows) {
      try {
        final result = await Process.run('where.exe', ['yt-dlp']);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().trim().split(RegExp(r'[\r\n]+'));
          if (lines.isNotEmpty && lines.first.trim().isNotEmpty) {
            _cachedYtDlpPath = lines.first.trim();
            AppLog.i('Found yt-dlp via where.exe at: $_cachedYtDlpPath');
            return _cachedYtDlpPath!;
          }
        }
      } catch (_) {}
    }

    // Fallback to system command
    _cachedYtDlpPath = 'yt-dlp';
    return _cachedYtDlpPath!;
  }

  /// Resolves the storage config file path.
  Future<File?> _getConfigFile() async {
    if (kIsWeb) return null;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return File(p.join(Directory.systemTemp.path, _configFileName));
    }
    try {
      final dir = await getApplicationSupportDirectory()
          .timeout(const Duration(milliseconds: 500));
      return File(p.join(dir.path, _configFileName));
    } catch (_) {
      return File(p.join(Directory.current.path, _configFileName));
    }
  }

  /// Gets the currently configured download directory (with persistence).
  Future<String> getDownloadDirectory() async {
    if (_cachedDownloadDir != null && _cachedDownloadDir!.isNotEmpty) {
      return _cachedDownloadDir!;
    }

    // Read saved configuration if exists
    try {
      final file = await _getConfigFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final saved = data['download_dir'] as String?;
        if (saved != null && saved.isNotEmpty) {
          _cachedDownloadDir = saved;
          final dir = Directory(saved);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          return saved;
        }
      }
    } catch (e) {
      AppLog.w('Failed to load saved yt-dlp download directory: $e');
    }

    // Default directory resolution: Downloads/ClipIt_Downloads
    String defaultPath;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      defaultPath = p.join(Directory.systemTemp.path, 'ClipIt_Downloads');
    } else {
      try {
        final downloadsDir = await getDownloadsDirectory()
            .timeout(const Duration(milliseconds: 500));
        if (downloadsDir != null) {
          defaultPath = p.join(downloadsDir.path, 'ClipIt_Downloads');
        } else {
          final userProfile = Platform.environment['USERPROFILE'] ??
              Platform.environment['HOME'] ??
              Directory.current.path;
          defaultPath = p.join(userProfile, 'Downloads', 'ClipIt_Downloads');
        }
      } catch (_) {
        final userProfile = Platform.environment['USERPROFILE'] ??
            Platform.environment['HOME'] ??
            Directory.current.path;
        defaultPath = p.join(userProfile, 'Downloads', 'ClipIt_Downloads');
      }
    }

    try {
      final dir = Directory(defaultPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } catch (_) {}

    _cachedDownloadDir = defaultPath;
    return defaultPath;
  }

  /// Saves the new download directory to local persistent configuration.
  Future<void> saveDownloadDirectory(String path) async {
    _cachedDownloadDir = path;
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = await _getConfigFile();
      if (file != null) {
        if (!await file.parent.exists()) {
          await file.parent.create(recursive: true);
        }
        await file.writeAsString(jsonEncode({'download_dir': path}));
      }
    } catch (e) {
      AppLog.e('Failed to save download directory: $e');
    }
  }

  /// Opens the current download directory in the native Windows Explorer.
  Future<bool> openFolder(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      if (Platform.isWindows) {
        await Process.run('explorer.exe', [path]);
        return true;
      } else if (Platform.isMacOS) {
        await Process.run('open', [path]);
        return true;
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
        return true;
      }
    } catch (e) {
      AppLog.e('Failed to open directory in file explorer: $e');
    }
    return false;
  }

  /// Plays / opens a downloaded video file with the OS default media player.
  Future<bool> openFile(String filePath) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd.exe', ['/c', 'start', '', filePath]);
        return true;
      } else if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
        return true;
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [filePath]);
        return true;
      }
    } catch (e) {
      AppLog.e('Failed to open file: $e');
    }
    return false;
  }

  /// Reveals a video file selected inside the native file manager (Windows Explorer).
  Future<bool> revealFile(String filePath) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', ['/select,', filePath]);
        return true;
      } else {
        return await openFolder(p.dirname(filePath));
      }
    } catch (e) {
      AppLog.e('Failed to reveal file: $e');
    }
    return false;
  }

  /// Lets the user pick a new download directory with native folder picker.
  Future<String?> pickDownloadDirectory() async {
    try {
      final current = await getDownloadDirectory();
      final selectedPath = await FilePickerPlatform.instance.getDirectoryPath(
        dialogTitle: 'Select YouTube Download Location',
        initialDirectory: current,
      );
      if (selectedPath != null && selectedPath.isNotEmpty) {
        await saveDownloadDirectory(selectedPath);
        return selectedPath;
      }
    } catch (e) {
      AppLog.e('Error picking directory: $e');
    }
    return null;
  }

  /// Cancels any active yt-dlp download process.
  void cancelDownload() {
    if (_activeProcess != null) {
      try {
        _activeProcess!.kill(ProcessSignal.sigkill);
      } catch (_) {}
      _activeProcess = null;
    }
  }

  /// Executes yt-dlp to download the video, streaming output lines and emitting
  /// structured events for progress, logs, and final file metadata.
  Stream<YtDlpEvent> downloadVideo({
    required String url,
    required String outputDir,
  }) {
    final controller = StreamController<YtDlpEvent>();

    () async {
      try {
        cancelDownload();

        final ytDlpExe = await getYtDlpPath();
        final outputTemplate = p.join(outputDir, '%(title)s.%(ext)s');

        controller.add(YtDlpLogEvent('[clipit] Initializing yt-dlp engine from: $ytDlpExe'));
        controller.add(YtDlpLogEvent('[clipit] Target directory: $outputDir'));
        controller.add(YtDlpLogEvent('[clipit] Fetching stream and metadata for: $url'));

        final args = <String>[
          '--newline',
          '--no-warnings',
          '--no-mtime',
          '--no-update',
        ];

        // Check if Node.js runtime is available on Windows for solving JS challenges
        try {
          final nodeCheck = await Process.run('where.exe', ['node']);
          if (nodeCheck.exitCode == 0) {
            args.addAll(['--js-runtimes', 'node']);
          }
        } catch (_) {}

        // Check if FFmpeg is available and pass its folder location to yt-dlp
        try {
          final ffmpegPath = await FfmpegService.instance.getFfmpegPath();
          if (ffmpegPath != null && ffmpegPath.isNotEmpty && File(ffmpegPath).existsSync()) {
            args.addAll(['--ffmpeg-location', p.dirname(ffmpegPath)]);
          }
        } catch (_) {}

        // Check if platform authentication cookies are configured (Instagram / YouTube)
        final lowerUrl = url.toLowerCase();
        final isInstagram = lowerUrl.contains('instagram.com') || lowerUrl.contains('instagr.am');
        final isYouTube = lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be');

        final cookiePlatform = isInstagram
            ? CookiePlatform.instagram
            : (isYouTube ? CookiePlatform.youtube : CookiePlatform.general);

        try {
          final cookiePath = await CookieSettingsService.instance.getCookieFilePathFor(cookiePlatform);
          if (cookiePath != null && File(cookiePath).existsSync()) {
            args.addAll(['--cookies', cookiePath]);
            controller.add(YtDlpLogEvent(
              '[clipit] Using configured ${isInstagram ? 'Instagram' : (isYouTube ? 'YouTube' : 'site')} cookies for authentication',
            ));
          }
        } catch (e) {
          AppLog.w('Failed to attach cookie file: $e');
        }

        args.addAll([
          '-o',
          outputTemplate,
          '--print',
          'after_move:%(filepath)s',
          '--print',
          'meta:%(title)s|||%(duration_string)s|||%(resolution)s',
          url,
        ]);

        Process process;
        try {
          final isDirectExe = ytDlpExe.toLowerCase().endsWith('.exe') || File(ytDlpExe).existsSync();
          process = await Process.start(
            ytDlpExe,
            args,
            runInShell: !isDirectExe && Platform.isWindows,
          );
          _activeProcess = process;
        } catch (e) {
          controller.add(YtDlpLogEvent('[clipit] ERROR: Could not start yt-dlp process: $e'));
          controller.add(YtDlpErrorEvent('Failed to launch yt-dlp: $e'));
          await controller.close();
          return;
        }

        String? extractedTitle;
        String? extractedDuration;
        String? extractedResolution;
        String? finalizedFilePath;
        final downloadedFilesFromLog = <String>[];
        bool isAuthOrCookieError = false;

        final progressRegex = RegExp(r'\[download\]\s+([\d\.]+)%\s+of\s+([^\s]+)\s+at\s+([^\s]+)\s+ETA\s+([^\s]+)');
        final destinationRegex = RegExp(r'\[download\]\s+Destination:\s+(.*)');
        final mergerRegex = RegExp(r'\[Merger\]\s+Merging\s+formats\s+into\s+"(.*)"');

        void processLine(String line) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) return;

          // Detect login / authentication / rate limit issues
          final lower = trimmed.toLowerCase();
          if (lower.contains('rate-limit reached') ||
              lower.contains('login required') ||
              lower.contains('requested content is not available') ||
              lower.contains('sign in to confirm') ||
              lower.contains('use --cookies-from-browser or --cookies')) {
            isAuthOrCookieError = true;
            controller.add(YtDlpLogEvent(
              '[clipit] ⚠️ AUTHENTICATION REQUIRED: This video requires login credentials.',
            ));
            controller.add(YtDlpLogEvent(
              '[clipit] 👉 Go to Settings -> "Downloader & Cookies" and paste your cookies.',
            ));
          }

          // Check metadata print line
          if (trimmed.startsWith('meta:')) {
            final payload = trimmed.substring(5);
            final parts = payload.split('|||');
            if (parts.isNotEmpty) extractedTitle = parts[0];
            if (parts.length > 1) extractedDuration = parts[1];
            if (parts.length > 2) extractedResolution = parts[2];

            controller.add(YtDlpMetadataEvent(
              title: extractedTitle ?? 'YouTube Video',
              duration: extractedDuration,
              resolution: extractedResolution,
            ));
            controller.add(YtDlpLogEvent(
              '[clipit] Video: "${extractedTitle ?? ''}" ($extractedDuration, $extractedResolution)',
            ));
            return;
          }

          // Check after_move final path
          if (trimmed.startsWith('after_move:')) {
            final path = trimmed.substring(11).trim();
            finalizedFilePath = path;
            controller.add(YtDlpLogEvent('[clipit] Final saved file: $path'));
            return;
          }

          // Check progress line
          final progMatch = progressRegex.firstMatch(trimmed);
          if (progMatch != null) {
            final pct = double.tryParse(progMatch.group(1) ?? '0') ?? 0.0;
            final speed = progMatch.group(3);
            final eta = progMatch.group(4);
            controller.add(YtDlpProgressEvent(
              percent: pct,
              speed: speed,
              eta: eta,
            ));
          }

          // Destination line
          final destMatch = destinationRegex.firstMatch(trimmed);
          if (destMatch != null) {
            downloadedFilesFromLog.add(destMatch.group(1)!.trim());
          }

          // Merger line
          final mergerMatch = mergerRegex.firstMatch(trimmed);
          if (mergerMatch != null) {
            downloadedFilesFromLog.add(mergerMatch.group(1)!.trim());
          }

          controller.add(YtDlpLogEvent(trimmed));
        }

        final stdoutSub = process.stdout
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter())
            .listen(processLine);

        final stderrSub = process.stderr
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter())
            .listen(processLine);

        final exitCode = await process.exitCode;
        await stdoutSub.cancel();
        await stderrSub.cancel();
        _activeProcess = null;

        if (exitCode != 0) {
          if (isAuthOrCookieError) {
            controller.add(YtDlpLogEvent(
              '[clipit] 💡 TIP: Copy your cookies with the free "Cookie-Editor" extension and paste them in Settings -> Downloader & Cookies.',
            ));
            controller.add(YtDlpErrorEvent(
              'Authentication required: Go to Settings -> Downloader & Cookies to paste your cookies.',
            ));
          } else {
            controller.add(YtDlpLogEvent('[clipit] Process completed with error exit code: $exitCode'));
            controller.add(YtDlpErrorEvent('yt-dlp exited with error code $exitCode'));
          }
          await controller.close();
          return;
        }

        // Determine final downloaded file path
        String? resolvedPath = finalizedFilePath;
        if (resolvedPath == null || !File(resolvedPath).existsSync()) {
          if (downloadedFilesFromLog.isNotEmpty) {
            for (final cand in downloadedFilesFromLog.reversed) {
              if (File(cand).existsSync()) {
                resolvedPath = cand;
                break;
              }
            }
          }
        }

        // If still null, search target directory for latest modified video file
        if (resolvedPath == null || !File(resolvedPath).existsSync()) {
          try {
            final dir = Directory(outputDir);
            if (dir.existsSync()) {
              final files = dir.listSync().whereType<File>().toList();
              files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
              for (final f in files) {
                final ext = p.extension(f.path).toLowerCase();
                if (['.mp4', '.mkv', '.webm', '.mov'].contains(ext)) {
                  resolvedPath = f.path;
                  break;
                }
              }
            }
          } catch (_) {}
        }

        int fileSize = 0;
        if (resolvedPath != null && File(resolvedPath).existsSync()) {
          fileSize = File(resolvedPath).lengthSync();
        }

        final finalTitle = extractedTitle ??
            (resolvedPath != null ? p.basenameWithoutExtension(resolvedPath) : 'YouTube Video');

        controller.add(const YtDlpProgressEvent(percent: 100.0));
        controller.add(YtDlpCompletedEvent(
          filePath: resolvedPath ?? '',
          fileSizeBytes: fileSize,
          title: finalTitle,
          duration: extractedDuration ?? 'HD',
          resolution: extractedResolution ?? '1080p',
        ));
        controller.add(const YtDlpLogEvent('[clipit] SUCCESS! Video download complete.'));
      } catch (err) {
        controller.add(YtDlpErrorEvent(err.toString()));
      } finally {
        await controller.close();
      }
    }();

    return controller.stream;
  }
}
