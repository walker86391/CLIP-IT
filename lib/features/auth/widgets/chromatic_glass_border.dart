import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../auth_theme.dart';

/// Paints an Apple-style "liquid glass" edge around a rounded surface.
///
/// The edge is built from three strokes of the same rounded-rect path:
///
///   1. A RED fringe, shifted [AuthColors.glassAberrationShift] px LEFT.
///   2. A CYAN fringe, shifted the same amount RIGHT.
///   3. The main hairline, a vertical white gradient (brighter at the top,
///      fading toward the bottom), drawn last so it stays crisp on top.
///
/// The sub-pixel red/cyan split imitates chromatic dispersion in real glass
/// — light of different wavelengths refracting at slightly different angles
/// — which is what gives Apple's glass surfaces their lens-like shimmer at
/// the edges. Keep [AuthColors.glassAberrationOpacity] low: the fringes
/// must read as a faint shimmer along the edge, never as colored outlining.
///
/// Used as a `CustomPaint.foregroundPainter` so the strokes sit above the
/// surface's fill gradient (one fill + one edge = ONE unified glass layer —
/// deliberately NOT the old stacked fill+border boxes the user disliked).
class ChromaticGlassBorderPainter extends CustomPainter {
  const ChromaticGlassBorderPainter({
    required this.radius,
    required this.borderColorTop,
    required this.borderColorBottom,
    this.aberrationShift = AuthColors.glassAberrationShift,
    this.aberrationOpacity = AuthColors.glassAberrationOpacity,
  });

  /// Corner radius of the rounded-rect edge.
  final double radius;

  /// Main hairline color at the TOP of the edge (before the gradient fade).
  final Color borderColorTop;

  /// Main hairline color at the BOTTOM of the edge.
  final Color borderColorBottom;

  /// Horizontal offset of the red/cyan fringes, in logical pixels.
  final double aberrationShift;

  /// Alpha multiplier applied to both fringe strokes (0..1).
  final double aberrationOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    // Inset the path by half a stroke width so the centered 1px stroke fits
    // inside the CustomPaint bounds instead of being shaved off at the edge.
    final double inset = 0.5;
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
      Radius.circular(radius),
    );

    // ── Chromatic aberration fringes ────────────────────────────────────
    // Red on the left, cyan on the right, both at low alpha, both painted
    // BEFORE the main hairline so the white edge stays crisp above them.
    final Color redFringe = AuthColors.aberrationRed
        .withValues(alpha: AuthColors.aberrationRed.a * aberrationOpacity);
    final Color cyanFringe = AuthColors.aberrationCyan
        .withValues(alpha: AuthColors.aberrationCyan.a * aberrationOpacity);

    final Paint fringePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(
      rrect.shift(const Offset(-1, 0) * aberrationShift),
      fringePaint..color = redFringe,
    );
    canvas.drawRRect(
      rrect.shift(const Offset(1, 0) * aberrationShift),
      fringePaint..color = cyanFringe,
    );

    // ── Main hairline ───────────────────────────────────────────────────
    // Vertical gradient: bright at the top edge (catching "light"), fading
    // toward the bottom — the same specular behavior as the fill's sheen.
    final Paint hairlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [borderColorTop, borderColorBottom],
      );

    canvas.drawRRect(rrect, hairlinePaint);
  }

  @override
  bool shouldRepaint(ChromaticGlassBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.borderColorTop != borderColorTop ||
        oldDelegate.borderColorBottom != borderColorBottom ||
        oldDelegate.aberrationShift != aberrationShift ||
        oldDelegate.aberrationOpacity != aberrationOpacity;
  }
}
