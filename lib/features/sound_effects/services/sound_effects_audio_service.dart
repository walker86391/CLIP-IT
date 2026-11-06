import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Lightweight audio player service dedicated to auditioning short sound effects.
///
/// Ensures only one sound effect plays at any given time, auto-resets when finished,
/// and handles errors cleanly without throwing unhandled exceptions in tests or runtime.
class SoundEffectsAudioService {
  SoundEffectsAudioService._();
  static final SoundEffectsAudioService instance = SoundEffectsAudioService._();

  VideoPlayerController? _controller;
  String? _currentlyPlayingId;
  VoidCallback? _statusListener;

  String? get currentlyPlayingId => _currentlyPlayingId;
  bool isPlaying(String id) => _currentlyPlayingId == id;

  /// Plays a sound effect by its asset or absolute file path.
  /// If the same effect is already playing, toggling calls stop().
  Future<void> playEffect({
    required String id,
    required String assetPath,
    required void Function(String? currentPlayingId) onStateChanged,
  }) async {
    // If already playing this effect, toggle off
    if (_currentlyPlayingId == id) {
      await stop(onStateChanged: onStateChanged);
      return;
    }

    // Stop whatever was playing previously
    await stop(onStateChanged: onStateChanged);

    try {
      _currentlyPlayingId = id;
      onStateChanged(_currentlyPlayingId);

      // On Windows or local assets, check if the asset file exists directly on disk
      // or load via VideoPlayerController.asset / file
      final localAssetFile = File(assetPath);
      VideoPlayerController controller;

      if (localAssetFile.existsSync()) {
        controller = VideoPlayerController.file(localAssetFile);
      } else {
        controller = VideoPlayerController.asset(assetPath);
      }

      _controller = controller;

      await controller.initialize();
      await controller.setVolume(1.0);

      _statusListener = () {
        if (!controller.value.isInitialized) return;
        final pos = controller.value.position;
        final dur = controller.value.duration;
        if (pos >= dur && dur > Duration.zero) {
          stop(onStateChanged: onStateChanged);
        }
      };

      controller.addListener(_statusListener!);
      await controller.play();
    } catch (e) {
      debugPrint('SoundEffectsAudioService: Playback simulation notice ($e)');
      // If native player fails (e.g. in headless unit tests), we gracefully reset state
      _currentlyPlayingId = null;
      onStateChanged(null);
    }
  }

  /// Stops playback immediately and clears controller resources.
  Future<void> stop({
    required void Function(String? currentPlayingId) onStateChanged,
  }) async {
    final oldController = _controller;
    _controller = null;
    _currentlyPlayingId = null;

    if (oldController != null) {
      if (_statusListener != null) {
        oldController.removeListener(_statusListener!);
        _statusListener = null;
      }
      try {
        await oldController.pause();
        await oldController.dispose();
      } catch (_) {}
    }

    onStateChanged(null);
  }

  /// Disposes active controller resources.
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _currentlyPlayingId = null;
    _statusListener = null;
  }
}
