import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clipit/core/services/ffmpeg_service.dart';
import 'package:clipit/features/effects/models/advanced_video_effects_models.dart';
import 'package:clipit/features/effects/models/video_repair_models.dart';
import 'package:clipit/features/effects/providers/advanced_video_effects_provider.dart';
import 'package:clipit/features/effects/providers/video_repair_provider.dart';
import 'package:clipit/features/sound_effects/models/audio_editing_models.dart';
import 'package:clipit/features/sound_effects/providers/audio_editing_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // ───────────────────────────────────────────────────────────────────────────
  // 1. AUTO DUCKING & 30% VOLUME RESTRICTION RULE
  // ───────────────────────────────────────────────────────────────────────────
  group('1. Auto Ducking & 30% Music Volume Enforcement Rule', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial State: Music volume is 70% (above 30%), Auto Ducking is allowed but disabled', () {
      final state = container.read(audioEditingProvider);
      expect(state.customMusic.volume, equals(0.70));
      expect(state.mixer.channel2MusicVolume, equals(0.70));
      expect(state.autoDucking.isEnabled, isFalse);
      expect(state.autoDucking.isLockedDueToVolume, isFalse);
    });

    test('Can enable and configure Auto Ducking when volume is above 30%', () {
      final notifier = container.read(audioEditingProvider.notifier);

      final success = notifier.toggleAutoDucking();
      expect(success, isTrue);

      var state = container.read(audioEditingProvider);
      expect(state.autoDucking.isEnabled, isTrue);

      notifier.setDuckingStrength(0.85);
      notifier.setDuckingAttackMs(40);
      notifier.setDuckingReleaseMs(250);
      notifier.setDuckingTargetVolume(0.15);

      state = container.read(audioEditingProvider);
      expect(state.autoDucking.duckingStrength, equals(0.85));
      expect(state.autoDucking.attackMs, equals(40));
      expect(state.autoDucking.releaseMs, equals(250));
      expect(state.autoDucking.targetVolume, equals(0.15));
    });

    test('Lowering music volume to <= 30% IMMEDIATELY disables and locks Auto Ducking', () {
      final notifier = container.read(audioEditingProvider.notifier);

      // First enable auto ducking with volume at 70%
      notifier.toggleAutoDucking();
      expect(container.read(audioEditingProvider).autoDucking.isEnabled, isTrue);

      // Lower music volume to 25% (<= 30%)
      notifier.setMusicVolume(0.25);

      final state = container.read(audioEditingProvider);
      expect(state.customMusic.volume, equals(0.25));
      expect(state.mixer.channel2MusicVolume, equals(0.25));
      // MUST be forcibly disabled
      expect(state.autoDucking.isEnabled, isFalse);
      // MUST be locked
      expect(state.autoDucking.isLockedDueToVolume, isTrue);
      expect(
        state.autoDucking.lockReason,
        equals('Increase MP3 volume above 30% to enable Auto Ducking.'),
      );
    });

    test('Attempting to enable Auto Ducking when volume is <= 30% is rejected in application logic', () {
      final notifier = container.read(audioEditingProvider.notifier);

      // Set volume directly to 20%
      notifier.setMusicVolume(0.20);
      expect(container.read(audioEditingProvider).autoDucking.isLockedDueToVolume, isTrue);

      // Attempt toggle
      final success = notifier.toggleAutoDucking();
      expect(success, isFalse);
      expect(container.read(audioEditingProvider).autoDucking.isEnabled, isFalse);

      // Attempt direct config update
      notifier.updateAutoDucking((d) => d.copyWith(isEnabled: true));
      // Must be overridden back to disabled because volume <= 0.30
      expect(container.read(audioEditingProvider).autoDucking.isEnabled, isFalse);
      expect(container.read(audioEditingProvider).autoDucking.isLockedDueToVolume, isTrue);
    });

    test('Exactly at 30% (0.30), Auto Ducking is locked; at 31% (0.31), Auto Ducking unlocks', () {
      final notifier = container.read(audioEditingProvider.notifier);

      // Boundary: 0.30 is <= 30%
      notifier.setMusicVolume(0.30);
      expect(container.read(audioEditingProvider).autoDucking.isLockedDueToVolume, isTrue);

      // Boundary: 0.31 is > 30%
      notifier.setMusicVolume(0.31);
      expect(container.read(audioEditingProvider).autoDucking.isLockedDueToVolume, isFalse);

      // Can now enable
      final success = notifier.toggleAutoDucking();
      expect(success, isTrue);
      expect(container.read(audioEditingProvider).autoDucking.isEnabled, isTrue);
    });

    test('Raising volume from <= 30% back above 30% unlocks ducking controls without auto-re-enabling', () {
      final notifier = container.read(audioEditingProvider.notifier);

      notifier.setMusicVolume(0.15);
      expect(container.read(audioEditingProvider).autoDucking.isLockedDueToVolume, isTrue);

      // Raise to 75%
      notifier.setMusicVolume(0.75);
      final state = container.read(audioEditingProvider);
      expect(state.autoDucking.isLockedDueToVolume, isFalse);
      expect(state.autoDucking.isEnabled, isFalse); // Stays off until user explicitly turns it on
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 2. THREE-CHANNEL VOLUME MIXER TESTS
  // ───────────────────────────────────────────────────────────────────────────
  group('2. Three-Channel Master Volume Mixer Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Channel defaults: Channel 1 = 100%, Channel 2 = 70%, Channel 3 = 85%', () {
      final mixer = container.read(audioEditingProvider).mixer;
      expect(mixer.channel1MainVolume, equals(1.0));
      expect(mixer.channel2MusicVolume, equals(0.70));
      expect(mixer.channel3SfxVolume, equals(0.85));
      expect(mixer.channel1MainMuted, isFalse);
      expect(mixer.channel2MusicMuted, isFalse);
      expect(mixer.channel3SfxMuted, isFalse);

      expect(mixer.mainVolumePercent, equals(100));
      expect(mixer.musicVolumePercent, equals(70));
      expect(mixer.sfxVolumePercent, equals(85));
    });

    test('Channel 2 Background Music visibility is strictly conditional on imported MP3 track', () {
      final notifier = container.read(audioEditingProvider.notifier);

      // Initially no imported track
      var state = container.read(audioEditingProvider);
      expect(state.customMusic.hasTrack, isFalse);

      // Import an MP3 track
      notifier.importMusicFile(
        filePath: 'C:/Audio/lofi_beats.mp3',
        fileName: 'lofi_beats.mp3',
        fileSizeBytes: 4500000,
        durationSec: 154.2,
      );

      state = container.read(audioEditingProvider);
      expect(state.customMusic.hasTrack, isTrue);
      expect(state.customMusic.fileName, equals('lofi_beats.mp3'));
      expect(state.customMusic.formattedFileSize, equals('4.29 MB'));

      // Remove music track -> Channel 2 hides
      notifier.removeMusicFile();
      state = container.read(audioEditingProvider);
      expect(state.customMusic.hasTrack, isFalse);
    });

    test('All 3 channels maintain completely independent volume levels and mute states', () {
      final notifier = container.read(audioEditingProvider.notifier);

      notifier.setMainAudioVolume(0.42);
      notifier.setMusicChannelVolume(0.91);
      notifier.setSfxVolume(0.18);

      var mixer = container.read(audioEditingProvider).mixer;
      expect(mixer.channel1MainVolume, closeTo(0.42, 0.001));
      expect(mixer.channel2MusicVolume, closeTo(0.91, 0.001));
      expect(mixer.channel3SfxVolume, closeTo(0.18, 0.001));

      // Mute Channel 1 only
      notifier.toggleMainAudioMute();
      mixer = container.read(audioEditingProvider).mixer;
      expect(mixer.channel1MainMuted, isTrue);
      expect(mixer.channel2MusicMuted, isFalse);
      expect(mixer.channel3SfxMuted, isFalse);

      // Mute Channel 3 only
      notifier.toggleSfxMute();
      mixer = container.read(audioEditingProvider).mixer;
      expect(mixer.channel1MainMuted, isTrue);
      expect(mixer.channel2MusicMuted, isFalse);
      expect(mixer.channel3SfxMuted, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 3. AUDIO EFFECTS: FADE, REVERB, SILENCE REMOVAL
  // ───────────────────────────────────────────────────────────────────────────
  group('3. Audio Effects: Fade In/Out, Reverb & Silence Removal', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Fade In and Fade Out can be independently toggled and configured with curve options', () {
      final notifier = container.read(audioEditingProvider.notifier);

      notifier.toggleFadeIn();
      notifier.setFadeInDuration(2.5);
      notifier.setFadeInCurve(AudioFadeCurve.exponential);

      notifier.setFadeOutDuration(4.0);
      notifier.setFadeOutCurve(AudioFadeCurve.sCurve);

      final state = container.read(audioEditingProvider);
      expect(state.fade.fadeInEnabled, isTrue);
      expect(state.fade.fadeInDurationSec, equals(2.5));
      expect(state.fade.fadeInCurve, equals(AudioFadeCurve.exponential));

      expect(state.fade.fadeOutEnabled, isFalse); // Independent!
      expect(state.fade.fadeOutDurationSec, equals(4.0));
      expect(state.fade.fadeOutCurve, equals(AudioFadeCurve.sCurve));
    });

    test('Reverb configuration covers amount, room size, decay and wet/dry mix', () {
      final notifier = container.read(audioEditingProvider.notifier);

      notifier.toggleReverb();
      notifier.setReverbAmount(0.65);
      notifier.setReverbRoomSize(0.80);
      notifier.setReverbDecay(2.4);
      notifier.setReverbWetDryMix(0.35);

      final reverb = container.read(audioEditingProvider).reverb;
      expect(reverb.isEnabled, isTrue);
      expect(reverb.reverbAmount, equals(0.65));
      expect(reverb.roomSize, equals(0.80));
      expect(reverb.decay, equals(2.4));
      expect(reverb.wetDryMix, equals(0.35));
    });

    test('Silence Removal has configurable threshold dB, min duration, speech padding & sensitivity', () {
      final notifier = container.read(audioEditingProvider.notifier);

      notifier.toggleSilenceRemoval();
      notifier.setSilenceThresholdDb(-32.0);
      notifier.setMinSilenceDurationMs(750);
      notifier.setSpeechPaddingMs(200);
      notifier.setSilenceSensitivity(0.90);

      final silence = container.read(audioEditingProvider).silenceRemoval;
      expect(silence.isEnabled, isTrue);
      expect(silence.thresholdDb, equals(-32.0));
      expect(silence.minDurationMs, equals(750));
      expect(silence.speechPaddingMs, equals(200));
      expect(silence.sensitivity, equals(0.90));
      expect(container.read(audioEditingProvider).isPipelinePending, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 4. 10 VIDEO EFFECTS VERIFICATION & DEDICATED CONTROLS
  // ───────────────────────────────────────────────────────────────────────────
  group('4. 10 Advanced Video Effects & Dedicated Non-Generic Controls', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('All 10 effects exist and have effect-specific parameters', () {
      final state = container.read(advancedVideoEffectsProvider);
      expect(state.enabledEffectsCount, equals(0));

      // 1. Motion Blur
      expect(state.motionBlur.shutterAngle, equals(180.0));
      expect(state.motionBlur.sampleCount, equals(12));
      expect(state.motionBlur.directionDegrees, equals(90.0));

      // 2. Film Grain
      expect(state.filmGrain.intensity, equals(0.40));
      expect(state.filmGrain.grainAmount, equals(45.0));
      expect(state.filmGrain.isMonochrome, isTrue);

      // 3. Glitch
      expect(state.glitch.sliceCount, equals(14));
      expect(state.glitch.rgbSplitDistancePx, equals(12.0));
      expect(state.glitch.frequencyHz, equals(4.5));

      // 4. Digital Noise
      expect(state.digitalNoise.intensity, equals(0.35));
      expect(state.digitalNoise.amount, equals(30.0));
      expect(state.digitalNoise.noiseType, equals(DigitalNoiseType.gaussian));

      // 5. Chromatic Aberration
      expect(state.chromaticAberration.colourSeparationPx, equals(10.0));
      expect(state.chromaticAberration.directionDegrees, equals(45.0));

      // 6. Distortion
      expect(state.distortion.curvature, equals(0.35));
      expect(state.distortion.distortionMode, equals(DistortionMode.barrel));

      // 7. Lens Dispersion
      expect(state.lensDispersion.dispersionAmount, equals(0.50));
      expect(state.lensDispersion.spectralSpread, equals(1.0));

      // 8. Flicker
      expect(state.flicker.frequencyHz, equals(8.0));
      expect(state.flicker.amplitude, equals(0.40));

      // 9. Ghost Trail
      expect(state.ghostTrail.frameSpacing, equals(3));
      expect(state.ghostTrail.fadeDecayRate, equals(0.65));
      expect(state.ghostTrail.ghostCount, equals(4));

      // 10. Blur Detection
      expect(state.blurDetection.detectionThreshold, equals(0.45));
      expect(state.blurDetection.showHeatmapOverlay, isTrue);
    });

    test('Can toggle, update specific effect parameters, and track enabled count', () {
      final notifier = container.read(advancedVideoEffectsProvider.notifier);

      notifier.toggleEffectEnabled(AdvancedEffectType.motionBlur);
      notifier.toggleEffectEnabled(AdvancedEffectType.glitch);
      notifier.toggleEffectEnabled(AdvancedEffectType.lensDispersion);

      expect(container.read(advancedVideoEffectsProvider).enabledEffectsCount, equals(3));

      // Update Motion Blur custom shutter angle
      notifier.updateMotionBlur(
        (c) => c.copyWith(
          shutterAngle: 270.0,
          sampleCount: 16,
          directionDegrees: 180.0,
        ),
      );

      final mb = container.read(advancedVideoEffectsProvider).motionBlur;
      expect(mb.shutterAngle, equals(270.0));
      expect(mb.sampleCount, equals(16));
      expect(mb.directionDegrees, equals(180.0));
      expect(mb.isEnabled, isTrue);
    });

    test('Resetting individual effect restores its original defaults', () {
      final notifier = container.read(advancedVideoEffectsProvider.notifier);

      notifier.updateFilmGrain(
        (c) => c.copyWith(
          isEnabled: true,
          intensity: 0.90,
          grainAmount: 80.0,
          grainSize: FilmGrainSize.coarse,
          roughness: 0.80,
          isMonochrome: false,
        ),
      );

      expect(container.read(advancedVideoEffectsProvider).filmGrain.intensity, equals(0.90));
      expect(container.read(advancedVideoEffectsProvider).filmGrain.isMonochrome, isFalse);

      notifier.resetEffectToDefault(AdvancedEffectType.filmGrain);
      final fg = container.read(advancedVideoEffectsProvider).filmGrain;
      expect(fg.intensity, equals(0.40));
      expect(fg.grainAmount, equals(45.0));
      expect(fg.grainSize, equals(FilmGrainSize.medium));
      expect(fg.isMonochrome, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 5. VIDEO REPAIR, BLUR ANALYSIS & BEFORE/AFTER COMPARISON
  // ───────────────────────────────────────────────────────────────────────────
  group('5. Video Repair, Blur Detection Frame Analysis & Denoising', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Video Repair initial state includes pending pipeline status and clean baseline', () {
      final state = container.read(videoRepairProvider);
      expect(state.isPipelinePending, isTrue);
      expect(state.pipelineNotes.isNotEmpty, isTrue);
      expect(state.denoise.isEnabled, isTrue);
      expect(state.denoise.algorithm, equals(VideoDenoiseAlgorithm.hq3d));
      expect(state.blurAnalysis.isEnabled, isTrue);
      expect(state.comparisonMode, equals(ComparisonDisplayMode.splitScreen));
      expect(state.splitPosition, equals(0.50));
    });

    test('Denoising supports 4 algorithms: HQ3D, NLMeans, ATADenoise, Wavelet', () {
      final notifier = container.read(videoRepairProvider.notifier);

      notifier.toggleDenoise(true);
      notifier.setDenoiseAlgorithm(VideoDenoiseAlgorithm.nlmeans);
      notifier.setLumaThreshold(8.5);
      notifier.setChromaThreshold(6.0);
      notifier.setTemporalBlend(0.75);

      var denoise = container.read(videoRepairProvider).denoise;
      expect(denoise.isEnabled, isTrue);
      expect(denoise.algorithm, equals(VideoDenoiseAlgorithm.nlmeans));
      expect(denoise.lumaThreshold, equals(8.5));
      expect(denoise.chromaThreshold, equals(6.0));
      expect(denoise.temporalBlend, equals(0.75));

      notifier.setDenoiseAlgorithm(VideoDenoiseAlgorithm.atadenoise);
      denoise = container.read(videoRepairProvider).denoise;
      expect(denoise.algorithm, equals(VideoDenoiseAlgorithm.atadenoise));
    });

    test('Blur Detection is a diagnostic analyzer that detects blurry frame segments', () {
      final notifier = container.read(videoRepairProvider.notifier);

      notifier.toggleBlurDetection(true);
      notifier.setBlurThreshold(0.45);
      notifier.setBlurSampleRate(12);

      final blur = container.read(videoRepairProvider).blurAnalysis;
      expect(blur.isEnabled, isTrue);
      expect(blur.threshold, equals(0.45));
      expect(blur.sampleRateFrames, equals(12));
      expect(blur.detectedSegments.isNotEmpty, isTrue);

      final firstSegment = blur.detectedSegments.first;
      expect(firstSegment.startSec, greaterThanOrEqualTo(0.0));
      expect(firstSegment.endSec, greaterThan(firstSegment.startSec));
      expect(firstSegment.timeLabel, contains('s'));
    });

    test('Before/After comparison modes and split slider position are interactive', () {
      final notifier = container.read(videoRepairProvider.notifier);

      notifier.setComparisonMode(ComparisonDisplayMode.sideBySide);
      expect(container.read(videoRepairProvider).comparisonMode, equals(ComparisonDisplayMode.sideBySide));

      notifier.setComparisonMode(ComparisonDisplayMode.toggle);
      notifier.toggleRepairedPreview();
      expect(container.read(videoRepairProvider).isShowingRepairedPreview, isFalse);

      notifier.setComparisonMode(ComparisonDisplayMode.splitScreen);
      notifier.setSplitPosition(0.72);
      expect(container.read(videoRepairProvider).splitPosition, equals(0.72));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 6. FFMPEG INSTALLATION DISCOVERY & FILTER VERIFICATION
  // ───────────────────────────────────────────────────────────────────────────
  group('6. FFmpeg Installation Discovery, Bundled Binaries & Filter Support', () {
    test('FfmpegService discovers bundled Windows executable paths', () async {
      final service = FfmpegService.instance;
      final ffmpegPath = await service.getFfmpegPath();
      final ffprobePath = await service.getFfprobePath();

      expect(ffmpegPath, isNotNull);
      expect(ffprobePath, isNotNull);
      expect(ffmpegPath!.toLowerCase().endsWith('ffmpeg.exe'), isTrue);
      expect(ffprobePath!.toLowerCase().endsWith('ffprobe.exe'), isTrue);

      // Verify physical presence in windows/ffmpeg/
      final file = File(ffmpegPath);
      expect(await file.exists(), isTrue);
    });

    test('FfmpegService parses filters and checks for required video/audio filters', () async {
      final service = FfmpegService.instance;
      final report = await service.verifyInstallation(forceRefresh: true);

      expect(report.isFfmpegInstalled, isTrue);
      expect(report.isFfprobeInstalled, isTrue);
      expect(report.ffmpegPath, isNotNull);
      expect(report.ffprobePath, isNotNull);
      expect(report.version, isNotNull);

      // Verify the critical video filters
      expect(report.requiredVideoFiltersFound['hqdn3d'], isTrue, reason: 'hqdn3d required for HQ video denoise');
      expect(report.requiredVideoFiltersFound['nlmeans'], isTrue, reason: 'nlmeans required for non-local means denoise');
      expect(report.requiredVideoFiltersFound['atadenoise'], isTrue, reason: 'atadenoise required for temporal denoise');
      expect(report.requiredVideoFiltersFound['noise'], isTrue, reason: 'noise required for film grain & digital noise');
      expect(report.requiredVideoFiltersFound['tblend'], isTrue, reason: 'tblend required for ghost trail & motion blur');
      expect(report.requiredVideoFiltersFound['fade'], isTrue, reason: 'fade required for video transitions');

      // Verify the critical audio filters
      expect(report.requiredAudioFiltersFound['afade'], isTrue, reason: 'afade required for audio fade in/out');
      expect(report.requiredAudioFiltersFound['aecho'], isTrue, reason: 'aecho required for reverb');
      expect(report.requiredAudioFiltersFound['sidechaincompress'], isTrue, reason: 'sidechaincompress required for auto ducking');
      expect(report.requiredAudioFiltersFound['silencedetect'], isTrue, reason: 'silencedetect required for silence removal');
      expect(report.requiredAudioFiltersFound['volume'], isTrue, reason: 'volume required for 3-channel mixer');
      expect(report.requiredAudioFiltersFound['amix'], isTrue, reason: 'amix required for audio track mixing');

      // Check operational status
      expect(report.isFullyOperational, isTrue);
      expect(report.supportedVerifiedFiltersCount, equals(report.totalVerifiedFilters));
    });
  });
}
