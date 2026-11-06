import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/services/ffmpeg_service.dart';
import '../../../core/utils/app_logger.dart';

/// Result produced by the Computer Vision pipeline and effect compositor.
class VisionProcessResult {
  const VisionProcessResult({
    required this.processedFramePath,
    required this.analysis,
    this.isSuccessful = true,
    this.errorMessage,
  });

  final String processedFramePath;
  final Map<String, dynamic> analysis;
  final bool isSuccessful;
  final String? errorMessage;
}

/// Service interfacing with MediaPipe Face Landmarker & Image Segmenter
/// to composite real video-frame effects.
class VisionCompositorService {
  VisionCompositorService._();

  static final VisionCompositorService instance = VisionCompositorService._();

  String? _cachedPythonPath;
  final Map<String, Map<String, dynamic>> _analysisCache = {};

  /// Resolves the available Python executable path on Windows.
  Future<String?> getPythonPath() async {
    if (_cachedPythonPath != null) return _cachedPythonPath;

    final candidates = <String>[
      'python.exe',
      'python',
      'python3',
      r'C:\Users\Dell\AppData\Local\Programs\Python\Python313\python.exe',
    ];

    for (final candidate in candidates) {
      try {
        final res = await Process.run(candidate, ['--version']);
        if (res.exitCode == 0) {
          _cachedPythonPath = candidate;
          AppLog.i('Found Python executable at: $candidate');
          return _cachedPythonPath;
        }
      } catch (_) {}
    }

    return null;
  }

  /// Processes the current video frame by applying real computer vision tracking
  /// and effect compositing.
  Future<VisionProcessResult?> processFrame({
    required String? videoFilePath,
    required double timestampSeconds,
    required Set<String> effectIds,
  }) async {
    if (effectIds.isEmpty) {
      return null;
    }

    try {
      final tempDir = Directory(p.join(Directory.current.path, 'build', 'fx_cache'));
      if (!tempDir.existsSync()) {
        tempDir.createSync(recursive: true);
      }

      String inputFramePath;
      String frameKey;

      if (videoFilePath != null && File(videoFilePath).existsSync()) {
        final sanitizedTs = timestampSeconds.toStringAsFixed(2).replaceAll('.', '_');
        inputFramePath = p.join(tempDir.path, 'raw_$sanitizedTs.jpg');
        frameKey = '$videoFilePath:$sanitizedTs';

        // Extract frame at timestamp using FFmpeg if not already extracted
        if (!File(inputFramePath).existsSync()) {
          final ffmpegPath = await FfmpegService.instance.getFfmpegPath();
          if (ffmpegPath != null) {
            await Process.run(ffmpegPath, [
              '-ss',
              timestampSeconds.toStringAsFixed(2),
              '-i',
              videoFilePath,
              '-vframes',
              '1',
              '-q:v',
              '2',
              '-y',
              inputFramePath,
            ]);
          }
        }
      } else {
        // Fallback to high-resolution sample creator portrait frame
        inputFramePath = p.join(
          Directory.current.path,
          'assets',
          'images',
          'sample_creator_frame.jpg',
        );
        frameKey = 'sample_creator_frame';
      }

      if (!File(inputFramePath).existsSync()) {
        AppLog.w('Input frame not found at: $inputFramePath');
        return null;
      }

      final pythonPath = await getPythonPath();
      if (pythonPath == null) {
        AppLog.w('Python executable not available for vision pipeline');
        return null;
      }

      final scriptPath = p.join(Directory.current.path, 'tool', 'vision_pipeline.py');
      if (!File(scriptPath).existsSync()) {
        AppLog.w('Vision pipeline script not found at: $scriptPath');
        return null;
      }

      final fxHash = (effectIds.toList()..sort()).join('_');
      final outputFramePath = p.join(tempDir.path, 'fx_$fxHash.jpg');

      final args = [
        scriptPath,
        '--input',
        inputFramePath,
        '--output',
        outputFramePath,
        '--effects',
        ...effectIds,
      ];

      final processResult = await Process.run(
        pythonPath,
        args,
        environment: {'TF_CPP_MIN_LOG_LEVEL': '3'},
      );

      if (processResult.exitCode == 0) {
        final stdoutStr = processResult.stdout.toString().trim();
        // Parse last line of output which contains JSON response
        final jsonLine = stdoutStr.split('\n').lastWhere(
              (line) => line.trim().startsWith('{') && line.trim().endsWith('}'),
              orElse: () => '',
            );

        Map<String, dynamic> analysis = {};
        if (jsonLine.isNotEmpty) {
          try {
            final parsed = jsonDecode(jsonLine) as Map<String, dynamic>;
            analysis = parsed['analysis'] as Map<String, dynamic>? ?? {};
            _analysisCache[frameKey] = analysis;
          } catch (_) {}
        }

        return VisionProcessResult(
          processedFramePath: outputFramePath,
          analysis: analysis,
          isSuccessful: true,
        );
      } else {
        AppLog.e('Vision pipeline failed with code ${processResult.exitCode}: ${processResult.stderr}');
      }
    } catch (e, stack) {
      AppLog.e('Exception in VisionCompositorService.processFrame: $e\n$stack');
    }

    return null;
  }
}
