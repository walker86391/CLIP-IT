import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:clipit/features/downloads/pages/downloads_page.dart';
import 'package:clipit/features/youtube/services/youtube_download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('clipit_downloads_test_');
    await YoutubeDownloadService.instance.saveDownloadDirectory(tempDir.path);
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('DownloadsPage Tests', () {
    test('DownloadedVideoItem formats size and date cleanly', () {
      final item1 = DownloadedVideoItem(
        fileName: 'sample_video.mp4',
        filePath: 'C:/sample_video.mp4',
        fileSizeBytes: 1024 * 1024 * 45, // 45 MB
        modifiedTime: DateTime(2026, 10, 20, 14, 30),
        format: 'MP4',
      );

      expect(item1.formattedSize, equals('45.0 MB'));
      expect(item1.formattedDate, equals('Oct 20, 2026 - 14:30'));
      expect(item1.format, equals('MP4'));

      final item2 = DownloadedVideoItem(
        fileName: 'large_4k.mkv',
        filePath: 'C:/large_4k.mkv',
        fileSizeBytes: (1024 * 1024 * 1024 * 2.5).toInt(), // 2.5 GB
        modifiedTime: DateTime(2026, 5, 4, 9, 5),
        format: 'MKV',
      );
      expect(item2.formattedSize, equals('2.50 GB'));
      expect(item2.formattedDate, equals('May 04, 2026 - 09:05'));
    });

    testWidgets('DownloadsPage renders header, refresh button, and empty state when folder is empty',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DownloadsPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Header
      expect(find.text('DOWNLOADS & EXPORTS'), findsOneWidget);

      // Buttons
      expect(find.text('Refresh'), findsOneWidget);
      expect(find.text('Open Output Folder'), findsOneWidget);

      // Empty State
      expect(find.text('No downloaded videos found'), findsOneWidget);
      expect(find.byIcon(Icons.movie_filter_outlined), findsOneWidget);
    });

    testWidgets('DownloadsPage discovers real video files in folder and displays them in table',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      // Create dummy video files
      final testFile1 = File(p.join(tempDir.path, 'My_Downloaded_Reel.mp4'));
      testFile1.writeAsStringSync('fake mp4 video content');

      final testFile2 = File(p.join(tempDir.path, 'YouTube_4K_Edit.webm'));
      testFile2.writeAsStringSync('fake webm video content');

      // Create a temporary part file that should be ignored
      final ignoredPart =
          File(p.join(tempDir.path, 'incomplete_video.mp4.part'));
      ignoredPart.writeAsStringSync('part content');

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DownloadsPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Table columns
      expect(find.text('FILE NAME'), findsOneWidget);
      expect(find.text('FORMAT'), findsOneWidget);
      expect(find.text('SIZE'), findsOneWidget);

      // Real files discovered
      expect(find.text('My_Downloaded_Reel.mp4'), findsOneWidget);
      expect(find.text('YouTube_4K_Edit.webm'), findsOneWidget);

      // Partial file ignored
      expect(find.text('incomplete_video.mp4.part'), findsNothing);

      // Refresh button can be tapped
      await tester.tap(find.text('Refresh'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('My_Downloaded_Reel.mp4'), findsOneWidget);
    });
  });
}
