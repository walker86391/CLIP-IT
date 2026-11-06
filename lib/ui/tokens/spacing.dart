import 'package:flutter/material.dart';

/// ClipIt spacing, radius, and sizing tokens.
///
/// Spacing uses a 4px base grid. Use these instead of magic numbers so
/// layout rhythm stays consistent across screens.
abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Corner radii. Not everything needs rounding; prefer small radii.
abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 8;

  static final BorderRadius rSm = BorderRadius.circular(sm);
  static final BorderRadius rMd = BorderRadius.circular(md);
  static final BorderRadius rLg = BorderRadius.circular(lg);
}

/// Standard control heights for desktop density.
abstract final class AppSizes {
  /// Sidebar width (collapsed list of nav destinations).
  static const double sidebarWidth = 216;

  /// Toolbar height.
  static const double toolbarHeight = 44;

  /// Standard button / input height.
  static const double controlHeight = 32;

  /// Small control height (toolbars, table rows).
  static const double controlHeightSm = 26;

  /// Minimum window size.
  static const int minWindowWidth = 960;
  static const int minWindowHeight = 600;
}

/// Standard hairline widths.
abstract final class AppBorders {
  static const double thin = 1;
}
