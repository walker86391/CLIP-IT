import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/app_logger.dart';
import 'local_settings_service.dart';

/// Supported video platforms requiring authentication cookies.
enum CookiePlatform {
  instagram,
  youtube,
  general,
}

/// Service managing authentication cookies for yt-dlp (Instagram & YouTube).
///
/// Supports all standard cookie export formats:
/// 1. Netscape HTTP Cookie File format (tab-separated lines)
/// 2. JSON array format exported by "Cookie-Editor" browser extension
/// 3. Semicolon-separated HTTP Cookie header strings (e.g. sessionid=...; ds_user_id=...)
///
/// Automatically converts and writes cookies in Netscape format to:
/// `<app support>/ClipItV1/cookies/<platform>_cookies.txt`
/// which yt-dlp natively consumes with the `--cookies` argument.
final class CookieSettingsService {
  CookieSettingsService._();

  static final CookieSettingsService instance = CookieSettingsService._();

  static const String _keyInstagramCookies = 'instagram_cookie_text';
  static const String _keyYoutubeCookies = 'youtube_cookie_text';

  Directory? _cookiesDir;

  Future<Directory> _getCookiesDirectory() async {
    if (_cookiesDir != null && _cookiesDir!.existsSync()) {
      return _cookiesDir!;
    }

    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'ClipItV1', 'cookies'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    _cookiesDir = dir;
    return dir;
  }

  /// Returns the raw cookie text saved in settings for the specified platform.
  Future<String> getRawCookieText(CookiePlatform platform) async {
    final cached = LocalSettingsService.current;
    if (cached == null) return '';

    switch (platform) {
      case CookiePlatform.instagram:
        return (cached[_keyInstagramCookies] as String?) ?? '';
      case CookiePlatform.youtube:
        return (cached[_keyYoutubeCookies] as String?) ?? '';
      case CookiePlatform.general:
        return '';
    }
  }

  /// Returns the absolute path to the Netscape-formatted cookie file for yt-dlp,
  /// or null if no cookies have been configured for the platform.
  Future<String?> getCookieFilePathFor(CookiePlatform platform) async {
    final raw = await getRawCookieText(platform);
    if (raw.trim().isEmpty) return null;

    final dir = await _getCookiesDirectory();
    final fileName = switch (platform) {
      CookiePlatform.instagram => 'instagram_cookies.txt',
      CookiePlatform.youtube => 'youtube_cookies.txt',
      CookiePlatform.general => 'general_cookies.txt',
    };

    final file = File(p.join(dir.path, fileName));
    if (!file.existsSync()) {
      // Re-generate file if missing
      final netscapeContent = normalizeToNetscape(raw, platform);
      await file.writeAsString(netscapeContent);
    }

    return file.path;
  }

  /// Saves raw cookie text for the platform, converts to Netscape format,
  /// writes the cookie file for yt-dlp, and persists the raw string in local settings.
  Future<void> saveCookies({
    required CookiePlatform platform,
    required String rawInput,
  }) async {
    final trimmed = rawInput.trim();
    final key = switch (platform) {
      CookiePlatform.instagram => _keyInstagramCookies,
      CookiePlatform.youtube => _keyYoutubeCookies,
      CookiePlatform.general => 'general_cookie_text',
    };

    final dir = await _getCookiesDirectory();
    final fileName = switch (platform) {
      CookiePlatform.instagram => 'instagram_cookies.txt',
      CookiePlatform.youtube => 'youtube_cookies.txt',
      CookiePlatform.general => 'general_cookies.txt',
    };

    final file = File(p.join(dir.path, fileName));

    if (trimmed.isEmpty) {
      await LocalSettingsService.patch({key: ''});
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      AppLog.i('Cleared cookies for $platform');
      return;
    }

    final netscapeContent = normalizeToNetscape(trimmed, platform);
    await file.writeAsString(netscapeContent);
    await LocalSettingsService.patch({key: trimmed});
    AppLog.i('Saved cookies for $platform to ${file.path}');
  }

  /// Normalizes any input cookie representation (Netscape, JSON, or key=value header)
  /// into a standard Netscape HTTP Cookie File compatible with yt-dlp and curl.
  String normalizeToNetscape(String input, CookiePlatform platform) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    final defaultDomain = switch (platform) {
      CookiePlatform.instagram => '.instagram.com',
      CookiePlatform.youtube => '.youtube.com',
      CookiePlatform.general => '.example.com',
    };

    // 1. Try parsing as JSON (Cookie-Editor extension export)
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          final buffer = StringBuffer();
          buffer.writeln('# Netscape HTTP Cookie File');
          buffer.writeln('# Generated by ClipIt CookieManager');
          buffer.writeln();

          for (final item in decoded) {
            if (item is Map) {
              final domain = (item['domain']?.toString() ?? defaultDomain).trim();
              final isDomainFlag = domain.startsWith('.') ? 'TRUE' : 'FALSE';
              final path = (item['path']?.toString() ?? '/').trim();
              final secure = (item['secure'] == true) ? 'TRUE' : 'FALSE';
              
              int expiry = 2147483647; // Default far future
              if (item['expirationDate'] != null) {
                final expNum = double.tryParse(item['expirationDate'].toString());
                if (expNum != null && expNum > 0) {
                  expiry = expNum.toInt();
                }
              }

              final name = item['name']?.toString().trim() ?? '';
              final value = item['value']?.toString().trim() ?? '';

              if (name.isNotEmpty) {
                buffer.writeln('$domain\t$isDomainFlag\t$path\t$secure\t$expiry\t$name\t$value');
              }
            }
          }

          return buffer.toString();
        }
      } catch (e) {
        AppLog.w('Failed to parse cookies as JSON, falling back to line parser: $e');
      }
    }

    // 2. Check if already Netscape format (contains tabs or header)
    if (trimmed.contains('\t') || trimmed.contains('# Netscape HTTP Cookie File')) {
      if (!trimmed.startsWith('# Netscape HTTP Cookie File')) {
        return '# Netscape HTTP Cookie File\n# Generated by ClipIt CookieManager\n\n$trimmed\n';
      }
      return '$trimmed\n';
    }

    // 3. Fallback: Parse semicolon-separated header key=value pairs
    // e.g., sessionid=12345; ds_user_id=67890; csrftoken=abc
    final buffer = StringBuffer();
    buffer.writeln('# Netscape HTTP Cookie File');
    buffer.writeln('# Generated by ClipIt CookieManager from Header Strings');
    buffer.writeln();

    final pairs = trimmed.split(';');
    for (final pair in pairs) {
      final kv = pair.trim();
      if (kv.isEmpty) continue;
      final eqIdx = kv.indexOf('=');
      if (eqIdx > 0) {
        final name = kv.substring(0, eqIdx).trim();
        final value = kv.substring(eqIdx + 1).trim();
        if (name.isNotEmpty) {
          // domain, includeSubdomains, path, secure, expiry, name, value
          buffer.writeln('$defaultDomain\tTRUE\t/\tTRUE\t2147483647\t$name\t$value');
        }
      }
    }

    return buffer.toString();
  }

  /// Returns inspection summary for display in UI (e.g., whether sessionid / SID is present).
  Future<String> getCookieStatusSummary(CookiePlatform platform) async {
    final raw = await getRawCookieText(platform);
    if (raw.trim().isEmpty) {
      return 'Not configured (Public downloads only)';
    }

    final lower = raw.toLowerCase();
    switch (platform) {
      case CookiePlatform.instagram:
        final hasSession = lower.contains('sessionid');
        final hasUserId = lower.contains('ds_user_id');
        if (hasSession && hasUserId) {
          return 'Configured ✅ (Active sessionid & ds_user_id found)';
        } else if (hasSession) {
          return 'Configured ✅ (sessionid found)';
        }
        return 'Configured ✅ (Custom cookies saved)';

      case CookiePlatform.youtube:
        final hasSid = lower.contains('sid') || lower.contains('__secure');
        if (hasSid) {
          return 'Configured ✅ (Google/YouTube auth tokens detected)';
        }
        return 'Configured ✅ (Cookies saved)';

      case CookiePlatform.general:
        return 'Configured ✅';
    }
  }
}
