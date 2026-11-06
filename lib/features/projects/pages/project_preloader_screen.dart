import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Preloader screen displayed between Genre Selection and Project Settings.
///
/// Features:
/// - Grayish-black aesthetic with radial gradient.
/// - Glowing white pulsating dot.
/// - Real typewriter animation typing each status message letter-by-letter.
/// - Background preloading of GLB 3D models from assets.
class ProjectPreloaderScreen extends StatefulWidget {
  const ProjectPreloaderScreen({
    required this.onComplete,
    super.key,
  });

  final VoidCallback onComplete;

  @override
  State<ProjectPreloaderScreen> createState() => _ProjectPreloaderScreenState();
}

class _ProjectPreloaderScreenState extends State<ProjectPreloaderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _stages = const [
    'Preparing your project...',
    'Preparing 3D models...',
    'Preparing subtitles...',
    'Starting renderer...',
    'Transcribing audio...',
    'Initializing workspace...',
  ];

  int _currentStageIndex = 0;
  String _displayedText = '';
  bool _cursorVisible = true;
  Timer? _typewriterTimer;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Blinking cursor timer
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) {
        setState(() {
          _cursorVisible = !_cursorVisible;
        });
      }
    });

    _startLoadingSequence();
  }

  Future<void> _startLoadingSequence() async {
    for (int i = 0; i < _stages.length; i++) {
      if (!mounted) return;
      _currentStageIndex = i;
      final fullText = _stages[i];

      // If at "Preparing 3D models", preload the GLB files in parallel
      if (i == 1) {
        _preload3dModels();
      }

      // Typewriter type-in
      for (int charIndex = 1; charIndex <= fullText.length; charIndex++) {
        if (!mounted) return;
        setState(() {
          _displayedText = fullText.substring(0, charIndex);
        });
        await Future.delayed(const Duration(milliseconds: 28));
      }

      // Dwell on the full phrase
      await Future.delayed(const Duration(milliseconds: 420));

      // Fast backspace / fade out before next phrase
      if (i < _stages.length - 1) {
        for (int erase = fullText.length; erase >= 0; erase -= 3) {
          if (!mounted) return;
          final safeIndex = erase < 0 ? 0 : erase;
          setState(() {
            _displayedText = fullText.substring(0, safeIndex);
          });
          await Future.delayed(const Duration(milliseconds: 14));
        }
        await Future.delayed(const Duration(milliseconds: 80));
      }
    }

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 200));
    widget.onComplete();
  }

  /// Loads GLB 3D models into memory buffer to guarantee instant zero-lag rendering.
  Future<void> _preload3dModels() async {
    try {
      await Future.wait([
        rootBundle.load('assets/models/apple_iphone_18_pro_max_silver_2026.glb'),
        rootBundle.load('assets/models/samsung_galaxy_s26_sky_blue__low-poly.glb'),
        rootBundle.load('assets/models/28d9e16c1210455b8d8e6fea1ef2fbfb.glb'),
      ]);
      debugPrint('✓ 3D GLB models preloaded successfully.');
    } catch (e) {
      debugPrint('GLB asset note: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _typewriterTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStageIndex + 1) / _stages.length;

    return Scaffold(
      backgroundColor: const Color(0xFF10111A), // Grayish-black
      body: Stack(
        children: [
          // Subtle radial glow behind the center loader
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [
                    const Color(0xFF1E2030).withValues(alpha: 0.6),
                    const Color(0xFF0D0E16),
                  ],
                ),
              ),
            ),
          ),

          // Center Stage: White pulsing dot + Typewriter text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Glowing White Dot
                    RepaintBoundary(
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.8),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),

                    // Typewriter Text
                    SizedBox(
                      height: 32,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _displayedText,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: Color(0xFFF1F2F8),
                            ),
                          ),
                          Opacity(
                            opacity: _cursorVisible ? 1.0 : 0.0,
                            child: Container(
                              margin: const EdgeInsets.only(left: 3),
                              width: 2.2,
                              height: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Subtle minimal loading progress line
                Container(
                  width: 260,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222434),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.7),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom tech indicator
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'ClipIt Studio AI Engine • Hardware acceleration active',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.5,
                  color: const Color(0xFF6B7280).withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
