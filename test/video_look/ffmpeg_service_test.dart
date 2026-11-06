import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/core/services/ffmpeg_service.dart';

void main() {
  group('FfmpegService Bundling and Detection Tests', () {
    test('discovers bundled or system FFmpeg binary', () async {
      final path = await FfmpegService.instance.getFfmpegPath();
      expect(path, isNotNull);
      expect(path!.isNotEmpty, isTrue);
    });

    test('verifies FFmpeg is available and runnable', () async {
      final isAvailable = await FfmpegService.instance.isFfmpegAvailable();
      expect(isAvailable, isTrue);
    });

    test('queries FFmpeg version string', () async {
      final version = await FfmpegService.instance.getFfmpegVersion();
      expect(version, isNotNull);
      expect(version!.toLowerCase(), contains('ffmpeg version'));
    });
  });
}
