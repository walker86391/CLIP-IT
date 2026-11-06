import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/video_upload_state.dart';

class VideoUploadNotifier extends Notifier<VideoUploadState> {
  @override
  VideoUploadState build() {
    return const VideoUploadState();
  }

  /// Open native Windows file explorer to pick a video file (.mp4, .mov, etc.)
  Future<bool> pickVideoFile() async {
    try {
      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'mkv', 'avi', 'webm', 'm4v'],
      );

      if (files.isNotEmpty) {
        final pickedFile = files.first;
        final name = pickedFile.name;
        final originalPath = pickedFile.path;
        int? size;
        if (originalPath != null) {
          try {
            size = File(originalPath).lengthSync();
          } catch (_) {}
        }

        // 1. Set to reading state
        state = state.copyWith(
          status: VideoUploadStatus.reading,
          fileName: name,
          filePath: originalPath,
          fileSizeBytes: size,
          isFromHomeUpload: true,
        );

        // 2. Asynchronously save reference to appdata / app storage folder if path exists
        String? targetPath = originalPath;
        if (originalPath != null && !kIsWeb) {
          try {
            final appDir = await getApplicationSupportDirectory();
            final uploadsDir = Directory(p.join(appDir.path, 'imported_videos'));
            if (!await uploadsDir.exists()) {
              await uploadsDir.create(recursive: true);
            }
            final destination = File(p.join(uploadsDir.path, name));
            final sourceFile = File(originalPath);
            if (await sourceFile.exists()) {
              if (!await destination.exists()) {
                await sourceFile.copy(destination.path);
              }
              targetPath = destination.path;
            }
          } catch (storageError) {
            debugPrint('Local cache note: $storageError');
          }
        }

        // 3. Brief reading delay for smooth user feedback
        await Future.delayed(const Duration(milliseconds: 650));

        // 4. Set to ready state
        state = state.copyWith(
          status: VideoUploadStatus.ready,
          filePath: targetPath ?? originalPath,
        );

        return true;
      }
    } catch (e) {
      debugPrint('Video pick error: $e');
    }
    return false;
  }

  /// Manually select a video (used in tests or direct triggers)
  void setVideoManual({
    required String fileName,
    String? filePath,
    int? fileSizeBytes,
    bool simulateReading = false,
  }) {
    if (simulateReading) {
      state = state.copyWith(
        status: VideoUploadStatus.reading,
        fileName: fileName,
        filePath: filePath,
        fileSizeBytes: fileSizeBytes,
        isFromHomeUpload: true,
      );
      Future.delayed(const Duration(milliseconds: 250), () {
        state = state.copyWith(status: VideoUploadStatus.ready);
      });
    } else {
      state = state.copyWith(
        status: VideoUploadStatus.ready,
        fileName: fileName,
        filePath: filePath,
        fileSizeBytes: fileSizeBytes,
        isFromHomeUpload: true,
      );
    }
  }

  void setIsFromHomeUpload(bool value) {
    state = state.copyWith(isFromHomeUpload: value);
  }

  void clear() {
    state = const VideoUploadState();
  }
}

final videoUploadProvider =
    NotifierProvider<VideoUploadNotifier, VideoUploadState>(
  VideoUploadNotifier.new,
);
