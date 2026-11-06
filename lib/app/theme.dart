import 'package:flutter/material.dart';

import '../ui/tokens/colors.dart';
import '../ui/tokens/spacing.dart';
import '../ui/tokens/typography.dart';

/// Builds the ClipIt [ThemeData] for the given [brightness].
ThemeData buildAppTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? _Scheme.light : _Scheme.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.background,
    visualDensity: VisualDensity.standard,
    splashFactory: NoSplash.splashFactory,
    fontFamily: AppTypography.fontFamily,

    // ── Typography ──────────────────────────────────────────────────────
    textTheme: const TextTheme(
      displaySmall: AppTypography.header,
      headlineSmall: AppTypography.title,
      titleLarge: AppTypography.sectionTitle,
      titleMedium: AppTypography.bodyMedium,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.secondary,
      labelLarge: AppTypography.bodyMedium,
      labelSmall: AppTypography.label,
    ),

    // ── Component defaults (desktop density) ────────────────────────────
    dividerTheme: DividerThemeData(
      color: c.border,
      thickness: AppBorders.thin,
      space: 1,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
    ),

    inputDecorationTheme: InputDecorationThemeData(
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 8),
      hintStyle: TextStyle(color: c.textTertiary),
      border: OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: const BorderSide(color: AppColors.accent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      filled: true,
      fillColor: c.surface,
    ),

    iconTheme: IconThemeData(color: c.textSecondary, size: 18),

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionColor: AppColors.accentSubtle,
      selectionHandleColor: AppColors.accent,
    ),
  );
}

/// Surface/ink tokens resolved per brightness.
final class _Scheme {
  const _Scheme({
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
  });

  final Color background;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  static const light = _Scheme(
    background: AppColors.background,
    surface: AppColors.surface,
    border: AppColors.border,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
  );

  static const dark = _Scheme(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    border: AppColors.darkBorder,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
  );
}
