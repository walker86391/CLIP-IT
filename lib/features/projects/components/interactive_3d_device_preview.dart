import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/project_workflow_state.dart';

/// Interactive 3D Device Viewport.
///
/// Features:
/// - True 3D perspective rotation (Matrix4 with camera depth projection).
/// - Cursor changes to grab / grabbing.
/// - Horizontal drag rotates the device so the left side comes toward the camera
///   and the right side recedes into the background.
/// - Realistic multi-layer 3D chassis thickness, metallic rims, dynamic island,
///   and specular gloss highlights.
/// - Supports iPhone, Samsung Galaxy, and Laptop frames.
/// - Embeds real video player or simulated creative playback.
/// - Reframes video according to selected aspect ratio (16:9, 9:16, 1:1, etc.).
/// - Optional platform UI safe-zone blocks overlay ("preview platform blocks").
/// Video playback position and duration model for repaint isolation.
class VideoPlaybackProgress {
  const VideoPlaybackProgress({
    required this.positionSeconds,
    required this.durationSeconds,
  });

  final double positionSeconds;
  final double durationSeconds;

  double get fraction => durationSeconds > 0
      ? (positionSeconds / durationSeconds).clamp(0.0, 1.0)
      : 0.0;
}

class Interactive3dDevicePreview extends StatefulWidget {
  const Interactive3dDevicePreview({
    required this.deviceType,
    required this.aspectRatio,
    required this.previewPlatformBlocks,
    this.videoFilePath,
    this.onTogglePlatformBlocks,
    this.isFrozen = false,
    this.overlayContent,
    this.screenContentWrapper,
    this.showScrubber = true,
    this.onPlayPauseChanged,
    this.isMuted,
    this.onToggleMute,
    this.bottomWidget,
    super.key,
  });

  final PreviewDeviceType deviceType;
  final VideoAspectRatio aspectRatio;
  final bool previewPlatformBlocks;
  final String? videoFilePath;
  final VoidCallback? onTogglePlatformBlocks;
  final bool isFrozen;
  final Widget? overlayContent;
  final Widget Function(Widget child)? screenContentWrapper;
  final bool showScrubber;
  final ValueChanged<bool>? onPlayPauseChanged;
  final bool? isMuted;
  final VoidCallback? onToggleMute;
  final Widget? bottomWidget;

  /// Globally pauses video playback in the 3D device preview.
  /// Called when pipeline starts or when user navigates away from "My Clips".
  static void pausePlayback() {
    _Interactive3dDevicePreviewState.pausePlayback();
  }

  @override
  State<Interactive3dDevicePreview> createState() =>
      _Interactive3dDevicePreviewState();
}

class _Interactive3dDevicePreviewState extends State<Interactive3dDevicePreview>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  // Persisted cross-step playback state so navigation retains position & play/pause
  static double _sharedPositionSeconds = 4.0;
  static bool _sharedIsPlaying = true;
  static _Interactive3dDevicePreviewState? _activeInstance;

  /// Pauses playback across active instance and prevents auto-play on next steps.
  static void pausePlayback() {
    _sharedIsPlaying = false;
    _activeInstance?._pauseVideoInternal();
  }

  void _pauseVideoInternal() {
    _sharedIsPlaying = false;
    _stopSimulatedTimer();
    if (_videoController != null && _isVideoInitialized) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      }
    }
    _updateProgressData();
    if (mounted) {
      setState(() => _isPlaying = false);
    }
    widget.onPlayPauseChanged?.call(false);
  }

  bool _isPlaying = _sharedIsPlaying;
  bool _isMuted = false;
  Timer? _simulatedTimer;

  bool get _effectiveMuted => widget.isMuted ?? _isMuted;

  // 3D rotation angles (radians)
  static const double _initialRotY = -0.06; // slight initial tilt
  static const double _initialRotX = 0.0;
  double _rotY = _initialRotY;
  double _rotX = _initialRotX;
  bool _isRotating = false;

  late AnimationController _resetController;
  late Animation<double> _rotYAnimation;
  late Animation<double> _rotXAnimation;

  // Simulation timer for fallback when no video file
  double _simulatedPositionSeconds = _sharedPositionSeconds;
  final double _simulatedDurationSeconds = 12.0;

  late final ValueNotifier<VideoPlaybackProgress> _progressNotifier =
      ValueNotifier<VideoPlaybackProgress>(
    VideoPlaybackProgress(
      positionSeconds: _sharedPositionSeconds,
      durationSeconds: _simulatedDurationSeconds,
    ),
  );

  void _updateProgressData() {
    double curSec = 0.0;
    double durSec = 1.0;
    if (_videoController != null && _isVideoInitialized) {
      curSec = _videoController!.value.position.inMilliseconds / 1000.0;
      durSec = math.max(
        1.0,
        _videoController!.value.duration.inMilliseconds / 1000.0,
      );
    } else {
      curSec = _simulatedPositionSeconds;
      durSec = _simulatedDurationSeconds;
    }
    _sharedPositionSeconds = curSec;
    _progressNotifier.value = VideoPlaybackProgress(
      positionSeconds: curSec,
      durationSeconds: durSec,
    );
  }


  void _toggleMute() {
    if (widget.onToggleMute != null) {
      widget.onToggleMute!();
    } else {
      setState(() => _isMuted = !_isMuted);
      _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
    }
  }

  void _onBlankPointerDown(PointerDownEvent event) {
    if (widget.isFrozen) return;
    _resetController.stop();
    setState(() {
      _isRotating = true;
    });
  }

  void _onBlankPointerMove(PointerMoveEvent event) {
    if (widget.isFrozen || !_isRotating) return;
    setState(() {
      _rotY = (_rotY + event.delta.dx * 0.007).clamp(-0.85, 0.85);
      _rotX = (_rotX - event.delta.dy * 0.003).clamp(-0.16, 0.16);
    });
  }

  void _onBlankPointerUp(PointerEvent event) {
    if (!_isRotating) return;
    _isRotating = false;
    _rotYAnimation = Tween<double>(begin: _rotY, end: _initialRotY).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );
    _rotXAnimation = Tween<double>(begin: _rotX, end: _initialRotX).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );
    _resetController.forward(from: 0.0);
  }

  @override
  void initState() {
    super.initState();
    _activeInstance = this;
    _rotY = _initialRotY;
    _rotX = _initialRotX;
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotYAnimation = Tween<double>(begin: _initialRotY, end: _initialRotY)
        .animate(_resetController);
    _rotXAnimation = Tween<double>(begin: _initialRotX, end: _initialRotX)
        .animate(_resetController);
    _resetController.addListener(() {
      setState(() {
        _rotY = _rotYAnimation.value;
        _rotX = _rotXAnimation.value;
      });
    });
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant Interactive3dDevicePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoFilePath != widget.videoFilePath) {
      _initVideo();
    }
    if (oldWidget.isMuted != widget.isMuted) {
      _videoController?.setVolume(_effectiveMuted ? 0.0 : 1.0);
    }
  }

  void _startSimulatedTimer() {
    _simulatedTimer?.cancel();
    final isTest = WidgetsBinding.instance.runtimeType
        .toString()
        .toLowerCase()
        .contains('test');
    if (isTest) return;

    if (_isPlaying && (_videoController == null || !_isVideoInitialized)) {
      _simulatedTimer =
          Timer.periodic(const Duration(milliseconds: 250), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        _simulatedPositionSeconds += 0.25;
        if (_simulatedPositionSeconds > _simulatedDurationSeconds) {
          _simulatedPositionSeconds = 0.0;
        }
        _updateProgressData();
      });
    }
  }

  void _stopSimulatedTimer() {
    _simulatedTimer?.cancel();
    _simulatedTimer = null;
  }

  Future<void> _initVideo() async {
    final path = widget.videoFilePath;
    if (path != null && File(path).existsSync()) {
      try {
        _videoController?.removeListener(_onVideoTick);
        _videoController?.dispose();
        _stopSimulatedTimer();
        final controller = VideoPlayerController.file(File(path));
        await controller.initialize();
        await controller.setVolume(_effectiveMuted ? 0.0 : 1.0);
        await controller.setLooping(true);

        // Restore persisted playback position if within valid range
        if (_sharedPositionSeconds > 0) {
          final targetMs = (_sharedPositionSeconds * 1000).round();
          final durationMs = controller.value.duration.inMilliseconds;
          if (targetMs < durationMs) {
            await controller.seekTo(Duration(milliseconds: targetMs));
          }
        }

        if (_sharedIsPlaying) {
          await controller.play();
        } else {
          await controller.pause();
        }

        controller.addListener(_onVideoTick);
        if (mounted) {
          setState(() {
            _videoController = controller;
            _isVideoInitialized = true;
            _isPlaying = _sharedIsPlaying;
          });
          widget.onPlayPauseChanged?.call(_sharedIsPlaying);
        } else {
          controller.dispose();
        }
      } catch (e) {
        debugPrint('Video init note: $e');
        if (mounted) {
          setState(() {
            _isVideoInitialized = false;
          });
          _startSimulatedTimer();
        }
      }
    } else {
      _startSimulatedTimer();
    }
  }

  void _onVideoTick() {
    if (!mounted) return;
    _updateProgressData();
    final isNowPlaying = _videoController?.value.isPlaying ?? false;
    _sharedIsPlaying = isNowPlaying;
    if (isNowPlaying != _isPlaying) {
      setState(() => _isPlaying = isNowPlaying);
      widget.onPlayPauseChanged?.call(isNowPlaying);
    }
  }

  @override
  void dispose() {
    if (_activeInstance == this) {
      _activeInstance = null;
    }
    _resetController.dispose();
    _stopSimulatedTimer();
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController != null && _isVideoInitialized) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _sharedIsPlaying = false;
        setState(() => _isPlaying = false);
        widget.onPlayPauseChanged?.call(false);
      } else {
        _videoController!.play();
        _sharedIsPlaying = true;
        setState(() => _isPlaying = true);
        widget.onPlayPauseChanged?.call(true);
      }
    } else {
      final nextPlaying = !_isPlaying;
      _sharedIsPlaying = nextPlaying;
      setState(() => _isPlaying = nextPlaying);
      if (nextPlaying) {
        _startSimulatedTimer();
      } else {
        _stopSimulatedTimer();
      }
      widget.onPlayPauseChanged?.call(nextPlaying);
    }
  }

  void _seekRelative(int seconds) {
    if (_videoController != null && _isVideoInitialized) {
      final current = _videoController!.value.position;
      final target = current + Duration(seconds: seconds);
      _videoController!.seekTo(target);
      _sharedPositionSeconds = target.inMilliseconds / 1000.0;
      _updateProgressData();
    } else {
      _simulatedPositionSeconds = (_simulatedPositionSeconds + seconds)
          .clamp(0.0, _simulatedDurationSeconds);
      _updateProgressData();
    }
  }

  void _seekToFraction(double fraction) {
    final clamped = fraction.clamp(0.0, 1.0);
    if (_videoController != null && _isVideoInitialized) {
      final duration = _videoController!.value.duration;
      final target = duration * clamped;
      _videoController!.seekTo(target);
      _sharedPositionSeconds = target.inMilliseconds / 1000.0;
      _updateProgressData();
    } else {
      _simulatedPositionSeconds = _simulatedDurationSeconds * clamped;
      _updateProgressData();
    }
  }

  String _formatTime(Duration duration) {
    final mins = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final deviceColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── 3D Interactive Device Frame (Opaque: mouse on device/screen does NOT rotate 3D model) ──
        MouseRegion(
          cursor: SystemMouseCursors.basic,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) {
              // Mouse is on device/screen: screen interaction (subtitles) moves, model stays stationary
            },
            child: _buildDeviceChassis(),
          ),
        ),

        if (widget.showScrubber) ...[
          const SizedBox(height: 14),

          // ── Scrubber & Timestamp Row ────────────────────────────────────────
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) {},
            child: SizedBox(
              width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<VideoPlaybackProgress>(
                valueListenable: _progressNotifier,
                builder: (context, progress, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(Duration(
                          seconds: progress.positionSeconds.round(),
                        )),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: _InteractiveScrubberBar(
                            progressFraction: progress.fraction,
                            onSeek: _seekToFraction,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(Duration(
                          seconds: progress.durationSeconds.round(),
                        )),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),

              // ── Playback Controls: (-5s)  |<<  ||  >>|  (+5s)  [Mute] ───────
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Replay 5s
                    IconButton(
                      onPressed: () => _seekRelative(-5),
                      icon: const Icon(Icons.replay_5_rounded),
                      iconSize: 20,
                      color: const Color(0xFFD1D5DB),
                      tooltip: 'Replay 5s',
                      splashRadius: 18,
                    ),
                    const SizedBox(width: 6),
                    // Previous
                    IconButton(
                      onPressed: () => _seekToFraction(0.0),
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 22,
                      color: const Color(0xFFD1D5DB),
                      tooltip: 'Restart',
                      splashRadius: 18,
                    ),
                    const SizedBox(width: 6),
                    // Play / Pause
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2030),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3B3E54),
                          width: 1.0,
                        ),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: _togglePlayPause,
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: _isPlaying ? 'Pause' : 'Play',
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Next / End
                    IconButton(
                      onPressed: () => _seekToFraction(0.98),
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 22,
                      color: const Color(0xFFD1D5DB),
                      tooltip: 'Skip to End',
                      splashRadius: 18,
                    ),
                    const SizedBox(width: 6),
                    // Forward 5s
                    IconButton(
                      onPressed: () => _seekRelative(5),
                      icon: const Icon(Icons.forward_5_rounded),
                      iconSize: 20,
                      color: const Color(0xFFD1D5DB),
                      tooltip: 'Forward 5s',
                      splashRadius: 18,
                    ),
                    const SizedBox(width: 6),
                    // Mute / Unmute
                    IconButton(
                      onPressed: _toggleMute,
                      icon: Icon(
                        _effectiveMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                      ),
                      iconSize: 20,
                      color: _effectiveMuted
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFD1D5DB),
                      tooltip: _effectiveMuted ? 'Unmute' : 'Mute',
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── "preview platform blocks" Pill Button ─────────────────────
              GestureDetector(
                onTap: widget.onTogglePlatformBlocks,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: widget.previewPlatformBlocks
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.18)
                          : const Color(0xFF13141F),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.previewPlatformBlocks
                            ? const Color(0xFFA78BFA)
                            : const Color(0xFF8B5CF6).withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      boxShadow: widget.previewPlatformBlocks
                          ? [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6)
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: const Text(
                      'preview platform blocks',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: Color(0xFFC4B5FD),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ],
      if (widget.bottomWidget != null) ...[
        const SizedBox(height: 12),
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) {},
          child: widget.bottomWidget!,
        ),
      ],
    ],
  );

  return LayoutBuilder(
    builder: (context, constraints) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Blank space in left pane catches drag to rotate
          Positioned.fill(
            child: MouseRegion(
              cursor: widget.isFrozen
                  ? SystemMouseCursors.basic
                  : (_isRotating
                      ? SystemMouseCursors.grabbing
                      : SystemMouseCursors.grab),
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: widget.isFrozen ? null : _onBlankPointerDown,
                onPointerMove: widget.isFrozen ? null : _onBlankPointerMove,
                onPointerUp: widget.isFrozen ? null : _onBlankPointerUp,
                onPointerCancel: widget.isFrozen ? null : _onBlankPointerUp,
              ),
            ),
          ),
          // Centered scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Center(
              child: deviceColumn,
            ),
          ),
        ],
      );
    },
  );
  }

  /// Builds the 3D-projected device chassis.
  Widget _buildDeviceChassis() {
    final isLaptop = widget.deviceType == PreviewDeviceType.laptop;

    // Dimension setup
    final double width = isLaptop ? 460 : 252;
    final double height = isLaptop ? 295 : 495;

    final effectiveRotX = widget.isFrozen ? 0.0 : _rotX;
    final effectiveRotY = widget.isFrozen ? 0.0 : _rotY;

    // 3D Perspective Matrix
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0014) // Camera depth perspective
      ..rotateX(effectiveRotX)
      ..rotateY(effectiveRotY);

    return RepaintBoundary(
      child: Transform(
        transform: matrix,
        alignment: Alignment.center,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            boxShadow: [
              // Realistic ambient drop shadow behind device in 3D
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 36,
                offset: Offset(-_rotY * 40, 16 + _rotX * 20),
              ),
            ],
          ),
          child: isLaptop ? _buildLaptopFrame() : _buildPhoneFrame(),
        ),
      ),
    );
  }

  /// Builds mobile phone frame (iPhone or Samsung).
  Widget _buildPhoneFrame() {
    final isSamsung = widget.deviceType == PreviewDeviceType.samsung;
    final outerRadius = isSamsung ? 32.0 : 42.0;
    final innerRadius = isSamsung ? 24.0 : 34.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(outerRadius),
        // Metallic edge gradient
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSamsung
              ? [
                  const Color(0xFF8BB5DF),
                  const Color(0xFF384C66),
                  const Color(0xFF161F2E),
                ]
              : [
                  const Color(0xFF6B6E7D),
                  const Color(0xFF282A36),
                  const Color(0xFF14151C),
                ],
        ),
        border: Border.all(
          color: isSamsung
              ? const Color(0xFF90CAF9).withValues(alpha: 0.6)
              : const Color(0xFF6B7280).withValues(alpha: 0.5),
          width: 2.4,
        ),
      ),
      padding: const EdgeInsets.all(7.5),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF000000),
          borderRadius: BorderRadius.circular(innerRadius),
          border: Border.all(
            color: const Color(0xFF1F2230),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Video or Simulation Screen with bounded overlays
            Positioned.fill(
              child: RepaintBoundary(
                child: _buildScreenContent(isMobile: true),
              ),
            ),

            // Top Camera notch / Dynamic Island
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: isSamsung
                    ? Container(
                        // Samsung punch hole camera
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFF08090E),
                          shape: BoxShape.circle,
                        ),
                      )
                    : Container(
                        // iPhone Dynamic Island pill
                        width: 76,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF000000),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF1C1D26),
                            width: 0.8,
                          ),
                        ),
                      ),
              ),
            ),

            // Subtle 3D Glass Specular Reflection Highlight
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.0 + (_rotY * 2.0), -1.0),
                      end: Alignment(1.0 + (_rotY * 2.0), 1.0),
                      stops: const [0.0, 0.45, 0.5, 1.0],
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.02),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds Laptop frame (MacBook / UltraBook).
  Widget _buildLaptopFrame() {
    return Column(
      children: [
        // Laptop Screen Lid
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF12131C),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF3E4358),
                width: 2.0,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: _buildScreenContent(isMobile: false),
                    ),
                  ),
                  // Webcam dot
                  Positioned(
                    top: 4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D3042),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Laptop Hinge & Base Chassis
        Container(
          width: 480,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF282A3A),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(10),
            ),
            border: Border.all(
              color: const Color(0xFF3E4358),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 60,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF181924),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Screen content rendering video reframed to selected aspect ratio with
  /// distinct framing, badge, and overlays.
  Widget _buildScreenContent({required bool isMobile}) {
    final ratio = widget.aspectRatio;
    final double targetRatio = _calculateContainerRatio(isMobile, ratio);
    final isNative = (isMobile && ratio == VideoAspectRatio.ratio9x16) ||
        (!isMobile && ratio == VideoAspectRatio.ratio16x9);

    Widget coreMedia;
    if (_videoController != null && _isVideoInitialized) {
      coreMedia = SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    } else {
      coreMedia = _buildSimulationArt(isMobile, ratio);
    }

    if (widget.screenContentWrapper != null) {
      coreMedia = widget.screenContentWrapper!(coreMedia);
    }

    final videoViewport = coreMedia;

    // Screen video layer: Native fills the display; reframed aspect ratio letterboxes/pillarboxes cleanly
    Widget screenVideoLayer;
    if (isNative) {
      screenVideoLayer = videoViewport;
    } else {
      screenVideoLayer = Container(
        color: const Color(0xFF07080E),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: targetRatio,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF4B5563).withValues(alpha: 0.6),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: videoViewport,
                ),
              ),
            ),

            // Aspect ratio indicator badge
            Positioned(
              top: isMobile ? 32 : 10,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    ratio.label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFFDDD6FE),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // CRITICAL: The platform block is tied to the DEVICE SIZE, NOT the video size.
    // On laptop, the 16:9 YouTube player block covers the full 16:9 laptop screen every time.
    // On mobile, the vertical Shorts/Reels block covers the full mobile phone screen every time.
    // Changing the video aspect ratio (16:9, 9:16, 1:1, 4:5, 3:2) or resolution does NOT
    // distort, resize, squish, or displace the platform blocks overlay.
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: screenVideoLayer),
        // Overlay content (subtitles, branding, temporary overlays) spans full display,
        // allowing overlays over letterbox / pillarbox black bars (e.g. 1:1, 4:5 ratios).
        if (widget.overlayContent != null)
          Positioned.fill(
            child: RepaintBoundary(
              child: widget.overlayContent!,
            ),
          ),
        if (widget.previewPlatformBlocks)
          Positioned.fill(
            child: isMobile
                ? _buildMobilePlatformBlocksOverlay()
                : _buildLaptopPlatformBlocksOverlay(),
          ),
      ],
    );
  }

  double _calculateContainerRatio(bool isMobile, VideoAspectRatio ratio) {
    if (ratio.value != null) {
      return ratio.value!;
    }
    return isMobile ? (9 / 16) : (16 / 9);
  }

  /// High-fidelity animated simulation when no video file is active.
  Widget _buildSimulationArt(bool isMobile, VideoAspectRatio ratio) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base creator portrait frame for realistic computer vision preview
        Image.asset(
          'assets/images/sample_creator_frame.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF181A28),
                  Color(0xFF0E0F17),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.smart_display_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'LIVE PREVIEW • ${ratio.label}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Color(0xFFC4B5FD),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Spatial 3D Canvas Active',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Mobile Shorts / Reels vertical platform UI overlay.
  Widget _buildMobilePlatformBlocksOverlay() {
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.18),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Safe-Zone: Back Button (Left), Search & 3-Dots (Right)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button on left
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  // Search & 3-Dots on right
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Safe-Zone: Channel Info + Description + Right Action Stack
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Left Column: Channel Avatar, Handle, Subscribe Button, Description, Music
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Channel Name Logo & Subscribe Button Row (ABOVE description)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.0),
                              ),
                              child: const Center(
                                child: Text(
                                  'C',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '@ClipItOfficial',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 4),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Subscribe Button
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Subscribe',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 7),
                      // Video Description snippet
                      const Text(
                        '#viral #shorts Masterpiece created with ClipIt AI...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 4),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Audio Track info
                      Row(
                        children: const [
                          Icon(
                            Icons.music_note_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Original Sound • ClipIt Official',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 4),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right Action Buttons Stack (Like, Dislike, Comment, Bookmark, Share, Audio Disc)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _platformActionItem(Icons.thumb_up_rounded, '142K'),
                    const SizedBox(height: 8),
                    _platformActionItem(Icons.thumb_down_rounded, 'Dislike'),
                    const SizedBox(height: 8),
                    _platformActionItem(Icons.comment_rounded, '1.4K'),
                    const SizedBox(height: 8),
                    _platformActionItem(Icons.bookmark_rounded, 'Save'),
                    const SizedBox(height: 8),
                    _platformActionItem(Icons.share_rounded, 'Share'),
                    const SizedBox(height: 8),
                    // Rotating vinyl / sound disc
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2028),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 1.2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.album_rounded,
                          size: 15,
                          color: Color(0xFFC4B5FD),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// YouTube Desktop video player platform overlay for Laptop frame.
  Widget _buildLaptopPlatformBlocksOverlay() {
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Bar: Video title, Watch Later, Share, 3 dots
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF0000),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'ClipIt Masterclass • Cinematic 4K 60FPS Video Edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 6),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.watch_later_outlined, size: 16, color: Colors.white),
                    SizedBox(width: 10),
                    Icon(Icons.share_outlined, size: 16, color: Colors.white),
                    SizedBox(width: 10),
                    Icon(Icons.more_vert_rounded, size: 16, color: Colors.white),
                  ],
                ),
              ],
            ),

            // Bottom Bar: YouTube Scrubber + Controls Bar
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Red progress bar line
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 120,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0000),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF0000),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Controls Row (Wrapped in responsive scale container to fit any laptop display frame)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Left controls: Play, Next, Volume, Time
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Icon(Icons.skip_next_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Icon(Icons.volume_up_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            '0:04 / 0:12',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      // Channel Logo + Subscribe Pill
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B5CF6),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'C',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'ClipIt Official',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Subscribe',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      // Right controls: Subtitles, Settings, Miniplayer, Fullscreen
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.closed_caption_outlined, size: 15, color: Colors.white),
                          SizedBox(width: 8),
                          Icon(Icons.settings_outlined, size: 15, color: Colors.white),
                          SizedBox(width: 8),
                          Icon(Icons.picture_in_picture_alt_rounded, size: 15, color: Colors.white),
                          SizedBox(width: 8),
                          Icon(Icons.fullscreen_rounded, size: 17, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _platformActionItem(IconData icon, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 4),
            ],
          ),
        ),
      ],
    );
  }
}


/// Interactive Scrubber Bar with smooth hover expand and glow micro-animations.
class _InteractiveScrubberBar extends StatefulWidget {
  const _InteractiveScrubberBar({
    required this.progressFraction,
    required this.onSeek,
  });

  final double progressFraction;
  final ValueChanged<double> onSeek;

  @override
  State<_InteractiveScrubberBar> createState() =>
      _InteractiveScrubberBarState();
}

class _InteractiveScrubberBarState extends State<_InteractiveScrubberBar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              if (barWidth > 0) {
                widget.onSeek(
                  (details.localPosition.dx / barWidth).clamp(0.0, 1.0),
                );
              }
            },
            onHorizontalDragUpdate: (details) {
              if (barWidth > 0) {
                widget.onSeek(
                  (details.localPosition.dx / barWidth).clamp(0.0, 1.0),
                );
              }
            },
            child: Container(
              height: 24,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                height: _isHovered ? 6 : 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: const Color(0xFF262838),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: widget.progressFraction,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(
                                  alpha: _isHovered ? 0.95 : 0.7,
                                ),
                                blurRadius: _isHovered ? 8 : 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
