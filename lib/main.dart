import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player_win/video_player_win.dart';

import 'app/app.dart';
import 'core/config/app_env.dart';
import 'core/services/file_manager.dart';
import 'core/services/local_settings_service.dart';
import 'core/utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register native Windows video player implementation
  if (!kIsWeb && Platform.isWindows) {
    WindowsVideoPlayer.registerWith();
  }

  // ── Environment ──────────────────────────────────────────────────────
  // .env is optional; --dart-define values take precedence.
  await AppEnv.load();

  // ── Backend (optional) ───────────────────────────────────────────────
  // Only initialize when configured; otherwise the auth screen shows a
  // "Supabase not configured" banner and keeps the forms disabled.
  if (AppEnv.supabaseConfigured) {
    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl!,
        publishableKey: AppEnv.supabaseAnonKey!,
      );
      AppEnv.supabaseInitialized = true;
      AppLog.i('Supabase initialized — auth forms enabled');
    } catch (e, s) {
      AppLog.e('Supabase init failed — continuing without backend', e, s);
    }
  } else {
    AppLog.w('Supabase not configured — required env keys: '
        'SUPABASE_URL, SUPABASE_ANON_KEY');
    AppLog.w('Provide them via .env (see .env.example) or --dart-define. '
        'The auth screen will show a banner and keep forms disabled.');
  }

  // ── On-disk workspace ────────────────────────────────────────────────
  await FileManager.initialize();
  // Local ClipItV1/settings.json (best-effort, never crashes).
  await LocalSettingsService.initialize();

  AppLog.i('Auth background image asset: '
      '${'assets/images/Gemini_Generated_Image_df2l05df2l05df2l.png'} '
      '(copied from the user input resources folder into the project)');

  runApp(const ProviderScope(child: ClipItApp()));
}
