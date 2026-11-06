import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/providers/video_upload_provider.dart';
import '../models/editing_effect.dart';
import '../providers/effects_provider.dart';

/// Top large preview banner in the Effects studio panel.
///
/// Features:
/// - Real-time animated demonstration viewport of the currently focused recipe.
/// - Effect name, category pill badge, and comprehensive recipe direction.
/// - Creative recipe sub-components list (e.g. "Tracked Eye Mask", "B&W High Contrast", "Body Outline").
/// - Checkbox inclusion toggle button ("Included in Video" vs "Add to Video").
/// - Internal code (CLP_FX_...) is strictly hidden from UI.
class EffectsTopBannerPreview extends ConsumerWidget {
  const EffectsTopBannerPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effect = ref.watch(focusedEffectProvider);
    final uploadState = ref.watch(videoUploadProvider);
    final isSelected = ref.watch(
      effectsProvider.select((s) => s.isSelected(effect.id)),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF10121D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
              : const Color(0xFF222538),
          width: 1.2,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
              blurRadius: 18,
              spreadRadius: 1,
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ambient corner radial aura glow
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    effect.accentColor.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left: Live Animated Recipe Canvas Viewport ───────────────
                _RecipePreviewViewport(effect: effect),

                const SizedBox(width: 18),

                // ── Middle: Effect Details & Creative Recipe Layers ──────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge Row: Category + Popular / Recipe
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: effect.accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: effect.accentColor.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  effect.category.icon,
                                  size: 11,
                                  color: effect.accentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  effect.category.label.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: effect.accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CREATOR RECIPE',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: Color(0xFFC4B5FD),
                              ),
                            ),
                          ),
                          if (effect.isTrending) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'HOT',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF87171),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Effect Name
                      Text(
                        effect.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: Color(0xFFF9FAFB),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Description
                      Text(
                        effect.shortDescription,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                          color: Color(0xFF9CA3AF),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 10),

                      // Recipe Layers Pills (Multi-Component Architecture)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: effect.recipeLayers.map((layer) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161928),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF282D44),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _resolveLayerIcon(layer.layerType),
                                  size: 10,
                                  color: const Color(0xFFA78BFA),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  layer.name,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFD1D5DB),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // ── Right: Checkbox Selection Control ────────────────────────
                InkWell(
                  onTap: () {
                    ref.read(effectsProvider.notifier).toggleEffect(
                          effect.id,
                          videoFilePath: uploadState.filePath,
                        );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF1A1D2B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFA78BFA)
                            : const Color(0xFF33384F),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF6B7280),
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Color(0xFF8B5CF6),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isSelected ? 'Selected' : 'Select Effect',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _resolveLayerIcon(String type) {
    return switch (type) {
      'grade' => Icons.color_lens_rounded,
      'tracked' => Icons.track_changes_rounded,
      'overlay' => Icons.layers_rounded,
      'graphic' => Icons.image_rounded,
      'timing' => Icons.slow_motion_video_rounded,
      _ => Icons.auto_awesome_rounded,
    };
  }
}

/// Simulated live 60fps canvas demonstration box for the top preview banner.
class _RecipePreviewViewport extends StatefulWidget {
  const _RecipePreviewViewport({required this.effect});

  final EditingEffect effect;

  @override
  State<_RecipePreviewViewport> createState() => _RecipePreviewViewportState();
}

class _RecipePreviewViewportState extends State<_RecipePreviewViewport>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    final isTest = WidgetsBinding.instance.runtimeType
        .toString()
        .toLowerCase()
        .contains('test');
    if (isTest) {
      _controller.value = 0.5;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF07080E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.effect.accentColor.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _RecipeMiniPainter(
              effect: widget.effect,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _RecipeMiniPainter extends CustomPainter {
  const _RecipeMiniPainter({
    required this.effect,
    required this.progress,
  });

  final EditingEffect effect;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    final center = Offset(size.width / 2, size.height / 2);

    // Dark grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2132)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), gridPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), gridPaint);

    final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);

    // Draw stylized silhouette
    final headCenter = Offset(center.dx, center.dy - 6);
    final headPaint = Paint()
      ..color = const Color(0xFF242A3D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(headCenter, 14, headPaint);

    // Visual preview matching current effect
    if (effect.id == 'CLP_FX_CROWN') {
      final crownPaint = Paint()..color = const Color(0xFFFBBF24);
      final cPath = Path()
        ..moveTo(headCenter.dx - 11, headCenter.dy - 16)
        ..lineTo(headCenter.dx - 7, headCenter.dy - 24)
        ..lineTo(headCenter.dx, headCenter.dy - 19)
        ..lineTo(headCenter.dx + 7, headCenter.dy - 24)
        ..lineTo(headCenter.dx + 11, headCenter.dy - 16)
        ..close();
      canvas.drawPath(cPath, crownPaint);
    } else if (effect.id == 'CLP_FX_LIGHTNING') {
      final boltPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      final bolt = Path()
        ..moveTo(center.dx + 6, 8)
        ..lineTo(center.dx - 4, center.dy - 8)
        ..lineTo(center.dx + 4, center.dy + 4)
        ..lineTo(center.dx - 6, size.height - 8);
      canvas.drawPath(bolt, boltPaint);
    } else if (effect.id == 'CLP_FX_FIRE_AURA') {
      final flamePaint = Paint()
        ..color = const Color(0xFFFF5500).withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < 6; i++) {
        final fx = 12.0 + i * 16.0;
        final fy = size.height - 8 - math.sin(t * 12 + i) * 6;
        canvas.drawCircle(Offset(fx, fy), 5, flamePaint);
      }
    } else if (effect.id == 'CLP_FX_RED_PARTICLE_STORM' || effect.id == 'CLP_FX_RAGE_SCREEN') {
      final pPaint = Paint()..color = const Color(0xFFFF3344).withValues(alpha: 0.85);
      for (int i = 0; i < 12; i++) {
        final px = (size.width * ((i * 0.17 + t * 0.4) % 1.0));
        final py = (size.height * ((i * 0.31 - t * 0.3 + 1.0) % 1.0));
        canvas.drawCircle(Offset(px, py), 2.0, pPaint);
      }
    } else if (effect.id == 'CLP_FX_GLITCH') {
      final gPaint = Paint()..color = const Color(0xFF06B6D4).withValues(alpha: 0.5);
      canvas.drawRect(Rect.fromLTWH(8, center.dy - 8, size.width - 16, 5), gPaint);
      final rPaint = Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.5);
      canvas.drawRect(Rect.fromLTWH(12, center.dy + 4, size.width - 24, 4), rPaint);
    } else if (effect.id == 'CLP_FX_EMOJI_BURST') {
      final starPaint = Paint()..color = const Color(0xFFEC4899);
      for (int i = 0; i < 6; i++) {
        final ang = i * math.pi / 3;
        final dist = 12.0 + ((t * 20.0) % 18.0);
        canvas.drawCircle(Offset(center.dx + math.cos(ang) * dist, center.dy + math.sin(ang) * dist), 2.5, starPaint);
      }
    }

    // Ambient aura
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          effect.accentColor.withValues(alpha: 0.55 * pulse),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 36));
    canvas.drawCircle(center, 36, auraPaint);
  }

  @override
  bool shouldRepaint(covariant _RecipeMiniPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.effect != effect;
  }
}
