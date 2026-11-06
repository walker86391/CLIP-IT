import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/features/pipeline/models/pipeline_job.dart';
import 'package:clipit/features/pipeline/pages/ongoing_process_page.dart';
import 'package:clipit/features/pipeline/providers/pipeline_provider.dart';
import 'package:clipit/ui/components/app_top_bar.dart';

void main() {
  group('AppTopBar — Cleaned & Functional UI', () {
    testWidgets('Top bar removes Personal pill, notification bell, and user name, and wires search',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppTopBar(
                title: 'Processing',
                jobStatus: 'Transcribing (Hinglish) (24%)',
                hasActiveJobs: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Title displayed
      expect(find.text('PROCESSING'), findsOneWidget);

      // "Personal" pill must NOT exist
      expect(find.text('Personal'), findsNothing);

      // User name "Shivam C." and notifications must NOT exist
      expect(find.text('Shivam C.'), findsNothing);
      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);

      // Functional Search Bar exists
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search whole title…'), findsOneWidget);

      // Entering search text updates provider
      await tester.enterText(find.byType(TextField), 'Standup Special');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Standup Special'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tapping close clears search text
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Standup Special'), findsNothing);
    });
  });

  group('OngoingProcessPage Controls — Pause, Resume, Cancel & Red Delete Button', () {
    testWidgets('Active job displays Pause enabled, Resume greyed out, and Cancel button',
        (tester) async {
      final testJob = PipelineJob(
        id: 'job_test_1',
        projectId: 'proj_1',
        videoTitle: 'Viral Gaming Clutch',
        videoPath: 'sample.mp4',
        startedAt: DateTime.now(),
        stage: PipelineStage.discoveringClips,
        overallProgress: 0.45,
        currentStageLabel: 'Discovering clips — Chunk 1…',
      );

      final container = ProviderContainer(
        overrides: [
          pipelineJobProvider.overrideWith(() => _MockPipelineNotifier(testJob)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OngoingProcessPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tile shows title and stage
      expect(find.text('Viral Gaming Clutch'), findsOneWidget);
      expect(find.text('Discovering clips — Chunk 1…'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);

      // Pause button exists and is enabled
      expect(find.byKey(const Key('pause_pipeline_button')), findsOneWidget);

      // Resume button exists and is DISABLED (greyed out) while running
      final resumeBtn = tester.widget<ElevatedButton>(find.byKey(const Key('resume_pipeline_button')));
      expect(resumeBtn.onPressed, isNull);

      // Cancel button exists
      expect(find.byKey(const Key('cancel_pipeline_button')), findsOneWidget);
    });

    testWidgets('Paused job shows Resume button active', (tester) async {
      final pausedJob = PipelineJob(
        id: 'job_test_paused',
        projectId: 'proj_paused',
        videoTitle: 'Funny Interview Episode',
        videoPath: 'interview.mp4',
        startedAt: DateTime.now(),
        stage: PipelineStage.paused,
        overallProgress: 0.60,
        currentStageLabel: 'Pipeline paused',
      );

      final container = ProviderContainer(
        overrides: [
          pipelineJobProvider.overrideWith(() => _MockPipelineNotifier(pausedJob)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OngoingProcessPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('PAUSED — Work suspended'), findsOneWidget);

      // Resume button is ENABLED
      final resumeBtn = tester.widget<ElevatedButton>(find.byKey(const Key('resume_pipeline_button')));
      expect(resumeBtn.onPressed, isNotNull);

      // Pause button is hidden when already paused
      expect(find.byKey(const Key('pause_pipeline_button')), findsNothing);
    });

    testWidgets('Cancelled job blacks out buttons & tile and displays prominent RED DELETE BUTTON',
        (tester) async {
      final cancelledJob = PipelineJob(
        id: 'job_test_cancelled',
        projectId: 'proj_cancelled',
        videoTitle: 'Cancelled Live Stream',
        videoPath: 'stream.mp4',
        startedAt: DateTime.now(),
        stage: PipelineStage.cancelled,
        currentStageLabel: 'Pipeline cancelled',
      );

      var deleteWasCalled = false;
      final mockNotifier = _MockPipelineNotifier(
        cancelledJob,
        onDelete: () => deleteWasCalled = true,
      );

      final container = ProviderContainer(
        overrides: [
          pipelineJobProvider.overrideWith(() => mockNotifier),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OngoingProcessPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Normal controls must be blacked out / hidden
      expect(find.byKey(const Key('pause_pipeline_button')), findsNothing);
      expect(find.byKey(const Key('resume_pipeline_button')), findsNothing);
      expect(find.byKey(const Key('cancel_pipeline_button')), findsNothing);

      // Red Delete Button MUST appear
      expect(find.byKey(const Key('delete_pipeline_button')), findsOneWidget);
      expect(find.text('DELETE PIPELINE & CLEANUP'), findsOneWidget);

      // Tap the Red Delete Button
      await tester.tap(find.byKey(const Key('delete_pipeline_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(deleteWasCalled, isTrue);
    });

    testWidgets('Empty processing page shows clean state with Start New Project button and no fake AI slop',
        (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OngoingProcessPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // No fake hardcoded podcast/vision pro slop
      expect(find.textContaining('Vision Pro'), findsNothing);
      expect(find.textContaining('AI & Robotics'), findsNothing);

      // Clean empty state
      expect(find.text('No active video processing jobs'), findsOneWidget);
      expect(find.text('Start New Project'), findsOneWidget);
    });
  });
}

class _MockPipelineNotifier extends PipelineNotifier {
  _MockPipelineNotifier(this._initial, {this.onDelete});
  final PipelineJob _initial;
  final VoidCallback? onDelete;

  @override
  PipelineJob? build() => _initial;

  @override
  Future<void> deleteJobAndFiles(PipelineJob job) async {
    onDelete?.call();
    state = null;
  }
}
