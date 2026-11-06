import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/features/pipeline/models/pipeline_job.dart';
import 'package:clipit/features/pipeline/models/resumable_transcription_job.dart';
import 'package:clipit/features/pipeline/pages/ongoing_process_page.dart';
import 'package:clipit/features/pipeline/pages/pipeline_progress_page.dart';
import 'package:clipit/features/pipeline/providers/pipeline_provider.dart';
import 'package:clipit/features/projects/pages/project_workflow_coordinator.dart';

class _MockResumableNotifier extends ResumableTranscriptionNotifier {
  _MockResumableNotifier(this._initial);
  final ResumableTranscriptionJob? _initial;

  @override
  ResumableTranscriptionJob? build() => _initial;
}

class _MockPipelineJobNotifier extends PipelineNotifier {
  _MockPipelineJobNotifier(this._job);
  final PipelineJob? _job;

  @override
  PipelineJob? build() => _job;
}

void main() {
  const windowSize = Size(1280, 850);

  final testResumableJob = ResumableTranscriptionJob(
    projectDir: r'C:\Users\Dell\Desktop\CLIP-IT\live process\project 1',
    projectName: 'project 1',
    videoTitle: 'Sample Podcast Episode 42',
    videoPath: r'C:\Users\Dell\Desktop\CLIP-IT\sample.mp4',
    whisperModelPath: r'C:\models\whisper.bin',
    videoLanguage: 'auto',
    captionLanguage: 'hinglish',
    wordsTranscribed: 1644,
    phrasesTranscribed: 33,
    lastTranscribedSec: 990.0,
    totalAudioDurationSec: 2178.1,
    progressPercent: 45.45,
    totalChunks: 2,
    chunkFiles: const ['chunk_001.mp3', 'chunk_002.mp3'],
    outputJsonPath: 'transcript.json',
    outputTxtPath: 'transcript.txt',
  );

  testWidgets(
      'ProjectWorkflowCoordinator shows Resumable Transcription card when interrupted job detected',
      (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        resumableTranscriptionProvider.overrideWith(
          () => _MockResumableNotifier(testResumableJob),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ProjectWorkflowCoordinator(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Shows interrupted session banner and details
    expect(find.text('INTERRUPTED SESSION FOUND'), findsOneWidget);
    expect(find.text('Sample Podcast Episode 42'), findsOneWidget);
    expect(find.text('45.5% SAVED'), findsOneWidget);
    expect(
      find.textContaining('1644 words saved (33 segments)'),
      findsOneWidget,
    );

    // Shows Resume and Discard buttons
    expect(
      find.byKey(const Key('resume_workflow_transcription_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('discard_workflow_transcription_button')),
      findsOneWidget,
    );
  });

  testWidgets(
      'OngoingProcessPage shows Interrupted Transcription Card with Resume button',
      (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        pipelineJobProvider.overrideWith(() => _MockPipelineJobNotifier(null)),
        resumableTranscriptionProvider.overrideWith(
          () => _MockResumableNotifier(testResumableJob),
        ),
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

    // Shows section header
    expect(
      find.text('INTERRUPTED TRANSCRIPTION (RESUMABLE)'),
      findsOneWidget,
    );
    expect(find.text('Sample Podcast Episode 42'), findsOneWidget);

    // Shows resume button
    expect(
      find.byKey(const Key('resume_interrupted_transcription_button')),
      findsOneWidget,
    );
  });

  testWidgets(
      'PipelineProgressPage shows Resume Transcription button when job failed during transcription',
      (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final failedJob = PipelineJob(
      id: 'job_failed_transcription',
      projectId: 'proj_failed',
      videoTitle: 'Test Video Run',
      videoPath: 'test.mp4',
      startedAt: DateTime.now(),
      stage: PipelineStage.failed,
      overallProgress: 0.45,
      currentStageLabel: 'Transcribing audio with Whisper Prime…',
      errorMessage: 'Whisper Prime process stalled after 5 minutes of inactivity',
    );

    final container = ProviderContainer(
      overrides: [
        pipelineJobProvider.overrideWith(() => _MockPipelineJobNotifier(failedJob)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: PipelineProgressPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Shows error message and elevated Resume button
    expect(
      find.textContaining('Whisper Prime process stalled'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('pipeline_progress_resume_transcription_btn')),
      findsOneWidget,
    );
  });
}
