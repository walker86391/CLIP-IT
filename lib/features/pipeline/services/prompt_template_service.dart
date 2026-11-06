import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/pipeline_job.dart';
import 'default_master_prompt.dart';

/// Builds the three ChatGPT prompt types (master, chunk, validation, edit planner)
/// from the template files and saves chatgptprompt.txt to the prompts dir.
class PromptTemplateService {
  PromptTemplateService._();
  static final PromptTemplateService instance = PromptTemplateService._();

  static const int _chunkDurationSec = 1800;  // 30 min
  static const int _overlapSec = 60;           // 1 min overlap
  static const int _defaultMinClipSec = 15;
  static const int _defaultMaxClipSec = 90;
  static const double _defaultMinSilenceSec = 2.0;

  // ── Template loading ───────────────────────────────────────────────────────

  /// Reads clipit_master_prompt.txt from Flutter assets, local disk candidates,
  /// parent directories, or the built-in fallback template.
  /// Extracts only the text between ">>>>>>>> PROMPT START" and the matching
  /// end marker (as specified in the file header).
  Future<String> _loadMasterPromptTemplate() async {
    // 1. Try Flutter rootBundle asset first (packaged in all release builds)
    try {
      final assetContent = await rootBundle.loadString('assets/prompts/clipit_master_prompt.txt');
      if (assetContent.trim().isNotEmpty) {
        return _extractBetweenMarkers(assetContent);
      }
    } catch (_) {}

    try {
      final assetContent = await rootBundle.loadString('clipit_master_prompt.txt');
      if (assetContent.trim().isNotEmpty) {
        return _extractBetweenMarkers(assetContent);
      }
    } catch (_) {}

    // 2. Build disk candidate paths
    final candidates = <String>[];

    void addDirCandidates(Directory dir) {
      candidates.add(p.join(dir.path, 'clipit_master_prompt.txt'));
      candidates.add(p.join(dir.path, 'assets', 'prompts', 'clipit_master_prompt.txt'));
      candidates.add(p.join(dir.path, 'data', 'flutter_assets', 'assets', 'prompts', 'clipit_master_prompt.txt'));
      candidates.add(p.join(dir.path, 'data', 'flutter_assets', 'clipit_master_prompt.txt'));
    }

    // A. Relative to resolved executable and its parent directories (up to 8 levels)
    try {
      var exeDir = Directory(p.dirname(Platform.resolvedExecutable));
      for (int i = 0; i < 8; i++) {
        addDirCandidates(exeDir);
        final parent = exeDir.parent;
        if (parent.path == exeDir.path) break;
        exeDir = parent;
      }
    } catch (_) {}

    // B. Relative to current working directory and its parent directories
    try {
      var curDir = Directory.current;
      for (int i = 0; i < 8; i++) {
        addDirCandidates(curDir);
        final parent = curDir.parent;
        if (parent.path == curDir.path) break;
        curDir = parent;
      }
    } catch (_) {}

    // C. Hardcoded known path on this system
    candidates.add(r'C:\Users\Dell\Desktop\CLIP-IT\clipit_master_prompt.txt');
    candidates.add(r'C:\Users\Dell\Desktop\CLIP-IT\assets\prompts\clipit_master_prompt.txt');

    for (final candidate in candidates) {
      try {
        final f = File(candidate);
        if (f.existsSync()) {
          final raw = await f.readAsString();
          if (raw.trim().isNotEmpty) {
            return _extractBetweenMarkers(raw);
          }
        }
      } catch (_) {}
    }

    // 3. Fallback to embedded default prompt (guaranteed to always work)
    if (kDefaultMasterPrompt.trim().isNotEmpty) {
      return kDefaultMasterPrompt;
    }

    throw StateError(
      'clipit_master_prompt.txt not found. '
      'Ensure it is in the project root or bundled with the release.',
    );
  }

  /// Extracts text between the START and END markers of the master prompt file.
  String _extractBetweenMarkers(String raw) {
    const startMarker = '>>>>>>>>>>>>>>>>';
    const endMarker = '<<<<<<<<<<<<<<<<';

    final startIdx = raw.indexOf(startMarker);
    if (startIdx == -1) {
      return raw.trim();
    }

    // Skip past the START marker line
    final afterStart = raw.indexOf('\n', startIdx);
    final contentStart = (afterStart != -1) ? afterStart + 1 : startIdx + startMarker.length;

    final endIdx = raw.indexOf(endMarker, contentStart);
    if (endIdx == -1 || endIdx <= contentStart) {
      return raw.substring(contentStart).trim();
    }

    return raw.substring(contentStart, endIdx).trim();
  }

  // ── Master Prompt Builder ──────────────────────────────────────────────────

  /// Fills all {{PLACEHOLDER}} values in the master prompt template.
  /// Only includes effects the user actually selected (never the full catalogue).
  Future<String> buildMasterPrompt({
    required String videoId,
    required String videoTitle,
    required int videoDurationSec,
    String showContext = 'NOT_PROVIDED',
    int minClipSec = _defaultMinClipSec,
    int maxClipSec = _defaultMaxClipSec,
    double minSilenceSec = _defaultMinSilenceSec,
    List<Map<String, dynamic>> selectedVisualEffects = const [],
    List<Map<String, dynamic>> selectedSoundEffects = const [],
    List<Map<String, dynamic>> selectedTransitions = const [],
  }) async {
    var template = await _loadMasterPromptTemplate();

    final visualJson = selectedVisualEffects.isEmpty
        ? 'NONE_SELECTED'
        : jsonEncode(selectedVisualEffects);
    final soundJson = selectedSoundEffects.isEmpty
        ? 'NONE_SELECTED'
        : jsonEncode(selectedSoundEffects);
    final transJson = selectedTransitions.isEmpty
        ? 'NONE_SELECTED'
        : jsonEncode(selectedTransitions);

    template = template
        .replaceAll('{{VIDEO_ID}}', videoId)
        .replaceAll('{{VIDEO_TITLE}}', videoTitle.isEmpty ? 'NOT_PROVIDED' : videoTitle)
        .replaceAll('{{VIDEO_DURATION_SEC}}', videoDurationSec.toString())
        .replaceAll('{{MIN_CLIP_SEC}}', minClipSec.toString())
        .replaceAll('{{MAX_CLIP_SEC}}', maxClipSec.toString())
        .replaceAll('{{MIN_SILENCE_SEC}}', minSilenceSec.toStringAsFixed(1))
        .replaceAll('{{SHOW_CONTEXT}}', showContext)
        .replaceAll('{{SELECTED_VISUAL_EFFECTS}}', visualJson)
        .replaceAll('{{SELECTED_SOUND_EFFECTS}}', soundJson)
        .replaceAll('{{SELECTED_TRANSITIONS}}', transJson);

    return template;
  }

  /// Saves the fully-filled master prompt to %LOCALAPPDATA%\clipit\prompts\chatgptprompt.txt
  /// and also to the project root directory and executable directory as chatgptprompt.txt.
  Future<void> saveMasterPromptToDisk(String filledPrompt) async {
    try {
      final appSupport = await getApplicationSupportDirectory();
      final promptsDir = Directory(p.join(appSupport.path, '..', 'clipit', 'prompts'));
      await promptsDir.create(recursive: true);
      final file = File(p.join(promptsDir.path, 'chatgptprompt.txt'));
      await file.writeAsString(filledPrompt);
      debugPrint('[PromptService] Saved to app data: ${file.path}');
    } catch (e) {
      debugPrint('[PromptService] Could not save to app data: $e');
    }

    // Also save directly into project folder so it's readily accessible
    try {
      final projectPromptFile = File(p.join(Directory.current.path, 'chatgptprompt.txt'));
      await projectPromptFile.writeAsString(filledPrompt);
      debugPrint('[PromptService] Saved to project folder: ${projectPromptFile.path}');
    } catch (_) {}

    // Also save alongside executable
    try {
      final exePromptFile = File(p.join(p.dirname(Platform.resolvedExecutable), 'chatgptprompt.txt'));
      await exePromptFile.writeAsString(filledPrompt);
      debugPrint('[PromptService] Saved alongside executable: ${exePromptFile.path}');
    } catch (_) {}

    // Also save directly into C:\Users\Dell\Desktop\CLIP-IT
    try {
      final hardcodedPromptFile = File(r'C:\Users\Dell\Desktop\CLIP-IT\chatgptprompt.txt');
      await hardcodedPromptFile.writeAsString(filledPrompt);
    } catch (_) {}
  }

  // ── Chunk Math (Part 6 of templates file) ─────────────────────────────────

  /// Splits video duration into chunks and computes owned ranges.
  /// Returns list of [ChunkData].
  List<ChunkData> computeChunks({
    required int videoDurationSec,
    required String videoId,
  }) {
    final effectiveDuration = videoDurationSec <= 0 ? 60 : videoDurationSec;
    final chunks = <ChunkData>[];
    int chunkIndex = 0;
    int chunkStart = 0;

    while (chunkStart < effectiveDuration) {
      final chunkEnd = (chunkStart + _chunkDurationSec + _overlapSec)
          .clamp(0, effectiveDuration)
          .toInt();

      final prevChunkEnd = chunkIndex == 0
          ? null
          : ((chunkStart - _chunkDurationSec + _overlapSec)
              .clamp(0, effectiveDuration)
              .toInt());

      final nextChunkStart = chunkEnd < effectiveDuration
          ? (chunkStart + _chunkDurationSec)
          : null;

      // Owned range: midpoints of overlap with prev/next
      final ownedFrom = chunkIndex == 0
          ? 0
          : (prevChunkEnd != null
              ? ((chunkStart + prevChunkEnd) / 2).round()
              : chunkStart);

      final ownedUntil = nextChunkStart == null
          ? effectiveDuration
          : ((nextChunkStart + chunkEnd) / 2).round();

      final overlapPrev = chunkIndex == 0
          ? 'NONE'
          : '${chunkStart.toStringAsFixed(1)} to ${prevChunkEnd?.toStringAsFixed(1)}';

      final overlapNext = nextChunkStart == null
          ? 'NONE'
          : '${nextChunkStart.toStringAsFixed(1)} to ${chunkEnd.toStringAsFixed(1)}';

      chunks.add(ChunkData(
        chunkId: 'chunk_${(chunkIndex + 1).toString().padLeft(3, '0')}',
        chunkIndex: chunkIndex + 1,
        totalChunks: -1, // filled after loop
        startSec: chunkStart.toDouble(),
        endSec: chunkEnd.toDouble(),
        overlapPrev: overlapPrev,
        overlapNext: overlapNext,
        ownedStartFrom: ownedFrom.toDouble(),
        ownedStartUntil: ownedUntil.toDouble(),
        clipIdPrefix: 'clip_${(chunkIndex + 1).toString().padLeft(3, '0')}_',
        videoId: videoId,
      ));

      chunkStart += _chunkDurationSec;
      chunkIndex++;

      if (chunkEnd >= effectiveDuration) break;
    }

    // Back-fill totalChunks
    for (final c in chunks) {
      c.totalChunks = chunks.length;
    }

    return chunks;
  }

  // ── Chunk Message Builder (Part 2) ────────────────────────────────────────

  /// Formats word-level or segment-level transcript lines into natural,
  /// continuous plain-text paragraphs without timestamps or bracketed tags.
  /// Paragraphs are created when there is a significant speech pause (>= 1.8s)
  /// or when a sentence ends after accumulating a good number of words.
  /// This drastically reduces token consumption for AI prompts while keeping
  /// the verbatim text intact for alignment against the audio timestamps.
  String formatTranscriptAsParagraphs(List<TranscriptLine> lines) {
    if (lines.isEmpty) return '';

    final paragraphs = <String>[];
    final currentWords = <String>[];
    double lastEnd = -1.0;

    for (final line in lines) {
      final cleanText = line.text.trim();
      if (cleanText.isEmpty) continue;

      // Natural pause check between spoken lines/words
      final isLongPause = (lastEnd >= 0.0) && ((line.startSec - lastEnd) >= 1.8);

      // Sentence boundary check once enough words have accumulated in paragraph
      final endsSentence = RegExp(r'[.?!।]$').hasMatch(cleanText);
      final hasEnoughWords = currentWords.length >= 65;

      if (isLongPause || (hasEnoughWords && endsSentence)) {
        if (currentWords.isNotEmpty) {
          paragraphs.add(currentWords.join(' '));
          currentWords.clear();
        }
      }

      currentWords.add(cleanText);
      lastEnd = line.endSec;
    }

    if (currentWords.isNotEmpty) {
      paragraphs.add(currentWords.join(' '));
    }

    return paragraphs.join('\n\n');
  }

  String buildChunkMessage({
    required ChunkData chunk,
    required List<TranscriptLine> chunkTranscript,
    required List<SilenceInterval> chunkSilences,
  }) {
    // Formats plain text paragraphs without timestamps behind words to conserve AI credits/tokens
    final transcriptText = formatTranscriptAsParagraphs(chunkTranscript);

    return '''[CHUNK_DATA]
video_id: ${chunk.videoId}
chunk_id: ${chunk.chunkId}
chunk_index: ${chunk.chunkIndex} of ${chunk.totalChunks}
chunk_range_sec: ${chunk.startSec.toStringAsFixed(1)} to ${chunk.endSec.toStringAsFixed(1)}
overlap_with_previous_sec: ${chunk.overlapPrev}
overlap_with_next_sec: ${chunk.overlapNext}
owned_clip_start_range_sec: ${chunk.ownedStartFrom.toStringAsFixed(1)} to ${chunk.ownedStartUntil.toStringAsFixed(1)}
clip_id_prefix: ${chunk.clipIdPrefix}
[TRANSCRIPT]
$transcriptText
[/TRANSCRIPT]
[/CHUNK_DATA]

Reply with the Stage 1 JSON object only.''';
  }

  // ── Validation Message Builder (Part 3) ───────────────────────────────────

  String buildValidationMessage({
    required String videoId,
    required String validationId,
    required int validationRound,
    required int maxRounds,
    required List<PipelineClip> clips,
    required List<TranscriptLine> fullTranscript,
    required List<SilenceInterval> silences,
  }) {
    final clipBlocks = clips.map((clip) {
      final windowStart = (clip.startSec - 120).clamp(0, double.infinity);
      final windowEnd = clip.endSec + 120;

      final windowLines = fullTranscript
          .where((l) => l.endSec >= windowStart && l.startSec <= windowEnd)
          .map((l) => l.toFormattedLine())
          .join('\n');

      final windowSilences = silences
          .where((s) => s.endSec >= windowStart && s.startSec <= windowEnd)
          .toList();

      final silenceJson = windowSilences.isEmpty
          ? 'NONE_PROVIDED'
          : jsonEncode(windowSilences.map((s) => s.toJson()).toList());

      final clipJson = jsonEncode({
        'id': clip.id,
        'start_sec': clip.startSec,
        'end_sec': clip.endSec,
        'hook_title': clip.hookTitle,
        'viral_score': clip.viralScore,
        'virality_reason': clip.viralityReason,
        'suggested_caption': clip.suggestedCaption,
      });

      return '''[CLIP_TO_VALIDATE]
clip: $clipJson
window_range_sec: $windowStart to $windowEnd
[SILENCE_INTERVALS]
$silenceJson
[/SILENCE_INTERVALS]
[TRANSCRIPT_WINDOW]
$windowLines
[/TRANSCRIPT_WINDOW]
[/CLIP_TO_VALIDATE]''';
    }).join('\n\n');

    return '''[VALIDATION_DATA]
video_id: $videoId
validation_id: $validationId
validation_round: $validationRound of $maxRounds
$clipBlocks
[VALIDATION_CONTEXT]
NONE
[/VALIDATION_CONTEXT]
[/VALIDATION_DATA]

Reply with the Stage 2 JSON object only.''';
  }

  // ── AI Edit Planner Message ────────────────────────────────────────────────
  // IMPORTANT: Only permanent clips. Only selected effects. Never full catalogue.

  String buildEditPlannerMessage({
    required List<PipelineClip> permanentClips,
    required List<TranscriptLine> fullTranscript,
    required List<SilenceInterval> silences,
    required List<Map<String, dynamic>> selectedVisualEffects,
    required List<Map<String, dynamic>> selectedSoundEffects,
    required List<Map<String, dynamic>> selectedTransitions,
  }) {
    final clipsJson = jsonEncode(permanentClips.map((c) => {
          'id': c.id,
          'start_sec': c.startSec,
          'end_sec': c.endSec,
          'hook_title': c.hookTitle,
          'viral_score': c.viralScore,
          'transcript': fullTranscript
              .where((l) => l.endSec >= c.startSec && l.startSec <= c.endSec)
              .map((l) => l.toFormattedLine())
              .join('\n'),
          'silence_intervals': silences
              .where((s) => s.endSec >= c.startSec && s.startSec <= c.endSec)
              .map((s) => s.toJson())
              .toList(),
        }).toList());

    final visualJson = selectedVisualEffects.isEmpty
        ? 'NONE_SELECTED'
        : jsonEncode(selectedVisualEffects);
    final soundJson = selectedSoundEffects.isEmpty
        ? 'NONE_SELECTED'
        : jsonEncode(selectedSoundEffects);
    final transJson = selectedTransitions.isEmpty
        ? 'NONE_SELECTED'
        : jsonEncode(selectedTransitions);

    return '''[EDIT_PLANNER_DATA]
permanent_clips: $clipsJson
selected_visual_effects: $visualJson
selected_sound_effects: $soundJson
selected_transitions: $transJson
[/EDIT_PLANNER_DATA]

CRITICAL EDITING DIRECTIVE:
Only add effects if you think they are relevant and genuinely enhance the moment.
Do NOT force effects onto clips where they do not improve the content.
Return empty effect arrays when nothing fits or if the clip works best clean.
Evaluate each permanent clip and recommend effects from ONLY the supplied catalogues.
Return effect_ids exactly as provided.
Reply with the Stage 3 (Edit Plan) JSON object only.''';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chunk data value object
// ─────────────────────────────────────────────────────────────────────────────
class ChunkData {
  ChunkData({
    required this.chunkId,
    required this.chunkIndex,
    required this.totalChunks,
    required this.startSec,
    required this.endSec,
    required this.overlapPrev,
    required this.overlapNext,
    required this.ownedStartFrom,
    required this.ownedStartUntil,
    required this.clipIdPrefix,
    required this.videoId,
  });

  final String chunkId;
  final int chunkIndex;
  int totalChunks; // mutable — back-filled after all chunks computed
  final double startSec;
  final double endSec;
  final String overlapPrev;
  final String overlapNext;
  final double ownedStartFrom;
  final double ownedStartUntil;
  final String clipIdPrefix;
  final String videoId;
}
