import 'dart:convert';

import '../db/app_database.dart';
import '../models/settings.dart';

/// Key/value-backed typed settings store.
class SettingsRepo {
  SettingsRepo(this._db);

  final AppDatabase _db;
  static const _settingsKey = 'app';

  Future<AppSettings> read() async {
    final raw = await _db.settingsDao.read(_settingsKey);
    if (raw == null) return const AppSettings();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettings(
        reduceMotion: json['reduceMotion'] as bool? ?? false,
        themeMode:
            AppThemeMode.values.asNameMap()[json['themeMode'] as String?] ??
                AppThemeMode.system,
      );
    } on FormatException {
      // Corrupted row: fall back to defaults rather than crash.
      return const AppSettings();
    }
  }

  Future<void> write(AppSettings settings) =>
      _db.settingsDao.write(_settingsKey, jsonEncode({
        'reduceMotion': settings.reduceMotion,
        'themeMode': settings.themeMode.name,
      }));

  Future<void> setReduceMotion(bool value) async {
    final current = await read();
    await write(current.copyWith(reduceMotion: value));
  }
}
