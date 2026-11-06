import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/subtitle_models.dart';

/// CustomPainter rendering all 11 marker styles with 8 distinct visual stroke textures.
class SubtitleMarkerPainter extends CustomPainter {
  const SubtitleMarkerPainter({
    required this.style,
    required this.texture,
    required this.color,
    this.thickness = 3.0,
    this.distance = 4.0,
    this.paddingH = 8.0,
    this.paddingV = 4.0,
    this.opacity = 1.0,
    this.progress = 1.0,
    this.animation = MarkerAnimationBehavior.drawIn,
  });

  final SubtitleMarkerStyle style;
  final MarkerTexture texture;
  final Color color;
  final double thickness;
  final double distance;
  final double paddingH;
  final double paddingV;
  final double opacity;
  final double progress; // 0.0 to 1.0
  final MarkerAnimationBehavior animation;

  @override
  void paint(Canvas canvas, Size size) {
    if (style == SubtitleMarkerStyle.none || color.a == 0 || opacity <= 0.01) {
      return;
    }

    final effectiveAlpha = (color.a * opacity).clamp(0.0, 1.0);
    final baseColor = color.withValues(alpha: effectiveAlpha);

    // Calculate effective animated progress (0.0 to 1.0)
    double animProgress = 1.0;
    if (animation == MarkerAnimationBehavior.drawIn ||
        style == SubtitleMarkerStyle.animatedUnderline ||
        texture == MarkerTexture.animatedCrayon) {
      animProgress = progress.clamp(0.0, 1.0);
    } else if (animation == MarkerAnimationBehavior.snap) {
      animProgress = progress >= 0.2 ? 1.0 : 0.0;
    } else if (animation == MarkerAnimationBehavior.fade) {
      animProgress = 1.0;
    }

    if (animProgress <= 0.01 && animation == MarkerAnimationBehavior.drawIn) {
      return;
    }

    final rect = Rect.fromLTWH(
      -paddingH,
      -paddingV,
      size.width + paddingH * 2,
      size.height + paddingV * 2,
    );

    switch (style) {
      case SubtitleMarkerStyle.filledBox:
        _paintFilledBox(canvas, rect, baseColor, animProgress);
        break;
      case SubtitleMarkerStyle.outlineBox:
        _paintOutlineBox(canvas, rect, baseColor, animProgress);
        break;
      case SubtitleMarkerStyle.singleUnderline:
        _paintSingleUnderline(canvas, size, baseColor, animProgress);
        break;
      case SubtitleMarkerStyle.doubleUnderline:
        _paintDoubleUnderline(canvas, size, baseColor, animProgress);
        break;
      case SubtitleMarkerStyle.crossedUnderlines:
        _paintCrossedUnderlines(canvas, size, baseColor, animProgress);
        break;
      case SubtitleMarkerStyle.circleMarker:
        _paintCircleMarker(canvas, rect, baseColor, animProgress);
        break;
      case SubtitleMarkerStyle.crossMarker:
        _paintCrossMarker(canvas, rect, baseColor, animProgress);
        break;
      case SubtitleMarkerStyle.handDrawnBox:
        _paintHandDrawnBox(canvas, rect, baseColor, animProgress);
        break;
      case SubtitleMarkerStyle.highlightStroke:
        _paintHighlightStroke(canvas, size, baseColor, animProgress);
        break;
      case SubtitleMarkerStyle.sideBrackets:
        _paintSideBrackets(canvas, rect, baseColor, animProgress);
        break;
      case SubtitleMarkerStyle.animatedUnderline:
        _paintSingleUnderline(canvas, size, baseColor, animProgress);
        break;
      case SubtitleMarkerStyle.none:
        break;
    }
  }

  // ── 1. FILLED BOX ──────────────────────────────────────────────────────────
  void _paintFilledBox(Canvas canvas, Rect rect, Color c, double p) {
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(6.0));
    final paint = Paint()
      ..color = c
      ..style = PaintingStyle.fill;

    if (p < 1.0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(rect.left, rect.top, rect.width * p, rect.height));
      canvas.drawRRect(r, paint);
      canvas.restore();
    } else {
      canvas.drawRRect(r, paint);
    }

    // If textured, overlay texture grain or hand-drawn border
    if (texture == MarkerTexture.crayon || texture == MarkerTexture.animatedCrayon) {
      _drawGrainyOutline(canvas, rect, c.withValues(alpha: c.a * 0.4), thickness: 1.5);
    } else if (texture == MarkerTexture.markerPen) {
      final borderPaint = Paint()
        ..color = c.withValues(alpha: (c.a * 0.6).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(r, borderPaint);
    }
  }

  // ── 2. OUTLINE BOX ────────────────────────────────────────────────────────
  void _paintOutlineBox(Canvas canvas, Rect rect, Color c, double p) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6.0)));
    _paintPathWithTexture(canvas, path, c, thickness, p);
  }

  // ── 3. SINGLE UNDERLINE ───────────────────────────────────────────────────
  void _paintSingleUnderline(Canvas canvas, Size size, Color c, double p) {
    final y = size.height + distance;
    final totalWidth = size.width + paddingH;
    final startX = -paddingH * 0.5;
    final currentWidth = totalWidth * p;

    final path = Path()
      ..moveTo(startX, y)
      ..lineTo(startX + currentWidth, y);

    _paintPathWithTexture(canvas, path, c, thickness, 1.0);
  }

  // ── 4. DOUBLE UNDERLINE ───────────────────────────────────────────────────
  void _paintDoubleUnderline(Canvas canvas, Size size, Color c, double p) {
    final y1 = size.height + distance;
    final y2 = y1 + thickness + 3.0;
    final totalWidth = size.width + paddingH;
    final startX = -paddingH * 0.5;

    final p1 = p.clamp(0.0, 1.0);
    final p2 = (p * 1.2 - 0.2).clamp(0.0, 1.0);

    final path1 = Path()..moveTo(startX, y1)..lineTo(startX + totalWidth * p1, y1);
    final path2 = Path()..moveTo(startX, y2)..lineTo(startX + totalWidth * p2, y2);

    _paintPathWithTexture(canvas, path1, c, thickness, 1.0);
    if (p2 > 0.01) {
      _paintPathWithTexture(canvas, path2, c, thickness * 0.85, 1.0);
    }
  }

  // ── 5. CROSSED UNDERLINES ─────────────────────────────────────────────────
  void _paintCrossedUnderlines(Canvas canvas, Size size, Color c, double p) {
    final yMid = size.height + distance + 3.0;
    final w = size.width + paddingH;
    final startX = -paddingH * 0.5;

    final path1 = Path()
      ..moveTo(startX, yMid - 3.0)
      ..lineTo(startX + w * p, yMid + 3.0);
    final path2 = Path()
      ..moveTo(startX, yMid + 3.0)
      ..lineTo(startX + w * p, yMid - 3.0);

    _paintPathWithTexture(canvas, path1, c, thickness, 1.0);
    _paintPathWithTexture(canvas, path2, c.withValues(alpha: c.a * 0.85), thickness * 0.9, 1.0);
  }

  // ── 6. CIRCLE / OVAL MARKER ───────────────────────────────────────────────
  void _paintCircleMarker(Canvas canvas, Rect rect, Color c, double p) {
    final ovalRect = rect.inflate(2.0);
    final path = Path()..addOval(ovalRect);
    _paintPathWithTexture(canvas, path, c, thickness, p);
  }

  // ── 7. CROSS MARKER ───────────────────────────────────────────────────────
  void _paintCrossMarker(Canvas canvas, Rect rect, Color c, double p) {
    final path1 = Path()..moveTo(rect.left, rect.top)..lineTo(rect.left + rect.width * p, rect.top + rect.height * p);
    final path2 = Path()..moveTo(rect.left, rect.bottom)..lineTo(rect.left + rect.width * p, rect.bottom - rect.height * p);

    _paintPathWithTexture(canvas, path1, c, thickness, 1.0);
    _paintPathWithTexture(canvas, path2, c, thickness, 1.0);
  }

  // ── 8. HAND-DRAWN BOX ─────────────────────────────────────────────────────
  void _paintHandDrawnBox(Canvas canvas, Rect rect, Color c, double p) {
    final path = Path();
    // Top wavy line with subtle overshoot
    path.moveTo(rect.left - 3.0, rect.top + 1.0);
    path.quadraticBezierTo(rect.center.dx, rect.top - 2.5, rect.right + 4.0, rect.top + 0.5);
    // Right wavy line
    path.quadraticBezierTo(rect.right + 2.0, rect.center.dy, rect.right + 1.0, rect.bottom + 3.0);
    // Bottom wavy line
    path.quadraticBezierTo(rect.center.dx, rect.bottom + 2.5, rect.left - 4.0, rect.bottom - 1.0);
    // Left wavy line closing
    path.quadraticBezierTo(rect.left - 1.5, rect.center.dy, rect.left - 2.0, rect.top - 2.0);

    _paintPathWithTexture(canvas, path, c, thickness, p);
  }

  // ── 9. HIGHLIGHT STROKE ───────────────────────────────────────────────────
  void _paintHighlightStroke(Canvas canvas, Size size, Color c, double p) {
    final strokeHeight = size.height * 0.65;
    final yCenter = size.height * 0.52;
    final strokeWidth = (size.width + paddingH * 2) * p;

    final paint = Paint()
      ..color = c.withValues(alpha: (c.a * 0.55).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final highlightRect = Rect.fromLTWH(
      -paddingH,
      yCenter - strokeHeight * 0.5,
      strokeWidth,
      strokeHeight,
    );

    if (texture == MarkerTexture.brushStroke) {
      // Bristled multi-brush highlight
      for (int i = 0; i < 4; i++) {
        final brPaint = Paint()
          ..color = c.withValues(alpha: (c.a * (0.2 + i * 0.1)).clamp(0.0, 1.0))
          ..strokeWidth = strokeHeight * 0.28
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final yOffset = (yCenter - strokeHeight * 0.35) + i * (strokeHeight * 0.22);
        canvas.drawLine(
          Offset(-paddingH, yOffset),
          Offset(-paddingH + strokeWidth, yOffset + (i % 2 == 0 ? 1.0 : -1.0)),
          brPaint,
        );
      }
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlightRect, const Radius.circular(3.0)),
        paint,
      );
    }
  }

  // ── 10. SIDE BRACKETS ─────────────────────────────────────────────────────
  void _paintSideBrackets(Canvas canvas, Rect rect, Color c, double p) {
    final bracketArm = 6.0 * p;

    // Left bracket '['
    final leftPath = Path()
      ..moveTo(rect.left + bracketArm, rect.top)
      ..lineTo(rect.left, rect.top)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left + bracketArm, rect.bottom);

    // Right bracket ']'
    final rightPath = Path()
      ..moveTo(rect.right - bracketArm, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right - bracketArm, rect.bottom);

    _paintPathWithTexture(canvas, leftPath, c, thickness, 1.0);
    _paintPathWithTexture(canvas, rightPath, c, thickness, 1.0);
  }

  // ── TEXTURE RENDERING PIPELINE ─────────────────────────────────────────────
  void _paintPathWithTexture(Canvas canvas, Path path, Color c, double th, double p) {
    Path effectivePath = path;
    if (p < 0.999) {
      // Animate path reveal progressively
      effectivePath = _extractProgressivePath(path, p);
    }

    switch (texture) {
      case MarkerTexture.clean:
        final paint = Paint()
          ..color = c
          ..strokeWidth = th
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(effectivePath, paint);
        break;

      case MarkerTexture.pen:
        final penPaint = Paint()
          ..color = c
          ..strokeWidth = th
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(effectivePath, penPaint);
        // Subtle secondary pen ink trail
        final secondaryPaint = Paint()
          ..color = c.withValues(alpha: c.a * 0.4)
          ..strokeWidth = th * 0.5
          ..style = PaintingStyle.stroke;
        canvas.drawPath(effectivePath, secondaryPaint);
        break;

      case MarkerTexture.crayon:
      case MarkerTexture.animatedCrayon:
        // Crayon rough textured stipple stroke
        final crayonPaint = Paint()
          ..color = c
          ..strokeWidth = th
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(effectivePath, crayonPaint);

        // Stippled textured speckles
        _drawStippledPathOverlay(canvas, effectivePath, c, th);
        break;

      case MarkerTexture.markerPen:
        // Broad chisel marker stroke with slight angle
        final markerPaint = Paint()
          ..color = c.withValues(alpha: (c.a * 0.85).clamp(0.0, 1.0))
          ..strokeWidth = th * 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.square
          ..strokeJoin = StrokeJoin.bevel;
        canvas.drawPath(effectivePath, markerPaint);
        break;

      case MarkerTexture.brushStroke:
        // Multi-strand bristled brush stroke
        for (int i = -1; i <= 1; i++) {
          final offsetPaint = Paint()
            ..color = c.withValues(alpha: (c.a * (0.55 + 0.2 * (1 - i.abs()))).clamp(0.0, 1.0))
            ..strokeWidth = th * 0.65
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
          canvas.save();
          canvas.translate(i * 1.2, i * 0.6);
          canvas.drawPath(effectivePath, offsetPaint);
          canvas.restore();
        }
        break;

      case MarkerTexture.chalk:
        final chalkBase = Paint()
          ..color = c.withValues(alpha: (c.a * 0.70).clamp(0.0, 1.0))
          ..strokeWidth = th * 1.1
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(effectivePath, chalkBase);
        _drawStippledPathOverlay(canvas, effectivePath, c.withValues(alpha: c.a * 0.6), th * 1.4);
        break;

      case MarkerTexture.pencilSketch:
        // 3 sketchy overlapping graphite passes
        for (int i = 0; i < 3; i++) {
          final sketchPaint = Paint()
            ..color = c.withValues(alpha: (c.a * (0.35 + i * 0.15)).clamp(0.0, 1.0))
            ..strokeWidth = th * 0.55
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
          canvas.save();
          canvas.translate((i - 1) * 0.8, (i == 1 ? 0.6 : -0.4));
          canvas.drawPath(effectivePath, sketchPaint);
          canvas.restore();
        }
        break;
    }
  }

  Path _extractProgressivePath(Path source, double p) {
    final metrics = source.computeMetrics().toList();
    final result = Path();
    for (final metric in metrics) {
      final extractLength = metric.length * p;
      result.addPath(metric.extractPath(0.0, extractLength), Offset.zero);
    }
    return result;
  }

  void _drawStippledPathOverlay(Canvas canvas, Path path, Color c, double width) {
    final dotPaint = Paint()
      ..color = c.withValues(alpha: (c.a * 0.45).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    for (final metric in path.computeMetrics()) {
      final step = math.max(3.0, width * 0.9);
      for (double d = 0; d < metric.length; d += step) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null) {
          final pseudoRandom = math.sin(d * 12.9898) * 43758.5453;
          final jitterX = (pseudoRandom - pseudoRandom.floor() - 0.5) * width * 0.8;
          final jitterY = ((pseudoRandom * 2) - (pseudoRandom * 2).floor() - 0.5) * width * 0.8;
          canvas.drawCircle(
            tangent.position + Offset(jitterX, jitterY),
            width * 0.25,
            dotPaint,
          );
        }
      }
    }
  }

  void _drawGrainyOutline(Canvas canvas, Rect r, Color c, {double thickness = 1.0}) {
    final paint = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6.0)), paint);
  }

  @override
  bool shouldRepaint(covariant SubtitleMarkerPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.texture != texture ||
        oldDelegate.color != color ||
        oldDelegate.thickness != thickness ||
        oldDelegate.distance != distance ||
        oldDelegate.paddingH != paddingH ||
        oldDelegate.paddingV != paddingV ||
        oldDelegate.opacity != opacity ||
        oldDelegate.progress != progress ||
        oldDelegate.animation != animation;
  }
}
