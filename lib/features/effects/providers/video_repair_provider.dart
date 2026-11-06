import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_repair_models.dart';

/// Notifier managing Video Repair parameters: video denoising, blur detection
/// analysis, quality evaluation, noise reduction, and before/after comparisons.
class VideoRepairNotifier extends Notifier<VideoRepairState> {
  static const _prefsKey = 'clipit_video_repair_state_v1';
  Timer? _scanTimer;

  @override
  VideoRepairState build() {
    _loadFromPreferences();
    ref.onDispose(() {
      _scanTimer?.cancel();
    });
    return const VideoRepairState();
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        state = VideoRepairState.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('Failed to load VideoRepairState from preferences: $e');
    }
  }

  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(state.toJson());
      await prefs.setString(_prefsKey, jsonStr);
    } catch (e) {
      debugPrint('Failed to persist VideoRepairState: $e');
    }
  }

  // ── 1. Video Denoising ───────────────────────────────────────────────────

  void updateDenoise(
      VideoDenoiseConfig Function(VideoDenoiseConfig current) update) {
    state = state.copyWith(denoise: update(state.denoise));
    _saveToPreferences();
  }

  void toggleDenoise([bool? force]) {
    updateDenoise((d) => d.copyWith(isEnabled: force ?? !d.isEnabled));
  }

  void setDenoiseAlgorithm(VideoDenoiseAlgorithm algorithm) {
    updateDenoise((d) => d.copyWith(algorithm: algorithm));
  }

  void setDenoiseStrength(double strength) {
    updateDenoise((d) => d.copyWith(strength: strength.clamp(0.0, 1.0)));
  }

  void setLumaThreshold(double luma) {
    updateDenoise((d) => d.copyWith(lumaThreshold: luma.clamp(1.0, 20.0)));
  }

  void setChromaThreshold(double chroma) {
    updateDenoise((d) => d.copyWith(chromaThreshold: chroma.clamp(1.0, 20.0)));
  }

  void setTemporalBlend(double blend) {
    updateDenoise((d) => d.copyWith(temporalBlend: blend.clamp(0.0, 1.0)));
  }

  // ── 2. Blur Detection Analysis ───────────────────────────────────────────

  void updateBlurAnalysis(
      BlurDetectionAnalysisConfig Function(BlurDetectionAnalysisConfig current)
          update) {
    state = state.copyWith(blurAnalysis: update(state.blurAnalysis));
    _saveToPreferences();
  }

  void toggleBlurDetection([bool? force]) {
    updateBlurAnalysis((b) => b.copyWith(isEnabled: force ?? !b.isEnabled));
  }

  void setBlurThreshold(double threshold) {
    updateBlurAnalysis((b) => b.copyWith(threshold: threshold.clamp(0.0, 1.0)));
  }

  void setBlurSampleRate(int rate) {
    updateBlurAnalysis((b) => b.copyWith(sampleRateFrames: rate.clamp(1, 60)));
  }

  /// Triggers a simulated interactive scan across the video frames for blur analysis.
  void runBlurScan() {
    _scanTimer?.cancel();
    updateBlurAnalysis((b) => b.copyWith(isScanning: true, scanProgress: 0.0));

    var step = 0;
    _scanTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      step++;
      final progress = (step / 15).clamp(0.0, 1.0);
      if (progress >= 1.0) {
        timer.cancel();
        updateBlurAnalysis((b) => b.copyWith(
              isScanning: false,
              scanProgress: 1.0,
              detectedSegments: const [
                BlurrySegmentReport(
                  startSec: 4.20,
                  endSec: 6.10,
                  severity: BlurrySeverity.medium,
                  blurScore: 0.38,
                  reason: 'Rapid camera pan & motion defocus',
                ),
                BlurrySegmentReport(
                  startSec: 14.50,
                  endSec: 15.80,
                  severity: BlurrySeverity.high,
                  blurScore: 0.28,
                  reason: 'Subject out of focal plane',
                ),
                BlurrySegmentReport(
                  startSec: 28.10,
                  endSec: 29.40,
                  severity: BlurrySeverity.low,
                  blurScore: 0.42,
                  reason: 'Micro-jitter camera shake',
                ),
              ],
            ));
      } else {
        updateBlurAnalysis((b) => b.copyWith(scanProgress: progress));
      }
    });
  }

  // ── 3. Noise Reduction & Repair Intensity ────────────────────────────────

  void setRepairIntensityLevel(RepairIntensityLevel level) {
    state = state.copyWith(
      noiseReduction: state.noiseReduction.copyWith(level: level),
    );
    _saveToPreferences();
  }

  void setCustomRepairIntensity(double intensity) {
    state = state.copyWith(
      noiseReduction: state.noiseReduction.copyWith(
        level: RepairIntensityLevel.custom,
        customIntensity: intensity.clamp(0.0, 1.0),
      ),
    );
    _saveToPreferences();
  }

  void togglePreserveFineDetail([bool? force]) {
    state = state.copyWith(
      noiseReduction: state.noiseReduction.copyWith(
        preserveFineDetail:
            force ?? !state.noiseReduction.preserveFineDetail,
      ),
    );
    _saveToPreferences();
  }

  // ── 4. Before / After Comparison ─────────────────────────────────────────

  void setComparisonMode(ComparisonDisplayMode mode) {
    state = state.copyWith(comparisonMode: mode);
    _saveToPreferences();
  }

  void setSplitPosition(double position) {
    state = state.copyWith(splitPosition: position.clamp(0.0, 1.0));
  }

  void toggleRepairedPreview([bool? force]) {
    state = state.copyWith(
      isShowingRepairedPreview:
          force ?? !state.isShowingRepairedPreview,
    );
  }
}

/// Global provider for Video Repair capabilities.
final videoRepairProvider =
    NotifierProvider<VideoRepairNotifier, VideoRepairState>(
  VideoRepairNotifier.new,
);
