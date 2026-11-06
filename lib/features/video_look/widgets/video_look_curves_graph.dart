import 'package:flutter/material.dart';

import '../models/curve_point.dart';

/// Interactive tonal Curves graph supporting:
/// - RGB, Luma, Red, Green, Blue channel tabs
/// - Adding points on tap
/// - Dragging points with live position feedback
/// - Removing points on double-tap or long-press
/// - 8 one-click presets (Default, S-Curve, Soft, High Contrast, Fade, Matte, Dark, Bright)
/// - Reset affordance
class VideoLookCurvesGraph extends StatefulWidget {
  const VideoLookCurvesGraph({
    required this.activeChannel,
    required this.points,
    required this.activePreset,
    required this.onChannelChanged,
    required this.onPointAdded,
    required this.onPointUpdated,
    required this.onPointRemoved,
    required this.onPresetSelected,
    required this.onResetChannel,
    super.key,
  });

  final CurveChannel activeChannel;
  final List<CurvePoint> points;
  final CurvePreset activePreset;
  final ValueChanged<CurveChannel> onChannelChanged;
  final ValueChanged<CurvePoint> onPointAdded;
  final void Function(int index, CurvePoint point) onPointUpdated;
  final ValueChanged<int> onPointRemoved;
  final ValueChanged<CurvePreset> onPresetSelected;
  final VoidCallback onResetChannel;

  @override
  State<VideoLookCurvesGraph> createState() => _VideoLookCurvesGraphState();
}

class _VideoLookCurvesGraphState extends State<VideoLookCurvesGraph> {
  int? _draggedPointIndex;

  static const double _graphSize = 220.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Channel Selector Tabs ───────────────────────────────────────────
        Row(
          children: CurveChannel.values.map((channel) {
            final isSelected = channel == widget.activeChannel;
            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => widget.onChannelChanged(channel),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? channel.color.withValues(alpha: 0.2)
                          : const Color(0xFF131522),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? channel.color : const Color(0xFF26283C),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: channel.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          channel.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        // ── Interactive Curves Canvas ───────────────────────────────────────
        Center(
          child: Container(
            width: _graphSize,
            height: _graphSize,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0E16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF26283C), width: 1.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: GestureDetector(
              onTapUp: (details) {
                // If not tapping near an existing point, add a new point
                final local = details.localPosition;
                final normX = (local.dx / _graphSize).clamp(0.0, 1.0);
                final normY = (1.0 - (local.dy / _graphSize)).clamp(0.0, 1.0);
                final newX = normX * 255.0;
                final newY = normY * 255.0;

                // Check proximity to existing points
                final nearIndex = _findNearestPointIndex(local);
                if (nearIndex == null) {
                  widget.onPointAdded(CurvePoint(x: newX, y: newY));
                }
              },
              onPanStart: (details) {
                final local = details.localPosition;
                final index = _findNearestPointIndex(local);
                if (index != null) {
                  setState(() => _draggedPointIndex = index);
                }
              },
              onPanUpdate: (details) {
                if (_draggedPointIndex != null) {
                  final local = details.localPosition;
                  final normX = (local.dx / _graphSize).clamp(0.0, 1.0);
                  final normY = (1.0 - (local.dy / _graphSize)).clamp(0.0, 1.0);

                  final idx = _draggedPointIndex!;
                  // Endpoints keep their X clamped to 0 or 255
                  final effectiveX = idx == 0
                      ? 0.0
                      : (idx == widget.points.length - 1 ? 255.0 : normX * 255.0);
                  final effectiveY = normY * 255.0;

                  widget.onPointUpdated(
                    idx,
                    CurvePoint(x: effectiveX, y: effectiveY),
                  );
                }
              },
              onPanEnd: (_) {
                setState(() => _draggedPointIndex = null);
              },
              onDoubleTapDown: (details) {
                final index = _findNearestPointIndex(details.localPosition);
                if (index != null && index > 0 && index < widget.points.length - 1) {
                  widget.onPointRemoved(index);
                }
              },
              child: CustomPaint(
                size: const Size(_graphSize, _graphSize),
                painter: _CurveGraphPainter(
                  channel: widget.activeChannel,
                  points: widget.points,
                  draggedIndex: _draggedPointIndex,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Hint row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tap to add point • Drag to shape • Double-tap point to delete',
              style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
            ),
            GestureDetector(
              onTap: widget.onResetChannel,
              child: const MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  'Reset Channel',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Easy Presets Row ────────────────────────────────────────────────
        const Text(
          'CURVE PRESETS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: CurvePreset.values.map((preset) {
            final isSelected = widget.activePreset == preset;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => widget.onPresetSelected(preset),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                        : const Color(0xFF141522),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF26283C),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    preset.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFFD1D5DB),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  int? _findNearestPointIndex(Offset local) {
    const hitRadius = 14.0;
    for (int i = 0; i < widget.points.length; i++) {
      final p = widget.points[i];
      final px = (p.x / 255.0) * _graphSize;
      final py = (1.0 - (p.y / 255.0)) * _graphSize;
      final dist = (Offset(px, py) - local).distance;
      if (dist <= hitRadius) {
        return i;
      }
    }
    return null;
  }
}

class _CurveGraphPainter extends CustomPainter {
  const _CurveGraphPainter({
    required this.channel,
    required this.points,
    required this.draggedIndex,
  });

  final CurveChannel channel;
  final List<CurvePoint> points;
  final int? draggedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid lines (4x4)
    final gridPaint = Paint()
      ..color = const Color(0xFF1C1E2C)
      ..strokeWidth = 1.0;

    for (int i = 1; i < 4; i++) {
      final x = (size.width / 4) * i;
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Identity diagonal reference
    final diagPaint = Paint()
      ..color = const Color(0xFF26283C)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), diagPaint);

    if (points.isEmpty) return;

    // 3. Spline / Curve path through points
    final path = Path();
    final first = points.first;
    path.moveTo(
      (first.x / 255.0) * size.width,
      (1.0 - (first.y / 255.0)) * size.height,
    );

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      final x0 = (p0.x / 255.0) * size.width;
      final y0 = (1.0 - (p0.y / 255.0)) * size.height;
      final x1 = (p1.x / 255.0) * size.width;
      final y1 = (1.0 - (p1.y / 255.0)) * size.height;

      // Smooth cubic bezier segment
      final cx0 = x0 + (x1 - x0) / 2.0;
      final cy0 = y0;
      final cx1 = x0 + (x1 - x0) / 2.0;
      final cy1 = y1;

      path.cubicTo(cx0, cy0, cx1, cy1, x1, y1);
    }

    // Curve line glow
    final glowPaint = Paint()
      ..color = channel.color.withValues(alpha: 0.35)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, glowPaint);

    // Curve line core
    final curvePaint = Paint()
      ..color = channel.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, curvePaint);

    // 4. Draw control points
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final px = (p.x / 255.0) * size.width;
      final py = (1.0 - (p.y / 255.0)) * size.height;
      final isDragged = draggedIndex == i;

      // Point halo
      canvas.drawCircle(
        Offset(px, py),
        isDragged ? 7.0 : 5.0,
        Paint()..color = channel.color.withValues(alpha: isDragged ? 0.6 : 0.3),
      );

      // Point core
      canvas.drawCircle(
        Offset(px, py),
        isDragged ? 4.5 : 3.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CurveGraphPainter oldDelegate) => true;
}
