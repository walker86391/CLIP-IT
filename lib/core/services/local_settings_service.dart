import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/app_logger.dart';

/// Local (file-based) app settings — safe, best-effort.
///
/// Layout: `<app support>/ClipItV1/settings.json`
/// First run writes { "theme": "darkGray", "firstRun": true }; later runs
/// read the same file if present. Any failure logs a warning and continues —
/// a missing local-settings file must never crash the app.
///
/// TODO(user): surface these values in the real Settings feature (the
/// Drift-backed SettingsRepo handles user preferences; this file tracks
/// first-run/install state only).
final class LocalSettingsService {
  LocalSettingsService._();

  static File? _settingsFile;

  /// Contents of the last successful read (null when unavailable).
  static Map<String, dynamic>? get current =>
      _cached == null ? null : Map<String, dynamic>.unmodifiable(_cached!);

  static Map<String, dynamic>? _cached;

  static Future<void> initialize() async {
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory(p.join(base.path, 'ClipItV1'));

      if (!dir.existsSync()) {
        await dir.create(recursive: true);
        AppLog.i('LocalSettings: created ${dir.path}');
      }

      final file = File(p.join(dir.path, 'settings.json'));
      _settingsFile = file;

      if (!file.existsSync()) {
        const defaults = <String, dynamic>{
          'theme': 'darkGray',
          'firstRun': true,
        };
        await file.writeAsString(const JsonEncoder.withIndent('  ').convert(defaults));
        _cached = Map<String, dynamic>.of(defaults);
        AppLog.i('LocalSettings: first run — settings.json created');
        return;
      }

      // Subsequent runs: read whatever is there (tolerate corruption).
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _cached = decoded;
        AppLog.i('LocalSettings: loaded ${file.path}');
      } else {
        AppLog.w('LocalSettings: unexpected settings.json shape — ignoring');
      }
    } catch (e, s) {
      // Never crash on local settings problems.
      AppLog.w('LocalSettings init failed (non-fatal): $e');
      AppLog.w('at: $s');
    }
  }

  /// Best-effort persist of a merged map. Silent on failure.
  static Future<void> patch(Map<String, dynamic> updates) async {
    final file = _settingsFile;
    if (file == null) return;
    try {
      final merged = <String, dynamic>{...?_cached, ...updates};
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(merged),
      );
      _cached = merged;
    } catch (e) {
      AppLog.w('LocalSettings patch failed (non-fatal): $e');
    }
  }
}
