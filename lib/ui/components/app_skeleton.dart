import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// Skeleton placeholder for loading content.
///
/// Preferred over spinners for lists/cards (per premium-windows-ui skill).
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({this.width, this.height = 14, this.radius, super.key});

  final double? width;
  final double height;
  final double? radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          // Gentle opacity pulse: 0.45 → 0.85.
          final opacity = 0.45 + 0.4 * (0.5 + 0.5 * math.sin(_c.value * 2 * math.pi));
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(widget.radius ?? 4),
            ),
          );
        },
      ),
    );
  }
}
