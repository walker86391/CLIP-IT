import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/core/providers/core_providers.dart';
import 'package:clipit/features/clips/pages/clips_page.dart';
import 'package:clipit/features/pipeline/models/pipeline_job.dart';
import 'package:clipit/features/pipeline/providers/pipeline_provider.dart';

void main() {
  testWidgets('ClipsPage displays clean empty state when no clips exist without any mock slop', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ClipsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // No hardcoded fake podcasts
    expect(find.textContaining('Vision Pro'), findsNothing);
    expect(find.textContaining('AI Podcast #42'), findsNothing);
    expect(find.textContaining('Spatial computing'), findsNothing);

    // Clean empty state
    expect(find.text('No clips generated yet'), findsOneWidget);
    expect(find.text('Start New Project'), findsOneWidget);
    expect(find.text('Ongoing Process'), findsOneWidget);
  });

  testWidgets('ClipsPage renders real pipeline clips with dynamic counts and ratio filters', (tester) async {
    final job = PipelineJob(
      id: 'job_real_1',
      projectId: 'proj_1',
      videoTitle: 'Crazy Standup Set',
      videoPath: 'standup.mp4',
      startedAt: DateTime.now(),
      stage: PipelineStage.completed,
      clips: const [
        PipelineClip(
          id: 'clip_001_01',
          status: ClipDiscoveryStatus.permanent,
          startSec: 10.0,
          endSec: 35.0,
          hookTitle: 'Bhai yeh kya bol diya',
          viralScore: 94.0,
          viralityReason: 'High punchline velocity',
          suggestedCaption: 'Wait for the end',
          outputPath: 'C:/Users/Dell/AppData/Local/clipit/clips/proj_1/clip_001_01.mp4',
        ),
        PipelineClip(
          id: 'clip_001_02',
          status: ClipDiscoveryStatus.permanent,
          startSec: 40.0,
          endSec: 75.0,
          hookTitle: 'Crowd work went completely rogue',
          viralScore: 91.0,
          viralityReason: 'Audience reaction climax',
          suggestedCaption: 'Bro was stunned',
          outputPath: null, // confirmed, not rendered yet
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        pipelineJobProvider.overrideWith(() => _MockCompletedPipelineNotifier(job)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ClipsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify dynamic counts
    expect(find.text('Batch Export (2)'), findsOneWidget);
    expect(find.text('All Ratios (2)'), findsOneWidget);

    // Verify clip titles
    expect(find.text('Bhai yeh kya bol diya'), findsOneWidget);
    expect(find.text('Crowd work went completely rogue'), findsOneWidget);

    // Verify viral score pill
    expect(find.text('94 Viral'), findsOneWidget);
    expect(find.text('91 Viral'), findsOneWidget);

    // Filter with search query
    container.read(globalSearchQueryProvider.notifier).setQuery('rogue');
    await tester.pumpAndSettle();

    expect(find.text('Crowd work went completely rogue'), findsOneWidget);
    expect(find.text('Bhai yeh kya bol diya'), findsNothing);
  });
}

class _MockCompletedPipelineNotifier extends PipelineNotifier {
  _MockCompletedPipelineNotifier(this._initial);
  final PipelineJob _initial;

  @override
  PipelineJob? build() => _initial;
}
