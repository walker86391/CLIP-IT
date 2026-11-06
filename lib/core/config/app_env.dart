import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration.
///
/// Resolution order: `--dart-define` overrides `.env` asset values.
/// Never log or commit real credentials; `.env` is gitignored.
abstract final class AppEnv {
  static const String _defineUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _defineAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static bool _dotenvLoaded = false;

  /// Set to true by main() after a successful Supabase.initialize().
  /// Gates which AuthService implementation the app uses.
  static bool supabaseInitialized = false;

  /// Loads the `.env` asset if present. Missing file or keys are not fatal:
  /// the app runs in "not configured" mode (stub services).
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
      _dotenvLoaded = true;
    } catch (_) {
      // No .env bundled / unreadable — fall through to dart-defines only.
    }
  }

  /// Test hook: mark dotenv as loaded when the caller populated it manually.
  static void markLoaded() => _dotenvLoaded = true;

  static String? get supabaseUrl => _pick(_defineUrl, 'SUPABASE_URL');

  static String? get supabaseAnonKey => _pick(_defineAnonKey, 'SUPABASE_ANON_KEY');

  /// True only when both URL and anon key are present.
  static bool get supabaseConfigured =>
      (supabaseUrl?.isNotEmpty ?? false) && (supabaseAnonKey?.isNotEmpty ?? false);

  static String? _pick(String define, String key) {
    if (define.isNotEmpty) return define;
    if (_dotenvLoaded) {
      final v = dotenv.maybeGet(key);
      return (v == null || v.isEmpty) ? null : v;
    }
    return null;
  }
}
