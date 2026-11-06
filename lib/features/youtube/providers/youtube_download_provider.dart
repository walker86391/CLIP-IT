import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/youtube_download_state.dart';
import '../services/video_source_detector.dart';
import '../services/youtube_download_service.dart';

class YoutubeDownloadNotifier extends Notifier<YoutubeDownloadState> {
  StreamSubscription<YtDlpEvent>? _sub;

  @override
  YoutubeDownloadState build() {
    ref.onDispose(() {
      _sub?.cancel();
      YoutubeDownloadService.instance.cancelDownload();
    });

    // Asynchronously load saved download directory
    _loadInitialDirectory();

    return const YoutubeDownloadState();
  }

  Future<void> _loadInitialDirectory() async {
    final dir = await YoutubeDownloadService.instance.getDownloadDirectory();
    state = state.copyWith(downloadDirectory: dir);
  }

  void setVideoUrl(String url) {
    final platform = VideoSourceDetector.detect(url);
    state = state.copyWith(
      videoUrl: url,
      errorMessage: null,
      platform: platform,
    );
  }

  void setRightsConfirmed(bool value) {
    state = state.copyWith(hasRightsConfirmed: value);
  }

  Future<void> openDownloadFolder() async {
    final dir = state.downloadDirectory.isNotEmpty
        ? state.downloadDirectory
        : await YoutubeDownloadService.instance.getDownloadDirectory();
    await YoutubeDownloadService.instance.openFolder(dir);
  }

  Future<void> changeDownloadDirectory() async {
    final newDir = await YoutubeDownloadService.instance.pickDownloadDirectory();
    if (newDir != null && newDir.isNotEmpty) {
      state = state.copyWith(downloadDirectory: newDir);
    }
  }

  void dismissTopNotification() {
    state = state.copyWith(showTopNotification: false);
  }

  void selectTargetWorkflow(TargetWorkflow workflow) {
    state = state.copyWith(selectedTargetWorkflow: workflow);
  }

  Future<void> startDownload() async {
    if (!state.canStartDownload) return;

    final targetDir = state.downloadDirectory.isNotEmpty
        ? state.downloadDirectory
        : await YoutubeDownloadService.instance.getDownloadDirectory();

    state = state.copyWith(
      status: YoutubeDownloadStatus.downloading,
      logs: ['[clipit] Preparing download stream...'],
      progressPercent: 0.0,
      downloadSpeed: null,
      eta: null,
      errorMessage: null,
      showTopNotification: false,
      selectedTargetWorkflow: TargetWorkflow.none,
    );

    await _sub?.cancel();

    final eventStream = YoutubeDownloadService.instance.downloadVideo(
      url: state.videoUrl.trim(),
      outputDir: targetDir,
    );

    _sub = eventStream.listen(
      (event) {
        switch (event) {
          case YtDlpLogEvent(:final line):
            final updatedLogs = List<String>.from(state.logs)..add(line);
            state = state.copyWith(logs: updatedLogs);

          case YtDlpProgressEvent(:final percent, :final speed, :final eta):
            state = state.copyWith(
              progressPercent: percent,
              downloadSpeed: speed ?? state.downloadSpeed,
              eta: eta ?? state.eta,
            );

          case YtDlpMetadataEvent(:final title, :final duration, :final resolution):
            state = state.copyWith(
              videoTitle: title,
              videoDuration: duration ?? state.videoDuration,
              videoResolution: resolution ?? state.videoResolution,
            );

          case YtDlpCompletedEvent(
              :final filePath,
              :final fileSizeBytes,
              :final title,
              :final duration,
              :final resolution,
            ):
            state = state.copyWith(
              status: YoutubeDownloadStatus.completed,
              downloadedFilePath: filePath,
              fileSizeBytes: fileSizeBytes,
              videoTitle: title ?? state.videoTitle,
              videoDuration: duration ?? state.videoDuration,
              videoResolution: resolution ?? state.videoResolution,
              progressPercent: 100.0,
              showTopNotification: true,
            );

          case YtDlpErrorEvent(:final message):
            state = state.copyWith(
              status: YoutubeDownloadStatus.error,
              errorMessage: message,
            );
        }
      },
      onError: (err) {
        state = state.copyWith(
          status: YoutubeDownloadStatus.error,
          errorMessage: err.toString(),
        );
      },
    );
  }

  void cancelDownload() {
    _sub?.cancel();
    YoutubeDownloadService.instance.cancelDownload();
    final updatedLogs = List<String>.from(state.logs)
      ..add('[clipit] Download cancelled by user.');
    state = state.copyWith(
      status: YoutubeDownloadStatus.idle,
      logs: updatedLogs,
      progressPercent: 0.0,
    );
  }

  void reset() {
    _sub?.cancel();
    YoutubeDownloadService.instance.cancelDownload();
    state = YoutubeDownloadState(downloadDirectory: state.downloadDirectory);
  }
}

final youtubeDownloadProvider =
    NotifierProvider<YoutubeDownloadNotifier, YoutubeDownloadState>(
  YoutubeDownloadNotifier.new,
);
