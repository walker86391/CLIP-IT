import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../features/pipeline/models/pipeline_job.dart';
import '../utils/app_logger.dart';
import '../utils/app_path_resolver.dart';

/// Runs whisper-cli.exe (whisper.cpp) with the selected GGUF model to
/// produce a timestamped Hinglish/Roman-Hindi transcript.
///
/// Binary discovery:
///  1. Bundled alongside the app: `&lt;exeDir&gt;/whisper/whisper-cli.exe`
///  2. Development path: `windows/whisper/whisper-cli.exe` (relative to CWD)
class WhisperService {
  WhisperService._();
  static final WhisperService instance = WhisperService._();

  String? _cachedCliPath;

  // ── Devanagari to Roman phonetic map (common words only) ──────────────────
  static const Map<String, String> _devanagariToRoman = {
    'है': 'hai',
    'हैं': 'hain',
    'और': 'aur',
    'में': 'mein',
    'की': 'ki',
    'का': 'ka',
    'के': 'ke',
    'को': 'ko',
    'से': 'se',
    'पर': 'par',
    'भाई': 'bhai',
    'यार': 'yaar',
    'आज': 'aaj',
    'तो': 'toh',
    'बहुत': 'bahut',
    'अच्छा': 'accha',
    'नहीं': 'nahi',
    'हो': 'ho',
    'गया': 'gaya',
    'गए': 'gaye',
    'क्या': 'kya',
    'मैं': 'main',
    'हम': 'hum',
    'तुम': 'tum',
    'वो': 'wo',
    'यह': 'yeh',
    'इस': 'is',
    'उस': 'us',
    'अब': 'ab',
    'जब': 'jab',
    'सब': 'sab',
    'कुछ': 'kuch',
    'बस': 'bas',
    'एक': 'ek',
    'दो': 'do',
    'तीन': 'teen',
    'बड़ा': 'bada',
    'छोटा': 'chota',
    'अरे': 'are',
    'हाँ': 'haan',
    'ना': 'na',
    'मतलब': 'matlab',
    'सच': 'sach',
    'झूठ': 'jhooth',
    'पागल': 'pagal',
    'क्रेज़ी': 'crazy',
  };

  /// Returns the path to whisper-cli.exe, or null if not found.
  Future<String?> getWhisperCliPath() async {
    if (_cachedCliPath != null) return _cachedCliPath;

    final candidates = <String>[];

    // 1. Bundled alongside released executable
    try {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      candidates.add(p.join(exeDir, 'whisper', 'whisper-cli.exe'));
      candidates.add(p.join(exeDir, 'whisper-cli.exe'));
    } catch (_) {}

    // 2. Development path (windows/whisper/ in project root)
    final cwd = Directory.current.path;
    candidates.add(p.join(cwd, 'windows', 'whisper', 'whisper-cli.exe'));

    // 3. Check each candidate
    for (final candidate in candidates) {
      try {
        if (File(candidate).existsSync()) {
          _cachedCliPath = p.canonicalize(candidate);
          AppLog.i('[Whisper] Found whisper-cli at: $_cachedCliPath');
          return _cachedCliPath;
        }
      } catch (_) {}
    }

    AppLog.w('[Whisper] whisper-cli.exe not found in bundled or dev paths.');
    return null;
  }

  /// Transcribes a 16kHz mono WAV file using whisper-cli.
  ///
  /// Returns a list of [TranscriptLine] with ABSOLUTE timestamps (seconds).
  /// If Devanagari is detected in the output, applies phonetic transliteration.
  Future<List<TranscriptLine>> transcribe({
    required String wavPath,
    required String modelPath,
    String language = 'hi',
    void Function(String)? onLog,
  }) async {
    final cliPath = await getWhisperCliPath();
    final modelExists = File(modelPath).existsSync();

    if (cliPath == null || !modelExists) {
      final reason = cliPath == null
          ? 'whisper-cli.exe not bundled at windows/whisper/'
          : 'Whisper model not found at: $modelPath';
      onLog?.call('[Whisper] ERROR: $reason');
      AppLog.e('[Whisper] $reason');
      throw StateError(reason);
    }

    AppLog.i('[Whisper] Starting transcription: $wavPath');
    AppLog.i('[Whisper] Model: $modelPath');

    final args = [
      '-m', modelPath,
      '-f', wavPath,
      '-l', language,
      '--output-txt',
      '--output-vtt',
      '--print-progress',
    ];

    final result = await Process.run(
      cliPath,
      args,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    if (result.exitCode != 0) {
      final err = result.stderr.toString();
      AppLog.e('[Whisper] Exit ${result.exitCode}: $err');
      throw StateError('whisper-cli failed (exit ${result.exitCode}): $err');
    }

    final stdout = result.stdout.toString();
    final stderr = result.stderr.toString();

    // Log progress lines from stderr
    for (final line in stderr.split('\n')) {
      if (line.trim().isNotEmpty) {
        onLog?.call('[whisper] $line');
      }
    }

    AppLog.i('[Whisper] Transcription complete. Parsing output…');
    return _parseWhisperOutput(stdout);
  }

  /// Parses whisper-cli stdout.
  /// Whisper outputs lines like: [00:00:14.250 --> 00:00:18.800]  text
  List<TranscriptLine> _parseWhisperOutput(String raw) {
    final lines = <TranscriptLine>[];
    final regex = RegExp(
      r'\[(\d{2}:\d{2}:\d{2}[.,]\d{3})\s*-->\s*(\d{2}:\d{2}:\d{2}[.,]\d{3})\]\s*(.*)',
    );

    for (final line in raw.split('\n')) {
      final match = regex.firstMatch(line.trim());
      if (match == null) continue;

      final startSec = _parseTimestamp(match.group(1)!);
      final endSec = _parseTimestamp(match.group(2)!);
      var text = match.group(3)!.trim();

      if (text.isEmpty) continue;

      // Apply Hinglish transliteration if Devanagari detected
      text = _transliterateIfNeeded(text);

      lines.add(TranscriptLine(
        startSec: startSec,
        endSec: endSec,
        text: text,
      ));
    }

    AppLog.i('[Whisper] Parsed ${lines.length} transcript segments.');
    return lines;
  }

  /// Converts HH:MM:SS.mmm or HH:MM:SS,mmm to absolute seconds.
  double _parseTimestamp(String ts) {
    final normalized = ts.replaceAll(',', '.');
    final parts = normalized.split(':');
    if (parts.length != 3) return 0.0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final s = double.tryParse(parts[2]) ?? 0.0;
    return (h * 3600) + (m * 60) + s;
  }

  /// Detects Devanagari Unicode characters and replaces known words with
  /// their Roman Hindi equivalents. English tokens are preserved as-is.
  String _transliterateIfNeeded(String text) {
    // Quick Devanagari detection: U+0900–U+097F range
    final hasDevanagari = text.runes.any((r) => r >= 0x0900 && r <= 0x097F);
    if (!hasDevanagari) return text;

    var result = text;
    for (final entry in _devanagariToRoman.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    // Any remaining Devanagari chars: convert to empty (unknown words)
    // Keeps all Latin/English tokens intact
    result = result.replaceAll(
      RegExp(r'[\u0900-\u097F]+'),
      '',
    );

    // Collapse multiple spaces
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    return result;
  }

  /// Discovers the active Python executable path.
  Future<String> _resolvePythonPath() async {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final candidates = [
      if (localAppData.isNotEmpty)
        p.join(localAppData, 'Programs', 'Python', 'Python313', 'python.exe'),
      if (localAppData.isNotEmpty)
        p.join(localAppData, 'Programs', 'Python', 'Python312', 'python.exe'),
      if (localAppData.isNotEmpty)
        p.join(localAppData, 'Programs', 'Python', 'Python311', 'python.exe'),
      'python.exe',
      'python',
    ];

    for (final cand in candidates) {
      try {
        if (File(cand).existsSync()) {
          return cand;
        }
      } catch (_) {}
    }

    return 'python';
  }

  /// Transcribes audio chunks using the Python Whisper-Hindi2Hinglish-Prime runner.
  Future<List<TranscriptLine>?> transcribeWithPrime({
    required List<String> chunkPaths,
    required List<double> chunkOffsets,
    String modelDir = 'models/Whisper-Hindi2Hinglish-Prime',
    String videoLanguage = 'auto',
    String captionLanguage = 'hinglish',
    String outputJson = 'live process/transcription/transcript.json',
    String outputTxt = 'live process/transcription/transcript.txt',
    void Function(int chunkIndex, int chunksTotal, int cumulativeSegments)? onChunkDone,
    void Function(int chunkIndex, int chunksTotal, int chunkPercent, int totalWords, String recentText)? onWindowProgress,
    void Function(String)? onLog,
  }) async {
    final scriptPath = AppPathResolver.resolveTranscribeScript();
    if (scriptPath == null) {
      final msg = '[Whisper Prime] Script transcribe_hinglish.py not found in bundled or project paths.';
      onLog?.call(msg);
      AppLog.e(msg);
      throw StateError(msg);
    }
    final effectiveModelDir = AppPathResolver.resolveModelDir(modelDir);

    final pythonPath = await _resolvePythonPath();
    onLog?.call('[Whisper Prime] Launching Whisper-Hindi2Hinglish-Prime ($pythonPath)…');
    onLog?.call('[Whisper Prime] Script: $scriptPath');
    onLog?.call('[Whisper Prime] Model: $effectiveModelDir');
    onLog?.call('[Whisper Prime] Video Language: $videoLanguage, Target Caption Language: $captionLanguage');

    // Ensure output directories exist
    final jsonDir = Directory(p.dirname(outputJson));
    if (!jsonDir.existsSync()) {
      await jsonDir.create(recursive: true);
    }
    final txtDir = Directory(p.dirname(outputTxt));
    if (!txtDir.existsSync()) {
      await txtDir.create(recursive: true);
    }

    final args = <String>[
      scriptPath,
      '--chunks',
      ...chunkPaths,
      '--offsets',
      ...chunkOffsets.map((o) => o.toStringAsFixed(3)),
      '--model',
      effectiveModelDir,
      '--video-language',
      videoLanguage,
      '--caption-language',
      captionLanguage,
      '--output-json',
      outputJson,
      '--output-txt',
      outputTxt,
    ];

    try {
      final process = await Process.start(
        pythonPath,
        args,
        runInShell: false,
      );

      final stderrBuffer = StringBuffer();
      DateTime lastActivityTime = DateTime.now();
      const stallInactivityTimeout = Duration(minutes: 10);
      bool hasStalled = false;

      // Inactivity Watchdog: Detects if whisper engine freezes or stalls without output
      final watchdogTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        final inactivity = DateTime.now().difference(lastActivityTime);
        if (inactivity > stallInactivityTimeout) {
          hasStalled = true;
          timer.cancel();
          final stallMsg =
              '[Whisper Prime] Watchdog detected transcription stall (no output for ${inactivity.inMinutes} minutes). Terminating runner to prevent hang.';
          onLog?.call(stallMsg);
          AppLog.e(stallMsg);
          try {
            process.kill(ProcessSignal.sigkill);
          } catch (_) {}
        }
      });

      process.stdout.transform(utf8.decoder).listen((line) {
        lastActivityTime = DateTime.now();
        for (final raw in line.split('\n')) {
          final trimmed = raw.trim();
          if (trimmed.isEmpty) continue;

          if (trimmed.startsWith('[CHUNK_DONE]')) {
            try {
              final payload = trimmed.substring('[CHUNK_DONE]'.length).trim();
              final data = jsonDecode(payload) as Map<String, dynamic>;
              final cIndex = data['chunk_index'] as int? ?? 0;
              final cTotal = data['chunks_total'] as int? ?? 1;
              final segs = (data['cumulative_words'] ?? data['cumulative_segments']) as int? ?? 0;
              onChunkDone?.call(cIndex, cTotal, segs);
            } catch (_) {}
          } else if (trimmed.startsWith('[WINDOW_PROGRESS]')) {
            try {
              final payload = trimmed.substring('[WINDOW_PROGRESS]'.length).trim();
              final data = jsonDecode(payload) as Map<String, dynamic>;
              final cIdx = data['chunk_index'] as int? ?? 0;
              final cTot = data['chunks_total'] as int? ?? 1;
              final pct = data['chunk_percent'] as int? ?? 0;
              final words = data['total_words'] as int? ?? 0;
              final txt = data['recent_text'] as String? ?? '';
              onWindowProgress?.call(cIdx, cTot, pct, words, txt);
            } catch (_) {}
          } else {
            onLog?.call(trimmed);
          }
        }
      });

      process.stderr.transform(utf8.decoder).listen((errLine) {
        lastActivityTime = DateTime.now();
        for (final raw in errLine.split('\n')) {
          final trimmed = raw.trim();
          if (trimmed.isNotEmpty) {
            // Keep meaningful errors in the buffer, filter out tqdm progress ticks
            if (!trimmed.contains('%|') && !trimmed.startsWith('Loading weights:')) {
              stderrBuffer.writeln(trimmed);
            }
            onLog?.call('[Whisper Prime STDERR] $trimmed');
          }
        }
      });

      final exitCode = await process.exitCode;
      watchdogTimer.cancel();

      if (hasStalled) {
        throw TimeoutException(
          'Whisper transcription stalled (no output for 5 minutes). '
          'You can resume transcription directly from the last saved segment.',
        );
      }
      if (exitCode == 0 && File(outputJson).existsSync()) {
        final jsonStr = await File(outputJson).readAsString();
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final segments = (data['words'] as List<dynamic>?) ??
            (data['segments'] as List<dynamic>?) ??
            (data['phrases'] as List<dynamic>?) ??
            [];
        final lines = <TranscriptLine>[];
        for (final s in segments) {
          final map = s as Map<String, dynamic>;
          final start = (map['start'] as num).toDouble();
          final end = (map['end'] as num).toDouble();
          final text = (map['word'] as String?) ?? (map['text'] as String?) ?? '';
          if (text.isNotEmpty) {
            lines.add(TranscriptLine(startSec: start, endSec: end, text: text));
          }
        }
        if (lines.isEmpty) {
          final msg = '[Whisper Prime] Process completed with code 0, but no words were extracted into $outputJson.';
          onLog?.call(msg);
          throw StateError(msg);
        }
        onLog?.call('[Whisper Prime] Loaded ${lines.length} segments from $outputJson');
        await AppPathResolver.syncLiveProcessToRelease();
        return lines;
      } else {
        final errText = stderrBuffer.toString().trim();
        final detail = errText.isNotEmpty ? ' Error details:\n$errText' : '.';
        final msg = '[Whisper Prime] Transcription runner failed with exit code $exitCode.$detail';
        onLog?.call(msg);
        AppLog.e(msg);
        throw StateError(msg);
      }
    } catch (e, st) {
      onLog?.call('[Whisper Prime] Runner execution failure: $e');
      AppLog.e('[Whisper Prime] Runner execution failure: $e\n$st');
      rethrow;
    }
  }

  bool isAvailable() => _cachedCliPath != null;

  void invalidateCache() => _cachedCliPath = null;
}
