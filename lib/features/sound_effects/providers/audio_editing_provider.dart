import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/audio_editing_models.dart';

/// Notifier managing audio fade, reverb, silence removal, custom background music,
/// auto ducking volume gating, and the 3-channel master audio mixer.
class AudioEditingNotifier extends Notifier<AudioEditingState> {
  static const _prefsKey = 'clipit_audio_editing_state_v1';

  @override
  AudioEditingState build() {
    _loadFromPreferences();
    return const AudioEditingState();
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final loaded = AudioEditingState.fromJson(decoded);

        // Re-enforce the volume restriction logic upon load
        final isVolumeLocked = loaded.customMusic.volume <= 0.30;
        final duckingEnabled = isVolumeLocked ? false : loaded.autoDucking.isEnabled;

        state = loaded.copyWith(
          autoDucking: loaded.autoDucking.copyWith(
            isEnabled: duckingEnabled,
            isLockedDueToVolume: isVolumeLocked,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to load AudioEditingState from preferences: $e');
    }
  }

  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(state.toJson());
      await prefs.setString(_prefsKey, jsonStr);
    } catch (e) {
      debugPrint('Failed to persist AudioEditingState: $e');
    }
  }

  // ── 1. Audio Fade In / Fade Out ──────────────────────────────────────────

  void updateFade(AudioFadeConfig Function(AudioFadeConfig current) update) {
    state = state.copyWith(fade: update(state.fade));
    _saveToPreferences();
  }

  void toggleFadeIn([bool? force]) {
    updateFade((f) => f.copyWith(fadeInEnabled: force ?? !f.fadeInEnabled));
  }

  void setFadeInDuration(double seconds) {
    updateFade((f) => f.copyWith(fadeInDurationSec: seconds.clamp(0.1, 10.0)));
  }

  void setFadeInCurve(AudioFadeCurve curve) {
    updateFade((f) => f.copyWith(fadeInCurve: curve));
  }

  void toggleFadeOut([bool? force]) {
    updateFade((f) => f.copyWith(fadeOutEnabled: force ?? !f.fadeOutEnabled));
  }

  void setFadeOutDuration(double seconds) {
    updateFade((f) => f.copyWith(fadeOutDurationSec: seconds.clamp(0.1, 10.0)));
  }

  void setFadeOutCurve(AudioFadeCurve curve) {
    updateFade((f) => f.copyWith(fadeOutCurve: curve));
  }

  // ── 2. Audio Reverb ──────────────────────────────────────────────────────

  void updateReverb(AudioReverbConfig Function(AudioReverbConfig current) update) {
    state = state.copyWith(reverb: update(state.reverb));
    _saveToPreferences();
  }

  void toggleReverb([bool? force]) {
    updateReverb((r) => r.copyWith(isEnabled: force ?? !r.isEnabled));
  }

  void setReverbAmount(double amount) {
    updateReverb((r) => r.copyWith(reverbAmount: amount.clamp(0.0, 1.0)));
  }

  void setReverbRoomSize(double roomSize) {
    updateReverb((r) => r.copyWith(roomSize: roomSize.clamp(0.0, 1.0)));
  }

  void setReverbDecay(double decaySec) {
    updateReverb((r) => r.copyWith(decay: decaySec.clamp(0.1, 5.0)));
  }

  void setReverbWetDryMix(double mix) {
    updateReverb((r) => r.copyWith(wetDryMix: mix.clamp(0.0, 1.0)));
  }

  // ── 3. Silence Removal ───────────────────────────────────────────────────

  void updateSilenceRemoval(
      SilenceRemovalConfig Function(SilenceRemovalConfig current) update) {
    state = state.copyWith(silenceRemoval: update(state.silenceRemoval));
    _saveToPreferences();
  }

  void toggleSilenceRemoval([bool? force]) {
    updateSilenceRemoval(
        (s) => s.copyWith(isEnabled: force ?? !s.isEnabled));
  }

  void setSilenceThresholdDb(double db) {
    updateSilenceRemoval(
        (s) => s.copyWith(thresholdDb: db.clamp(-60.0, -10.0)));
  }

  void setMinSilenceDurationMs(int ms) {
    updateSilenceRemoval(
        (s) => s.copyWith(minDurationMs: ms.clamp(100, 3000)));
  }

  void setSpeechPaddingMs(int ms) {
    updateSilenceRemoval(
        (s) => s.copyWith(speechPaddingMs: ms.clamp(0, 500)));
  }

  void setSilenceSensitivity(double sensitivity) {
    updateSilenceRemoval(
        (s) => s.copyWith(sensitivity: sensitivity.clamp(0.0, 1.0)));
  }

  // ── 4. Custom Music Track ────────────────────────────────────────────────

  void importMusicFile({
    required String filePath,
    required String fileName,
    int? fileSizeBytes,
    double? durationSec,
  }) {
    final nextTrack = state.customMusic.copyWith(
      hasTrack: true,
      filePath: filePath,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      durationSec: durationSec,
      isEnabled: true,
    );

    // Keep channel 2 volume in sync with music track volume
    final nextMixer = state.mixer.copyWith(
      channel2MusicVolume: state.customMusic.volume,
    );

    state = state.copyWith(
      customMusic: nextTrack,
      mixer: nextMixer,
    );
    _saveToPreferences();
  }

  void removeMusicFile() {
    state = state.copyWith(
      customMusic: const CustomMusicTrack(
        hasTrack: false,
        filePath: null,
        fileName: null,
        fileSizeBytes: null,
        durationSec: null,
      ),
      autoDucking: state.autoDucking.copyWith(isEnabled: false),
    );
    _saveToPreferences();
  }

  void toggleMusicEnabled([bool? force]) {
    final next = force ?? !state.customMusic.isEnabled;
    state = state.copyWith(
      customMusic: state.customMusic.copyWith(isEnabled: next),
    );
    _saveToPreferences();
  }

  void setMusicFadeIn(double seconds) {
    state = state.copyWith(
      customMusic: state.customMusic.copyWith(
        fadeInSec: seconds.clamp(0.0, 10.0),
      ),
    );
    _saveToPreferences();
  }

  void setMusicFadeOut(double seconds) {
    state = state.copyWith(
      customMusic: state.customMusic.copyWith(
        fadeOutSec: seconds.clamp(0.0, 10.0),
      ),
    );
    _saveToPreferences();
  }

  // ── 5. Automatic Audio Ducking (Strict Volume Gating) ────────────────────

  /// Sets music volume and enforces the mandatory Auto Ducking restriction:
  ///
  /// CRITICAL RULE:
  /// Auto Ducking must only be accessible when the imported MP3 volume is ABOVE 30% (> 0.30).
  /// If MP3 volume is 30% or lower (<= 0.30):
  /// - Visually disable the Auto Ducking toggle.
  /// - Prevent users from opening or enabling its settings.
  /// - If volume is reduced to 30% or below while Auto Ducking is enabled,
  ///   disable Auto Ducking immediately and visually lock it again.
  /// If volume is increased above 30%, automatically unlock the feature.
  void setMusicVolume(double volume) {
    final clamped = volume.clamp(0.0, 1.0);
    final isLocked = clamped <= 0.30;

    // If volume falls to 30% or below, ducking must be shut off immediately
    final effectiveDuckingEnabled =
        isLocked ? false : state.autoDucking.isEnabled;

    state = state.copyWith(
      customMusic: state.customMusic.copyWith(volume: clamped),
      mixer: state.mixer.copyWith(channel2MusicVolume: clamped),
      autoDucking: state.autoDucking.copyWith(
        isEnabled: effectiveDuckingEnabled,
        isLockedDueToVolume: isLocked,
      ),
    );
    _saveToPreferences();
  }

  /// Toggles Auto Ducking if eligible. Strictly blocked if volume <= 30%.
  bool toggleAutoDucking() {
    if (state.customMusic.volume <= 0.30) {
      // Rule: cannot enable if volume <= 30%
      state = state.copyWith(
        autoDucking: state.autoDucking.copyWith(
          isEnabled: false,
          isLockedDueToVolume: true,
        ),
      );
      _saveToPreferences();
      return false;
    }

    final next = !state.autoDucking.isEnabled;
    state = state.copyWith(
      autoDucking: state.autoDucking.copyWith(
        isEnabled: next,
        isLockedDueToVolume: false,
      ),
    );
    _saveToPreferences();
    return next;
  }

  void updateAutoDucking(
      AutoDuckingConfig Function(AutoDuckingConfig current) update) {
    final updated = update(state.autoDucking);

    // Enforce volume lock override
    if (state.customMusic.volume <= 0.30) {
      state = state.copyWith(
        autoDucking: updated.copyWith(
          isEnabled: false,
          isLockedDueToVolume: true,
        ),
      );
    } else {
      state = state.copyWith(autoDucking: updated);
    }
    _saveToPreferences();
  }

  void setDuckingStrength(double strength) {
    updateAutoDucking((d) => d.copyWith(duckingStrength: strength.clamp(0.0, 1.0)));
  }

  void setDuckingAttackMs(int ms) {
    updateAutoDucking((d) => d.copyWith(attackMs: ms.clamp(10, 500)));
  }

  void setDuckingReleaseMs(int ms) {
    updateAutoDucking((d) => d.copyWith(releaseMs: ms.clamp(50, 2000)));
  }

  void setDuckingTargetVolume(double target) {
    updateAutoDucking((d) => d.copyWith(targetVolume: target.clamp(0.0, 0.5)));
  }

  // ── 6. Three-Channel Master Volume Mixer ─────────────────────────────────

  /// Channel 1: Main Audio from uploaded video (0.0 to 1.0)
  void setMainAudioVolume(double volume) {
    state = state.copyWith(
      mixer: state.mixer.copyWith(
        channel1MainVolume: volume.clamp(0.0, 1.0),
      ),
    );
    _saveToPreferences();
  }

  void toggleMainAudioMute([bool? force]) {
    state = state.copyWith(
      mixer: state.mixer.copyWith(
        channel1MainMuted: force ?? !state.mixer.channel1MainMuted,
      ),
    );
    _saveToPreferences();
  }

  /// Channel 2: Background Music (0.0 to 1.0) - Syncs with CustomMusicTrack
  void setMusicChannelVolume(double volume) {
    setMusicVolume(volume);
  }

  void toggleMusicChannelMute([bool? force]) {
    final next = force ?? !state.mixer.channel2MusicMuted;
    state = state.copyWith(
      mixer: state.mixer.copyWith(channel2MusicMuted: next),
      customMusic: state.customMusic.copyWith(isMuted: next),
    );
    _saveToPreferences();
  }

  /// Channel 3: Sound Effects (0.0 to 1.0)
  void setSfxVolume(double volume) {
    state = state.copyWith(
      mixer: state.mixer.copyWith(
        channel3SfxVolume: volume.clamp(0.0, 1.0),
      ),
    );
    _saveToPreferences();
  }

  void toggleSfxMute([bool? force]) {
    state = state.copyWith(
      mixer: state.mixer.copyWith(
        channel3SfxMuted: force ?? !state.mixer.channel3SfxMuted,
      ),
    );
    _saveToPreferences();
  }
}

/// Global provider for Audio Editing capabilities.
final audioEditingProvider =
    NotifierProvider<AudioEditingNotifier, AudioEditingState>(
  AudioEditingNotifier.new,
);
