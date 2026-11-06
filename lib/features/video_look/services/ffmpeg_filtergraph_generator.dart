import 'dart:math' as math;

import '../models/video_look_state.dart';

/// Prepares and generates deterministic FFmpeg video filter-graphs
/// directly from the unified [VideoLookState].
///
/// This layer ensures that every visual look chosen in ClipIt's Step 3 UI
/// maps directly to native FFmpeg command-line filters (eq, colorbalance,
/// curves, hue, unsharp, noise, vignette, etc.) for the future rendering pipeline.
class FfmpegFiltergraphGenerator {
  FfmpegFiltergraphGenerator._();

  /// Converts a [VideoLookState] into a list of individual FFmpeg video filters.
  static List<String> buildFilterList(VideoLookState state) {
    final filters = <String>[];

    // ── 1. Basic: eq (Contrast, Brightness, Saturation, Gamma) ──────────────
    final hasEq = state.contrast != 0 ||
        state.brightness != 0 ||
        state.saturation != 0 ||
        state.gamma != 0 ||
        state.exposure != 0;

    if (hasEq) {
      // Effective contrast: 1.0 is neutral, -100..+100 maps to 0.0..2.0
      final contrastVal = (1.0 + (state.contrast / 100.0)).clamp(0.0, 3.0);
      // Effective brightness: 0.0 is neutral, -100..+100 maps to -0.5..0.5 (plus exposure)
      final brightnessVal =
          ((state.brightness / 200.0) + (state.exposure / 250.0)).clamp(-1.0, 1.0);
      // Effective saturation: 1.0 is neutral, -100..+100 maps to 0.0..2.5
      var satVal = (1.0 + (state.saturation / 100.0)).clamp(0.0, 3.0);
      if (state.bwEnabled || state.grayscale > 0) {
        final bwFactor = (state.bwEnabled ? (state.bwAmount / 100.0) : (state.grayscale / 100.0))
            .clamp(0.0, 1.0);
        satVal = satVal * (1.0 - bwFactor);
      }
      // Gamma: 1.0 is neutral, -100..+100 maps to 0.2..2.5
      final gammaVal = (1.0 + (state.gamma / 100.0)).clamp(0.1, 4.0);

      filters.add(
        'eq=contrast=${contrastVal.toStringAsFixed(3)}:'
        'brightness=${brightnessVal.toStringAsFixed(3)}:'
        'saturation=${satVal.toStringAsFixed(3)}:'
        'gamma=${gammaVal.toStringAsFixed(3)}',
      );
    }

    // ── 2. Color Balance (Temperature, Tint, Shadow/Mid/Highlight Colors) ──
    final hasColorBalance = state.temperature != 0 ||
        state.tint != 0 ||
        state.colorBalance != 0 ||
        state.shadowColorIntensity > 0 ||
        state.midtoneColorIntensity > 0 ||
        state.highlightColorIntensity > 0 ||
        state.rgbMixRed != 0 ||
        state.rgbMixGreen != 0 ||
        state.rgbMixBlue != 0;

    if (hasColorBalance) {
      // Temperature: warm shifts red up, blue down. Cool shifts blue up, red down.
      final tempNorm = (state.temperature / 100.0).clamp(-1.0, 1.0);
      // Tint: green vs magenta
      final tintNorm = (state.tint / 100.0).clamp(-1.0, 1.0);

      // Midtones base
      var rm = (tempNorm * 0.45).clamp(-1.0, 1.0);
      var gm = (-tintNorm * 0.35).clamp(-1.0, 1.0);
      var bm = (-tempNorm * 0.45).clamp(-1.0, 1.0);

      // RGB Mix offsets
      rm = (rm + (state.rgbMixRed / 200.0)).clamp(-1.0, 1.0);
      gm = (gm + (state.rgbMixGreen / 200.0)).clamp(-1.0, 1.0);
      bm = (bm + (state.rgbMixBlue / 200.0)).clamp(-1.0, 1.0);

      // Shadows from shadowColor
      var rs = 0.0;
      var gs = 0.0;
      var bs = 0.0;
      if (state.shadowColorIntensity > 0) {
        final factor = state.shadowColorIntensity / 100.0;
        rs = ((state.shadowColor.r - 0.5) * factor).clamp(-1.0, 1.0);
        gs = ((state.shadowColor.g - 0.5) * factor).clamp(-1.0, 1.0);
        bs = ((state.shadowColor.b - 0.5) * factor).clamp(-1.0, 1.0);
      }

      // Highlights from highlightColor
      var rh = 0.0;
      var gh = 0.0;
      var bh = 0.0;
      if (state.highlightColorIntensity > 0) {
        final factor = state.highlightColorIntensity / 100.0;
        rh = ((state.highlightColor.r - 0.5) * factor).clamp(-1.0, 1.0);
        gh = ((state.highlightColor.g - 0.5) * factor).clamp(-1.0, 1.0);
        bh = ((state.highlightColor.b - 0.5) * factor).clamp(-1.0, 1.0);
      }

      filters.add(
        'colorbalance=rs=${rs.toStringAsFixed(3)}:gs=${gs.toStringAsFixed(3)}:bs=${bs.toStringAsFixed(3)}:'
        'rm=${rm.toStringAsFixed(3)}:gm=${gm.toStringAsFixed(3)}:bm=${bm.toStringAsFixed(3)}:'
        'rh=${rh.toStringAsFixed(3)}:gh=${gh.toStringAsFixed(3)}:bh=${bh.toStringAsFixed(3)}',
      );
    }

    // ── 3. Hue Shift ────────────────────────────────────────────────────────
    if (state.hue != 0) {
      filters.add('hue=h=${state.hue.toStringAsFixed(1)}');
    }

    // ── 4. Sepia / Toning ──────────────────────────────────────────────────
    if (state.sepia > 0 || state.toningPreset == ToningPreset.sepia) {
      final intensity = math.max(state.sepia, state.toningIntensity) / 100.0;
      // Linear blend between normal identity and sepia transformation matrix
      final rr = (1.0 - intensity) + 0.393 * intensity;
      final rg = 0.769 * intensity;
      final rb = 0.189 * intensity;
      final gr = 0.349 * intensity;
      final gg = (1.0 - intensity) + 0.686 * intensity;
      final gb = 0.168 * intensity;
      final br = 0.272 * intensity;
      final bg = 0.534 * intensity;
      final bb = (1.0 - intensity) + 0.131 * intensity;

      filters.add(
        'colorchannelmixer='
        '${rr.toStringAsFixed(3)}:${rg.toStringAsFixed(3)}:${rb.toStringAsFixed(3)}:0:'
        '${gr.toStringAsFixed(3)}:${gg.toStringAsFixed(3)}:${gb.toStringAsFixed(3)}:0:'
        '${br.toStringAsFixed(3)}:${bg.toStringAsFixed(3)}:${bb.toStringAsFixed(3)}:0',
      );
    }


    // ── 6. Detail / Sharpen (unsharp) ───────────────────────────────────────
    if (state.sharpen > 0 || state.clarity > 0) {
      final amount = ((state.sharpen * 0.02) + (state.clarity * 0.01)).clamp(0.1, 2.5);
      filters.add('unsharp=5:5:${amount.toStringAsFixed(2)}:5:5:0.0');
    }

    // ── 7. Detail: Denoise (hqdn3d) ─────────────────────────────────────────
    if (state.denoise > 0 || state.noiseReduction > 0) {
      final denoiseVal = ((state.denoise + state.noiseReduction) / 25.0).clamp(1.0, 10.0);
      filters.add('hqdn3d=${denoiseVal.toStringAsFixed(1)}');
    }

    // ── 8. Blur & Softness (boxblur / gblur) ─────────────────────────────────
    final totalBlur = state.blur +
        state.softBlur +
        state.gaussianBlur +
        state.lensBlur +
        state.softFocus +
        state.dreamSoftness;

    if (totalBlur > 0) {
      final sigma = (totalBlur / 15.0).clamp(0.5, 30.0);
      filters.add('gblur=sigma=${sigma.toStringAsFixed(1)}');
    }

    // ── 9. Vignette ─────────────────────────────────────────────────────────
    if (state.vignetteAmount != 0) {
      // In FFmpeg vignette: angle PI/5 to PI/2
      final factor = (state.vignetteAmount / 100.0).clamp(-1.0, 1.0);
      if (factor > 0) {
        final angle = (math.pi / 4.0) * (1.0 + factor * 0.8);
        filters.add('vignette=angle=${angle.toStringAsFixed(3)}');
      }
    }

    // ── 10. Film Grain (noise filter) ───────────────────────────────────────
    if (state.filmGrainAmount > 0) {
      final strength = (state.filmGrainAmount * 0.45).clamp(1.0, 60.0).round();
      filters.add('noise=alls=$strength:allf=t+u');
    }

    // ── 11. Creative Negative / Invert ──────────────────────────────────────
    if (state.creativePreset == CreativeLookPreset.negative) {
      filters.add('negate');
    }

    // ── 12. Darken at Bottom of Frame ───────────────────────────────────────
    if (state.darkenBottomStrength > 0) {
      final opacity = (state.darkenBottomStrength / 100.0).clamp(0.05, 1.0);
      final heightFrac = (0.15 + (state.darkenBottomSpread / 100.0) * 0.65).clamp(0.15, 0.85);
      filters.add('drawbox=y=ih*(1-$heightFrac):h=ih*$heightFrac:color=black@${opacity.toStringAsFixed(2)}:t=fill');
    }

    return filters;
  }

  /// Builds a single consolidated `-vf` filtergraph string.
  static String buildFiltergraphString(VideoLookState state) {
    final list = buildFilterList(state);
    if (list.isEmpty) {
      return 'null';
    }
    return list.join(',');
  }


  /// Constructs the full FFmpeg command argument list for future rendering.
  static List<String> buildFfmpegArgs({
    required String inputVideoPath,
    required String outputVideoPath,
    required VideoLookState state,
    String? audioPath,
  }) {
    final args = <String>[
      '-y',
      '-i',
      inputVideoPath,
    ];

    if (audioPath != null && audioPath.isNotEmpty) {
      args.addAll(['-i', audioPath]);
    }

    final vfString = buildFiltergraphString(state);
    if (vfString != 'null') {
      args.addAll(['-vf', vfString]);
    }

    args.addAll([
      '-c:v',
      'libx264',
      '-preset',
      'medium',
      '-crf',
      '20',
      '-pix_fmt',
      'yuv420p',
      '-c:a',
      'aac',
      '-b:a',
      '192k',
      outputVideoPath,
    ]);

    return args;
  }
}
