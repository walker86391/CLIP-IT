import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/features/home/pages/home_page.dart';
import 'package:clipit/features/home/providers/video_upload_provider.dart';
import 'package:clipit/features/youtube/models/youtube_download_state.dart';
import 'package:clipit/features/youtube/providers/youtube_download_provider.dart';
import 'package:clipit/features/youtube/services/video_source_detector.dart';
import 'package:clipit/features/youtube/widgets/youtube_download_panel.dart';

void main() {
  const windowSize = Size(1280, 850);

  Widget createSubject({ProviderContainer? container, VoidCallback? onNextTap}) {
    final home = HomePage(onNextTap: onNextTap);
    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: home),
      );
    }
    return ProviderScope(
      child: MaterialApp(home: home),
    );
  }

  testWidgets(
      'Tapping GET A VIDEO FROM YOUTUBE reveals YouTube download panel and location line',
      (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    // Initially in local file upload mode
    expect(find.text('NOTHING TO DISPLAY'), findsOneWidget);
    expect(find.byType(YoutubeDownloadPanel), findsNothing);

    // Tap "GET A VIDEO FROM YOUTUBE"
    final ytBtn = find.text('GET A VIDEO FROM YOUTUBE');
    expect(ytBtn, findsOneWidget);
    await tester.tap(ytBtn);
    await tester.pumpAndSettle();

    // Now in YouTube mode
    expect(find.byType(YoutubeDownloadPanel), findsOneWidget);
    expect(find.byKey(const Key('youtube_download_location_line')), findsOneWidget);
    expect(find.textContaining('Your video will be downloaded at:'), findsOneWidget);
    expect(find.byKey(const Key('youtube_url_input_field')), findsOneWidget);
    expect(find.byKey(const Key('youtube_legal_checkbox')), findsOneWidget);
  });

  testWidgets(
      'Location line opens dialog with Open Folder and Change Location options',
      (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    // Enter YouTube mode
    await tester.tap(find.text('GET A VIDEO FROM YOUTUBE'));
    await tester.pumpAndSettle();

    // Click location line
    await tester.tap(find.byKey(const Key('youtube_download_location_line')));
    await tester.pumpAndSettle();

    // Verify popup dialog
    expect(find.text('Download Location'), findsOneWidget);
    expect(find.text('Videos downloaded via yt-dlp are saved here:'), findsOneWidget);
    expect(find.text('Open Folder'), findsOneWidget);
    expect(find.text('Change Location'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Download Location'), findsNothing);
  });

  testWidgets(
      'Download button is blanked out until URL is entered AND copyright checkbox is checked',
      (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(createSubject(container: container));
    await tester.pumpAndSettle();

    // Open YouTube panel
    await tester.tap(find.text('GET A VIDEO FROM YOUTUBE'));
    await tester.pumpAndSettle();

    final ytState = container.read(youtubeDownloadProvider);
    expect(ytState.canStartDownload, isFalse);

    // Enter URL only (checkbox still false)
    await tester.enterText(
      find.byKey(const Key('youtube_url_input_field')),
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    );
    await tester.pumpAndSettle();

    expect(container.read(youtubeDownloadProvider).canStartDownload, isFalse);

    // Check legal rights checkbox
    await tester.tap(find.byKey(const Key('youtube_legal_checkbox')));
    await tester.pumpAndSettle();

    expect(container.read(youtubeDownloadProvider).canStartDownload, isTrue);

    // Uncheck checkbox -> button becomes blanked out again
    await tester.tap(find.byKey(const Key('youtube_legal_checkbox')));
    await tester.pumpAndSettle();

    expect(container.read(youtubeDownloadProvider).canStartDownload, isFalse);
  });

  testWidgets(
      'Completed download shows top popup, converts URL box into video title/duration/resolution',
      (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(createSubject(container: container));
    await tester.pumpAndSettle();

    // Switch to YouTube mode
    await tester.tap(find.text('GET A VIDEO FROM YOUTUBE'));
    await tester.pumpAndSettle();

    // Simulate completion of yt-dlp download
    container.read(youtubeDownloadProvider.notifier).state =
        const YoutubeDownloadState(
      status: YoutubeDownloadStatus.completed,
      downloadDirectory: r'C:\Downloads\ClipIt_Downloads',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      videoTitle: 'Rick Astley - Never Gonna Give You Up',
      videoDuration: '3:33',
      videoResolution: '3840x2160',
      fileSizeBytes: 47185920,
      downloadedFilePath: r'C:\Downloads\ClipIt_Downloads\Rick_Astley.mp4',
      showTopNotification: true,
      selectedTargetWorkflow: TargetWorkflow.none,
    );
    await tester.pumpAndSettle();

    // 1. Verify Top Notification Popup
    expect(find.byKey(const Key('youtube_top_notification_banner')), findsOneWidget);
    expect(find.text('Video downloaded successfully!'), findsOneWidget);
    expect(find.textContaining('Choose what to do next'), findsOneWidget);

    // 2. Verify Converted URL Box showing title, length, resolution, size
    expect(find.text('Rick Astley - Never Gonna Give You Up'), findsOneWidget);
    expect(find.text('3:33'), findsOneWidget);
    expect(find.text('3840x2160'), findsOneWidget);
    expect(find.text('45.0 MB'), findsOneWidget);

    // 3. User should not see active continue yet until a workflow button is selected
    expect(container.read(videoUploadProvider).isReady, isFalse);
  });

  testWidgets(
      'Selecting unfinished buttons shows honest No UI Made Yet dialog, selecting LONG-FORM auto-attaches video and enables NEXT',
      (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    bool nextTriggered = false;

    await tester.pumpWidget(createSubject(
      container: container,
      onNextTap: () => nextTriggered = true,
    ));
    await tester.pumpAndSettle();

    // Open YouTube and simulate completed download
    await tester.tap(find.text('GET A VIDEO FROM YOUTUBE'));
    await tester.pumpAndSettle();

    container.read(youtubeDownloadProvider.notifier).state =
        const YoutubeDownloadState(
      status: YoutubeDownloadStatus.completed,
      downloadDirectory: r'C:\Downloads\ClipIt_Downloads',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      videoTitle: 'Sample Lecture Video',
      videoDuration: '45:12',
      videoResolution: '1920x1080',
      fileSizeBytes: 125829120,
      downloadedFilePath: r'C:\Downloads\ClipIt_Downloads\lecture.mp4',
      showTopNotification: true,
      selectedTargetWorkflow: TargetWorkflow.none,
    );
    await tester.pumpAndSettle();

    // 1. Tap UPLOAD SHORT CLIPS ALREADY CUT -> Shows clean "No UI made yet" dialog
    await tester.tap(find.text('UPLOAD SHORT CLIPS ALREADY CUT'));
    await tester.pumpAndSettle();

    expect(find.text('UPLOAD SHORT CLIPS ALREADY CUT'), findsWidgets);
    expect(
      find.textContaining('No UI made yet for this workflow'),
      findsOneWidget,
    );

    // Dismiss dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No UI made yet for this workflow'), findsNothing);

    // 2. Tap REUSE CLIPS -> Shows clean "No UI made yet" dialog
    await tester.tap(find.text('REUSE CLIPS'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No UI made yet for this workflow'),
      findsOneWidget,
    );

    // Dismiss dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // 3. Tap UPLOAD A LONG-FORM CONTENT -> auto attaches video to long form!
    await tester.tap(find.text('UPLOAD A LONG-\nFORM CONTENT'));
    await tester.pumpAndSettle();

    // Video upload state is now ready with downloaded YouTube video
    final uploadState = container.read(videoUploadProvider);
    expect(uploadState.isReady, isTrue);
    expect(uploadState.fileName, equals('Sample Lecture Video'));
    expect(uploadState.filePath, equals(r'C:\Downloads\ClipIt_Downloads\lecture.mp4'));

    // Top notification is dismissed
    expect(find.byKey(const Key('youtube_top_notification_banner')), findsNothing);

    // Status bar and action card both show READY with the video name
    expect(find.text('READY'), findsWidgets);

    // NEXT button is now active and clickable!
    await tester.tap(find.byKey(const Key('home_upload_next_button')));
    await tester.pumpAndSettle();

    expect(nextTriggered, isTrue);
  });

  group('VideoSourceDetector URL Detection Tests', () {
    test('detects various YouTube URL formats', () {
      expect(
        VideoSourceDetector.detect('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        equals(VideoSourcePlatform.youtube),
      );
      expect(
        VideoSourceDetector.detect('https://youtu.be/dQw4w9WgXcQ'),
        equals(VideoSourcePlatform.youtube),
      );
      expect(
        VideoSourceDetector.detect('https://m.youtube.com/shorts/abcdef123'),
        equals(VideoSourcePlatform.youtube),
      );
    });

    test('detects various Instagram Reel and post URL formats', () {
      expect(
        VideoSourceDetector.detect('https://www.instagram.com/reel/C7xY9z0A1B2/'),
        equals(VideoSourcePlatform.instagram),
      );
      expect(
        VideoSourceDetector.detect('https://instagram.com/p/C7xY9z0A1B2'),
        equals(VideoSourcePlatform.instagram),
      );
      expect(
        VideoSourceDetector.detect('https://www.instagr.am/reel/xyz123'),
        equals(VideoSourcePlatform.instagram),
      );
      expect(
        VideoSourceDetector.detect('https://www.instagram.com/share/reel/abc456'),
        equals(VideoSourcePlatform.instagram),
      );
    });

    test('detects unknown / generic URLs', () {
      expect(
        VideoSourceDetector.detect('https://example.com/video.mp4'),
        equals(VideoSourcePlatform.generic),
      );
      expect(
        VideoSourceDetector.detect('invalid_string'),
        equals(VideoSourcePlatform.unknown),
      );
      expect(
        VideoSourceDetector.detect(''),
        equals(VideoSourcePlatform.unknown),
      );
    });
  });

  testWidgets(
      'Instagram Reel download blacks out UPLOAD LONG-FORM button and routes to effects workflows',
      (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(createSubject(container: container));
    await tester.pumpAndSettle();

    // 1. Enter YouTube mode by clicking GET A VIDEO FROM YOUTUBE
    await tester.tap(find.text('GET A VIDEO FROM YOUTUBE'));
    await tester.pumpAndSettle();

    // 2. Simulate completed Instagram Reel download
    container.read(youtubeDownloadProvider.notifier).state =
        const YoutubeDownloadState(
      status: YoutubeDownloadStatus.completed,
      platform: VideoSourcePlatform.instagram,
      downloadDirectory: r'C:\Downloads\ClipIt_Downloads',
      videoUrl: 'https://www.instagram.com/reel/C7xY9z0A1B2/',
      videoTitle: 'Viral Dance Reel',
      videoDuration: '00:30',
      videoResolution: '1080x1920',
      fileSizeBytes: 15728640,
      downloadedFilePath: r'C:\Downloads\ClipIt_Downloads\reel.mp4',
      showTopNotification: true,
      selectedTargetWorkflow: TargetWorkflow.none,
    );
    await tester.pumpAndSettle();

    // 3. Top Notification displays Instagram Reel message
    expect(find.byKey(const Key('youtube_top_notification_banner')), findsOneWidget);
    expect(
      find.text('Instagram Reel downloaded successfully!'),
      findsOneWidget,
    );

    // 4. UPLOAD A LONG-FORM CONTENT card is blacked out with "DISABLED FOR REELS" badge
    expect(find.text('DISABLED FOR REELS'), findsOneWidget);

    // 5. Tapping UPLOAD A LONG-FORM CONTENT opens the dialog explaining Reels are already cut
    await tester.tap(find.text('UPLOAD A LONG-\nFORM CONTENT'));
    await tester.pumpAndSettle();

    expect(find.text('Not Available for Instagram Reels'), findsOneWidget);
    expect(
      find.textContaining('Instagram Reels are already cut short vertical clips and cannot be imported into the long-form content cutter.'),
      findsOneWidget,
    );

    // Dismiss dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Not Available for Instagram Reels'), findsNothing);

    // 6. User selects UPLOAD SHORT CLIPS ALREADY CUT -> sets shortClips workflow and shows effects dialog
    await tester.tap(find.text('UPLOAD SHORT CLIPS ALREADY CUT'));
    await tester.pumpAndSettle();

    expect(find.text('Add Effects & Styling (Short Clips)'), findsOneWidget);
    expect(
      find.textContaining('Instagram Reel "Viral Dance Reel" selected!'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Reels do not need cutting because they are already short clips.'),
      findsOneWidget,
    );

    // Workflow state is now shortClips and top notification is dismissed
    final ytStateShort = container.read(youtubeDownloadProvider);
    expect(ytStateShort.selectedTargetWorkflow, equals(TargetWorkflow.shortClips));
    expect(find.byKey(const Key('youtube_top_notification_banner')), findsNothing);

    // Dismiss dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // 7. User selects REUSE CLIPS -> sets reuseClips workflow and shows reuse & effects dialog
    await tester.tap(find.text('REUSE CLIPS'));
    await tester.pumpAndSettle();

    expect(find.text('Reuse Clips & Add Effects'), findsOneWidget);
    expect(
      find.textContaining('Instagram Reel "Viral Dance Reel" selected for clip reuse!'),
      findsOneWidget,
    );

    final ytStateReuse = container.read(youtubeDownloadProvider);
    expect(ytStateReuse.selectedTargetWorkflow, equals(TargetWorkflow.reuseClips));

    // Dismiss dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });
}
