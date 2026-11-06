import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/features/youtube/models/youtube_download_state.dart';
import 'package:clipit/features/youtube/services/youtube_download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YoutubeDownloadService Tests', () {
    test('getYtDlpPath returns a non-empty string or path', () async {
      final path = await YoutubeDownloadService.instance.getYtDlpPath();
      expect(path, isNotEmpty);
    });

    test('getDownloadDirectory returns a valid directory path', () async {
      final dir = await YoutubeDownloadService.instance.getDownloadDirectory();
      expect(dir, isNotEmpty);
    });

    test('saveDownloadDirectory updates and persists directory', () async {
      const testPath = r'C:\Test_ClipIt_Downloads';
      await YoutubeDownloadService.instance.saveDownloadDirectory(testPath);
      final retrieved =
          await YoutubeDownloadService.instance.getDownloadDirectory();
      expect(retrieved, equals(testPath));
    });

    test('downloadVideo emits error event and closes stream when binary fails or invalid url',
        () async {
      final stream = YoutubeDownloadService.instance.downloadVideo(
        url: 'https://invalid-url-domain-does-not-exist.example.com',
        outputDir: r'C:\Test_ClipIt_Downloads',
      );

      final events = await stream.toList();
      expect(events, isNotEmpty);

      // Verify that at least one log event was emitted and stream closed cleanly without hanging
      final hasLogOrError = events.any(
        (e) => e is YtDlpLogEvent || e is YtDlpErrorEvent,
      );
      expect(hasLogOrError, isTrue);
    });
  });

  group('YoutubeDownloadState model tests', () {
    test('formattedFileSize handles bytes, MB, GB, and null', () {
      const state1 = YoutubeDownloadState(fileSizeBytes: 1048576 * 10);
      expect(state1.formattedFileSize, equals('10.0 MB'));

      const state2 = YoutubeDownloadState(fileSizeBytes: 1048576 * 1500);
      expect(state2.formattedFileSize, equals('1.5 GB'));

      const stateNull = YoutubeDownloadState(fileSizeBytes: null);
      expect(stateNull.formattedFileSize, equals(''));
    });

    test('canStartDownload logic', () {
      const state1 = YoutubeDownloadState(
        videoUrl: '',
        hasRightsConfirmed: false,
      );
      expect(state1.canStartDownload, isFalse);

      const state2 = YoutubeDownloadState(
        videoUrl: 'https://youtu.be/test',
        hasRightsConfirmed: false,
      );
      expect(state2.canStartDownload, isFalse);

      const state3 = YoutubeDownloadState(
        videoUrl: 'https://youtu.be/test',
        hasRightsConfirmed: true,
      );
      expect(state3.canStartDownload, isTrue);

      const state4 = YoutubeDownloadState(
        videoUrl: 'https://youtu.be/test',
        hasRightsConfirmed: true,
        status: YoutubeDownloadStatus.downloading,
      );
      expect(state4.canStartDownload, isFalse);
    });
  });
}
