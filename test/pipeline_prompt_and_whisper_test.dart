import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/core/services/chatgpt_bridge_service.dart';
import 'package:clipit/core/services/whisper_service.dart';
import 'package:clipit/features/pipeline/models/pipeline_job.dart';
import 'package:clipit/features/pipeline/providers/pipeline_provider.dart';
import 'package:clipit/features/pipeline/services/prompt_template_service.dart';

void main() {
  group('PromptTemplateService chunking math', () {
    test('computes correct chunks and owned ranges for a 2-hour video', () {
      final chunks = PromptTemplateService.instance.computeChunks(
        videoDurationSec: 7200, // 2 hours
        videoId: 'test_vid_123',
      );

      expect(chunks.isNotEmpty, isTrue);
      expect(chunks.first.chunkIndex, equals(1));
      expect(chunks.first.startSec, equals(0.0));
      expect(chunks.first.ownedStartFrom, equals(0.0));

      for (final chunk in chunks) {
        expect(chunk.totalChunks, equals(chunks.length));
        expect(chunk.ownedStartFrom, lessThanOrEqualTo(chunk.ownedStartUntil));
        expect(chunk.clipIdPrefix, startsWith('clip_'));
      }
    });
  });

  group('Silence intervals and Part 7 Guard 5', () {
    test('Silence interval computes 0.5s margins correctly', () {
      const silence = SilenceInterval(
        id: 'sil_0001',
        startSec: 10.0,
        endSec: 14.0,
      );

      expect(silence.durationSec, equals(4.0));
      expect(silence.removeStart, equals(10.5));
      expect(silence.removeEnd, equals(13.5));
      expect(silence.toJson()['silence_id'], equals('sil_0001'));
    });
  });

  group('Bridge JSON code-fence stripping', () {
    test('extracts raw JSON cleanly from markdown backticks', () {
      const rawResponse = '''
```json
{
  "clips": [
    {
      "id": "clip_001_1",
      "status": "FOR_SURE",
      "start_sec": 12.5,
      "end_sec": 45.0,
      "hook_title": "Bhai aaj toh crazy ho gya",
      "viral_score": 95
    }
  ]
}
```
''';
      final stripped = ChatGptBridgeService.stripAndExtractJson(rawResponse);
      expect(stripped.startsWith('{'), isTrue);
      expect(stripped.endsWith('}'), isTrue);
      expect(stripped.contains('clip_001_1'), isTrue);
    });
  });

  group('Prompt Relevance Directives', () {
    test('buildEditPlannerMessage instructs ChatGPT to only add effects if relevant', () {
      final msg = PromptTemplateService.instance.buildEditPlannerMessage(
        permanentClips: [
          const PipelineClip(
            id: 'clip_001',
            status: ClipDiscoveryStatus.permanent,
            startSec: 10.0,
            endSec: 25.0,
            hookTitle: 'Crazy Punchline',
            viralScore: 90,
            viralityReason: 'High engagement',
            suggestedCaption: 'Wait for it',
            chunkId: 'chunk_001',
          ),
        ],
        fullTranscript: const [
          TranscriptLine(startSec: 10.0, endSec: 25.0, text: 'Bhai aaj toh crazy scenes ho gaye'),
        ],
        silences: const [],
        selectedVisualEffects: const [
          {'effect_id': 'VFX_ZOOM_PUNCH', 'name': 'Zoom Punch'},
        ],
        selectedSoundEffects: const [],
        selectedTransitions: const [],
      );

      expect(msg, contains('CRITICAL EDITING DIRECTIVE:'));
      expect(msg, contains('Only add effects if you think they are relevant and genuinely enhance the moment'));
      expect(msg, contains('Do NOT force effects onto clips where they do not improve the content'));
    });

    test('buildMasterPrompt contains CRITICAL RELEVANCE RULE in section 10', () async {
      final master = await PromptTemplateService.instance.buildMasterPrompt(
        videoId: 'vid_test',
        videoTitle: 'Test Standup Video',
        videoDurationSec: 3600,
      );

      expect(master, contains('CRITICAL RELEVANCE RULE:'));
      expect(master, contains('Only add effects if you think they are relevant and genuinely enhance the moment'));
      expect(master, isNot(contains('>>>>>>>> PROMPT START')));
      expect(master, isNot(contains('PROMPT END <<<<<<<<')));
    });

    test('buildMasterPrompt specifies plain text paragraphs and permits overlapping clips', () async {
      final master = await PromptTemplateService.instance.buildMasterPrompt(
        videoId: 'vid_test',
        videoTitle: 'Standup Special',
        videoDurationSec: 3600,
      );

      // Plain paragraphs and token conservation
      expect(master, contains('Transcripts are delivered as clean plain-text paragraphs without per-word timestamps'));
      expect(master, contains('quote_start'));
      expect(master, contains('quote_end'));
      expect(master, contains('script_paragraph'));

      // Overlapping clips allowed
      expect(master, contains('Clips CAN overlap each other in time'));
      expect(master, contains('can_overlap: true'));
    });

    test('buildMasterPrompt succeeds and never throws Bad State in any environment', () async {
      final master = await PromptTemplateService.instance.buildMasterPrompt(
        videoId: 'vid_release_test',
        videoTitle: 'Standalone Release Run',
        videoDurationSec: 1800,
      );

      expect(master.isNotEmpty, isTrue);
      expect(master, contains('CLIPIT - STAND-UP CLIP SELECTION - MASTER PROMPT'));
      expect(master, contains('vid_release_test'));
    });
  });

  group('Whisper Robustness & Error State', () {
    test('WhisperService throws StateError when model or CLI is absent', () async {
      final whisper = WhisperService.instance;
      expect(
        () => whisper.transcribe(
          wavPath: 'non_existent.wav',
          modelPath: 'non_existent.bin',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Plain-Text Paragraph Formatting (No Timestamps in Chunk Prompts)', () {
    test('formatTranscriptAsParagraphs creates natural paragraphs without timestamps', () {
      final lines = [
        const TranscriptLine(startSec: 0.0, endSec: 0.5, text: 'Hello'),
        const TranscriptLine(startSec: 0.5, endSec: 1.0, text: 'everyone,'),
        const TranscriptLine(startSec: 1.0, endSec: 1.5, text: 'welcome.'),
        // 2.5s pause -> creates paragraph break
        const TranscriptLine(startSec: 4.0, endSec: 4.5, text: 'Today'),
        const TranscriptLine(startSec: 4.5, endSec: 5.0, text: 'we'),
        const TranscriptLine(startSec: 5.0, endSec: 5.5, text: 'discuss'),
        const TranscriptLine(startSec: 5.5, endSec: 6.0, text: 'comedy.'),
      ];

      final paragraphs = PromptTemplateService.instance.formatTranscriptAsParagraphs(lines);

      // Verify no timestamps in output
      expect(paragraphs, isNot(contains('[')));
      expect(paragraphs, isNot(contains('-->')));
      expect(paragraphs, isNot(contains(']')));
      expect(paragraphs, isNot(contains('0.0')));

      // Verify two paragraphs separated by blank line
      expect(paragraphs, contains('Hello everyone, welcome.'));
      expect(paragraphs, contains('Today we discuss comedy.'));
      expect(paragraphs, contains('\n\n'));
    });

    test('buildChunkMessage formats plain paragraphs and omits per-word timestamps', () {
      final chunkData = ChunkData(
        chunkId: 'chunk_001',
        chunkIndex: 1,
        totalChunks: 3,
        startSec: 0.0,
        endSec: 1860.0,
        overlapPrev: 'NONE',
        overlapNext: '1800.0 to 1860.0',
        ownedStartFrom: 0.0,
        ownedStartUntil: 1800.0,
        clipIdPrefix: 'clip_001_',
        videoId: 'project_1',
      );

      final lines = [
        const TranscriptLine(startSec: 10.0, endSec: 10.4, text: 'Sabziwala'),
        const TranscriptLine(startSec: 10.4, endSec: 10.8, text: 'bolta'),
        const TranscriptLine(startSec: 10.8, endSec: 11.2, text: 'hai'),
        const TranscriptLine(startSec: 11.2, endSec: 11.6, text: 'tamatar'),
        const TranscriptLine(startSec: 11.6, endSec: 12.0, text: 'mehnge'),
        const TranscriptLine(startSec: 12.0, endSec: 12.5, text: 'hain.'),
      ];

      final msg = PromptTemplateService.instance.buildChunkMessage(
        chunk: chunkData,
        chunkTranscript: lines,
        chunkSilences: const [],
      );

      expect(msg, contains('[TRANSCRIPT]'));
      expect(msg, contains('Sabziwala bolta hai tamatar mehnge hain.'));
      expect(msg, isNot(contains('[10.00-10.40]')));
      expect(msg, isNot(contains('[10.40-10.80]')));
      expect(msg, contains('owned_clip_start_range_sec: 0.0 to 1800.0'));
    });
  });

  group('Bridge Disconnection State & No Fake Simulation', () {
    test('sendPromptAndWait throws StateError when bridge is disconnected', () async {
      final bridge = ChatGptBridgeService();
      expect(
        () => bridge.sendPromptAndWait('test prompt'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Timestamp Alignment Engine & Overlapping Clips', () {
    test('resolves exact millisecond timestamps by matching quote_start and quote_end against word database', () {
      final lines = [
        const TranscriptLine(startSec: 10.120, endSec: 10.550, text: 'Sabziwala'),
        const TranscriptLine(startSec: 10.550, endSec: 10.920, text: 'bolta'),
        const TranscriptLine(startSec: 10.920, endSec: 11.300, text: 'hai'),
        const TranscriptLine(startSec: 11.300, endSec: 11.750, text: 'ki'),
        const TranscriptLine(startSec: 11.750, endSec: 12.200, text: 'bhaiya'),
        const TranscriptLine(startSec: 12.200, endSec: 12.800, text: 'tamatar'),
        const TranscriptLine(startSec: 12.800, endSec: 13.200, text: 'bohot'),
        const TranscriptLine(startSec: 13.200, endSec: 13.700, text: 'mehnge'),
        const TranscriptLine(startSec: 13.700, endSec: 14.100, text: 'hain.'),
        const TranscriptLine(startSec: 14.100, endSec: 14.600, text: 'Maine'),
        const TranscriptLine(startSec: 14.600, endSec: 15.000, text: 'kaha'),
        const TranscriptLine(startSec: 15.000, endSec: 15.400, text: 'kitne'),
        const TranscriptLine(startSec: 15.400, endSec: 15.800, text: 'ke'),
        const TranscriptLine(startSec: 15.800, endSec: 16.200, text: 'hain.'),
        const TranscriptLine(startSec: 16.200, endSec: 16.700, text: 'To'),
        const TranscriptLine(startSec: 16.700, endSec: 17.100, text: 'bolta'),
        const TranscriptLine(startSec: 17.100, endSec: 17.500, text: 'hai'),
        const TranscriptLine(startSec: 17.500, endSec: 18.000, text: 'ki'),
        const TranscriptLine(startSec: 18.000, endSec: 18.500, text: 'aap'),
        const TranscriptLine(startSec: 18.500, endSec: 19.000, text: 'nahi'),
        const TranscriptLine(startSec: 19.000, endSec: 19.500, text: 'le'),
        const TranscriptLine(startSec: 19.500, endSec: 20.000, text: 'paoge.'),
        const TranscriptLine(startSec: 20.000, endSec: 20.500, text: 'Aur'),
        const TranscriptLine(startSec: 20.500, endSec: 21.000, text: 'fir'),
        const TranscriptLine(startSec: 21.000, endSec: 21.500, text: 'sab'),
        const TranscriptLine(startSec: 21.500, endSec: 22.000, text: 'hasne'),
        const TranscriptLine(startSec: 22.000, endSec: 22.500, text: 'lage.'),
      ];

      final timing = PipelineNotifier.resolveClipTimestampsForTesting(
        chunkLines: lines,
        quoteStart: 'Sabziwala bolta hai ki bhaiya',
        quoteEnd: 'fir sab hasne lage',
        scriptParagraph: 'Sabziwala bolta hai ki bhaiya tamatar bohot mehnge hain. Maine kaha kitne ke hain. To bolta hai ki aap nahi le paoge. Aur fir sab hasne lage.',
        chunkStartSec: 0.0,
        chunkEndSec: 1800.0,
      );

      // StartSec should match 'Sabziwala' exactly (10.120s)
      expect(timing['start']!, closeTo(10.120, 0.001));
      // EndSec should match 'lage' (22.500s + punchline buffer)
      expect(timing['end']!, greaterThanOrEqualTo(22.500));
    });

    test('supports and retains overlapping clips with individual names and verbatim script paragraphs', () {
      final chunkData = ChunkData(
        chunkId: 'chunk_001',
        chunkIndex: 1,
        totalChunks: 1,
        startSec: 0.0,
        endSec: 1800.0,
        overlapPrev: 'NONE',
        overlapNext: 'NONE',
        ownedStartFrom: 0.0,
        ownedStartUntil: 1800.0,
        clipIdPrefix: 'clip_001_',
        videoId: 'project_1',
      );

      final lines = [
        const TranscriptLine(startSec: 10.0, endSec: 15.0, text: 'Longer story begins with setup here.'),
        const TranscriptLine(startSec: 15.0, endSec: 25.0, text: 'Comedic escalation occurs and middle joke lands.'),
        const TranscriptLine(startSec: 25.0, endSec: 35.0, text: 'Huge punchline lands at the end of story.'),
      ];

      final aiJson = '''
{
  "clips": [
    {
      "clip_id": "clip_001_001",
      "clip_name": "Full Sabziwala Story",
      "status": "FOR_SURE",
      "quote_start": "Longer story begins with",
      "quote_end": "end of story",
      "script_paragraph": "Longer story begins with setup here. Comedic escalation occurs and middle joke lands. Huge punchline lands at the end of story.",
      "hook_text": "Longer story begins with setup here",
      "virality_score": 9.5,
      "can_overlap": true
    },
    {
      "clip_id": "clip_001_002",
      "clip_name": "Quick Punchline Hit",
      "status": "FOR_SURE",
      "quote_start": "Huge punchline lands",
      "quote_end": "end of story",
      "script_paragraph": "Huge punchline lands at the end of story.",
      "hook_text": "Huge punchline lands",
      "virality_score": 9.8,
      "can_overlap": true
    }
  ]
}
''';

      final container = ProviderContainer();
      final notifier = container.read(pipelineJobProvider.notifier);
      final clips = notifier.parseStage1ResponseForTesting(
        aiJson,
        chunk: chunkData,
        chunkTranscriptLines: lines,
        ownedFrom: 0.0,
        ownedUntil: 1800.0,
        chunkEnd: 1800.0,
      );

      expect(clips.length, equals(2));
      expect(clips[0].id, equals('clip_001_001'));
      expect(clips[0].hookTitle, equals('Full Sabziwala Story'));
      expect(clips[0].canOverlap, isTrue);

      expect(clips[1].id, equals('clip_001_002'));
      expect(clips[1].hookTitle, equals('Quick Punchline Hit'));
      expect(clips[1].canOverlap, isTrue);

      // Overlap verification: clip 2 starts inside clip 1's time range
      expect(clips[1].startSec, greaterThanOrEqualTo(clips[0].startSec));
      expect(clips[1].startSec, lessThan(clips[0].endSec));
    });
  });
}
