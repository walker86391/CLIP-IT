import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/curve_point.dart';
import '../models/quick_looks_presets.dart';
import '../models/video_look_state.dart';

/// Riverpod provider for the Step 3 Video Look state.
final videoLookProvider =
    NotifierProvider<VideoLookNotifier, VideoLookState>(VideoLookNotifier.new);

/// Notifier managing visual look effects, accordion category expansion
/// (strictly ONE open at a time), live preview parameters, and category resets.
class VideoLookNotifier extends Notifier<VideoLookState> {
  @override
  VideoLookState build() => const VideoLookState();

  // ── Accordion Category Management ─────────────────────────────────────────

  /// Toggles an accordion category.
  /// Enforces the rule: ONLY ONE CATEGORY CAN BE OPEN AT A TIME.
  /// Opening a category automatically closes whichever one was open.
  void toggleCategory(VideoLookCategory category) {
    if (state.activeCategory == category) {
      // Toggle closed if tapped again
      state = state.copyWith(clearActiveCategory: true);
    } else {
      state = state.copyWith(activeCategory: category);
    }
  }

  /// Explicitly opens a category and closes all others.
  void openCategory(VideoLookCategory category) {
    state = state.copyWith(activeCategory: category);
  }

  /// Closes any currently open category.
  void closeCategory() {
    state = state.copyWith(clearActiveCategory: true);
  }

  // ── Reset Logic ───────────────────────────────────────────────────────────

  /// Resets ONLY the specified category to its default values.
  /// All other categories remain completely untouched.
  void resetCategory(VideoLookCategory category) {
    state = state.resetCategory(category);
  }

  /// Resets all visual effects across all categories to default neutral state.
  void resetAll() {
    final openCat = state.activeCategory;
    state = const VideoLookState().copyWith(activeCategory: openCat);
  }

  // ── Quick Looks ───────────────────────────────────────────────────────────

  /// Applies one of the 10 top-level Quick Looks.
  void applyQuickLook(QuickLookPreset preset) {
    state = QuickLooksPresets.applyQuickLook(preset, state);
  }

  // ── 1. Basic Visual Controls ──────────────────────────────────────────────

  void setBrightness(double val) => state = state.copyWith(brightness: val);
  void setExposure(double val) => state = state.copyWith(exposure: val);
  void setContrast(double val) => state = state.copyWith(contrast: val);
  void setSaturation(double val) => state = state.copyWith(saturation: val);
  void setVibrance(double val) => state = state.copyWith(vibrance: val);
  void setTemperature(double val) => state = state.copyWith(temperature: val);
  void setTint(double val) => state = state.copyWith(tint: val);
  void setHighlights(double val) => state = state.copyWith(highlights: val);
  void setShadows(double val) => state = state.copyWith(shadows: val);
  void setBlacks(double val) => state = state.copyWith(blacks: val);
  void setWhites(double val) => state = state.copyWith(whites: val);
  void setGamma(double val) => state = state.copyWith(gamma: val);
  void setFade(double val) => state = state.copyWith(fade: val);

  // ── 2. Color Controls ─────────────────────────────────────────────────────

  void setHue(double val) => state = state.copyWith(hue: val);
  void setColorBalance(double val) => state = state.copyWith(colorBalance: val);
  void setColorizeColor(Color color) => state = state.copyWith(colorizeColor: color);
  void setColorizeIntensity(double val) => state = state.copyWith(colorizeIntensity: val);
  void setGrayscale(double val) => state = state.copyWith(grayscale: val);
  void setSepia(double val) => state = state.copyWith(sepia: val);
  void setSelectiveColor(Color color) => state = state.copyWith(selectiveColor: color);
  void setSelectiveTolerance(double val) => state = state.copyWith(selectiveTolerance: val);
  void setShadowColor(Color color) => state = state.copyWith(shadowColor: color);
  void setShadowColorIntensity(double val) => state = state.copyWith(shadowColorIntensity: val);
  void setMidtoneColor(Color color) => state = state.copyWith(midtoneColor: color);
  void setMidtoneColorIntensity(double val) => state = state.copyWith(midtoneColorIntensity: val);
  void setHighlightColor(Color color) => state = state.copyWith(highlightColor: color);
  void setHighlightColorIntensity(double val) => state = state.copyWith(highlightColorIntensity: val);
  void setRgbMixRed(double val) => state = state.copyWith(rgbMixRed: val);
  void setRgbMixGreen(double val) => state = state.copyWith(rgbMixGreen: val);
  void setRgbMixBlue(double val) => state = state.copyWith(rgbMixBlue: val);

  // ── 3. Black & White / Toning ─────────────────────────────────────────────

  void setBwEnabled(bool enabled) => state = state.copyWith(bwEnabled: enabled);
  void setBwAmount(double val) => state = state.copyWith(bwAmount: val);
  void setToningPreset(ToningPreset preset) =>
      state = state.copyWith(toningPreset: preset);
  void setToningIntensity(double val) =>
      state = state.copyWith(toningIntensity: val);
  void setDuotoneShadowColor(Color color) =>
      state = state.copyWith(duotoneShadowColor: color);
  void setDuotoneHighlightColor(Color color) =>
      state = state.copyWith(duotoneHighlightColor: color);
  void setTritoneShadowColor(Color color) =>
      state = state.copyWith(tritoneShadowColor: color);
  void setTritoneMidtoneColor(Color color) =>
      state = state.copyWith(tritoneMidtoneColor: color);
  void setTritoneHighlightColor(Color color) =>
      state = state.copyWith(tritoneHighlightColor: color);

  // ── 4. Curves ─────────────────────────────────────────────────────────────

  void setActiveCurveChannel(CurveChannel channel) =>
      state = state.copyWith(activeCurveChannel: channel);

  void setCurvePreset(CurvePreset preset) {
    final updated = Map<CurveChannel, List<CurvePoint>>.from(state.curvePoints);
    updated[state.activeCurveChannel] = preset.points;
    state = state.copyWith(
      curvePoints: updated,
      activeCurvePreset: preset,
    );
  }

  void updateCurvePoint(CurveChannel channel, int index, CurvePoint newPoint) {
    final updated = Map<CurveChannel, List<CurvePoint>>.from(state.curvePoints);
    final list = List<CurvePoint>.from(updated[channel] ?? []);
    if (index >= 0 && index < list.length) {
      list[index] = newPoint;
      list.sort((a, b) => a.x.compareTo(b.x));
      updated[channel] = list;
      state = state.copyWith(curvePoints: updated);
    }
  }

  void addCurvePoint(CurveChannel channel, CurvePoint point) {
    final updated = Map<CurveChannel, List<CurvePoint>>.from(state.curvePoints);
    final list = List<CurvePoint>.from(updated[channel] ?? []);
    list.add(point);
    list.sort((a, b) => a.x.compareTo(b.x));
    updated[channel] = list;
    state = state.copyWith(curvePoints: updated);
  }

  void removeCurvePoint(CurveChannel channel, int index) {
    final updated = Map<CurveChannel, List<CurvePoint>>.from(state.curvePoints);
    final list = List<CurvePoint>.from(updated[channel] ?? []);
    if (list.length > 2 && index > 0 && index < list.length - 1) {
      list.removeAt(index);
      updated[channel] = list;
      state = state.copyWith(curvePoints: updated);
    }
  }

  // ── 5. Cinematic ──────────────────────────────────────────────────────────

  void setCinematicPreset(CinematicLookPreset preset) {
    state = state.copyWith(
      cinematicPreset: preset,
      cinematicIntensity: preset == CinematicLookPreset.none ? 0.0 : 85.0,
    );
  }

  void setCinematicIntensity(double val) =>
      state = state.copyWith(cinematicIntensity: val);

  // ── 6. Light ──────────────────────────────────────────────────────────────

  void setGlow(double val) => state = state.copyWith(glow: val);
  void setSoftGlow(double val) => state = state.copyWith(softGlow: val);
  void setStrongGlow(double val) => state = state.copyWith(strongGlow: val);
  void setBloom(double val) => state = state.copyWith(bloom: val);
  void setSoftBloom(double val) => state = state.copyWith(softBloom: val);
  void setHighlightBloom(double val) => state = state.copyWith(highlightBloom: val);
  void setNeonGlow(double val) => state = state.copyWith(neonGlow: val);
  void setEdgeGlow(double val) => state = state.copyWith(edgeGlow: val);
  void setDiffusion(double val) => state = state.copyWith(diffusion: val);
  void setHighlightDiffusion(double val) => state = state.copyWith(highlightDiffusion: val);
  void setHalation(double val) => state = state.copyWith(halation: val);
  void setLightLeakPreset(LightLeakPreset preset) =>
      state = state.copyWith(lightLeakPreset: preset);
  void setLightLeakIntensity(double val) =>
      state = state.copyWith(lightLeakIntensity: val);
  void setLensFlarePreset(LensFlarePreset preset) =>
      state = state.copyWith(lensFlarePreset: preset);
  void setLensFlareIntensity(double val) =>
      state = state.copyWith(lensFlareIntensity: val);
  void setLightStreak(double val) => state = state.copyWith(lightStreak: val);
  void setFilmBurnPreset(FilmBurnPreset preset) =>
      state = state.copyWith(filmBurnPreset: preset);
  void setFilmBurnIntensity(double val) =>
      state = state.copyWith(filmBurnIntensity: val);

  // ── 7. Detail ─────────────────────────────────────────────────────────────

  void setSharpen(double val) => state = state.copyWith(sharpen: val);
  void setClarity(double val) => state = state.copyWith(clarity: val);
  void setDetail(double val) => state = state.copyWith(detail: val);
  void setTexture(double val) => state = state.copyWith(texture: val);
  void setEdgeEnhancement(double val) => state = state.copyWith(edgeEnhancement: val);
  void setDenoise(double val) => state = state.copyWith(denoise: val);
  void setNoiseReduction(double val) => state = state.copyWith(noiseReduction: val);
  void setDehaze(double val) => state = state.copyWith(dehaze: val);
  void setDeband(double val) => state = state.copyWith(deband: val);

  // ── 8. Blur & Softness ────────────────────────────────────────────────────

  void setBlur(double val) => state = state.copyWith(blur: val);
  void setSoftBlur(double val) => state = state.copyWith(softBlur: val);
  void setGaussianBlur(double val) => state = state.copyWith(gaussianBlur: val);
  void setLensBlur(double val) => state = state.copyWith(lensBlur: val);
  void setSoftnessDiffusion(double val) => state = state.copyWith(softnessDiffusion: val);
  void setSoftFocus(double val) => state = state.copyWith(softFocus: val);
  void setDreamSoftness(double val) => state = state.copyWith(dreamSoftness: val);

  // ── 9. Lens / Image Character ─────────────────────────────────────────────

  void setVignetteAmount(double val) => state = state.copyWith(vignetteAmount: val);
  void setVignetteSoftness(double val) => state = state.copyWith(vignetteSoftness: val);
  void setVignetteStyle(VignetteStyle style) => state = state.copyWith(vignetteStyle: style);
  void setDarkenBottomStrength(double val) => state = state.copyWith(darkenBottomStrength: val);
  void setDarkenBottomSpread(double val) => state = state.copyWith(darkenBottomSpread: val);
  void setChromaticAberration(double val) => state = state.copyWith(chromaticAberration: val);
  void setColorFringing(double val) => state = state.copyWith(colorFringing: val);
  void setLensDistortion(double val) => state = state.copyWith(lensDistortion: val);
  void setFisheye(double val) => state = state.copyWith(fisheye: val);

  // ── 10. Film ──────────────────────────────────────────────────────────────

  void setFilmGrainAmount(double val) => state = state.copyWith(filmGrainAmount: val);
  void setGrainSize(double val) => state = state.copyWith(grainSize: val);
  void setGrainSoftness(double val) => state = state.copyWith(grainSoftness: val);
  void setGrainType(FilmGrainType type) => state = state.copyWith(grainType: type);
  void setFilmDust(double val) => state = state.copyWith(filmDust: val);
  void setFilmScratches(double val) => state = state.copyWith(filmScratches: val);
  void setFilmFlicker(double val) => state = state.copyWith(filmFlicker: val);
  void setFilmFade(double val) => state = state.copyWith(filmFade: val);
  void setFilmBleed(double val) => state = state.copyWith(filmBleed: val);
  void setFilmDamage(double val) => state = state.copyWith(filmDamage: val);
  void setFilmLookPreset(FilmLookPreset preset) =>
      state = state.copyWith(filmLookPreset: preset);
  void setFilmLookIntensity(double val) =>
      state = state.copyWith(filmLookIntensity: val);

  // ── 11. VHS / Retro ───────────────────────────────────────────────────────

  void setVhsPreset(VhsLookPreset preset) =>
      state = state.copyWith(vhsPreset: preset);
  void setVhsPresetIntensity(double val) =>
      state = state.copyWith(vhsPresetIntensity: val);
  void setVhsColorBleed(double val) => state = state.copyWith(vhsColorBleed: val);
  void setVhsNoise(double val) => state = state.copyWith(vhsNoise: val);
  void setVhsDistortion(double val) => state = state.copyWith(vhsDistortion: val);
  void setVhsTracking(double val) => state = state.copyWith(vhsTracking: val);
  void setTapeNoise(double val) => state = state.copyWith(tapeNoise: val);
  void setAnalogNoise(double val) => state = state.copyWith(analogNoise: val);
  void setCrtScanlines(double val) => state = state.copyWith(crtScanlines: val);
  void setCrtGlow(double val) => state = state.copyWith(crtGlow: val);
  void setCrtFlicker(double val) => state = state.copyWith(crtFlicker: val);
  void setRetroColor(double val) => state = state.copyWith(retroColor: val);
  void setRetroFade(double val) => state = state.copyWith(retroFade: val);

  // ── 12. RGB Effects ───────────────────────────────────────────────────────

  void setRgbSplit(double val) => state = state.copyWith(rgbSplit: val);
  void setRgbShift(double val) => state = state.copyWith(rgbShift: val);
  void setRedOffset(double val) => state = state.copyWith(redOffset: val);
  void setGreenOffset(double val) => state = state.copyWith(greenOffset: val);
  void setBlueOffset(double val) => state = state.copyWith(blueOffset: val);
  void setRgbChromaticAberration(double val) =>
      state = state.copyWith(rgbChromaticAberration: val);
  void setRgbColorFringing(double val) =>
      state = state.copyWith(rgbColorFringing: val);
  void setRgbGhost(double val) => state = state.copyWith(rgbGhost: val);
  void setRgbChannelMix(double val) => state = state.copyWith(rgbChannelMix: val);
  void setRgbColorSeparation(double val) =>
      state = state.copyWith(rgbColorSeparation: val);

  // ── 13. Glitch ────────────────────────────────────────────────────────────

  void setGlitchAmount(double val) => state = state.copyWith(glitchAmount: val);
  void setGlitchIntensity(double val) => state = state.copyWith(glitchIntensity: val);
  void setGlitchFrequency(double val) => state = state.copyWith(glitchFrequency: val);
  void setGlitchRgbAmount(double val) => state = state.copyWith(glitchRgbAmount: val);
  void setRgbGlitch(double val) => state = state.copyWith(rgbGlitch: val);
  void setDigitalGlitch(double val) => state = state.copyWith(digitalGlitch: val);
  void setColorGlitch(double val) => state = state.copyWith(colorGlitch: val);
  void setPixelGlitch(double val) => state = state.copyWith(pixelGlitch: val);
  void setScanlineGlitch(double val) => state = state.copyWith(scanlineGlitch: val);
  void setBlockGlitch(double val) => state = state.copyWith(blockGlitch: val);
  void setColorCorruption(double val) => state = state.copyWith(colorCorruption: val);
  void setSignalInterference(double val) => state = state.copyWith(signalInterference: val);
  void setDigitalNoise(double val) => state = state.copyWith(digitalNoise: val);

  // ── 14. Creative ──────────────────────────────────────────────────────────

  void setCreativePreset(CreativeLookPreset preset) =>
      state = state.copyWith(creativePreset: preset);
  void setCreativeIntensity(double val) =>
      state = state.copyWith(creativeIntensity: val);
  void setPosterizeLevels(double val) => state = state.copyWith(posterizeLevels: val);
  void setPixelateSize(double val) => state = state.copyWith(pixelateSize: val);
  void setSolarizeThreshold(double val) => state = state.copyWith(solarizeThreshold: val);

  // ── 15. Blend / Overlay ───────────────────────────────────────────────────

  void setBlendMode(LookBlendMode mode) => state = state.copyWith(blendMode: mode);
  void setBlendOpacity(double val) => state = state.copyWith(blendOpacity: val);
  void setOverlayTintColor(Color color) => state = state.copyWith(overlayTintColor: color);
  void setOverlayTextureIntensity(double val) =>
      state = state.copyWith(overlayTextureIntensity: val);
}
