import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/features/video_look/models/curve_point.dart';
import 'package:clipit/features/video_look/models/quick_looks_presets.dart';
import 'package:clipit/features/video_look/models/video_look_state.dart';

void main() {
  group('VideoLookState Default & Isolation Tests', () {
    test('default state has neutral 0.0 values across core visual adjustments', () {
      const state = VideoLookState();

      // 1. Basic
      expect(state.brightness, equals(0.0));
      expect(state.exposure, equals(0.0));
      expect(state.contrast, equals(0.0));
      expect(state.saturation, equals(0.0));
      expect(state.vibrance, equals(0.0));
      expect(state.temperature, equals(0.0));
      expect(state.tint, equals(0.0));
      expect(state.highlights, equals(0.0));
      expect(state.shadows, equals(0.0));
      expect(state.blacks, equals(0.0));
      expect(state.whites, equals(0.0));
      expect(state.gamma, equals(0.0));
      expect(state.fade, equals(0.0));

      // 2. Color
      expect(state.hue, equals(0.0));
      expect(state.colorBalance, equals(0.0));
      expect(state.colorizeIntensity, equals(0.0));
      expect(state.grayscale, equals(0.0));
      expect(state.sepia, equals(0.0));
      expect(state.shadowColorIntensity, equals(0.0));

      // 3. B&W
      expect(state.bwEnabled, isFalse);
      expect(state.bwAmount, equals(0.0));
      expect(state.toningPreset, equals(ToningPreset.none));

      // 4. Cinematic
      expect(state.cinematicPreset, equals(CinematicLookPreset.none));

      // 5. Film & Grain
      expect(state.filmGrainAmount, equals(0.0));
      expect(state.filmDust, equals(0.0));
      expect(state.filmScratches, equals(0.0));

      // 6. VHS
      expect(state.crtScanlines, equals(0.0));
      expect(state.vhsPreset, equals(VhsLookPreset.none));

      // 7. Glitch
      expect(state.glitchAmount, equals(0.0));
    });

    test('resetCategory resets ONLY target category without touching others', () {
      var state = const VideoLookState().copyWith(
        contrast: 40.0,
        brightness: 20.0,
        hue: 45.0,
        sepia: 50.0,
        filmGrainAmount: 30.0,
        crtScanlines: 60.0,
      );

      // Reset BASIC category only
      state = state.resetCategory(VideoLookCategory.basic);

      // Basic should be back to 0
      expect(state.contrast, equals(0.0));
      expect(state.brightness, equals(0.0));

      // Other categories remain untouched!
      expect(state.hue, equals(45.0));
      expect(state.sepia, equals(50.0));
      expect(state.filmGrainAmount, equals(30.0));
      expect(state.crtScanlines, equals(60.0));

      // Reset FILM category only
      state = state.resetCategory(VideoLookCategory.film);
      expect(state.filmGrainAmount, equals(0.0));
      expect(state.sepia, equals(50.0));
      expect(state.crtScanlines, equals(0.0));
    });

    test('QuickLook presets apply expected aesthetic adjustments', () {
      final initial = const VideoLookState();

      // 1. Cinematic Look
      final cinematic = QuickLooksPresets.applyQuickLook(QuickLookPreset.cinematic, initial);
      expect(cinematic.activeQuickLook, equals(QuickLookPreset.cinematic));
      expect(cinematic.contrast, greaterThan(0.0));
      expect(cinematic.vignetteAmount, greaterThan(0.0));
      expect(cinematic.filmGrainAmount, greaterThan(0.0));
      expect(cinematic.cinematicPreset, equals(CinematicLookPreset.cinematic));

      // 2. Black & White Look
      final bw = QuickLooksPresets.applyQuickLook(QuickLookPreset.blackAndWhite, initial);
      expect(bw.bwEnabled, isTrue);
      expect(bw.bwAmount, equals(100.0));
      expect(bw.toningPreset, equals(ToningPreset.monochrome));

      // 3. Warm Look
      final warm = QuickLooksPresets.applyQuickLook(QuickLookPreset.warm, initial);
      expect(warm.temperature, greaterThan(20.0));

      // 4. Cold Look
      final cold = QuickLooksPresets.applyQuickLook(QuickLookPreset.cold, initial);
      expect(cold.temperature, lessThan(-20.0));

      // 5. Vintage Look
      final vintage = QuickLooksPresets.applyQuickLook(QuickLookPreset.vintage, initial);
      expect(vintage.sepia, greaterThan(0.0));
      expect(vintage.filmGrainAmount, greaterThan(0.0));

      // 6. Retro Look
      final retro = QuickLooksPresets.applyQuickLook(QuickLookPreset.retro, initial);
      expect(retro.crtScanlines, greaterThan(0.0));
      expect(retro.vhsPreset, equals(VhsLookPreset.classicVhs));

      // 7. Original Look
      final resetOriginal = QuickLooksPresets.applyQuickLook(QuickLookPreset.original, cinematic);
      expect(resetOriginal.contrast, equals(0.0));
      expect(resetOriginal.vignetteAmount, equals(0.0));
      expect(resetOriginal.activeQuickLook, equals(QuickLookPreset.original));
    });

    test('CurvePoint and CurvePreset geometry and interpolation', () {
      const sCurve = CurvePreset.sCurve;
      final points = sCurve.points;
      expect(points.length, equals(5));
      expect(points.first.x, equals(0.0));
      expect(points.first.y, equals(0.0));
      expect(points.last.x, equals(255.0));
      expect(points.last.y, equals(255.0));

      // Modifying point
      final updated = points[2].copyWith(y: 140.0);
      expect(updated.y, equals(140.0));
      expect(updated.x, equals(128.0));
    });
  });
}
