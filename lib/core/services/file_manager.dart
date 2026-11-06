import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/pipeline/models/pipeline_job.dart';

/// Manages the temp work directory, output clips directory, and models directory.
/// All paths are under %LOCALAPPDATA%\clipit\ — UAC-free, MSIX-safe.
class FileManager {
  FileManager._();
  static final FileManager instance = FileManager._();

  static Future<void> initialize() async {
    await instance._baseDir;
    debugPrint('[FileManager] Initialized ClipIt storage hierarchy.');
  }

  /// %LOCALAPPDATA%\clipit\
  Future<Directory> get _baseDir async {
    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appSupport.path, '..', 'clipit'));
    await dir.create(recursive: true);
    return dir;
  }

  /// Returns (creating if needed) %LOCALAPPDATA%\clipit\temp\{jobId}\
  Future<Directory> createTempDir(String jobId) async {
    final base = await _baseDir;
    final dir = Directory(p.join(base.path, 'temp', jobId));
    await dir.create(recursive: true);
    debugPrint('[FileManager] Temp dir: ${dir.path}');
    return dir;
  }

  /// Returns (creating if needed) %LOCALAPPDATA%\clipit\clips\{projectId}\
  Future<Directory> ensureClipsDir(String projectId) async {
    final base = await _baseDir;
    final dir = Directory(p.join(base.path, 'clips', projectId));
    await dir.create(recursive: true);
    debugPrint('[FileManager] Clips dir: ${dir.path}');
    return dir;
  }

  /// Returns %LOCALAPPDATA%\clipit\models\
  Future<Directory> ensureModelsDir() async {
    final base = await _baseDir;
    final dir = Directory(p.join(base.path, 'models'));
    await dir.create(recursive: true);
    return dir;
  }

  /// Returns %LOCALAPPDATA%\clipit\prompts\
  Future<Directory> ensurePromptsDir() async {
    final base = await _baseDir;
    final dir = Directory(p.join(base.path, 'prompts'));
    await dir.create(recursive: true);
    return dir;
  }

  /// Deletes the entire temp directory for a job after successful render.
  Future<void> cleanupTempDir(String jobId) async {
    final base = await _baseDir;
    final dir = Directory(p.join(base.path, 'temp', jobId));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      debugPrint('[FileManager] Temp dir cleaned up: ${dir.path}');
    }
  }

  /// Lists all .mp4 files in a project's clips dir.
  Future<List<FileSystemEntity>> listClipFiles(String projectId) async {
    final dir = await ensureClipsDir(projectId);
    if (!await dir.exists()) return [];
    return dir.listSync().where((e) => e.path.endsWith('.mp4')).toList();
  }

  /// Reads and parses silence_intervals.json from a job's temp dir.
  Future<List<SilenceInterval>> readSilenceIntervals(String tempDirPath) async {
    final file = File(p.join(tempDirPath, 'silence_intervals.json'));
    if (!await file.exists()) return [];
    try {
      final raw = jsonDecode(await file.readAsString()) as List<dynamic>;
      return raw.asMap().entries.map((e) {
        final m = e.value as Map<String, dynamic>;
        return SilenceInterval(
          id: 'sil_${e.key.toString().padLeft(4, '0')}',
          startSec: (m['start'] as num).toDouble(),
          endSec: (m['end'] as num).toDouble(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

typedef ClipItFileManager = FileManager;
