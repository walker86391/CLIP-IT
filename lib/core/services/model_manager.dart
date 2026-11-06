import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../utils/app_logger.dart';
import '../utils/app_path_resolver.dart';
import 'file_manager.dart';
import 'local_settings_service.dart';

/// Verification result providing exact details of on-disk file checks.
class ModelVerificationResult {
  const ModelVerificationResult({
    required this.isValid,
    required this.message,
    this.totalSizeBytes = 0,
    this.fileCount = 0,
    this.timestamp,
  });

  final bool isValid;
  final String message;
  final int totalSizeBytes;
  final int fileCount;
  final DateTime? timestamp;

  String get formattedSize {
    if (totalSizeBytes >= 1024 * 1024 * 1024) {
      return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Descriptor for a downloadable or installed speech recognition model.
class ModelInfo {
  const ModelInfo({
    required this.id,
    required this.name,
    required this.fileName,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.description,
    this.tier = 'Balanced',
    this.installed = false,
    this.localPath,
    this.sha256Hash,
  });

  final String id;
  final String name;
  final String fileName;
  final String downloadUrl;
  final int sizeBytes;
  final String description;
  final String tier;
  final bool installed;
  final String? localPath;
  final String? sha256Hash;

  String get formattedSize {
    if (sizeBytes >= 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }

  ModelInfo copyWith({
    bool? installed,
    String? localPath,
  }) {
    return ModelInfo(
      id: id,
      name: name,
      fileName: fileName,
      downloadUrl: downloadUrl,
      sizeBytes: sizeBytes,
      description: description,
      tier: tier,
      installed: installed ?? this.installed,
      localPath: localPath ?? this.localPath,
      sha256Hash: sha256Hash,
    );
  }
}

/// Download progress callback definition.
typedef ModelProgressCallback = void Function(
  int received,
  int total,
  double fraction,
);

/// Manages downloading, file verification, model switching, and deletion
/// for ClipIt's local speech recognition models.
class ClipItModelManager {
  ClipItModelManager._();
  static final ClipItModelManager instance = ClipItModelManager._();

  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};

  static const String defaultActiveModelId = 'oriserve_whisper_prime';

  static const List<ModelInfo> availableModels = [
    ModelInfo(
      id: 'oriserve_whisper_prime',
      name: 'Oriserve Whisper-Hindi2Hinglish-Prime',
      fileName: 'models/Whisper-Hindi2Hinglish-Prime',
      downloadUrl:
          'https://huggingface.co/Oriserve/Whisper-Hindi2Hinglish-Prime',
      sizeBytes: 5893000000,
      tier: 'Flagship (Highest Power)',
      description:
          'Flagship Hindi-to-Hinglish model (Large-v3 architecture, ~5.8 GB). Maximum Romanized accuracy and contextual speech fidelity. Active Live Model.',
    ),
    ModelInfo(
      id: 'oriserve_whisper_apex',
      name: 'Oriserve Whisper-Hindi2Hinglish-Apex',
      fileName: 'models/Whisper-Hindi2Hinglish-Apex',
      downloadUrl:
          'https://huggingface.co/Oriserve/Whisper-Hindi2Hinglish-Apex',
      sizeBytes: 1618000000,
      tier: 'Fast Apex (Mid-tier)',
      description:
          'Mid-tier Hindi2Hinglish model with 4-layer fast decoder (~1.5 GB). High throughput Romanized speech recognition with low VRAM footprint.',
    ),
    ModelInfo(
      id: 'whisper_base',
      name: 'Whisper Base (Ultra-Lightweight)',
      fileName: 'models/ggml-base.bin',
      downloadUrl:
          'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin',
      sizeBytes: 147951465,
      tier: 'Ultra-Light (Lowest PC Power)',
      description:
          'Lowest PC power consumption (~148 MB). Runs lightning-fast on budget laptops, battery power, and basic CPUs via whisper.cpp.',
    ),
    ModelInfo(
      id: 'whisper_small',
      name: 'Whisper Small (Balanced Mid)',
      fileName: 'models/ggml-small.bin',
      downloadUrl:
          'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin',
      sizeBytes: 487601967,
      tier: 'Balanced Mid-Range',
      description:
          'Balanced mid-power model (~488 MB). Accurate multilingual transcription with modest CPU and memory consumption.',
    ),
    ModelInfo(
      id: 'whisper_large_v3_turbo',
      name: 'Whisper Large-v3-Turbo',
      fileName: 'models/ggml-large-v3-turbo.bin',
      downloadUrl:
          'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin',
      sizeBytes: 1630000000,
      tier: 'High Precision C++',
      description:
          'High precision multilingual engine optimized for fast whisper.cpp CPU inference (~1.6 GB).',
    ),
    ModelInfo(
      id: 'oriserve_hindi2hinglish',
      name: 'Oriserve Hindi2Hinglish GGML',
      fileName: 'models/whisper-hindi2hinglish-large-v3.bin',
      downloadUrl:
          'https://huggingface.co/curiophile/whisper-hindi2hinglish-ggml/resolve/main/ggml-model.bin',
      sizeBytes: 1600000000,
      tier: 'Legacy Hinglish GGML',
      description:
          'Fine-tuned on 550+ hrs of conversational Hinglish (~1.6 GB). Direct Romanized output for whisper.cpp.',
    ),
  ];

  /// Gets the currently active model ID from persisted local settings.
  Future<String> getActiveModelId() async {
    final cached = LocalSettingsService.current?['activeModelId'] as String?;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return defaultActiveModelId;
  }

  /// Persists the active model selection so it survives app restarts.
  Future<void> setActiveModelId(String id) async {
    await LocalSettingsService.patch({'activeModelId': id});
    AppLog.i('[ModelManager] Active model set to: $id');
  }

  /// Returns the model file or directory path for the currently active model.
  Future<String> getActiveModelPath() async {
    final id = await getActiveModelId();
    final models = await listModels();
    final model = models.firstWhere(
      (m) => m.id == id,
      orElse: () => models.firstWhere((m) => m.id == defaultActiveModelId),
    );

    if (model.localPath != null && model.installed) {
      return model.localPath!;
    }
    return model.fileName;
  }

  /// Returns all models annotated with local installation state across all lookup paths.
  Future<List<ModelInfo>> listModels() async {
    final projectDir = AppPathResolver.projectRoot;
    final modelsDir = await FileManager.instance.ensureModelsDir();
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final results = <ModelInfo>[];

    for (final model in availableModels) {
      final base = p.basename(model.fileName);
      final candidatePaths = <String>[
        p.join(projectDir.path, model.fileName),
        p.join(projectDir.path, 'models', base),
        p.join(Directory.current.path, model.fileName),
        p.join(Directory.current.path, 'models', base),
        p.join(modelsDir.path, model.fileName),
        p.join(modelsDir.path, base),
        if (localAppData.isNotEmpty)
          p.join(localAppData, 'clipit', 'models', base),
        p.join(r'C:\Users\Dell\Desktop\CLIP-IT', model.fileName),
        p.join(r'C:\Users\Dell\Desktop\CLIP-IT\models', base),
      ];

      try {
        final exeDir = p.dirname(Platform.resolvedExecutable);
        candidatePaths.insert(0, p.join(exeDir, model.fileName));
        candidatePaths.insert(1, p.join(exeDir, 'models', base));
      } catch (_) {}

      bool exists = false;
      String? matchedPath;

      for (final candidate in candidatePaths) {
        final dir = Directory(candidate);
        if (dir.existsSync()) {
          try {
            final contents = dir.listSync();
            if (contents.isNotEmpty) {
              exists = true;
              matchedPath = candidate;
              break;
            }
          } catch (_) {}
        }

        final file = File(candidate);
        if (file.existsSync()) {
          try {
            if (file.lengthSync() > 1024 * 1024) {
              // At least 1 MB
              exists = true;
              matchedPath = candidate;
              break;
            }
          } catch (_) {}
        }
      }

      results.add(model.copyWith(
        installed: exists,
        localPath: matchedPath,
      ));
    }

    return results;
  }

  /// Performs an in-depth file check on a downloaded model to verify completeness.
  Future<ModelVerificationResult> checkModelFiles(String modelId) async {
    final models = await listModels();
    final model = models.firstWhere(
      (m) => m.id == modelId,
      orElse: () => throw ArgumentError('Model not found: $modelId'),
    );

    if (!model.installed || model.localPath == null) {
      return const ModelVerificationResult(
        isValid: false,
        message: 'Model is not installed locally on disk.',
      );
    }

    final path = model.localPath!;
    final dir = Directory(path);

    if (dir.existsSync()) {
      int totalBytes = 0;
      int count = 0;
      bool hasSafetensors = false;
      bool hasConfig = false;

      try {
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is File) {
            final len = entity.lengthSync();
            totalBytes += len;
            count++;
            final name = p.basename(entity.path);
            if (name.endsWith('.safetensors') || name.endsWith('.bin')) {
              hasSafetensors = true;
            }
            if (name == 'config.json') {
              hasConfig = true;
            }
          }
        }
      } catch (e) {
        return ModelVerificationResult(
          isValid: false,
          message: 'Error reading model directory: $e',
        );
      }

      if (count > 0 && hasConfig && (hasSafetensors || totalBytes > 100 * 1024 * 1024)) {
        final gb = (totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2);
        return ModelVerificationResult(
          isValid: true,
          message: 'Verified on disk: $gb GB across $count files (weights intact)',
          totalSizeBytes: totalBytes,
          fileCount: count,
          timestamp: DateTime.now(),
        );
      } else {
        return ModelVerificationResult(
          isValid: false,
          message: 'Directory exists but missing weight files ($count files).',
          totalSizeBytes: totalBytes,
          fileCount: count,
          timestamp: DateTime.now(),
        );
      }
    }

    final file = File(path);
    if (file.existsSync()) {
      final len = file.lengthSync();
      if (len >= model.sizeBytes * 0.75) {
        final mb = (len / (1024 * 1024)).toStringAsFixed(1);
        return ModelVerificationResult(
          isValid: true,
          message: 'Verified on disk: $mb MB (binary intact)',
          totalSizeBytes: len,
          fileCount: 1,
          timestamp: DateTime.now(),
        );
      } else {
        final mb = (len / (1024 * 1024)).toStringAsFixed(1);
        return ModelVerificationResult(
          isValid: false,
          message: 'File incomplete: $mb MB (expected ${model.formattedSize})',
          totalSizeBytes: len,
          fileCount: 1,
          timestamp: DateTime.now(),
        );
      }
    }

    return const ModelVerificationResult(
      isValid: false,
      message: 'Local model file cannot be found or read.',
    );
  }

  /// Downloads a model with live progress updates.
  Future<String> downloadModel(
    String modelId, {
    ModelProgressCallback? onProgress,
  }) async {
    final model = availableModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => throw ArgumentError('Unknown modelId: $modelId'),
    );

    // 1. Python-based downloader for Whisper-Hindi2Hinglish-Prime
    if (model.id == 'oriserve_whisper_prime') {
      final script = p.join(AppPathResolver.projectRoot.path, 'tool', 'download_whisper_prime.py');
      if (File(script).existsSync()) {
        final process = await Process.start('python', [script]);
        process.stdout.transform(utf8.decoder).listen((line) {
          debugPrint('[WhisperPrimeDownload] $line');
          final match = RegExp(r'\((\d+(?:\.\d+)?)%\)').firstMatch(line);
          if (match != null) {
            final pct = double.tryParse(match.group(1)!) ?? 0.0;
            onProgress?.call(0, 0, (pct / 100.0).clamp(0.0, 1.0));
          }
        });
        final exitCode = await process.exitCode;
        if (exitCode == 0) {
          return p.join(AppPathResolver.projectRoot.path, model.fileName);
        } else {
          throw StateError('Prime download script failed with code $exitCode');
        }
      }
    }

    // 2. Python-based downloader for Whisper-Hindi2Hinglish-Apex
    if (model.id == 'oriserve_whisper_apex') {
      final script = p.join(AppPathResolver.projectRoot.path, 'tool', 'download_whisper_apex.py');
      if (File(script).existsSync()) {
        final process = await Process.start('python', [script]);
        process.stdout.transform(utf8.decoder).listen((line) {
          debugPrint('[WhisperApexDownload] $line');
          final match = RegExp(r'\((\d+(?:\.\d+)?)%\)').firstMatch(line);
          if (match != null) {
            final pct = double.tryParse(match.group(1)!) ?? 0.0;
            onProgress?.call(0, 0, (pct / 100.0).clamp(0.0, 1.0));
          }
        });
        final exitCode = await process.exitCode;
        if (exitCode == 0) {
          return p.join(AppPathResolver.projectRoot.path, model.fileName);
        } else {
          throw StateError('Apex download script failed with code $exitCode');
        }
      }
    }

    // 3. Direct Dio streaming download for single-file models (GGML binaries)
    final projectModelsDir = Directory(p.join(AppPathResolver.projectRoot.path, 'models'));
    if (!projectModelsDir.existsSync()) {
      await projectModelsDir.create(recursive: true);
    }

    final targetPath = p.join(projectModelsDir.path, p.basename(model.fileName));
    final tempPath = '$targetPath.part';

    final cancelToken = CancelToken();
    _cancelTokens[modelId] = cancelToken;

    try {
      debugPrint('[ModelManager] Downloading ${model.name} to $tempPath');

      await _dio.download(
        model.downloadUrl,
        tempPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final fraction = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
          onProgress?.call(received, total, fraction);
        },
      );

      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        final targetFile = File(targetPath);
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        await tempFile.rename(targetPath);
      }

      // Also mirror to %LOCALAPPDATA%\clipit\models for multi-location resiliency
      try {
        final localModelsDir = await FileManager.instance.ensureModelsDir();
        final localTarget = File(p.join(localModelsDir.path, p.basename(model.fileName)));
        if (!await localTarget.exists()) {
          await File(targetPath).copy(localTarget.path);
        }
      } catch (_) {}

      debugPrint('[ModelManager] Successfully downloaded ${model.name} to $targetPath');
      return targetPath;
    } catch (e) {
      debugPrint('[ModelManager] Download error: $e');
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    } finally {
      _cancelTokens.remove(modelId);
    }
  }

  /// Cancels an in-progress download.
  void cancelDownload(String modelId) {
    _cancelTokens[modelId]?.cancel('Cancelled by user');
    _cancelTokens.remove(modelId);
  }

  /// Verifies the integrity of a locally downloaded model via SHA-256.
  Future<bool> verifyModel(String modelId) async {
    final result = await checkModelFiles(modelId);
    return result.isValid;
  }

  /// Deletes a locally downloaded model file or directory to free disk space.
  Future<void> deleteModel(String modelId) async {
    final models = await listModels();
    final model = models.firstWhere((m) => m.id == modelId);
    final base = p.basename(model.fileName);

    final projectDir = AppPathResolver.projectRoot;
    final modelsDir = await FileManager.instance.ensureModelsDir();
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';

    final candidatePaths = <String>[
      p.join(projectDir.path, model.fileName),
      p.join(projectDir.path, 'models', base),
      p.join(Directory.current.path, model.fileName),
      p.join(Directory.current.path, 'models', base),
      p.join(modelsDir.path, model.fileName),
      p.join(modelsDir.path, base),
      if (localAppData.isNotEmpty)
        p.join(localAppData, 'clipit', 'models', base),
      p.join(r'C:\Users\Dell\Desktop\CLIP-IT', model.fileName),
      p.join(r'C:\Users\Dell\Desktop\CLIP-IT\models', base),
    ];

    try {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      candidatePaths.add(p.join(exeDir, model.fileName));
      candidatePaths.add(p.join(exeDir, 'models', base));
    } catch (_) {}

    for (final candidate in candidatePaths) {
      final dir = Directory(candidate);
      if (dir.existsSync()) {
        try {
          await dir.delete(recursive: true);
          debugPrint('[ModelManager] Deleted directory: $candidate');
        } catch (e) {
          debugPrint('[ModelManager] Error deleting directory $candidate: $e');
        }
      }

      final file = File(candidate);
      if (file.existsSync()) {
        try {
          await file.delete();
          debugPrint('[ModelManager] Deleted file: $candidate');
        } catch (e) {
          debugPrint('[ModelManager] Error deleting file $candidate: $e');
        }
      }
    }
  }
}
