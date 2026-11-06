import 'package:flutter/material.dart';

/// ClipIt color tokens.
///
/// Palette rules:
/// - One meaningful accent (used for primary actions and selection only).
/// - Neutrals carry structure; color carries meaning.
/// - No gradients, no neon, no decorative color.
abstract final class AppColors {
  // ── Brand accent ────────────────────────────────────────────────────────
  /// Primary accent for primary actions, selection, and progress.
  /// Sophisticated violet / lavender.
  static const Color accent = Color(0xFF8B5CF6);
  static const Color accentLight = Color(0xFF9B7BFF);
  static const Color accentHover = Color(0xFF996DF8);
  static const Color accentPressed = Color(0xFF7C3AED);
  static const Color accentSubtle = Color(0x1F8B5CF6); // ~12% alpha fill
  static const Color secondaryAccent = Color(0xFF6366F1); // soft blue-violet

  // ── Light surface scheme ────────────────────────────────────────────────
  /// App background (lowest layer).
  static const Color background = Color(0xFFF7F8FA);

  /// Sidebar / chrome surface, slightly distinct from content.
  static const Color surfaceChrome = Color(0xFFEFF1F4);

  /// Cards, panels, elevated content.
  static const Color surface = Color(0xFFFFFFFF);

  /// Hover fill on top of [surface].
  static const Color surfaceHover = Color(0xFFF2F4F7);

  /// Active/pressed fill on top of [surface].
  static const Color surfacePressed = Color(0xFFE8EBF0);

  /// Thin structural borders.
  static const Color border = Color(0xFFE3E6EB);
  static const Color borderStrong = Color(0xFFD0D5DD);

  // ── Ink (text) ──────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF17191C);
  static const Color textSecondary = Color(0xFF5A6070);
  static const Color textTertiary = Color(0xFF8B90A0);
  static const Color textOnAccent = Color(0xFFFFFFFF);
  static const Color textDisabled = Color(0xFFB4B9C4);

  // ── Semantic ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF1F9D62);
  static const Color successSubtle = Color(0x1A1F9D62);
  static const Color warning = Color(0xFFB57E10);
  static const Color warningSubtle = Color(0x1AB57E10);
  static const Color danger = Color(0xFFD64545);
  static const Color dangerSubtle = Color(0x1AD64545);
  static const Color dangerHover = Color(0xFFC23A3A);

  // ── Focus ───────────────────────────────────────────────────────────────
  /// Keyboard focus ring color.
  static const Color focusRing = Color(0x668B5CF6);

  // ── Dark surface scheme (used by AppTheme.dark & creative app desktop) ────
  static const Color darkBackground = Color(0xFF0F1016);
  static const Color darkSurfaceChrome = Color(0xFF14151E);
  static const Color darkSurface = Color(0xFF1A1B26);
  static const Color darkSurfaceElevated = Color(0xFF232534);
  static const Color darkSurfaceHover = Color(0xFF222432);
  static const Color darkSurfacePressed = Color(0xFF161722);
  static const Color darkBorder = Color(0xFF262837);
  static const Color darkBorderSubtle = Color(0x1FFFFFFF);
  static const Color darkBorderStrong = Color(0xFF383B4F);
  static const Color darkTextPrimary = Color(0xFFF3F4F8);
  static const Color darkTextSecondary = Color(0xFF9194A6);
  static const Color darkTextTertiary = Color(0xFF606377);
}
