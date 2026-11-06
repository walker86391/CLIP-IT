import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../utils/app_logger.dart';

/// Service responsible for locating, verifying, and interfacing with
/// bundled or system-installed FFmpeg and FFprobe binaries.
///
/// Discovery precedence:
/// 1. Application bundle directory: adjacent `ffmpeg/ffmpeg.exe`
/// 2. Workspace root development path: `windows/ffmpeg/ffmpeg.exe`
/// 3. Known WinGet / Local AppData installation paths
/// 4. System PATH environment variable
class FfmpegService {
  FfmpegService._();

  static final FfmpegService instance = FfmpegService._();

  String? _cachedFfmpegPath;
  String? _cachedFfprobePath;
  String? _cachedVersion;
  Set<String>? _cachedFilters;
  Set<String>? _cachedCodecs;
  FfmpegDiagnosticReport? _cachedReport;

  /// Candidate relative paths and environment locations for FFmpeg.
  List<String> _getCandidateFfmpegPaths() {
    final candidates = <String>[];

    // 1. Production bundle adjacent path (e.g. Release/ffmpeg/ffmpeg.exe)
    try {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      candidates.add(p.join(exeDir, 'ffmpeg', 'ffmpeg.exe'));
      candidates.add(p.join(exeDir, 'ffmpeg.exe'));
      candidates.add(p.join(exeDir, 'bin', 'ffmpeg.exe'));
    } catch (_) {}

    // 2. Development project tree relative to current directory
    final current = Directory.current.path;
    candidates.add(p.join(current, 'windows', 'ffmpeg', 'ffmpeg.exe'));
    candidates.add(p.join(current, 'assets', 'bin', 'ffmpeg.exe'));
    candidates.add(p.join(current, 'bin', 'ffmpeg.exe'));

    // 3. User local AppData WinGet package location
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null && localAppData.isNotEmpty) {
      final wingetBase = p.join(
        localAppData,
        'Microsoft',
        'WinGet',
        'Packages',
      );
      final wingetDir = Directory(wingetBase);
      if (wingetDir.existsSync()) {
        try {
          final entries = wingetDir.listSync();
          for (final entry in entries) {
            if (entry.path.toLowerCase().contains('ffmpeg')) {
              // Look recursively inside bin
              final binPath = p.join(entry.path, 'bin', 'ffmpeg.exe');
              if (File(binPath).existsSync()) {
                candidates.add(binPath);
              }
              // Check subdirectories
              if (entry is Directory) {
                for (final sub in entry.listSync()) {
                  final nestedBin = p.join(sub.path, 'bin', 'ffmpeg.exe');
                  if (File(nestedBin).existsSync()) {
                    candidates.add(nestedBin);
                  }
                }
              }
            }
          }
        } catch (_) {}
      }
    }

    // 4. Default fallback binary name for system PATH lookup
    candidates.add('ffmpeg.exe');
    candidates.add('ffmpeg');

    return candidates;
  }

  /// Candidate relative paths and environment locations for FFprobe.
  List<String> _getCandidateFfprobePaths() {
    final candidates = <String>[];

    try {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      candidates.add(p.join(exeDir, 'ffmpeg', 'ffprobe.exe'));
      candidates.add(p.join(exeDir, 'ffprobe.exe'));
      candidates.add(p.join(exeDir, 'bin', 'ffprobe.exe'));
    } catch (_) {}

    final current = Directory.current.path;
    candidates.add(p.join(current, 'windows', 'ffmpeg', 'ffprobe.exe'));
    candidates.add(p.join(current, 'assets', 'bin', 'ffprobe.exe'));
    candidates.add(p.join(current, 'bin', 'ffprobe.exe'));

    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null && localAppData.isNotEmpty) {
      final wingetBase = p.join(
        localAppData,
        'Microsoft',
        'WinGet',
        'Packages',
      );
      final wingetDir = Directory(wingetBase);
      if (wingetDir.existsSync()) {
        try {
          final entries = wingetDir.listSync();
          for (final entry in entries) {
            if (entry.path.toLowerCase().contains('ffmpeg')) {
              final binPath = p.join(entry.path, 'bin', 'ffprobe.exe');
              if (File(binPath).existsSync()) {
                candidates.add(binPath);
              }
              if (entry is Directory) {
                for (final sub in entry.listSync()) {
                  final nestedBin = p.join(sub.path, 'bin', 'ffprobe.exe');
                  if (File(nestedBin).existsSync()) {
                    candidates.add(nestedBin);
                  }
                }
              }
            }
          }
        } catch (_) {}
      }
    }

    candidates.add('ffprobe.exe');
    candidates.add('ffprobe');

    return candidates;
  }

  /// Discovers and returns the absolute path to the active FFmpeg binary.
  Future<String?> getFfmpegPath() async {
    if (_cachedFfmpegPath != null) return _cachedFfmpegPath;

    for (final candidate in _getCandidateFfmpegPaths()) {
      try {
        if (File(candidate).existsSync()) {
          _cachedFfmpegPath = p.canonicalize(candidate);
          AppLog.i('Found bundled/installed FFmpeg at: $_cachedFfmpegPath');
          return _cachedFfmpegPath;
        }
      } catch (_) {}
    }

    // Try executing directly via PATH
    try {
      final res = await Process.run('ffmpeg', ['-version']);
      if (res.exitCode == 0) {
        _cachedFfmpegPath = 'ffmpeg';
        AppLog.i('Found FFmpeg on system PATH');
        return _cachedFfmpegPath;
      }
    } catch (_) {}

    AppLog.w('FFmpeg binary could not be located in bundled or system paths');
    return null;
  }

  /// Discovers and returns the absolute path to the active FFprobe binary.
  Future<String?> getFfprobePath() async {
    if (_cachedFfprobePath != null) return _cachedFfprobePath;

    for (final candidate in _getCandidateFfprobePaths()) {
      try {
        if (File(candidate).existsSync()) {
          _cachedFfprobePath = p.canonicalize(candidate);
          AppLog.i('Found bundled/installed FFprobe at: $_cachedFfprobePath');
          return _cachedFfprobePath;
        }
      } catch (_) {}
    }

    try {
      final res = await Process.run('ffprobe', ['-version']);
      if (res.exitCode == 0) {
        _cachedFfprobePath = 'ffprobe';
        AppLog.i('Found FFprobe on system PATH');
        return _cachedFfprobePath;
      }
    } catch (_) {}

    return null;
  }

  /// Checks whether FFmpeg is available and runnable.
  Future<bool> isFfmpegAvailable() async {
    final path = await getFfmpegPath();
    if (path == null) return false;

    try {
      final res = await Process.run(path, ['-version']);
      return res.exitCode == 0;
    } catch (e) {
      debugPrint('Error testing FFmpeg execution: $e');
      return false;
    }
  }

  /// Queries the FFmpeg version string.
  Future<String?> getFfmpegVersion() async {
    if (_cachedVersion != null) return _cachedVersion;

    final path = await getFfmpegPath();
    if (path == null) return null;

    try {
      final res = await Process.run(path, ['-version']);
      if (res.exitCode == 0) {
        final stdoutStr = res.stdout.toString();
        final firstLine = stdoutStr.split('\n').first.trim();
        _cachedVersion = firstLine;
        return _cachedVersion;
      }
    } catch (e) {
      debugPrint('Failed to query FFmpeg version: $e');
    }
    return null;
  }

  /// Executes FFmpeg with provided arguments.
  Future<ProcessResult> runFfmpeg(List<String> args) async {
    final path = await getFfmpegPath();
    if (path == null) {
      throw StateError(
        'FFmpeg executable not found. Ensure FFmpeg is bundled or installed.',
      );
    }
    return Process.run(path, args);
  }

  /// Executes FFprobe with provided arguments.
  Future<ProcessResult> runFfprobe(List<String> args) async {
    final path = await getFfprobePath();
    if (path == null) {
      throw StateError(
        'FFprobe executable not found. Ensure FFprobe is bundled or installed.',
      );
    }
    return Process.run(path, args);
  }

  /// Queries the video duration in seconds using ffprobe.
  Future<double?> getVideoDurationSec(String videoPath) async {
    try {
      final res = await runFfprobe([
        '-v', 'error',
        '-show_entries', 'format=duration',
        '-of', 'default=noprint_wrappers=1:nokey=1',
        videoPath,
      ]);
      if (res.exitCode == 0) {
        final out = res.stdout.toString().trim();
        return double.tryParse(out);
      }
    } catch (_) {}
    return null;
  }

  /// Escapes Windows paths for FFmpeg filtergraph arguments (subtitles, fontsdir, etc.).
  /// Replaces backward slashes with forward slashes and escapes colons.
  static String escapeFilterPath(String rawPath) {
    return rawPath.replaceAll(r'\', '/').replaceAll(':', r'\:');
  }

  /// Trims, filters (aspect ratio / video look / subtitles), and exports a video clip.
  Future<ProcessResult> renderVideoClip({
    required String inputVideoPath,
    required double startSec,
    required double durationSec,
    required String outputPath,
    String? filtergraph,
    String videoPreset = 'fast',
    int crf = 20,
    bool copyAudio = false,
  }) async {
    final args = <String>[
      '-y',
      '-ss', startSec.toStringAsFixed(3),
      '-t', durationSec.toStringAsFixed(3),
      '-i', inputVideoPath,
    ];

    if (filtergraph != null && filtergraph.trim().isNotEmpty) {
      args.addAll(['-vf', filtergraph]);
    }

    args.addAll([
      '-c:v', 'libx264',
      '-crf', '$crf',
      '-preset', videoPreset,
      '-pix_fmt', 'yuv420p',
    ]);

    if (copyAudio) {
      args.addAll(['-c:a', 'copy']);
    } else {
      args.addAll([
        '-c:a', 'aac',
        '-b:a', '192k',
      ]);
    }

    args.addAll([
      '-movflags', '+faststart',
      outputPath,
    ]);

    return runFfmpeg(args);
  }

  /// Queries all available audio and video filters compiled into the active FFmpeg build.
  Future<Set<String>> getAvailableFilters() async {
    if (_cachedFilters != null) return _cachedFilters!;

    final filters = <String>{};
    try {
      final res = await runFfmpeg(['-filters']);
      if (res.exitCode == 0) {
        final lines = res.stdout.toString().split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          // Filter lines typically look like: " ... afade             A->A       Fade in/out input audio."
          final match = RegExp(r'^\s*[T.][S.][C.]?\s+([a-zA-Z0-9_\-]+)\s+').firstMatch(trimmed);
          if (match != null) {
            filters.add(match.group(1)!.toLowerCase());
          } else {
            // Fallback split for various FFmpeg builds
            final parts = trimmed.split(RegExp(r'\s+'));
            if (parts.length >= 2 && parts[0].length <= 4) {
              final filterName = parts[1].toLowerCase();
              if (RegExp(r'^[a-z0-9_\-]+$').hasMatch(filterName)) {
                filters.add(filterName);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to query FFmpeg filters: $e');
    }

    _cachedFilters = filters;
    return filters;
  }

  /// Queries all available encoders and decoders compiled into the active FFmpeg build.
  Future<Set<String>> getAvailableCodecs() async {
    if (_cachedCodecs != null) return _cachedCodecs!;

    final codecs = <String>{};
    try {
      final res = await runFfmpeg(['-codecs']);
      if (res.exitCode == 0) {
        final lines = res.stdout.toString().split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          final parts = trimmed.split(RegExp(r'\s+'));
          if (parts.length >= 2 && parts[0].length >= 5) {
            final codecName = parts[1].toLowerCase();
            codecs.add(codecName);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to query FFmpeg codecs: $e');
    }

    _cachedCodecs = codecs;
    return codecs;
  }

  /// Checks whether a specific filter (e.g. 'afade', 'hqdn3d', 'sidechaincompress')
  /// is supported by the active FFmpeg executable.
  Future<bool> hasFilter(String filterName) async {
    final filters = await getAvailableFilters();
    return filters.contains(filterName.toLowerCase());
  }

  /// Checks whether a specific codec (e.g. 'h264', 'aac', 'mp3')
  /// is supported by the active FFmpeg executable.
  Future<bool> hasCodec(String codecName) async {
    final codecs = await getAvailableCodecs();
    return codecs.contains(codecName.toLowerCase());
  }

  /// Executes a comprehensive diagnostic verification of the FFmpeg and FFprobe
  /// binaries, ensuring proper paths, execution rights, and support for all required
  /// video effects, video repair, and audio filters.
  Future<FfmpegDiagnosticReport> verifyInstallation({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedReport != null) {
      return _cachedReport!;
    }

    final ffmpegPath = await getFfmpegPath();
    final ffprobePath = await getFfprobePath();
    final version = await getFfmpegVersion();

    final isFfmpegInstalled = ffmpegPath != null && await isFfmpegAvailable();
    bool isFfprobeInstalled = false;

    if (ffprobePath != null) {
      try {
        final probeRes = await Process.run(ffprobePath, ['-version']);
        isFfprobeInstalled = probeRes.exitCode == 0;
      } catch (_) {
        isFfprobeInstalled = false;
      }
    }

    final filters = isFfmpegInstalled ? await getAvailableFilters() : <String>{};
    final codecs = isFfmpegInstalled ? await getAvailableCodecs() : <String>{};

    // Essential Video Effects & Repair filters
    final requiredVideoFilters = <String, bool>{
      'hqdn3d': filters.contains('hqdn3d'),
      'nlmeans': filters.contains('nlmeans'),
      'atadenoise': filters.contains('atadenoise'),
      'noise': filters.contains('noise'),
      'tblend': filters.contains('tblend'),
      'fade': filters.contains('fade'),
      'scale': filters.contains('scale'),
      'fps': filters.contains('fps'),
      'subtitles': filters.contains('subtitles'),
      'ass': filters.contains('ass'),
    };

    // Essential Audio Effects, Music & Ducking filters
    final requiredAudioFilters = <String, bool>{
      'afade': filters.contains('afade'),
      'aecho': filters.contains('aecho'),
      'sidechaincompress': filters.contains('sidechaincompress'),
      'silencedetect': filters.contains('silencedetect'),
      'volume': filters.contains('volume'),
      'amix': filters.contains('amix'),
      'amerge': filters.contains('amerge'),
    };

    final allVideoFiltersPresent = !requiredVideoFilters.values.contains(false);
    final allAudioFiltersPresent = !requiredAudioFilters.values.contains(false);

    final isFullyOperational = isFfmpegInstalled &&
        isFfprobeInstalled &&
        allVideoFiltersPresent &&
        allAudioFiltersPresent;

    final missingFilters = <String>[
      ...requiredVideoFilters.entries.where((e) => !e.value).map((e) => e.key),
      ...requiredAudioFilters.entries.where((e) => !e.value).map((e) => e.key),
    ];

    String summary;
    if (!isFfmpegInstalled) {
      summary = 'FFmpeg binary not detected in local bundle or system PATH.';
    } else if (!isFfprobeInstalled) {
      summary = 'FFprobe binary not detected in local bundle or system PATH.';
    } else if (missingFilters.isNotEmpty) {
      summary = 'FFmpeg found but missing filters: ${missingFilters.join(", ")}.';
    } else {
      summary = 'FFmpeg & FFprobe verified operational with all required video/audio filters.';
    }

    final report = FfmpegDiagnosticReport(
      isFfmpegInstalled: isFfmpegInstalled,
      isFfprobeInstalled: isFfprobeInstalled,
      ffmpegPath: ffmpegPath,
      ffprobePath: ffprobePath,
      version: version,
      supportedFilters: filters,
      supportedCodecs: codecs,
      requiredVideoFiltersFound: requiredVideoFilters,
      requiredAudioFiltersFound: requiredAudioFilters,
      isFullyOperational: isFullyOperational,
      diagnosticSummary: summary,
    );

    _cachedReport = report;
    return report;
  }
}

/// Comprehensive verification report detailing FFmpeg & FFprobe availability,
/// executable paths, and filter capability support.
class FfmpegDiagnosticReport {
  const FfmpegDiagnosticReport({
    required this.isFfmpegInstalled,
    required this.isFfprobeInstalled,
    required this.ffmpegPath,
    required this.ffprobePath,
    required this.version,
    required this.supportedFilters,
    required this.supportedCodecs,
    required this.requiredVideoFiltersFound,
    required this.requiredAudioFiltersFound,
    required this.isFullyOperational,
    required this.diagnosticSummary,
  });

  final bool isFfmpegInstalled;
  final bool isFfprobeInstalled;
  final String? ffmpegPath;
  final String? ffprobePath;
  final String? version;
  final Set<String> supportedFilters;
  final Set<String> supportedCodecs;
  final Map<String, bool> requiredVideoFiltersFound;
  final Map<String, bool> requiredAudioFiltersFound;
  final bool isFullyOperational;
  final String diagnosticSummary;

  int get totalVerifiedFilters =>
      requiredVideoFiltersFound.length + requiredAudioFiltersFound.length;

  int get supportedVerifiedFiltersCount =>
      requiredVideoFiltersFound.values.where((v) => v).length +
      requiredAudioFiltersFound.values.where((v) => v).length;
}
