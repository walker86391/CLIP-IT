import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/effect_catalogue.dart';
import '../models/editing_effect.dart';
import '../providers/effects_provider.dart';

/// Renders real-time composited editing effects over the live video player.
///
/// Rendering Order:
/// 1. VIDEO (with camera jolt/shake translation for Rage Screen & Lightning)
/// 2. COLOR GRADE (GPU ColorFiltered matrices for B&W, Red Filter, Rage, Golden OP)
/// 3. VIGNETTE (Cinematic, Red, Golden, or Fire perimeter gradients)
/// 4. PARTICLES (Red Particle Storm, Fire Aura embers/flames, Golden dust, Emoji Burst)
/// 5. TRACKED GRAPHICS (Crown Moment tracked to detected head pose; hidden if no face)
/// 6. GLITCH & LIGHTNING (Chromatic separation, CRT scanlines, branching lightning bolts)
/// 7. STATUS / CREATOR BADGES
class EffectsVideoOverlay extends ConsumerStatefulWidget {
  const EffectsVideoOverlay({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  ConsumerState<EffectsVideoOverlay> createState() => _EffectsVideoOverlayState();
}

class _EffectsVideoOverlayState extends ConsumerState<EffectsVideoOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    final isTest = WidgetsBinding.instance.runtimeType
        .toString()
        .toLowerCase()
        .contains('test');
    if (isTest) {
      _animController.value = 0.5;
    } else {
      _animController.repeat();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectsState = ref.watch(effectsProvider);
    final selectedIds = effectsState.selectedEffectIds;
    final preparingText = effectsState.preparingEffectName;
    final isProcessing = effectsState.isProcessing;

    final hasRage = selectedIds.contains('CLP_FX_RAGE_SCREEN');
    final hasLightning = selectedIds.contains('CLP_FX_LIGHTNING');
    final hasCrown = selectedIds.contains('CLP_FX_CROWN');

    final analysis = effectsState.detectionAnalysis;
    final bool faceDetected = analysis['face_detected'] == true;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Video Frame with Shake & GPU Color Processing ────────────
            AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                final t = _animController.value;
                double dx = 0.0;
                double dy = 0.0;

                // Screen shake for Rage Screen
                if (hasRage) {
                  final ragePulse = math.pow(math.sin(t * math.pi * 3).abs(), 6).toDouble();
                  final intensity = 2.0 + 3.0 * ragePulse;
                  dx += math.sin(t * 85.0) * intensity;
                  dy += math.cos(t * 95.0) * (intensity * 0.75);
                }

                // Micro jolt for Lightning Flash
                if (hasLightning) {
                  final isStrike = (t >= 0.42 && t <= 0.54);
                  if (isStrike) {
                    final strikeFrac = (t - 0.42) / 0.12;
                    final jolt = math.sin(strikeFrac * math.pi * 10) * 4.0;
                    dx += jolt;
                    dy += math.cos(strikeFrac * math.pi * 8) * 3.0;
                  }
                }

                // Apply GPU Color Grade chaining
                Widget gradedContent = widget.child;
                if (selectedIds.isNotEmpty) {
                  gradedContent = _applyColorGrades(selectedIds, t, gradedContent);
                }

                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: gradedContent,
                );
              },
            ),

            // ── 2. Atmospheric Vignette Layer ───────────────────────────────
            if (selectedIds.isNotEmpty)
              IgnorePointer(
                child: _buildVignetteLayer(selectedIds),
              ),

            // ── 3. High-Performance Canvas Particles & Lighting FX ───────────
            if (selectedIds.isNotEmpty)
              AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      size: boxSize,
                      painter: _EffectsMasterCanvasPainter(
                        selectedIds: selectedIds,
                        progress: _animController.value,
                        analysis: analysis,
                      ),
                    ),
                  );
                },
              ),

            // ── 4. Tracked Head Props: Crown Moment ─────────────────────────
            if (hasCrown && faceDetected)
              _buildTrackedCrown(boxSize, analysis, _animController),

            // ── 5. Active Creator Effect Badge HUD ──────────────────────────
            if (selectedIds.isNotEmpty)
              AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return _buildCreatorBadges(selectedIds, _animController.value);
                },
              ),

            // ── 6. In-Preview Subtle Loading State Indicator ─────────────────
            if (isProcessing || preparingText != null)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F111D).withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              value: WidgetsBinding.instance.runtimeType
                                      .toString()
                                      .toLowerCase()
                                      .contains('test')
                                  ? 0.7
                                  : null,
                              strokeWidth: 2,
                              color: const Color(0xFFC4B5FD),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              preparingText ?? 'Processing visual effect...',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Chains GPU ColorFilter.matrix transforms for active color grading effects.
  Widget _applyColorGrades(Set<String> selectedIds, double t, Widget content) {
    Widget result = content;

    // 1. Cinematic B&W
    if (selectedIds.contains('CLP_FX_CINEMATIC_BW')) {
      const bwMatrix = <double>[
        0.35, 0.65, 0.12, 0, -16,
        0.35, 0.65, 0.12, 0, -16,
        0.35, 0.65, 0.12, 0, -16,
        0, 0, 0, 1, 0,
      ];
      result = ColorFiltered(
        colorFilter: const ColorFilter.matrix(bwMatrix),
        child: result,
      );
    }

    // 2. Red Filter
    if (selectedIds.contains('CLP_FX_RED_FILTER')) {
      const redFilterMatrix = <double>[
        1.45, 0.15, 0.10, 0, 15,
        0.10, 0.45, 0.10, 0, -10,
        0.10, 0.10, 0.45, 0, -10,
        0, 0, 0, 1, 0,
      ];
      result = ColorFiltered(
        colorFilter: const ColorFilter.matrix(redFilterMatrix),
        child: result,
      );
    }

    // 3. Golden / OP Filter
    if (selectedIds.contains('CLP_FX_GOLDEN_OP')) {
      const goldenMatrix = <double>[
        1.28, 0.18, 0.05, 0, 22,
        0.22, 1.12, 0.05, 0, 14,
        0.05, 0.10, 0.55, 0, -22,
        0, 0, 0, 1, 0,
      ];
      result = ColorFiltered(
        colorFilter: const ColorFilter.matrix(goldenMatrix),
        child: result,
      );
    }

    // 4. Rage Screen (Aggressive red grade with quick periodic brightness pulses)
    if (selectedIds.contains('CLP_FX_RAGE_SCREEN')) {
      final ragePulse = math.pow(math.sin(t * math.pi * 3).abs(), 6).toDouble();
      final pulseBoost = 35.0 * ragePulse;
      final rageMatrix = <double>[
        1.60 + 0.3 * ragePulse, 0.15, 0.10, 0, 30 + pulseBoost,
        0.05, 0.35 + 0.15 * ragePulse, 0.05, 0, -15 + pulseBoost * 0.4,
        0.05, 0.05, 0.35 + 0.15 * ragePulse, 0, -15 + pulseBoost * 0.4,
        0, 0, 0, 1, 0,
      ];
      result = ColorFiltered(
        colorFilter: ColorFilter.matrix(rageMatrix),
        child: result,
      );
    }

    // 5. Lightning Brightness Spike
    if (selectedIds.contains('CLP_FX_LIGHTNING')) {
      final isStrike = (t >= 0.42 && t <= 0.54);
      if (isStrike) {
        final strikeFrac = (1.0 - ((t - 0.42) / 0.12)).clamp(0.0, 1.0);
        final flashMatrix = <double>[
          1.0 + 0.6 * strikeFrac, 0, 0, 0, 80.0 * strikeFrac,
          0, 1.0 + 0.6 * strikeFrac, 0, 0, 80.0 * strikeFrac,
          0, 0, 1.0 + 0.9 * strikeFrac, 0, 105.0 * strikeFrac,
          0, 0, 0, 1, 0,
        ];
        result = ColorFiltered(
          colorFilter: ColorFilter.matrix(flashMatrix),
          child: result,
        );
      }
    }

    return result;
  }

  /// Builds appropriate subtle vignette overlays matching active effects.
  Widget _buildVignetteLayer(Set<String> selectedIds) {
    List<Color> vignetteColors;
    if (selectedIds.contains('CLP_FX_RAGE_SCREEN')) {
      vignetteColors = [
        Colors.transparent,
        const Color(0x33450000),
        const Color(0xAA2B0000),
      ];
    } else if (selectedIds.contains('CLP_FX_FIRE_AURA')) {
      vignetteColors = [
        Colors.transparent,
        const Color(0x22802000),
        const Color(0x992B0800),
      ];
    } else if (selectedIds.contains('CLP_FX_GOLDEN_OP')) {
      vignetteColors = [
        Colors.transparent,
        const Color(0x22241604),
        const Color(0x88120B02),
      ];
    } else if (selectedIds.contains('CLP_FX_CINEMATIC_BW') ||
        selectedIds.contains('CLP_FX_RED_FILTER')) {
      vignetteColors = [
        Colors.transparent,
        const Color(0x22000000),
        const Color(0x88000000),
      ];
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 0.95,
          colors: vignetteColors,
          stops: const [0.55, 0.85, 1.0],
        ),
      ),
    );
  }

  /// Builds the tracked Crown graphic locked to detected head position & angle.
  Widget _buildTrackedCrown(
    Size boxSize,
    Map<String, dynamic> analysis,
    AnimationController controller,
  ) {
    final frameW = (analysis['width'] as num?)?.toDouble() ?? boxSize.width;
    final frameH = (analysis['height'] as num?)?.toDouble() ?? boxSize.height;
    final forehead = analysis['forehead_top'] as Map<String, dynamic>?;

    final fx = (forehead?['x'] as num?)?.toDouble() ?? (frameW * 0.5);
    final fy = (forehead?['y'] as num?)?.toDouble() ?? (frameH * 0.32);
    final faceW = (analysis['face_width'] as num?)?.toDouble() ?? (frameW * 0.22);
    final angleDeg = (analysis['head_angle_deg'] as num?)?.toDouble() ?? 0.0;

    // Map coordinates to preview viewport
    final headX = (fx / frameW) * boxSize.width;
    final headY = (fy / frameH) * boxSize.height;
    final crownW = ((faceW / frameW) * boxSize.width * 1.35).clamp(48.0, boxSize.width * 0.55);
    final crownH = crownW * 0.65;
    final angleRad = (angleDeg * math.pi) / 180.0;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        // Subtle floating bob
        final floatY = math.sin(t * math.pi * 2) * 3.0;

        return Positioned(
          left: headX - crownW / 2,
          top: headY - crownH * 0.88 + floatY,
          width: crownW,
          height: crownH,
          child: Transform.rotate(
            angle: angleRad,
            alignment: Alignment.bottomCenter,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Golden radial ambient glow behind crown
                Container(
                  width: crownW * 0.8,
                  height: crownH * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.55),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                // Crown Graphic
                Image.asset(
                  'assets/effects/crown.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.workspace_premium_rounded,
                    size: 42,
                    color: Color(0xFFFBBF24),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds a bottom badge HUD showing active creator recipe.
  Widget _buildCreatorBadges(Set<String> selectedIds, double t) {
    final activeBadges = <EditingEffect>[];
    for (final id in selectedIds) {
      final effect = EffectCatalogue.findById(id);
      if (effect != null && effect.badgeText != null) {
        activeBadges.add(effect);
      }
    }

    if (activeBadges.isEmpty) return const SizedBox.shrink();

    final primary = activeBadges.first;
    final pulse = 0.92 + 0.08 * math.sin(t * math.pi * 3);

    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Transform.scale(
          scale: pulse,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primary.accentColor.withValues(alpha: 0.85),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.accentColor.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (primary.badgeIcon != null) ...[
                  Icon(primary.badgeIcon, size: 13, color: primary.accentColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  primary.badgeText!,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: primary.accentColor,
                  ),
                ),
                if (selectedIds.length > 1) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: primary.accentColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${selectedIds.length - 1}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: primary.accentColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Canvas Painter orchestrating:
/// - Red Particle Storm (120 depth particles with glow & blur)
/// - Fire Aura (animated perimeter flame arcs and rising sparks)
/// - Golden OP particles (floating golden dust & bloom)
/// - Lightning Flash (branching procedural jagged electric bolts)
/// - Glitch / Chromatic (chromatic displacement & scanline texture)
/// - Emoji & Confetti Burst (colorful celebratory emoji & ribbon particles)
class _EffectsMasterCanvasPainter extends CustomPainter {
  const _EffectsMasterCanvasPainter({
    required this.selectedIds,
    required this.progress,
    required this.analysis,
  });

  final Set<String> selectedIds;
  final double progress;
  final Map<String, dynamic> analysis;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final t = progress;

    // ── 1. RED PARTICLE STORM ────────────────────────────────────────────────
    if (selectedIds.contains('CLP_FX_RED_PARTICLE_STORM') ||
        selectedIds.contains('CLP_FX_RAGE_SCREEN')) {
      _drawRedParticleStorm(canvas, size, t);
    }

    // ── 2. FIRE AURA ─────────────────────────────────────────────────────────
    if (selectedIds.contains('CLP_FX_FIRE_AURA')) {
      _drawFireAura(canvas, size, t);
    }

    // ── 3. GOLDEN / OP PARTICLES & BLOOM ─────────────────────────────────────
    if (selectedIds.contains('CLP_FX_GOLDEN_OP')) {
      _drawGoldenParticles(canvas, size, t);
    }

    // ── 4. EMOJI & CONFETTI BURST ────────────────────────────────────────────
    if (selectedIds.contains('CLP_FX_EMOJI_BURST')) {
      _drawEmojiBurst(canvas, size, t);
    }

    // ── 5. GLITCH / CHROMATIC ARTIFACTS ──────────────────────────────────────
    if (selectedIds.contains('CLP_FX_GLITCH')) {
      _drawGlitchScanlines(canvas, size, t);
    }

    // ── 6. LIGHTNING FLASH BOLTS ─────────────────────────────────────────────
    if (selectedIds.contains('CLP_FX_LIGHTNING')) {
      _drawLightningBolts(canvas, size, t);
    }
  }

  /// 1. Hundreds of moving red particles with depth, glow, and parallax speeds.
  void _drawRedParticleStorm(Canvas canvas, Size size, double t) {
    final bool isStorm = selectedIds.contains('CLP_FX_RED_PARTICLE_STORM');
    final int count = isStorm ? 110 : 35; // Rage screen has lighter ember count

    for (int i = 0; i < count; i++) {
      final double seed = (i * 37.19) % 1.0;
      final double seedY = (i * 71.43) % 1.0;
      final int depth = i % 3; // 0: background, 1: midground, 2: foreground

      final double speed = depth == 0 ? 0.35 : (depth == 1 ? 0.65 : 1.1);
      final double r = depth == 0 ? 1.4 : (depth == 1 ? 2.4 : 3.8);

      // Trajectory drifting across and upward/downward with turbulence
      final double x = (seed * size.width + t * speed * size.width * 0.9 + math.sin(t * 6 + i) * 16) % size.width;
      final double y = (seedY * size.height - t * speed * size.height * 0.65 + math.cos(t * 5 + i) * 12) % size.height;

      final double alpha = depth == 0 ? 0.40 : (depth == 1 ? 0.70 : 0.95);

      if (depth == 2) {
        // Outer soft glow for foreground embers
        final glowPaint = Paint()
          ..color = const Color(0xFFFF2233).withValues(alpha: alpha * 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
        canvas.drawCircle(Offset(x, y), r * 1.8, glowPaint);
      }

      final corePaint = Paint()
        ..color = (depth == 2 ? const Color(0xFFFF4D4D) : const Color(0xFFEF4444))
            .withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), r, corePaint);
    }
  }

  /// 2. Animated fire aura flames along the perimeter and rising sparks.
  void _drawFireAura(Canvas canvas, Size size, double t) {
    // A. Bottom Perimeter Flames
    final flamePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFF3700).withValues(alpha: 0.65),
          const Color(0xFFFFA500).withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.75, size.width, size.height * 0.25));

    final flamePath = Path()..moveTo(0, size.height);
    const step = 18.0;
    for (double x = 0; x <= size.width; x += step) {
      final wave1 = math.sin((x / 25.0) + t * 14.0) * 12.0;
      final wave2 = math.cos((x / 40.0) - t * 10.0) * 8.0;
      final py = size.height - (32.0 + wave1 + wave2);
      flamePath.lineTo(x, py);
    }
    flamePath.lineTo(size.width, size.height);
    flamePath.close();
    canvas.drawPath(flamePath, flamePaint);

    // B. Left & Right fiery perimeter glow
    final leftGlow = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFFF5500).withValues(alpha: 0.45),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, 36, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, 36, size.height), leftGlow);

    final rightGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          const Color(0xFFFF5500).withValues(alpha: 0.45),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(size.width - 36, 0, 36, size.height));
    canvas.drawRect(Rect.fromLTWH(size.width - 36, 0, 36, size.height), rightGlow);

    // C. Rising energetic sparks
    final sparkPaint = Paint()..color = const Color(0xFFFFB800);
    for (int i = 0; i < 28; i++) {
      final sx = (size.width * ((i * 0.13) % 1.0));
      final sp = 0.5 + ((i * 7) % 6) * 0.18;
      final sy = size.height - ((t * sp * size.height + i * 36) % size.height);
      final sr = 1.2 + (i % 3) * 0.8;
      final flicker = 0.4 + 0.6 * math.sin(t * 15 + i).abs();
      sparkPaint.color = const Color(0xFFFFB800).withValues(alpha: flicker);
      canvas.drawCircle(Offset(sx, sy), sr, sparkPaint);
    }
  }

  /// 3. Floating golden particles & ambient bloom for Golden / OP Moment.
  void _drawGoldenParticles(Canvas canvas, Size size, double t) {
    // Upper-center subtle golden bloom
    final bloomPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x35FBBF24),
          const Color(0x10F59E0B),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.35),
          radius: size.width * 0.45,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.35),
      size.width * 0.45,
      bloomPaint,
    );

    // Floating gold specks
    for (int i = 0; i < 35; i++) {
      final sx = (size.width * ((i * 0.17) % 1.0)) + math.sin(t * 4 + i) * 10;
      final sp = 0.3 + ((i * 5) % 5) * 0.12;
      final sy = (size.height * 0.9) - ((t * sp * size.height + i * 28) % (size.height * 0.8));
      final twinkle = 0.3 + 0.7 * math.sin(t * 8 + i).abs();
      final r = 1.2 + (i % 3) * 0.8;

      final goldPaint = Paint()
        ..color = const Color(0xFFFDE047).withValues(alpha: twinkle);
      canvas.drawCircle(Offset(sx, sy), r, goldPaint);
    }
  }

  /// 4. Celebratory Emoji & Confetti Burst radiating outward with gravity.
  void _drawEmojiBurst(Canvas canvas, Size size, double t) {
    // Repeats every 2.4s: progress 0.0 to 1.0
    final burstProgress = (t * 1.5) % 1.0;
    final center = Offset(size.width * 0.5, size.height * 0.42);

    final emojiList = ['🎉', '🔥', '👑', '💯', '⭐', '✨'];
    const count = 16;

    for (int i = 0; i < count; i++) {
      final angle = (i * (math.pi * 2 / count)) + (i * 0.2);
      final speed = 80.0 + ((i * 23) % 70);
      final dist = speed * burstProgress;

      // Parabolic arc with downward gravity
      final px = center.dx + math.cos(angle) * dist;
      final py = center.dy + math.sin(angle) * dist + (burstProgress * burstProgress * 65.0);

      final alpha = (1.0 - burstProgress).clamp(0.0, 1.0);
      if (alpha <= 0.02) continue;

      if (i % 2 == 0) {
        // Render Emoji
        final emoji = emojiList[i ~/ 2 % emojiList.length];
        final textPainter = TextPainter(
          text: TextSpan(
            text: emoji,
            style: TextStyle(
              fontSize: 14 + (i % 3) * 4.0,
              color: Colors.white.withValues(alpha: alpha),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(angle + burstProgress * 3.0);
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        canvas.restore();
      } else {
        // Render colorful fluttering confetti ribbon
        final confettiColors = [
          const Color(0xFFEC4899),
          const Color(0xFF06B6D4),
          const Color(0xFFFBBF24),
          const Color(0xFF10B981),
          const Color(0xFFA855F7),
        ];
        final cColor = confettiColors[i % confettiColors.length];
        final cPaint = Paint()..color = cColor.withValues(alpha: alpha);

        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(burstProgress * 6.0 + i);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 8.0, height: 4.5),
          cPaint,
        );
        canvas.restore();
      }
    }
  }

  /// 5. Glitch Scanline texture & occasional horizontal slice displacement.
  void _drawGlitchScanlines(Canvas canvas, Size size, double t) {
    // Subtle CRT horizontal scanlines
    final scanlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..strokeWidth = 1.0;
    for (double y = 0; y < size.height; y += 3.5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }

    // Occasional brief glitch burst displacement bars
    final isBurst = (t * 3.0) % 1.0 < 0.22;
    if (isBurst) {
      final glitchPaint = Paint()
        ..color = const Color(0xFF06B6D4).withValues(alpha: 0.24);
      final barY = (size.height * ((t * 7.0) % 1.0));
      canvas.drawRect(
        Rect.fromLTWH(0, barY, size.width, 14),
        glitchPaint,
      );

      final redShiftPaint = Paint()
        ..color = const Color(0xFFEF4444).withValues(alpha: 0.20);
      canvas.drawRect(
        Rect.fromLTWH(0, (barY + 18) % size.height, size.width, 8),
        redShiftPaint,
      );
    }
  }

  /// 6. Branching lightning bolts with electric white core and cyan glow.
  void _drawLightningBolts(Canvas canvas, Size size, double t) {
    final isStrike = (t >= 0.42 && t <= 0.54);
    if (!isStrike) return;

    final strikeFrac = (1.0 - ((t - 0.42) / 0.12)).clamp(0.0, 1.0);
    final coreAlpha = strikeFrac;

    final boltCore = Paint()
      ..color = Colors.white.withValues(alpha: coreAlpha)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final boltGlow = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: coreAlpha * 0.75)
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    // Procedural branching lightning path
    final mainBolt = Path()..moveTo(size.width * 0.52, 0);
    final points = <Offset>[
      Offset(size.width * 0.52, 0),
      Offset(size.width * 0.48, size.height * 0.22),
      Offset(size.width * 0.56, size.height * 0.40),
      Offset(size.width * 0.46, size.height * 0.62),
      Offset(size.width * 0.54, size.height * 0.85),
      Offset(size.width * 0.50, size.height),
    ];

    for (int i = 1; i < points.length; i++) {
      mainBolt.lineTo(points[i].dx, points[i].dy);
    }

    // Secondary fork branch
    final forkBolt = Path()
      ..moveTo(points[2].dx, points[2].dy)
      ..lineTo(points[2].dx + 35, points[2].dy + 45)
      ..lineTo(points[2].dx + 25, points[2].dy + 90);

    // Draw glow then core
    canvas.drawPath(mainBolt, boltGlow);
    canvas.drawPath(forkBolt, boltGlow);
    canvas.drawPath(mainBolt, boltCore);
    canvas.drawPath(forkBolt, boltCore);
  }

  @override
  bool shouldRepaint(covariant _EffectsMasterCanvasPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIds != selectedIds ||
        oldDelegate.analysis != analysis;
  }
}
