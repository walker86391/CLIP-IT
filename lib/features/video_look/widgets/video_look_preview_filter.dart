import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../models/video_look_state.dart';

/// Wraps the live video player with hardware-accelerated ColorFilter matrices,
/// blur, and overlay shaders to provide real-time preview of all visual looks.
class VideoLookPreviewFilter extends StatelessWidget {
  const VideoLookPreviewFilter({
    required this.child,
    required this.state,
    super.key,
  });

  final Widget child;
  final VideoLookState state;

  @override
  Widget build(BuildContext context) {
    // 1. Build the unified 4x5 color matrix for color grading
    final matrix = _buildColorMatrix(state);

    Widget filtered = ColorFiltered(
      colorFilter: ColorFilter.matrix(matrix),
      child: child,
    );

    // 2. Hardware blur & softness (gblur/ImageFiltered)
    final totalBlur = state.blur +
        state.softBlur +
        state.gaussianBlur +
        state.lensBlur +
        state.softFocus +
        state.dreamSoftness;

    if (totalBlur > 0.5) {
      final sigma = (totalBlur / 25.0).clamp(0.1, 14.0);
      filtered = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: filtered,
      );
    }

    // 3. Stack overlays: Vignette, Film Grain, Glow, CRT Scanlines, Glitch, Flares
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          filtered,

          // Vignette Overlay
          if (state.vignetteAmount.abs() > 0.5 ||
              state.filmLookPreset != FilmLookPreset.none)
            Positioned.fill(
              child: IgnorePointer(
                child: _buildVignette(state),
              ),
            ),

          // Darken at Bottom of Frame
          if (state.darkenBottomStrength > 0.0)
            Positioned.fill(
              child: IgnorePointer(
                child: _buildDarkenBottomOverlay(state),
              ),
            ),

          // Glow / Bloom / Diffusion Overlay
          if (state.glow > 0 ||
              state.softGlow > 0 ||
              state.bloom > 0 ||
              state.neonGlow > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: _buildGlowOverlay(state),
              ),
            ),

          // Light Leak / Lens Flare / Film Burn
          if (state.lightLeakIntensity > 0 ||
              state.lensFlareIntensity > 0 ||
              state.filmBurnIntensity > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: _buildLightLeakOverlay(state),
              ),
            ),

          // CRT Scanlines
          if (state.crtScanlines > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _CrtScanlinesPainter(
                      intensity: state.crtScanlines / 100.0,
                    ),
                  ),
                ),
              ),
            ),

          // Film Grain & Dust Overlay (enhanced for Film & Retro presets)
          if (state.filmGrainAmount > 0 ||
              state.filmDust > 0 ||
              state.filmScratches > 0 ||
              state.filmLookPreset != FilmLookPreset.none)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _FilmGrainPainter(
                      grainAmount: state.filmLookPreset != FilmLookPreset.none
                          ? (math.max(state.filmGrainAmount, 30.0 * (state.filmLookIntensity / 100.0)) / 100.0)
                          : state.filmGrainAmount / 100.0,
                      grainSize: state.grainSize,
                      dustAmount: state.filmDust / 100.0,
                      scratchAmount: state.filmScratches / 100.0,
                    ),
                  ),
                ),
              ),
            ),


          // Compositing / Blend Overlay
          if (state.blendMode != LookBlendMode.normal &&
              state.overlayTintColor != Colors.transparent &&
              state.blendOpacity > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: state.overlayTintColor.withValues(
                    alpha: (state.blendOpacity / 100.0) * 0.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Calculates a 4x5 ColorFilter matrix combining all color and tone settings.
  List<double> _buildColorMatrix(VideoLookState s) {
    // Identity matrix:
    // [ 1, 0, 0, 0, 0,
    //   0, 1, 0, 0, 0,
    //   0, 0, 1, 0, 0,
    //   0, 0, 0, 1, 0 ]

    // 1. Contrast factor: 1.0 is neutral
    final c = (1.0 + (s.contrast / 100.0)).clamp(0.0, 3.0);
    final contrastOffset = 128.0 * (1.0 - c);

    // 2. Brightness & Exposure & Fade & Blacks/Whites
    final b = ((s.brightness * 1.28) + (s.exposure * 1.5) + (s.fade * 0.6) + (s.whites * 0.5) - (s.blacks * 0.5));

    // 3. Saturation factor: 1.0 is neutral
    var sat = (1.0 + (s.saturation / 100.0) + (s.vibrance / 140.0)).clamp(0.0, 3.0);
    if (s.bwEnabled || s.grayscale > 0 || s.toningPreset == ToningPreset.monochrome) {
      final bwFactor = s.bwEnabled
          ? (s.bwAmount / 100.0).clamp(0.0, 1.0)
          : (s.grayscale > 0 ? (s.grayscale / 100.0) : 1.0);
      sat = sat * (1.0 - bwFactor);
    }

    // Standard Rec. 709 luminance weights
    const lr = 0.2126;
    const lg = 0.7152;
    const lb = 0.0722;

    final sr = (1.0 - sat) * lr;
    final sg = (1.0 - sat) * lg;
    final sb = (1.0 - sat) * lb;

    // Saturation base matrix:
    var m00 = sr + sat;
    var m01 = sg;
    var m02 = sb;

    var m10 = sr;
    var m11 = sg + sat;
    var m12 = sb;

    var m20 = sr;
    var m21 = sg;
    var m22 = sb + sat;

    // 4. Contrast scaling
    m00 *= c;
    m01 *= c;
    m02 *= c;
    m10 *= c;
    m11 *= c;
    m12 *= c;
    m20 *= c;
    m21 *= c;
    m22 *= c;

    // 5. Temperature (warm adds red, cuts blue; cool does opposite)
    final temp = s.temperature * 0.65;
    // 6. Tint (green vs magenta)
    final tintVal = s.tint * 0.5;

    // 7. RGB Mix offsets
    final rMix = (s.rgbMixRed * 0.4);
    final gMix = (s.rgbMixGreen * 0.4);
    final bMix = (s.rgbMixBlue * 0.4);

    // 8. Shadow/Highlight color tint offsets
    var rTint = 0.0;
    var gTint = 0.0;
    var bTint = 0.0;

    if (s.shadowColorIntensity > 0) {
      final f = s.shadowColorIntensity / 100.0 * 30.0;
      rTint += (s.shadowColor.r - 0.5) * f;
      gTint += (s.shadowColor.g - 0.5) * f;
      bTint += (s.shadowColor.b - 0.5) * f;
    }
    if (s.highlightColorIntensity > 0) {
      final f = s.highlightColorIntensity / 100.0 * 30.0;
      rTint += (s.highlightColor.r - 0.5) * f;
      gTint += (s.highlightColor.g - 0.5) * f;
      bTint += (s.highlightColor.b - 0.5) * f;
    }
    if (s.colorizeIntensity > 0) {
      final f = s.colorizeIntensity / 100.0 * 45.0;
      rTint += (s.colorizeColor.r - 0.5) * f;
      gTint += (s.colorizeColor.g - 0.5) * f;
      bTint += (s.colorizeColor.b - 0.5) * f;
    }

    var rOff = contrastOffset + b + temp + rMix + rTint;
    var gOff = contrastOffset + b - tintVal + gMix + gTint;
    var bOff = contrastOffset + b - temp + bMix + bTint;

    // 9. Sepia blend
    final sepiaAmount = (s.sepia > 0 ? s.sepia : (s.toningPreset == ToningPreset.sepia ? s.toningIntensity : 0.0)) / 100.0;
    if (sepiaAmount > 0.01) {
      m00 = (1.0 - sepiaAmount) * m00 + sepiaAmount * 0.393 * 255 / 128;
      m01 = (1.0 - sepiaAmount) * m01 + sepiaAmount * 0.769 * 255 / 128;
      m02 = (1.0 - sepiaAmount) * m02 + sepiaAmount * 0.189 * 255 / 128;

      m10 = (1.0 - sepiaAmount) * m10 + sepiaAmount * 0.349 * 255 / 128;
      m11 = (1.0 - sepiaAmount) * m11 + sepiaAmount * 0.686 * 255 / 128;
      m12 = (1.0 - sepiaAmount) * m12 + sepiaAmount * 0.168 * 255 / 128;

      m20 = (1.0 - sepiaAmount) * m20 + sepiaAmount * 0.272 * 255 / 128;
      m21 = (1.0 - sepiaAmount) * m21 + sepiaAmount * 0.534 * 255 / 128;
      m22 = (1.0 - sepiaAmount) * m22 + sepiaAmount * 0.131 * 255 / 128;
    }

    // 10. Film & Retro Look presets color curve enhancement
    if (s.filmLookPreset != FilmLookPreset.none) {
      final intensity = (s.filmLookIntensity / 100.0).clamp(0.0, 1.0);
      switch (s.filmLookPreset) {
        case FilmLookPreset.vintageFilm:
          // Rich vintage film stock: golden amber warmth, slightly lifted blacks
          m00 = m00 * (1.0 + 0.14 * intensity);
          m11 = m11 * (1.0 + 0.05 * intensity);
          m22 = m22 * (1.0 - 0.16 * intensity);
          rOff += 24.0 * intensity;
          gOff += 12.0 * intensity;
          bOff -= 14.0 * intensity;
          break;
        case FilmLookPreset.look8mm:
          // 8mm home reel: warm nostalgic orange-gold, softened blacks, cyan shadow bias
          m00 = m00 * (1.0 + 0.22 * intensity);
          m11 = m11 * (1.0 + 0.08 * intensity);
          m22 = m22 * (1.0 - 0.24 * intensity);
          rOff += 32.0 * intensity;
          gOff += 16.0 * intensity;
          bOff -= 8.0 * intensity;
          break;
        case FilmLookPreset.look16mm:
          // 16mm indie print: organic green-cyan midtones, creamy highlights, deep filmic curve
          m00 = m00 * (1.0 + 0.08 * intensity);
          m11 = m11 * (1.0 + 0.16 * intensity);
          m22 = m22 * (1.0 - 0.04 * intensity);
          rOff += 10.0 * intensity;
          gOff += 18.0 * intensity;
          bOff += 6.0 * intensity;
          break;
        case FilmLookPreset.look35mm:
          // 35mm Hollywood motion picture: dramatic cinematic contrast, teal shadows and warm golden highlights
          m00 = m00 * (1.0 + 0.18 * intensity);
          m11 = m11 * (1.0 + 0.02 * intensity);
          m22 = m22 * (1.0 + 0.14 * intensity);
          rOff += 18.0 * intensity;
          gOff -= 4.0 * intensity;
          bOff += 22.0 * intensity;
          break;
        case FilmLookPreset.super8Look:
          // Super 8: saturated home movie warmth, golden orange halation, nostalgic glow
          m00 = m00 * (1.0 + 0.26 * intensity);
          m11 = m11 * (1.0 + 0.14 * intensity);
          m22 = m22 * (1.0 - 0.22 * intensity);
          rOff += 28.0 * intensity;
          gOff += 20.0 * intensity;
          bOff -= 16.0 * intensity;
          break;
        default:
          break;
      }
    }

    // 11. Negative / Invert Creative look
    if (s.creativePreset == CreativeLookPreset.negative) {
      m00 = -m00;
      m11 = -m11;
      m22 = -m22;
      rOff += 255;
      gOff += 255;
      bOff += 255;
    }

    return [
      m00, m01, m02, 0.0, rOff,
      m10, m11, m12, 0.0, gOff,
      m20, m21, m22, 0.0, bOff,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }

  Widget _buildVignette(VideoLookState s) {
    var rawAmount = s.vignetteAmount / 100.0;
    if (s.filmLookPreset != FilmLookPreset.none && rawAmount.abs() < 0.15) {
      rawAmount = 0.35 * (s.filmLookIntensity / 100.0);
    }
    final amount = rawAmount.clamp(-1.0, 1.0);
    final softness = (s.vignetteSoftness / 100.0).clamp(0.1, 1.0);

    final isEdgeDarkening = s.vignetteStyle == VignetteStyle.edgeDarkening;
    final isHard = s.vignetteStyle == VignetteStyle.hardVignette;

    final color = amount > 0 ? Colors.black : Colors.white;
    final alpha = (amount.abs() * (isEdgeDarkening ? 0.85 : 0.7)).clamp(0.0, 0.95);

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: isHard ? 0.65 : (0.7 + (1.0 - softness) * 0.4),
          colors: [
            Colors.transparent,
            color.withValues(alpha: alpha * 0.4),
            color.withValues(alpha: alpha),
          ],
          stops: [
            0.0,
            (0.55 - (softness * 0.2)).clamp(0.1, 0.8),
            1.0,
          ],
        ),
      ),
    );
  }

  Widget _buildDarkenBottomOverlay(VideoLookState s) {
    final alpha = (s.darkenBottomStrength / 100.0).clamp(0.0, 1.0);
    final spread = (s.darkenBottomSpread / 100.0).clamp(0.05, 1.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        widthFactor: 1.0,
        heightFactor: (0.15 + spread * 0.65).clamp(0.15, 0.85),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4, 1.0],
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: alpha * 0.5),
                Colors.black.withValues(alpha: alpha),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowOverlay(VideoLookState s) {
    final intensity = (math.max(s.glow, math.max(s.softGlow, s.bloom)) / 100.0).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: intensity * 0.25),
            Colors.transparent,
          ],
          radius: 0.8,
        ),
      ),
    );
  }

  Widget _buildLightLeakOverlay(VideoLookState s) {
    final leakIntensity = (s.lightLeakIntensity / 100.0).clamp(0.0, 1.0);
    final flareIntensity = (s.lensFlareIntensity / 100.0).clamp(0.0, 1.0);
    final total = math.max(leakIntensity, flareIntensity);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: total * 0.35),
            const Color(0xFFEF4444).withValues(alpha: total * 0.15),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

/// Painter for CRT horizontal scanline effect.
class _CrtScanlinesPainter extends CustomPainter {
  const _CrtScanlinesPainter({required this.intensity});

  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: (intensity * 0.4).clamp(0.0, 0.7))
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += 3.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CrtScanlinesPainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}

/// Painter for realistic Film Grain, Dust, and Scratches overlay.
class _FilmGrainPainter extends CustomPainter {
  const _FilmGrainPainter({
    required this.grainAmount,
    required this.grainSize,
    required this.dustAmount,
    required this.scratchAmount,
  });

  final double grainAmount;
  final double grainSize;
  final double dustAmount;
  final double scratchAmount;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Film grain noise particles
    if (grainAmount > 0.01) {
      final random = math.Random(42);
      final dotCount = (size.width * size.height * 0.0025 * grainAmount).round();
      final grainPaint = Paint()
        ..color = Colors.white.withValues(alpha: (grainAmount * 0.22).clamp(0.02, 0.35))
        ..strokeWidth = (grainSize * 0.5).clamp(1.0, 3.0);

      final points = <Offset>[];
      for (int i = 0; i < dotCount; i++) {
        points.add(Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ));
      }
      grainPaint.strokeCap = StrokeCap.round;
      canvas.drawPoints(ui.PointMode.points, points, grainPaint);
    }

    // 2. Film scratches
    if (scratchAmount > 0.01) {
      final scratchPaint = Paint()
        ..color = Colors.white.withValues(alpha: (scratchAmount * 0.4).clamp(0.05, 0.6))
        ..strokeWidth = 1.0;

      // Draw subtle vertical scratch streaks
      canvas.drawLine(
        Offset(size.width * 0.32, 0),
        Offset(size.width * 0.32, size.height),
        scratchPaint,
      );
      if (scratchAmount > 0.4) {
        canvas.drawLine(
          Offset(size.width * 0.68, 0),
          Offset(size.width * 0.68, size.height),
          scratchPaint,
        );
      }
    }

    // 3. Film dust specks
    if (dustAmount > 0.01) {
      final dustPaint = Paint()
        ..color = Colors.black.withValues(alpha: (dustAmount * 0.5).clamp(0.1, 0.7));
      final random = math.Random(108);
      for (int i = 0; i < (dustAmount * 8).round(); i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        canvas.drawCircle(Offset(x, y), 2.2, dustPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FilmGrainPainter oldDelegate) =>
      oldDelegate.grainAmount != grainAmount ||
      oldDelegate.grainSize != grainSize ||
      oldDelegate.dustAmount != dustAmount ||
      oldDelegate.scratchAmount != scratchAmount;
}
