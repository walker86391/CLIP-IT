import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/services/ffmpeg_service.dart';
import '../../../core/utils/app_logger.dart';
import '../models/subtitle_models.dart';

/// A contiguous voice activity speech interval in seconds (relative to clip start).
class SpeechInterval {
  const SpeechInterval({
    required this.startSec,
    required this.endSec,
  });

  final double startSec;
  final double endSec;

  double get durationSec => math.max(0.05, endSec - startSec);
  int get startMs => (startSec * 1000).round();
  int get endMs => (endSec * 1000).round();
}

/// A speech utterance containing synchronized words bounded by voice activity.
/// When the utterance finishes, subtitles disappear completely until the next utterance.
class SpeechUtterance {
  const SpeechUtterance({
    required this.startMs,
    required this.endMs,
    required this.words,
  });

  final int startMs;
  final int endMs;
  final List<TimedWord> words;

  int get durationMs => math.max(50, endMs - startMs);
  String get text => words.map((w) => w.text).join(' ');
}

/// High-precision Voice Activity Detection (VAD) and pause-aware subtitle aligner.
/// Guarantees that subtitles appear ONLY when speech is present and vanish during pauses.
class SpeechAlignerService {
  SpeechAlignerService._();
  static final SpeechAlignerService instance = SpeechAlignerService._();

  /// Analyzes a 16kHz mono WAV file's raw PCM samples and extracts speech intervals (seconds),
  /// skipping all silences and pauses.
  List<SpeechInterval> detectSpeechIntervalsFromWav(Uint8List wavBytes) {
    if (wavBytes.lengthInBytes <= 44) return [];

    // Skip 44-byte standard RIFF WAV header to read 16-bit signed PCM samples
    final pcm = wavBytes.buffer.asInt16List(44, (wavBytes.lengthInBytes - 44) ~/ 2);
    const frameLen = 320; // 20ms frames at 16kHz
    final numFrames = pcm.length ~/ frameLen;
    if (numFrames == 0) return [];

    // Calculate RMS energy per 20ms frame
    final energies = <double>[];
    for (int f = 0; f < numFrames; f++) {
      double sum = 0.0;
      final base = f * frameLen;
      for (int i = 0; i < frameLen; i++) {
        final s = pcm[base + i] / 32768.0;
        sum += s * s;
      }
      energies.add(math.sqrt(sum / frameLen));
    }

    // Adaptive noise floor and thresholding
    final sorted = List<double>.from(energies)..sort();
    final noiseFloor = sorted[(sorted.length * 0.15).round()];
    final thresh = math.max(0.012, noiseFloor * 2.5);

    const minGapFrames = 13; // ~260ms pause to treat as distinct silence
    const minSpeechFrames = 7; // ~140ms minimum speech utterance

    final blocks = <SpeechInterval>[];
    bool inBlock = false;
    int startIdx = 0;

    for (int i = 0; i < numFrames; i++) {
      final active = energies[i] >= thresh;
      if (active && !inBlock) {
        inBlock = true;
        startIdx = i;
      } else if (!active && inBlock) {
        // Look ahead: bridge short intra-word gaps (< 260ms)
        bool hasFuture = false;
        final maxLook = math.min(numFrames, i + minGapFrames);
        for (int k = i; k < maxLook; k++) {
          if (energies[k] >= thresh) {
            hasFuture = true;
            break;
          }
        }
        if (hasFuture) continue;

        inBlock = false;
        if ((i - startIdx) >= minSpeechFrames) {
          blocks.add(SpeechInterval(
            startSec: startIdx * 0.02,
            endSec: i * 0.02,
          ));
        }
      }
    }
    if (inBlock && (numFrames - startIdx) >= minSpeechFrames) {
      blocks.add(SpeechInterval(
        startSec: startIdx * 0.02,
        endSec: numFrames * 0.02,
      ));
    }

    return blocks;
  }

  /// Extracts 16kHz mono WAV from source video for a clip and detects speech intervals.
  Future<List<SpeechInterval>> extractAndDetectClipSpeech({
    required String videoPath,
    required double startSec,
    required double durationSec,
    required String tempDir,
  }) async {
    final wavPath = p.join(tempDir, 'clip_audio_${startSec.toStringAsFixed(1)}.wav');
    try {
      final args = [
        '-y',
        '-ss',
        startSec.toStringAsFixed(3),
        '-i',
        videoPath,
        '-t',
        durationSec.toStringAsFixed(3),
        '-vn',
        '-ac',
        '1',
        '-ar',
        '16000',
        wavPath,
      ];
      final res = await FfmpegService.instance.runFfmpeg(args);
      if (res.exitCode == 0 && File(wavPath).existsSync()) {
        final bytes = await File(wavPath).readAsBytes();
        final intervals = detectSpeechIntervalsFromWav(bytes);
        try {
          File(wavPath).deleteSync();
        } catch (_) {}
        if (intervals.isNotEmpty) {
          return intervals;
        }
      }
    } catch (e) {
      AppLog.w('[SpeechAligner] Audio extraction notice: $e');
    }

    // Fallback if audio extraction fails: single utterance covering the duration with margin
    return [
      SpeechInterval(startSec: 0.2, endSec: math.max(0.5, durationSec - 0.2)),
    ];
  }

  /// Aligns script tokens to the detected speech intervals with phonetic weighting.
  /// Splits words at sentence boundaries (?, !, .) and pauses so words only exist during speech.
  List<SpeechUtterance> alignWordsToIntervals({
    required List<String> rawTokens,
    required List<SpeechInterval> intervals,
  }) {
    if (rawTokens.isEmpty || intervals.isEmpty) return [];

    // Merge very close speech intervals (< 300ms gap) into logical phrase blocks
    final mergedIntervals = <SpeechInterval>[];
    SpeechInterval current = intervals.first;
    for (int i = 1; i < intervals.length; i++) {
      final next = intervals[i];
      if ((next.startSec - current.endSec) < 0.35) {
        current = SpeechInterval(startSec: current.startSec, endSec: next.endSec);
      } else {
        mergedIntervals.add(current);
        current = next;
      }
    }
    mergedIntervals.add(current);

    // Group raw tokens by sentence punctuation or natural chunk sizes (3-6 words)
    final tokenGroups = <List<String>>[];
    var currentGroup = <String>[];
    for (final token in rawTokens) {
      currentGroup.add(token);
      final endsSentence = token.endsWith('?') ||
          token.endsWith('!') ||
          token.endsWith('.') ||
          token.endsWith('।');
      if (endsSentence || currentGroup.length >= 6) {
        tokenGroups.add(currentGroup);
        currentGroup = [];
      }
    }
    if (currentGroup.isNotEmpty) {
      tokenGroups.add(currentGroup);
    }

    // Map token groups to speech intervals
    final utterances = <SpeechUtterance>[];
    final numBlocks = mergedIntervals.length;
    final numGroups = tokenGroups.length;

    for (int b = 0; b < numBlocks; b++) {
      final interval = mergedIntervals[b];
      final gStart = (b * numGroups) ~/ numBlocks;
      final gEnd = ((b + 1) * numGroups) ~/ numBlocks;
      final assignedTokens = <String>[];
      for (int g = gStart; g < gEnd; g++) {
        assignedTokens.addAll(tokenGroups[g]);
      }
      if (assignedTokens.isEmpty) {
        // If groups are fewer than intervals, distribute words
        final wStart = (b * rawTokens.length) ~/ numBlocks;
        final wEnd = ((b + 1) * rawTokens.length) ~/ numBlocks;
        assignedTokens.addAll(rawTokens.sublist(wStart, math.min(wEnd, rawTokens.length)));
      }
      if (assignedTokens.isEmpty) continue;

      // Assign phonetic weights (character count of cleaned word)
      final weights = assignedTokens.map((t) => math.max(2, t.replaceAll(RegExp(r'[^\w]'), '').length)).toList();
      final totalWeight = weights.fold<int>(0, (sum, w) => sum + w);
      final intervalDurMs = interval.endMs - interval.startMs;

      final timedWords = <TimedWord>[];
      double curMs = interval.startMs.toDouble();

      for (int i = 0; i < assignedTokens.length; i++) {
        final w = assignedTokens[i];
        final durMs = totalWeight > 0
            ? (intervalDurMs * (weights[i] / totalWeight))
            : (intervalDurMs / assignedTokens.length);
        final wStart = curMs.round();
        final wEnd = (i == assignedTokens.length - 1) ? interval.endMs : (curMs + durMs).round();
        curMs += durMs;

        timedWords.add(TimedWord(
          text: w,
          startTimeMs: wStart,
          endTimeMs: math.max(wStart + 30, wEnd),
        ));
      }

      utterances.add(SpeechUtterance(
        startMs: interval.startMs,
        endMs: interval.endMs,
        words: timedWords,
      ));
    }

    return utterances;
  }

  /// Generates a Word-by-Word ASS karaoke script where every dialogue event
  /// ENDS when speech stops. During pauses, no subtitles are displayed.
  String generatePauseAwareWordByWordAss({
    required List<SpeechUtterance> utterances,
    int videoWidth = 1080,
    int videoHeight = 1920,
    String fontFamily = 'Arial',
    double fontSize = 64,
    Color normalTextColor = Colors.white,
    Color activeWordHighlightColor = const Color(0xFFFFD700), // Vibrant gold
    Color outlineColor = Colors.black,
    int marginV = 360,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('[Script Info]');
    buffer.writeln('Title: ClipIt Pause-Aware Motion Typography');
    buffer.writeln('ScriptType: v4.00+');
    buffer.writeln('PlayResX: $videoWidth');
    buffer.writeln('PlayResY: $videoHeight');
    buffer.writeln('ScaledBorderAndShadow: yes');
    buffer.writeln('YCbCr Matrix: TV.709');
    buffer.writeln();

    String assColor(int argb) {
      final a = (argb >> 24) & 0xFF;
      final r = (argb >> 16) & 0xFF;
      final g = (argb >> 8) & 0xFF;
      final b = argb & 0xFF;
      final assA = (255 - a).toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexB = b.toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexG = g.toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexR = r.toRadixString(16).padLeft(2, '0').toUpperCase();
      return '&H$assA$hexB$hexG$hexR';
    }

    final primaryHighlight = assColor(activeWordHighlightColor.toARGB32());
    final secondaryNormal = assColor(normalTextColor.toARGB32());
    final outline = assColor(outlineColor.toARGB32());
    const shadow = '&H80000000';

    buffer.writeln('[V4+ Styles]');
    buffer.writeln(
        'Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding');
    buffer.writeln(
      'Style: Default,$fontFamily,${fontSize.round()},'
      '$primaryHighlight,$secondaryNormal,$outline,$shadow,'
      '-1,0,0,0,100,100,0,0,1,4.0,1.8,2,30,30,$marginV,1',
    );
    buffer.writeln();
    buffer.writeln('[Events]');
    buffer.writeln('Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text');

    String formatTime(int ms) {
      final clamped = math.max(0, ms);
      final hours = clamped ~/ 3600000;
      final mins = (clamped % 3600000) ~/ 60000;
      final secs = (clamped % 60000) ~/ 1000;
      final cs = (clamped % 1000) ~/ 10;
      return '$hours:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
    }

    for (final utt in utterances) {
      if (utt.words.isEmpty) continue;

      // If an utterance has more than 6 words, split into readable lines within this utterance's window
      const maxPerLine = 5;
      final words = utt.words;
      for (int i = 0; i < words.length; i += maxPerLine) {
        final endIdx = math.min(words.length, i + maxPerLine);
        final lineWords = words.sublist(i, endIdx);
        final lineStart = lineWords.first.startTimeMs;
        final lineEnd = lineWords.last.endTimeMs;

        final lineBuf = StringBuffer();
        for (final w in lineWords) {
          final durCs = math.max(1, w.duration.inMilliseconds ~/ 10);
          lineBuf.write(r'{\k' '$durCs}${w.text} ');
        }

        buffer.writeln(
          'Dialogue: 0,${formatTime(lineStart)},${formatTime(lineEnd)},Default,,0,0,0,,${lineBuf.toString().trim()}',
        );
      }
    }

    return buffer.toString();
  }

  /// Generates a Normal clean subtitle ASS script where dialogue events start
  /// and end strictly with speech. During pauses, no subtitles are displayed.
  String generatePauseAwareNormalAss({
    required List<SpeechUtterance> utterances,
    int videoWidth = 1080,
    int videoHeight = 1920,
    String fontFamily = 'Arial',
    double fontSize = 58,
    Color textColor = Colors.white,
    Color outlineColor = Colors.black,
    int marginV = 360,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('[Script Info]');
    buffer.writeln('Title: ClipIt Clean Pause-Aware Subtitles');
    buffer.writeln('ScriptType: v4.00+');
    buffer.writeln('PlayResX: $videoWidth');
    buffer.writeln('PlayResY: $videoHeight');
    buffer.writeln('ScaledBorderAndShadow: yes');
    buffer.writeln('YCbCr Matrix: TV.709');
    buffer.writeln();

    String assColor(int argb) {
      final a = (argb >> 24) & 0xFF;
      final r = (argb >> 16) & 0xFF;
      final g = (argb >> 8) & 0xFF;
      final b = argb & 0xFF;
      final assA = (255 - a).toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexB = b.toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexG = g.toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexR = r.toRadixString(16).padLeft(2, '0').toUpperCase();
      return '&H$assA$hexB$hexG$hexR';
    }

    final primary = assColor(textColor.toARGB32());
    final outline = assColor(outlineColor.toARGB32());
    const shadow = '&H80000000';

    buffer.writeln('[V4+ Styles]');
    buffer.writeln(
        'Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding');
    buffer.writeln(
      'Style: Default,$fontFamily,${fontSize.round()},'
      '$primary,$primary,$outline,$shadow,'
      '-1,0,0,0,100,100,0,0,1,4.0,1.8,2,30,30,$marginV,1',
    );
    buffer.writeln();
    buffer.writeln('[Events]');
    buffer.writeln('Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text');

    String formatTime(int ms) {
      final clamped = math.max(0, ms);
      final hours = clamped ~/ 3600000;
      final mins = (clamped % 3600000) ~/ 60000;
      final secs = (clamped % 60000) ~/ 1000;
      final cs = (clamped % 1000) ~/ 10;
      return '$hours:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
    }

    for (final utt in utterances) {
      if (utt.words.isEmpty) continue;

      const maxPerLine = 5;
      final words = utt.words;
      for (int i = 0; i < words.length; i += maxPerLine) {
        final endIdx = math.min(words.length, i + maxPerLine);
        final lineWords = words.sublist(i, endIdx);
        final lineStart = lineWords.first.startTimeMs;
        final lineEnd = lineWords.last.endTimeMs;
        final lineText = lineWords.map((w) => w.text).join(' ');

        buffer.writeln(
          'Dialogue: 0,${formatTime(lineStart)},${formatTime(lineEnd)},Default,,0,0,0,,$lineText',
        );
      }
    }

    return buffer.toString();
  }

  /// Groups a list of timestamped words directly from transcription into readable
  /// subtitle lines (1 line displayed together at a time, or at max 2-3 lines).
  /// Breaks on sentence punctuation, natural speech pauses (gap >= 350ms), or max word count.
  List<SubtitleDisplayLine> groupTimedWordsIntoLines(
    List<TimedWord> words, {
    int maxWordsPerLine = 5,
    int pauseThresholdMs = 350,
  }) {
    final lines = <SubtitleDisplayLine>[];
    if (words.isEmpty) return lines;

    List<TimedWord> currentWords = [];

    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      currentWords.add(w);

      final text = w.text.trim();
      final isPunctuationEnd = text.endsWith('?') ||
          text.endsWith('!') ||
          text.endsWith('.') ||
          text.endsWith(';');

      bool isPauseNext = false;
      if (i < words.length - 1) {
        final gap = words[i + 1].startTimeMs - w.endTimeMs;
        if (gap >= pauseThresholdMs) {
          isPauseNext = true;
        }
      }

      final isMaxWords = currentWords.length >= maxWordsPerLine;
      final isLast = i == words.length - 1;

      if (isPunctuationEnd || isPauseNext || isMaxWords || isLast) {
        if (currentWords.isNotEmpty) {
          lines.add(SubtitleDisplayLine(
            words: List.from(currentWords),
            startMs: currentWords.first.startTimeMs,
            endMs: currentWords.last.endTimeMs,
          ));
          currentWords.clear();
        }
      }
    }

    return lines;
  }

  /// Generates viral Word-by-Word ASS subtitles from exact timestamped transcript lines.
  /// The full line is displayed together on screen, and as each word is spoken,
  /// that word is highlighted with dynamic scale pop and semantic color pops.
  String generateTimedWordsWordByWordAss({
    required List<SubtitleDisplayLine> lines,
    int videoWidth = 1080,
    int videoHeight = 1920,
    String fontFamily = 'Impact',
    double fontSize = 78,
    Color activeWordHighlightColor = const Color(0xFF00FFFF),
    Color normalTextColor = const Color(0xFFD8D8D8),
    Color outlineColor = Colors.black,
    int marginV = 420,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('[Script Info]');
    buffer.writeln('Title: ClipIt Word By Word Speaking Typography');
    buffer.writeln('ScriptType: v4.00+');
    buffer.writeln('PlayResX: $videoWidth');
    buffer.writeln('PlayResY: $videoHeight');
    buffer.writeln('ScaledBorderAndShadow: yes');
    buffer.writeln('YCbCr Matrix: TV.709');
    buffer.writeln();

    String assColor(int argb) {
      final a = (argb >> 24) & 0xFF;
      final r = (argb >> 16) & 0xFF;
      final g = (argb >> 8) & 0xFF;
      final b = argb & 0xFF;
      final assA = (255 - a).toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexB = b.toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexG = g.toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexR = r.toRadixString(16).padLeft(2, '0').toUpperCase();
      return '&H$assA$hexB$hexG$hexR';
    }

    final primaryWhite = assColor(normalTextColor.toARGB32());
    final highlightYellow = assColor(activeWordHighlightColor.toARGB32());
    final outline = assColor(outlineColor.toARGB32());
    const shadow = '&H90000000';

    buffer.writeln('[V4+ Styles]');
    buffer.writeln(
        'Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding');
    buffer.writeln(
      'Style: Default,$fontFamily,${fontSize.round()},'
      '$primaryWhite,$highlightYellow,$outline,$shadow,'
      '-1,0,0,0,100,100,1,0,1,6.5,3.0,2,40,40,$marginV,1',
    );
    buffer.writeln();
    buffer.writeln('[Events]');
    buffer.writeln('Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text');

    String formatTime(int ms) {
      final clamped = math.max(0, ms);
      final hours = clamped ~/ 3600000;
      final mins = (clamped % 3600000) ~/ 60000;
      final secs = (clamped % 60000) ~/ 1000;
      final cs = (clamped % 1000) ~/ 10;
      return '$hours:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
    }

    (String color, int scale) getWordStyle(String rawWord) {
      final clean = rawWord.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      // Money / Free / Win keywords: Vibrant Lime Green
      if (['FREE', 'WIN', 'CASH', 'OFF', 'CRORE', 'LAKH', 'MONEY', 'SALE', 'DISCOUNT'].contains(clean)) {
        return ('&H0022FF00&', 126);
      }
      // Punchline / Climax keywords: Aggressive Fiery Crimson
      if (['CHEAP', 'KILL', 'DEAD', 'DIE', 'SHOCK', 'SCAM', 'LOOT', 'FAIL', 'BUST'].contains(clean)) {
        return ('&H000045FF&', 132);
      }
      // Hook / Exclamation keywords: Fiery Gold
      if (['WELCOME', 'WHAT', 'WHY', 'HOW', 'WAIT', 'OMG', 'HEY', 'NO'].contains(clean) || rawWord.contains('!')) {
        return ('&H0000A5FF&', 128);
      }
      // Default spoken word: Electric Neon Yellow
      return ('&H0000FFFF&', 120);
    }

    String renderFormattedLine(List<TimedWord> words, {int? activeIdx}) {
      final formatted = <String>[];
      for (int i = 0; i < words.length; i++) {
        final w = words[i].text.toUpperCase();
        if (i == activeIdx) {
          final style = getWordStyle(w);
          formatted.add('{\\c${style.$1}\\fscx${style.$2}\\fscy${style.$2}\\b1}$w{\\c&H00D8D8D8&\\fscx100\\fscy100\\b0}');
        } else {
          formatted.add(w);
        }
      }
      if (formatted.length >= 7) {
        final splitAt = formatted.length ~/ 2;
        return '${formatted.sublist(0, splitAt).join(' ')}\\N${formatted.sublist(splitAt).join(' ')}';
      }
      return formatted.join(' ');
    }

    for (final line in lines) {
      if (line.words.isEmpty) continue;

      // 1. Pre-speech lead-in if line starts slightly before first word
      final firstStart = line.words.first.startTimeMs;
      if (firstStart > line.startMs) {
        final neutralLead = renderFormattedLine(line.words, activeIdx: null);
        buffer.writeln(
          'Dialogue: 0,${formatTime(line.startMs)},${formatTime(firstStart)},Default,,0,0,0,,$neutralLead',
        );
      }

      // 2. Active word highlights and intra-line pauses
      for (int wi = 0; wi < line.words.length; wi++) {
        final activeWord = line.words[wi];
        final wStart = activeWord.startTimeMs;
        final wEnd = activeWord.endTimeMs;
        if (wEnd <= wStart) continue;

        final activeText = renderFormattedLine(line.words, activeIdx: wi);
        buffer.writeln(
          'Dialogue: 0,${formatTime(wStart)},${formatTime(wEnd)},Default,,0,0,0,,$activeText',
        );

        // Check for gap before next word (e.g. comedic pause)
        if (wi < line.words.length - 1) {
          final nextStart = line.words[wi + 1].startTimeMs;
          if (nextStart > wEnd + 80) {
            final neutralPause = renderFormattedLine(line.words, activeIdx: null);
            buffer.writeln(
              'Dialogue: 0,${formatTime(wEnd)},${formatTime(nextStart)},Default,,0,0,0,,$neutralPause',
            );
          }
        }
      }

      // 3. Post-speech line hold if speech finishes before line disappearance
      final lastEnd = line.words.last.endTimeMs;
      if (line.endMs > lastEnd + 60) {
        final neutralHold = renderFormattedLine(line.words, activeIdx: null);
        buffer.writeln(
          'Dialogue: 0,${formatTime(lastEnd)},${formatTime(line.endMs)},Default,,0,0,0,,$neutralHold',
        );
      }
    }

    return buffer.toString();
  }

  /// Generates clean Normal ASS subtitles from exact timestamped transcript lines.
  /// Displays one line together on screen strictly during speech, clearing during pauses.
  String generateTimedWordsNormalAss({
    required List<SubtitleDisplayLine> lines,
    int videoWidth = 1080,
    int videoHeight = 1920,
    String fontFamily = 'Impact',
    double fontSize = 68,
    Color textColor = Colors.white,
    Color outlineColor = Colors.black,
    int marginV = 420,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('[Script Info]');
    buffer.writeln('Title: ClipIt Clean Spoken Subtitles');
    buffer.writeln('ScriptType: v4.00+');
    buffer.writeln('PlayResX: $videoWidth');
    buffer.writeln('PlayResY: $videoHeight');
    buffer.writeln('ScaledBorderAndShadow: yes');
    buffer.writeln('YCbCr Matrix: TV.709');
    buffer.writeln();

    String assColor(int argb) {
      final a = (argb >> 24) & 0xFF;
      final r = (argb >> 16) & 0xFF;
      final g = (argb >> 8) & 0xFF;
      final b = argb & 0xFF;
      final assA = (255 - a).toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexB = b.toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexG = g.toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexR = r.toRadixString(16).padLeft(2, '0').toUpperCase();
      return '&H$assA$hexB$hexG$hexR';
    }

    final primary = assColor(textColor.toARGB32());
    final outline = assColor(outlineColor.toARGB32());
    const shadow = '&H90000000';

    buffer.writeln('[V4+ Styles]');
    buffer.writeln(
        'Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding');
    buffer.writeln(
      'Style: Default,$fontFamily,${fontSize.round()},'
      '$primary,$primary,$outline,$shadow,'
      '-1,0,0,0,100,100,1,0,1,5.5,2.5,2,40,40,$marginV,1',
    );
    buffer.writeln();
    buffer.writeln('[Events]');
    buffer.writeln('Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text');

    String formatTime(int ms) {
      final clamped = math.max(0, ms);
      final hours = clamped ~/ 3600000;
      final mins = (clamped % 3600000) ~/ 60000;
      final secs = (clamped % 60000) ~/ 1000;
      final cs = (clamped % 1000) ~/ 10;
      return '$hours:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
    }

    for (final line in lines) {
      if (line.words.isEmpty) continue;
      final words = line.words.map((w) => w.text.toUpperCase()).toList();
      String text;
      if (words.length >= 7) {
        final splitAt = words.length ~/ 2;
        text = '${words.sublist(0, splitAt).join(' ')}\\N${words.sublist(splitAt).join(' ')}';
      } else {
        text = words.join(' ');
      }
      buffer.writeln(
        'Dialogue: 0,${formatTime(line.startMs)},${formatTime(line.endMs)},Default,,0,0,0,,$text',
      );
    }

    return buffer.toString();
  }
}

/// A grouped line of subtitle words displayed together on screen.
class SubtitleDisplayLine {
  const SubtitleDisplayLine({
    required this.words,
    required this.startMs,
    required this.endMs,
  });

  final List<TimedWord> words;
  final int startMs;
  final int endMs;

  int get durationMs => math.max(50, endMs - startMs);
}
