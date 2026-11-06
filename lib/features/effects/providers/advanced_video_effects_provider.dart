import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/advanced_video_effects_models.dart';

/// Notifier managing configuration and states for the 10 professional video effects.
class AdvancedVideoEffectsNotifier extends Notifier<AdvancedVideoEffectsState> {
  static const _prefsKey = 'clipit_advanced_video_effects_v1';

  @override
  AdvancedVideoEffectsState build() {
    _loadFromPreferences();
    return const AdvancedVideoEffectsState();
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        state = AdvancedVideoEffectsState.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('Failed to load AdvancedVideoEffectsState from preferences: $e');
    }
  }

  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(state.toJson());
      await prefs.setString(_prefsKey, jsonStr);
    } catch (e) {
      debugPrint('Failed to persist AdvancedVideoEffectsState: $e');
    }
  }

  void setActiveEffectType(AdvancedEffectType type) {
    state = state.copyWith(activeEffectType: type);
  }

  void toggleEffectEnabled(AdvancedEffectType type, [bool? force]) {
    switch (type) {
      case AdvancedEffectType.motionBlur:
        state = state.copyWith(
          motionBlur: state.motionBlur.copyWith(
            isEnabled: force ?? !state.motionBlur.isEnabled,
          ),
        );
        break;
      case AdvancedEffectType.filmGrain:
        state = state.copyWith(
          filmGrain: state.filmGrain.copyWith(
            isEnabled: force ?? !state.filmGrain.isEnabled,
          ),
        );
        break;
      case AdvancedEffectType.glitch:
        state = state.copyWith(
          glitch: state.glitch.copyWith(
            isEnabled: force ?? !state.glitch.isEnabled,
          ),
        );
        break;
      case AdvancedEffectType.digitalNoise:
        state = state.copyWith(
          digitalNoise: state.digitalNoise.copyWith(
            isEnabled: force ?? !state.digitalNoise.isEnabled,
          ),
        );
        break;
      case AdvancedEffectType.chromaticAberration:
        state = state.copyWith(
          chromaticAberration: state.chromaticAberration.copyWith(
            isEnabled: force ?? !state.chromaticAberration.isEnabled,
          ),
        );
        break;
      case AdvancedEffectType.distortion:
        state = state.copyWith(
          distortion: state.distortion.copyWith(
            isEnabled: force ?? !state.distortion.isEnabled,
          ),
        );
        break;
      case AdvancedEffectType.lensDispersion:
        state = state.copyWith(
          lensDispersion: state.lensDispersion.copyWith(
            isEnabled: force ?? !state.lensDispersion.isEnabled,
          ),
        );
        break;
      case AdvancedEffectType.flicker:
        state = state.copyWith(
          flicker: state.flicker.copyWith(
            isEnabled: force ?? !state.flicker.isEnabled,
          ),
        );
        break;
      case AdvancedEffectType.ghostTrail:
        state = state.copyWith(
          ghostTrail: state.ghostTrail.copyWith(
            isEnabled: force ?? !state.ghostTrail.isEnabled,
          ),
        );
        break;
      case AdvancedEffectType.blurDetection:
        state = state.copyWith(
          blurDetection: state.blurDetection.copyWith(
            isEnabled: force ?? !state.blurDetection.isEnabled,
          ),
        );
        break;
    }
    _saveToPreferences();
  }

  void resetEffectToDefault(AdvancedEffectType type) {
    switch (type) {
      case AdvancedEffectType.motionBlur:
        state = state.copyWith(motionBlur: const MotionBlurEffectConfig());
        break;
      case AdvancedEffectType.filmGrain:
        state = state.copyWith(filmGrain: const FilmGrainEffectConfig());
        break;
      case AdvancedEffectType.glitch:
        state = state.copyWith(glitch: const GlitchEffectConfig());
        break;
      case AdvancedEffectType.digitalNoise:
        state = state.copyWith(digitalNoise: const DigitalNoiseEffectConfig());
        break;
      case AdvancedEffectType.chromaticAberration:
        state = state.copyWith(
            chromaticAberration: const ChromaticAberrationEffectConfig());
        break;
      case AdvancedEffectType.distortion:
        state = state.copyWith(distortion: const DistortionEffectConfig());
        break;
      case AdvancedEffectType.lensDispersion:
        state = state.copyWith(
            lensDispersion: const LensDispersionEffectConfig());
        break;
      case AdvancedEffectType.flicker:
        state = state.copyWith(flicker: const FlickerEffectConfig());
        break;
      case AdvancedEffectType.ghostTrail:
        state = state.copyWith(ghostTrail: const GhostTrailEffectConfig());
        break;
      case AdvancedEffectType.blurDetection:
        state = state.copyWith(
            blurDetection: const BlurDetectionEffectConfig());
        break;
    }
    _saveToPreferences();
  }

  // ── Specific Effect Config Updaters ──────────────────────────────────────

  void updateMotionBlur(
      MotionBlurEffectConfig Function(MotionBlurEffectConfig current) update) {
    state = state.copyWith(motionBlur: update(state.motionBlur));
    _saveToPreferences();
  }

  void updateFilmGrain(
      FilmGrainEffectConfig Function(FilmGrainEffectConfig current) update) {
    state = state.copyWith(filmGrain: update(state.filmGrain));
    _saveToPreferences();
  }

  void updateGlitch(
      GlitchEffectConfig Function(GlitchEffectConfig current) update) {
    state = state.copyWith(glitch: update(state.glitch));
    _saveToPreferences();
  }

  void updateDigitalNoise(
      DigitalNoiseEffectConfig Function(DigitalNoiseEffectConfig current) update) {
    state = state.copyWith(digitalNoise: update(state.digitalNoise));
    _saveToPreferences();
  }

  void updateChromaticAberration(
      ChromaticAberrationEffectConfig Function(
              ChromaticAberrationEffectConfig current)
          update) {
    state = state.copyWith(chromaticAberration: update(state.chromaticAberration));
    _saveToPreferences();
  }

  void updateDistortion(
      DistortionEffectConfig Function(DistortionEffectConfig current) update) {
    state = state.copyWith(distortion: update(state.distortion));
    _saveToPreferences();
  }

  void updateLensDispersion(
      LensDispersionEffectConfig Function(LensDispersionEffectConfig current)
          update) {
    state = state.copyWith(lensDispersion: update(state.lensDispersion));
    _saveToPreferences();
  }

  void updateFlicker(
      FlickerEffectConfig Function(FlickerEffectConfig current) update) {
    state = state.copyWith(flicker: update(state.flicker));
    _saveToPreferences();
  }

  void updateGhostTrail(
      GhostTrailEffectConfig Function(GhostTrailEffectConfig current) update) {
    state = state.copyWith(ghostTrail: update(state.ghostTrail));
    _saveToPreferences();
  }

  void updateBlurDetection(
      BlurDetectionEffectConfig Function(BlurDetectionEffectConfig current)
          update) {
    state = state.copyWith(blurDetection: update(state.blurDetection));
    _saveToPreferences();
  }

  // ── Quick Presets ────────────────────────────────────────────────────────

  void applyMotionBlurPreset(String name) {
    switch (name) {
      case 'Fast Action':
        updateMotionBlur((c) => c.copyWith(
              intensity: 0.85,
              blurStrengthPx: 32.0,
              shutterAngle: 270.0,
              sampleCount: 20,
              isEnabled: true,
            ));
        break;
      case 'Cinematic Shutter':
        updateMotionBlur((c) => c.copyWith(
              intensity: 0.50,
              blurStrengthPx: 16.0,
              shutterAngle: 180.0,
              sampleCount: 12,
              isEnabled: true,
            ));
        break;
      case 'Subtle Dream':
        updateMotionBlur((c) => c.copyWith(
              intensity: 0.25,
              blurStrengthPx: 8.0,
              shutterAngle: 90.0,
              sampleCount: 8,
              isEnabled: true,
            ));
        break;
    }
  }

  void applyFilmGrainPreset(String name) {
    switch (name) {
      case '16mm Indie':
        updateFilmGrain((c) => c.copyWith(
              intensity: 0.65,
              grainAmount: 60.0,
              grainSize: FilmGrainSize.medium,
              roughness: 0.70,
              isMonochrome: false,
              isEnabled: true,
            ));
        break;
      case '35mm Fine':
        updateFilmGrain((c) => c.copyWith(
              intensity: 0.35,
              grainAmount: 30.0,
              grainSize: FilmGrainSize.fine,
              roughness: 0.45,
              isMonochrome: true,
              isEnabled: true,
            ));
        break;
      case 'Vintage Celluloid':
        updateFilmGrain((c) => c.copyWith(
              intensity: 0.85,
              grainAmount: 80.0,
              grainSize: FilmGrainSize.coarse,
              roughness: 0.85,
              isMonochrome: true,
              isEnabled: true,
            ));
        break;
    }
  }

  void applyGlitchPreset(String name) {
    switch (name) {
      case 'Cyberpunk Burst':
        updateGlitch((c) => c.copyWith(
              intensity: 0.80,
              frequencyHz: 8.0,
              sliceCount: 22,
              rgbSplitDistancePx: 20.0,
              speedJitter: 0.85,
              isEnabled: true,
            ));
        break;
      case 'VHS Tape Tear':
        updateGlitch((c) => c.copyWith(
              intensity: 0.45,
              frequencyHz: 3.0,
              sliceCount: 8,
              rgbSplitDistancePx: 8.0,
              speedJitter: 0.40,
              isEnabled: true,
            ));
        break;
    }
  }
}

/// Global provider for the 10 Advanced Video Effects.
final advancedVideoEffectsProvider = NotifierProvider<
    AdvancedVideoEffectsNotifier, AdvancedVideoEffectsState>(
  AdvancedVideoEffectsNotifier.new,
);
