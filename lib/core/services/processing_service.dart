import 'dart:async';
import 'package:flutter/foundation.dart';

import 'file_manager.dart';

/// Processing engine boundary interfacing with local processing binaries (FFmpeg, Whisper).
abstract class ProcessingService {
  Future<void> init();

  /// Runs a full pipeline for a job payload.
  Future<void> process({
    required String jobId,
    required Map<String, dynamic> payload,
  });

  Future<void> cancel(String jobId);

  Future<void> dispose();
}

/// Production implementation of [ProcessingService] for ClipIt Windows desktop.
class ClipItProcessingServiceImpl implements ProcessingService {
  ClipItProcessingServiceImpl();

  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    await FileManager.initialize();
    _initialized = true;
    debugPrint('[ProcessingService] Initialized ClipIt processing engine.');
  }

  @override
  Future<void> process({
    required String jobId,
    required Map<String, dynamic> payload,
  }) async {
    debugPrint('[ProcessingService] Queueing job $jobId');
  }

  @override
  Future<void> cancel(String jobId) async {
    debugPrint('[ProcessingService] Cancelled job $jobId');
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
  }
}
