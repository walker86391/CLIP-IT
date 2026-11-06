import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/settings.dart';
import '../core/providers/core_providers.dart';
import '../ui/components/app_toast.dart';
import '../ui/tokens/motion.dart';
import 'localization.dart';
import 'router.dart';
import 'theme.dart';

/// Root widget: theme, router, and global overlays.
class ClipItApp extends ConsumerWidget {
  const ClipItApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final themeMode = switch (settings.themeMode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => ReduceMotion(
        enabled: settings.reduceMotion,
        child: AppToastOverlay(child: child ?? const SizedBox()),
      ),
    );
  }
}
