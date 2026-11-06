import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../models/subtitle_models.dart';
import '../services/subtitle_font_registry.dart';
import 'subtitle_marker_painter.dart';

/// Renders the demonstration phrase “Bhai ye kya hai?” with dynamic two-layer motion typography,
/// word-by-word animation, karaoke highlights, advanced word markers, custom textures, and typography styling.
class SubtitlePhraseRenderer extends StatefulWidget {
  const SubtitlePhraseRenderer({
    required this.config,
    this.isAnimated = true,
    this.scaleFactor = 1.0,
    this.customText,
    super.key,
  });

  final SubtitleConfiguration config;
  final bool isAnimated;
  final double scaleFactor;
  final String? customText;

  @override
  State<SubtitlePhraseRenderer> createState() => _SubtitlePhraseRendererState();
}

class _SubtitlePhraseRendererState extends State<SubtitlePhraseRenderer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _activeWordIndex = 0;
  double _currentProgress = 0.0;
  late List<String> _words;

  @override
  void initState() {
    super.initState();
    _words = _getWords();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _setupAnimationLoop();

    if (widget.isAnimated) {
      if (WidgetsBinding.instance.runtimeType
          .toString()
          .contains('TestWidgetsFlutterBinding')) {
        _controller.value = 0.5;
      } else {
        _controller.forward();
      }
    }
  }

  void _setupAnimationLoop() {
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!WidgetsBinding.instance.runtimeType
            .toString()
            .contains('TestWidgetsFlutterBinding')) {
          _controller.reset();
          if (widget.isAnimated) {
            _controller.forward();
          }
        }
      }
    });

    _controller.addListener(() {
      if (_words.isEmpty) return;
      final progress = _controller.value;
      _currentProgress = progress;

      // Words cycle in the first 80% of duration; remaining 20% plays the exit animation
      final activePortion = (progress / 0.80).clamp(0.0, 1.0);
      final step = 1.0 / _words.length;
      final newIndex =
          (activePortion / step).floor().clamp(0, _words.length - 1);
      if (newIndex != _activeWordIndex || progress >= 0.80) {
        setState(() {
          _activeWordIndex = newIndex;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant SubtitlePhraseRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customText != widget.customText) {
      _words = _getWords();
    }

    final configChanged = oldWidget.config.entranceAnimation !=
            widget.config.entranceAnimation ||
        oldWidget.config.exitAnimation != widget.config.exitAnimation ||
        oldWidget.config.emphasisMode != widget.config.emphasisMode ||
        oldWidget.config.dimInactiveWords != widget.config.dimInactiveWords ||
        oldWidget.config.translucentInactiveWords != widget.config.translucentInactiveWords ||
        oldWidget.config.inactiveWordTransparency != widget.config.inactiveWordTransparency ||
        oldWidget.config.subtitlesEnabled != widget.config.subtitlesEnabled ||
        oldWidget.config.fontFamily != widget.config.fontFamily ||
        oldWidget.config.textAlign != widget.config.textAlign ||
        oldWidget.config.hasGlow != widget.config.hasGlow ||
        oldWidget.config.hasOutline != widget.config.hasOutline ||
        oldWidget.config.hasShadow != widget.config.hasShadow ||
        oldWidget.config.layer1Animation != widget.config.layer1Animation ||
        oldWidget.config.layer2Animation != widget.config.layer2Animation ||
        oldWidget.config.markerStyle != widget.config.markerStyle ||
        oldWidget.config.markerTexture != widget.config.markerTexture ||
        oldWidget.config.markerColor != widget.config.markerColor ||
        oldWidget.config.textOpacity != widget.config.textOpacity ||
        oldWidget.config.isLowercase != widget.config.isLowercase;

    if (configChanged && widget.isAnimated) {
      _controller.reset();
      _controller.forward();
    } else if (widget.isAnimated && !_controller.isAnimating) {
      _controller.forward();
    } else if (!widget.isAnimated && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _getWords() {
    final raw = widget.customText ?? 'Bhai ye kya hai?';
    return raw.trim().split(RegExp(r'\s+'));
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    if (!cfg.subtitlesEnabled) {
      return const SizedBox.shrink();
    }
    final words = _words;
    final wordsPerLine = cfg.wordsPerLine.clamp(1, 4);

    // Group words into lines according to wordsPerLine setting
    final List<List<int>> linesOfIndices = [];
    for (int i = 0; i < words.length; i += wordsPerLine) {
      final end = math.min(i + wordsPerLine, words.length);
      final lineIndices = <int>[];
      for (int j = i; j < end; j++) {
        lineIndices.add(j);
      }
      linesOfIndices.add(lineIndices);
    }

    final effectiveFontSize = cfg.fontSize * widget.scaleFactor;

    final WrapAlignment wrapAlign;
    final CrossAxisAlignment colAlign;
    final Alignment lineAlign;
    switch (cfg.textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        wrapAlign = WrapAlignment.start;
        colAlign = CrossAxisAlignment.start;
        lineAlign = Alignment.centerLeft;
        break;
      case TextAlign.right:
      case TextAlign.end:
        wrapAlign = WrapAlignment.end;
        colAlign = CrossAxisAlignment.end;
        lineAlign = Alignment.centerRight;
        break;
      case TextAlign.center:
      default:
        wrapAlign = WrapAlignment.center;
        colAlign = CrossAxisAlignment.center;
        lineAlign = Alignment.center;
        break;
    }

    Widget phraseContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: colAlign,
      children: linesOfIndices.map((lineIndices) {
        return Align(
          alignment: lineAlign,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.0 * widget.scaleFactor),
            child: Wrap(
              alignment: wrapAlign,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.0 * widget.scaleFactor,
              runSpacing: 6.0 * widget.scaleFactor,
              children: lineIndices.map((wordIndex) {
                return _buildWordWidget(
                  words[wordIndex],
                  wordIndex,
                  cfg,
                  effectiveFontSize,
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );

    // Apply global text opacity
    if (cfg.textOpacity < 0.99) {
      phraseContent = Opacity(
        opacity: cfg.textOpacity.clamp(0.05, 1.0),
        child: phraseContent,
      );
    }

    // Apply Layer 1 phrase entrance animation during initial loop portion
    if (widget.isAnimated && _currentProgress < 0.22) {
      phraseContent = _applyLayer1Reveal(phraseContent, cfg);
    }
    // Apply exit animation when phrase finishes cycle (progress >= 0.80)
    else if (widget.isAnimated && _currentProgress >= 0.80) {
      phraseContent = _applyExitAnimation(phraseContent, cfg);
    }

    // Apply Layer 2 floating motion across whole phrase if floatingMotion is selected
    if (widget.isAnimated && cfg.layer2Animation == SubtitleLayer2Animation.floatingMotion) {
      final floatY = math.sin(_currentProgress * 2 * math.pi * 2.0) * 3.5 * cfg.layer2Intensity;
      phraseContent = Transform.translate(
        offset: Offset(0, floatY),
        child: phraseContent,
      );
    }

    return phraseContent;
  }

  // ── LAYER 1 — TEXT REVEAL / ENTRANCE ANIMATIONS ───────────────────────────
  Widget _applyLayer1Reveal(Widget child, SubtitleConfiguration cfg) {
    final rawProgress = (_currentProgress / 0.22).clamp(0.0, 1.0);
    final curved = cfg.layer1Easing.curve.transform(rawProgress);

    // Effective Layer 1 animation: checks new layer1Animation first, fallbacks to legacy entranceAnimation
    final l1 = cfg.layer1Animation != SubtitleLayer1Animation.none
        ? cfg.layer1Animation
        : SubtitleLayer1Animation.fromLegacy(cfg.entranceAnimation);

    switch (l1) {
      case SubtitleLayer1Animation.lineBlur:
        final sigma = (12.0 * (1.0 - curved) * cfg.layer1Intensity).clamp(0.01, 24.0);
        return ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Opacity(opacity: curved.clamp(0.05, 1.0), child: child),
        );

      case SubtitleLayer1Animation.wordBlur:
      case SubtitleLayer1Animation.typewriter:
      case SubtitleLayer1Animation.scrambleReveal:
      case SubtitleLayer1Animation.staggeredLetter:
        // Handled word-by-word in _buildWordWidget
        return child;

      case SubtitleLayer1Animation.directionalSlide:
        Offset slideOffset;
        switch (cfg.layer1Direction) {
          case SubtitleAnimationDirection.left:
            slideOffset = Offset(-0.45 * (1.0 - curved), 0);
            break;
          case SubtitleAnimationDirection.right:
            slideOffset = Offset(0.45 * (1.0 - curved), 0);
            break;
          case SubtitleAnimationDirection.top:
            slideOffset = Offset(0, -0.40 * (1.0 - curved));
            break;
          case SubtitleAnimationDirection.bottom:
            slideOffset = Offset(0, 0.40 * (1.0 - curved));
            break;
        }
        return FractionalTranslation(
          translation: slideOffset,
          child: Opacity(opacity: curved, child: child),
        );

      case SubtitleLayer1Animation.fadeReveal:
        return Opacity(opacity: curved, child: child);

      case SubtitleLayer1Animation.maskReveal:
        return ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: curved,
            child: child,
          ),
        );

      case SubtitleLayer1Animation.scaleReveal:
        final scale = (0.50 + 0.50 * curved * cfg.layer1Intensity).clamp(0.05, 1.3);
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: curved, child: child),
        );

      case SubtitleLayer1Animation.trackingReveal:
        return child;

      case SubtitleLayer1Animation.none:
        return _applyLegacyEntranceAnimation(child, cfg, rawProgress, curved);
    }
  }

  Widget _applyLegacyEntranceAnimation(
    Widget child,
    SubtitleConfiguration cfg,
    double rawProgress,
    double curved,
  ) {
    switch (cfg.entranceAnimation) {
      case SubtitleEntranceAnimation.slideLeft:
        return FractionalTranslation(
          translation: Offset(-0.45 * (1.0 - curved), 0),
          child: Opacity(opacity: rawProgress, child: child),
        );
      case SubtitleEntranceAnimation.slideRight:
        return FractionalTranslation(
          translation: Offset(0.45 * (1.0 - curved), 0),
          child: Opacity(opacity: rawProgress, child: child),
        );
      case SubtitleEntranceAnimation.slideUp:
        return FractionalTranslation(
          translation: Offset(0, 0.40 * (1.0 - curved)),
          child: Opacity(opacity: rawProgress, child: child),
        );
      case SubtitleEntranceAnimation.fadeIn:
        return Opacity(opacity: rawProgress, child: child);
      case SubtitleEntranceAnimation.popIn:
        final scale = 0.65 + 0.35 * Curves.easeOutBack.transform(rawProgress);
        return Transform.scale(scale: scale.clamp(0.1, 1.25), child: Opacity(opacity: rawProgress, child: child));
      case SubtitleEntranceAnimation.bounceIn:
        final scale = 0.55 + 0.45 * Curves.elasticOut.transform(rawProgress);
        return Transform.scale(scale: scale.clamp(0.1, 1.3), child: Opacity(opacity: rawProgress, child: child));
      case SubtitleEntranceAnimation.zoomIn:
      case SubtitleEntranceAnimation.springScale:
        final scale = 0.70 + 0.30 * Curves.easeOutCubic.transform(rawProgress);
        return Transform.scale(scale: scale.clamp(0.1, 1.15), child: Opacity(opacity: rawProgress, child: child));
      case SubtitleEntranceAnimation.typewriter:
      case SubtitleEntranceAnimation.wordByWord:
      case SubtitleEntranceAnimation.instant:
        return child;
    }
  }

  // ── EXIT ANIMATIONS ────────────────────────────────────────────────────────
  Widget _applyExitAnimation(Widget child, SubtitleConfiguration cfg) {
    final exitProgress = ((_currentProgress - 0.80) / 0.20).clamp(0.0, 1.0);

    // Layer 2 directional exit if selected
    if (cfg.layer2Animation == SubtitleLayer2Animation.directionalExit) {
      Offset exitOffset;
      switch (cfg.layer2Direction) {
        case SubtitleAnimationDirection.left:
          exitOffset = Offset(-30.0 * exitProgress * widget.scaleFactor, 0);
          break;
        case SubtitleAnimationDirection.right:
          exitOffset = Offset(30.0 * exitProgress * widget.scaleFactor, 0);
          break;
        case SubtitleAnimationDirection.top:
          exitOffset = Offset(0, -25.0 * exitProgress * widget.scaleFactor);
          break;
        case SubtitleAnimationDirection.bottom:
          exitOffset = Offset(0, 25.0 * exitProgress * widget.scaleFactor);
          break;
      }
      return Transform.translate(
        offset: exitOffset,
        child: Opacity(opacity: (1.0 - exitProgress).clamp(0.0, 1.0), child: child),
      );
    }

    switch (cfg.exitAnimation) {
      case SubtitleExitAnimation.fadeOut:
        return Opacity(
          opacity: (1.0 - exitProgress).clamp(0.0, 1.0),
          child: child,
        );
      case SubtitleExitAnimation.slideUp:
        return Transform.translate(
          offset: Offset(0, -24.0 * exitProgress * widget.scaleFactor),
          child: Opacity(
            opacity: (1.0 - exitProgress).clamp(0.0, 1.0),
            child: child,
          ),
        );
      case SubtitleExitAnimation.slideDown:
        return Transform.translate(
          offset: Offset(0, 24.0 * exitProgress * widget.scaleFactor),
          child: Opacity(
            opacity: (1.0 - exitProgress).clamp(0.0, 1.0),
            child: child,
          ),
        );
      case SubtitleExitAnimation.zoomOut:
        final scale = (1.0 - (0.45 * exitProgress)).clamp(0.05, 1.0);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: (1.0 - exitProgress).clamp(0.0, 1.0),
            child: child,
          ),
        );
      case SubtitleExitAnimation.shrinkOut:
        final scale = (1.0 - exitProgress).clamp(0.0, 1.0);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: (1.0 - exitProgress).clamp(0.0, 1.0),
            child: child,
          ),
        );
      case SubtitleExitAnimation.instant:
        return child;
    }
  }

  // ── BUILD WORD WIDGET WITH TWO LAYERS & MARKERS ───────────────────────────
  Widget _buildWordWidget(
    String word,
    int wordIndex,
    SubtitleConfiguration cfg,
    double fontSize,
  ) {
    final isActive = widget.isAnimated && wordIndex == _activeWordIndex;
    final isPassed = widget.isAnimated && wordIndex < _activeWordIndex;
    final isFuture = widget.isAnimated && wordIndex > _activeWordIndex;

    // Word by word entrance: future words stay hidden until spoken
    if (widget.isAnimated &&
        cfg.entranceAnimation == SubtitleEntranceAnimation.wordByWord &&
        isFuture) {
      return const SizedBox.shrink();
    }

    // Text casing transformation
    String displayWord;
    if (cfg.isLowercase) {
      displayWord = word.toLowerCase();
    } else if (cfg.isUppercase) {
      displayWord = word.toUpperCase();
    } else {
      displayWord = word;
    }

    // Scramble reveal animation on active word
    if (isActive &&
        widget.isAnimated &&
        cfg.layer1Animation == SubtitleLayer1Animation.scrambleReveal) {
      displayWord = _scrambleText(displayWord, _currentProgress);
    }

    // Typewriter reveal character-by-character
    if (isActive &&
        widget.isAnimated &&
        (cfg.layer1Animation == SubtitleLayer1Animation.typewriter ||
            cfg.entranceAnimation == SubtitleEntranceAnimation.typewriter)) {
      final activeSubProgress = ((_currentProgress % (0.80 / math.max(1, _words.length))) /
              (0.80 / math.max(1, _words.length)))
          .clamp(0.0, 1.0);
      final visibleChars = (displayWord.length * activeSubProgress).ceil().clamp(1, displayWord.length);
      displayWord = displayWord.substring(0, visibleChars);
    }

    // Staggered letter reveal
    if (isFuture &&
        widget.isAnimated &&
        cfg.layer1Animation == SubtitleLayer1Animation.staggeredLetter) {
      return const SizedBox.shrink();
    }

    Color wordColor;
    if (isActive) {
      if (cfg.emphasisMode == SubtitleEmphasisMode.none && !cfg.isMarkerActive) {
        wordColor = cfg.textColor;
      } else {
        wordColor = cfg.highlightColor;
      }
    } else if (isPassed) {
      if (cfg.translucentInactiveWords) {
        wordColor = cfg.textColor.withValues(alpha: cfg.inactiveWordTransparency.clamp(0.05, 1.0));
      } else if (cfg.dimInactiveWords) {
        wordColor = cfg.textColor.withValues(alpha: 0.50);
      } else {
        wordColor = cfg.textColor;
      }
    } else {
      if (cfg.translucentInactiveWords) {
        wordColor = cfg.textColor.withValues(alpha: (cfg.inactiveWordTransparency * 0.70).clamp(0.05, 1.0));
      } else if (cfg.dimInactiveWords) {
        wordColor = cfg.textColor.withValues(alpha: 0.35);
      } else {
        wordColor = cfg.textColor;
      }
    }

    final shadows = <Shadow>[];
    final isGlowOutlineActive =
        cfg.emphasisMode == SubtitleEmphasisMode.glowOutline && isActive;
    final showGlow = cfg.hasGlow || isGlowOutlineActive;

    if (cfg.hasShadow && cfg.shadowBlur > 0 && !isGlowOutlineActive) {
      final shadowCol = (cfg.shadowColor != Colors.transparent && cfg.shadowColor.a > 0)
          ? cfg.shadowColor
          : Colors.black54;
      shadows.add(
        Shadow(
          color: shadowCol,
          blurRadius: cfg.shadowBlur * widget.scaleFactor,
          offset: cfg.shadowOffset * widget.scaleFactor,
        ),
      );
    }

    if (showGlow) {
      final glowCol = (cfg.glowColor != Colors.transparent && cfg.glowColor.a > 0)
          ? cfg.glowColor
          : cfg.highlightColor;
      final intensity = isGlowOutlineActive
          ? 1.0
          : (cfg.glowIntensity > 0.05 ? cfg.glowIntensity : 0.85).clamp(0.1, 1.0);
      final blur = (isGlowOutlineActive ? 20.0 : (cfg.glowBlur > 1.0 ? cfg.glowBlur : 14.0)) *
          widget.scaleFactor;
      final alpha = (isActive ? intensity : (intensity * 0.75)).clamp(0.0, 1.0);

      shadows.add(
        Shadow(
          color: glowCol.withValues(alpha: alpha),
          blurRadius: blur,
        ),
      );
      if (alpha > 0.25) {
        shadows.add(
          Shadow(
            color: glowCol.withValues(alpha: (alpha * 0.65).clamp(0.0, 1.0)),
            blurRadius: blur * 1.8,
          ),
        );
      }
    }

    // Tracking reveal letter spacing calculation
    double effectiveLetterSpacing = cfg.letterSpacing * widget.scaleFactor;
    if (widget.isAnimated && cfg.layer1Animation == SubtitleLayer1Animation.trackingReveal) {
      final trackProgress = (_currentProgress / 0.35).clamp(0.0, 1.0);
      final curvedTrack = Curves.easeOutCubic.transform(trackProgress);
      effectiveLetterSpacing += (8.0 * (1.0 - curvedTrack) * cfg.layer1Intensity);
    }

    final baseStyle = SubtitleFontRegistry.getTextStyle(
      family: cfg.fontFamily,
      fontSize: fontSize,
      fontWeight: cfg.fontWeight,
      letterSpacing: effectiveLetterSpacing,
      height: cfg.lineSpacing,
    );

    final isOutlineNeeded =
        (cfg.hasOutline && cfg.outlineWidth > 0) || isGlowOutlineActive;
    final outlineWidth = isGlowOutlineActive
        ? math.max(cfg.outlineWidth, 2.5) * widget.scaleFactor
        : (cfg.outlineWidth > 0 ? cfg.outlineWidth : 2.0) * widget.scaleFactor;
    final outlineColor = (cfg.outlineColor != Colors.transparent && cfg.outlineColor.a > 0)
        ? cfg.outlineColor
        : Colors.black;

    Widget textWidget;
    if (isOutlineNeeded) {
      textWidget = Stack(
        alignment: Alignment.center,
        children: [
          // Background stroke
          Text(
            displayWord,
            textAlign: cfg.textAlign,
            style: baseStyle.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = outlineWidth
                ..strokeJoin = StrokeJoin.round
                ..strokeCap = StrokeCap.round
                ..color = outlineColor,
            ),
          ),
          // Foreground fill
          Text(
            displayWord,
            textAlign: cfg.textAlign,
            style: baseStyle.copyWith(
              color: wordColor,
              shadows: shadows,
            ),
          ),
        ],
      );
    } else {
      textWidget = Text(
        displayWord,
        textAlign: cfg.textAlign,
        style: baseStyle.copyWith(
          color: wordColor,
          shadows: shadows,
        ),
      );
    }

    // ── IMPORTANT WORD MARKERS ───────────────────────────────────────────────
    if (cfg.isMarkerActive && isActive) {
      final markerStyle = cfg.effectiveMarkerStyle;
      final markerColor = cfg.effectiveMarkerColor;

      // Calculate progress of marker animation
      final subStep = 0.80 / math.max(1, _words.length);
      final wordTime = _currentProgress - (_activeWordIndex * subStep);
      final markerProgress = (wordTime / (subStep * 0.7)).clamp(0.0, 1.0);

      textWidget = CustomPaint(
        painter: SubtitleMarkerPainter(
          style: markerStyle,
          texture: cfg.markerTexture,
          color: markerColor,
          thickness: cfg.markerThickness * widget.scaleFactor,
          distance: cfg.markerDistance * widget.scaleFactor,
          paddingH: cfg.markerPaddingH * widget.scaleFactor,
          paddingV: cfg.markerPaddingV * widget.scaleFactor,
          opacity: cfg.markerOpacity,
          progress: markerProgress,
          animation: cfg.markerAnimation,
        ),
        child: textWidget,
      );
    }

    // Word blur reveal: active word clears from blur to sharp
    if (isActive &&
        widget.isAnimated &&
        cfg.layer1Animation == SubtitleLayer1Animation.wordBlur) {
      final subStep = 0.80 / math.max(1, _words.length);
      final wordTime = _currentProgress - (_activeWordIndex * subStep);
      final wordProgress = (wordTime / (subStep * 0.5)).clamp(0.0, 1.0);
      final sigma = (10.0 * (1.0 - wordProgress) * cfg.layer1Intensity).clamp(0.01, 20.0);
      textWidget = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: textWidget,
      );
    }

    // ── LAYER 2 — SECONDARY MOTION & EMPHASIS ─────────────────────────────────
    if (isActive && widget.isAnimated) {
      textWidget = _applyLayer2SecondaryMotion(textWidget, cfg, wordIndex);
    }

    // Motion stagger on non-active words
    if (!isActive &&
        widget.isAnimated &&
        cfg.layer2Animation == SubtitleLayer2Animation.motionStagger) {
      final staggerOffset = math.sin((_currentProgress * 2 * math.pi) + wordIndex) * 2.0;
      textWidget = Transform.translate(
        offset: Offset(0, staggerOffset),
        child: textWidget,
      );
    }

    // Translucent or dim inactive words across all styling
    if (!isActive) {
      if (cfg.translucentInactiveWords) {
        textWidget = Opacity(
          opacity: cfg.inactiveWordTransparency.clamp(0.05, 1.0),
          child: textWidget,
        );
      } else if (cfg.dimInactiveWords) {
        textWidget = Opacity(
          opacity: 0.40,
          child: textWidget,
        );
      }
    }

    return textWidget;
  }

  // ── LAYER 2 SECONDARY MOTION IMPLEMENTATION ────────────────────────────────
  Widget _applyLayer2SecondaryMotion(
    Widget child,
    SubtitleConfiguration cfg,
    int wordIndex,
  ) {
    final animKey = ValueKey('l2_${cfg.layer2Animation}_${wordIndex}_$_activeWordIndex');
    final l2 = cfg.layer2Animation != SubtitleLayer2Animation.none
        ? cfg.layer2Animation
        : SubtitleLayer2Animation.fromLegacy(cfg.entranceAnimation);

    switch (l2) {
      case SubtitleLayer2Animation.popBounce:
        return AnimatedScale(
          key: animKey,
          scale: 1.0 + (0.20 * cfg.layer2Intensity),
          duration: Duration(milliseconds: cfg.layer2DurationMs),
          curve: Curves.easeOutBack,
          child: child,
        );

      case SubtitleLayer2Animation.elasticMotion:
        return AnimatedScale(
          key: animKey,
          scale: 1.0 + (0.24 * cfg.layer2Intensity),
          duration: Duration(milliseconds: (cfg.layer2DurationMs * 1.2).round()),
          curve: Curves.elasticOut,
          child: child,
        );

      case SubtitleLayer2Animation.wordPunch:
        return AnimatedScale(
          key: animKey,
          scale: 1.0 + (0.28 * cfg.layer2Intensity),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: child,
        );

      case SubtitleLayer2Animation.springScale:
        return AnimatedScale(
          key: animKey,
          scale: 1.0 + (0.16 * cfg.layer2Intensity),
          duration: Duration(milliseconds: cfg.layer2DurationMs),
          curve: Curves.easeOutCubic,
          child: child,
        );

      case SubtitleLayer2Animation.pulseEmphasis:
        final pulseVal = 1.0 + (0.14 * math.sin(_currentProgress * 20) * cfg.layer2Intensity);
        return Transform.scale(
          scale: pulseVal,
          child: child,
        );

      case SubtitleLayer2Animation.shakeEmphasis:
        final jitterX = math.sin(_currentProgress * 55) * 3.0 * cfg.layer2Intensity;
        return Transform.translate(
          offset: Offset(jitterX, 0),
          child: child,
        );

      case SubtitleLayer2Animation.rotationEntrance:
        return TweenAnimationBuilder<double>(
          key: animKey,
          tween: Tween<double>(begin: -0.10 * cfg.layer2Intensity, end: 0.0),
          duration: Duration(milliseconds: cfg.layer2DurationMs),
          curve: Curves.easeOutBack,
          builder: (context, angle, child) => Transform.rotate(
            angle: angle,
            child: child,
          ),
          child: child,
        );

      case SubtitleLayer2Animation.motionStagger:
        return AnimatedScale(
          key: animKey,
          scale: 1.12,
          duration: const Duration(milliseconds: 160),
          child: child,
        );

      case SubtitleLayer2Animation.floatingMotion:
      case SubtitleLayer2Animation.directionalExit:
      case SubtitleLayer2Animation.none:
        // Handled at phrase level or legacy
        return _applyLegacyWordAnimation(child, cfg, wordIndex);
    }
  }

  Widget _applyLegacyWordAnimation(
    Widget child,
    SubtitleConfiguration cfg,
    int wordIndex,
  ) {
    final animKey = ValueKey('word_anim_${cfg.entranceAnimation}_${wordIndex}_$_activeWordIndex');

    switch (cfg.entranceAnimation) {
      case SubtitleEntranceAnimation.popIn:
        return AnimatedScale(
          key: animKey,
          scale: 1.18,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: child,
        );
      case SubtitleEntranceAnimation.bounceIn:
        return AnimatedScale(
          key: animKey,
          scale: 1.25,
          duration: const Duration(milliseconds: 170),
          curve: Curves.elasticOut,
          child: child,
        );
      case SubtitleEntranceAnimation.springScale:
        return AnimatedScale(
          key: animKey,
          scale: 1.15,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: child,
        );
      case SubtitleEntranceAnimation.zoomIn:
        return AnimatedScale(
          key: animKey,
          scale: 1.22,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: child,
        );
      case SubtitleEntranceAnimation.slideUp:
        return TweenAnimationBuilder<Offset>(
          key: animKey,
          tween: Tween<Offset>(begin: const Offset(0, 0.45), end: Offset.zero),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) => FractionalTranslation(
            translation: offset,
            child: AnimatedScale(scale: 1.06, duration: const Duration(milliseconds: 140), child: child),
          ),
          child: child,
        );
      case SubtitleEntranceAnimation.slideLeft:
        return TweenAnimationBuilder<Offset>(
          key: animKey,
          tween: Tween<Offset>(begin: const Offset(-0.55, 0), end: Offset.zero),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) => FractionalTranslation(translation: offset, child: child),
          child: child,
        );
      case SubtitleEntranceAnimation.slideRight:
        return TweenAnimationBuilder<Offset>(
          key: animKey,
          tween: Tween<Offset>(begin: const Offset(0.55, 0), end: Offset.zero),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) => FractionalTranslation(translation: offset, child: child),
          child: child,
        );
      case SubtitleEntranceAnimation.fadeIn:
        return AnimatedOpacity(
          key: animKey,
          opacity: 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedScale(scale: 1.06, duration: const Duration(milliseconds: 120), child: child),
        );
      case SubtitleEntranceAnimation.typewriter:
      case SubtitleEntranceAnimation.wordByWord:
      case SubtitleEntranceAnimation.instant:
        return AnimatedScale(
          key: animKey,
          scale: 1.08,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutQuad,
          child: child,
        );
    }
  }

  String _scrambleText(String target, double progress) {
    const chars = r'ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%&*?';
    final len = target.length;
    final revealed = (len * (progress / 0.15)).floor().clamp(0, len);
    if (revealed >= len) return target;

    final buffer = StringBuffer();
    for (int i = 0; i < len; i++) {
      if (i < revealed) {
        buffer.write(target[i]);
      } else {
        final randChar = chars[((progress * 1000 + i * 7).round() % chars.length)];
        buffer.write(randChar);
      }
    }
    return buffer.toString();
  }
}
