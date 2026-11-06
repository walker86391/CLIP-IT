import 'package:flutter/material.dart';

/// ClipIt type scale.
///
/// Deliberately small: hierarchy comes from size + weight + color, not from
/// many distinct styles. Desktop density means base size stays at 14.
abstract final class AppTypography {
  static const String? fontFamily = null; // Default platform font for Step 0.

  // ── Sizes ───────────────────────────────────────────────────────────────
  static const double sizeXs = 11; // Meta labels, badges.
  static const double sizeSm = 12; // Secondary/caption text.
  static const double sizeMd = 14; // Body / default.
  static const double sizeLg = 16; // Emphasized body, page titles.
  static const double sizeXl = 20; // View headers.
  static const double sizeXxl = 26; // Large headers (used sparingly).

  // ── Weights ─────────────────────────────────────────────────────────────
  static const FontWeight wRegular = FontWeight.w400;
  static const FontWeight wMedium = FontWeight.w500;
  static const FontWeight wSemibold = FontWeight.w600;

  // ── Letter spacing ──────────────────────────────────────────────────────
  static const double trackingTight = -0.3;
  static const double trackingNormal = 0;

  // ── Concrete styles ─────────────────────────────────────────────────────
  static const TextStyle header = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeXxl,
    height: 1.25,
    fontWeight: wSemibold,
    letterSpacing: trackingTight,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeXl,
    height: 1.3,
    fontWeight: wSemibold,
    letterSpacing: trackingTight,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeLg,
    height: 1.35,
    fontWeight: wSemibold,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeMd,
    height: 1.45,
    fontWeight: wRegular,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeMd,
    height: 1.45,
    fontWeight: wMedium,
  );

  static const TextStyle secondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeSm,
    height: 1.4,
    fontWeight: wRegular,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeXs,
    height: 1.2,
    fontWeight: wMedium,
    letterSpacing: 0.4,
  );
}
