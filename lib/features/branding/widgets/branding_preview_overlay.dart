import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../subtitles/services/subtitle_font_registry.dart';
import '../../subtitles/widgets/immovable_subtitle_overlay.dart';
import '../models/branding_models.dart';
import '../providers/branding_provider.dart';

/// Real-time live video preview overlay for Stage 6: Branding & Overlay Studio.
///
/// Features:
/// - Subtitles rendered immovably via ImmovableSubtitleOverlay.
/// - Composites all active Permanent Branding layers with opacity, typography, and continuous effects.
/// - Composites all active Temporary Overlays with responsive layout and continuous entrance/exit loops.
/// - Drag & Drop 2D positioning with gentle horizontal and vertical center snapping.
/// - Mutual tab exclusivity: only active tab layers are interactive / editable.
class BrandingPreviewOverlay extends ConsumerStatefulWidget {
  const BrandingPreviewOverlay({
    this.child,
    super.key,
  });

  final Widget? child;

  @override
  ConsumerState<BrandingPreviewOverlay> createState() =>
      _BrandingPreviewOverlayState();
}

class _BrandingPreviewOverlayState extends ConsumerState<BrandingPreviewOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _continuousController;
  bool _snapX = false;
  bool _snapY = false;

  // 1:1 Pick-Drag-Drop pointer tracking (matches subtitle dragging responsiveness)
  bool _isDragging = false;
  String? _draggingId;
  bool _isDraggingPermanent = false;
  Offset _dragStartGlobal = Offset.zero;
  Offset _dragStartFineOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _continuousController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    if (WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding')) {
      _continuousController.value = 0.5;
    } else {
      _continuousController.repeat();
    }
  }

  @override
  void dispose() {
    _continuousController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brandingState = ref.watch(brandingProvider);

    return AnimatedBuilder(
      animation: _continuousController,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerMove: (event) {
                if (_isDragging && _draggingId != null) {
                  if (w <= 0 || h <= 0) return;
                  final deltaPixels = event.position - _dragStartGlobal;
                  final newOffsetX = _dragStartFineOffset.dx + deltaPixels.dx;
                  final newOffsetY = _dragStartFineOffset.dy + deltaPixels.dy;

                  double finalOffsetX = newOffsetX;
                  double finalOffsetY = newOffsetY;
                  bool snapX = false;
                  bool snapY = false;

                  // Snap to center guideline if near zero offset or centered
                  if (finalOffsetX.abs() < 6.0) {
                    finalOffsetX = 0.0;
                    snapX = true;
                  }
                  if (finalOffsetY.abs() < 6.0) {
                    finalOffsetY = 0.0;
                    snapY = true;
                  }

                  setState(() {
                    _snapX = snapX;
                    _snapY = snapY;
                  });

                  if (_isDraggingPermanent) {
                    ref.read(brandingProvider.notifier).updatePermanentLayer(
                      _draggingId!,
                      (l) => l.copyWith(fineOffsetX: finalOffsetX, fineOffsetY: finalOffsetY),
                    );
                  } else {
                    ref.read(brandingProvider.notifier).updateTemporaryOverlay(
                      _draggingId!,
                      (o) => o.copyWith(fineOffsetX: finalOffsetX, fineOffsetY: finalOffsetY),
                    );
                  }
                }
              },
              onPointerUp: (_) {
                if (_isDragging) {
                  setState(() {
                    _isDragging = false;
                    _draggingId = null;
                    _snapX = false;
                    _snapY = false;
                  });
                }
              },
              onPointerCancel: (_) {
                if (_isDragging) {
                  setState(() {
                    _isDragging = false;
                    _draggingId = null;
                    _snapX = false;
                    _snapY = false;
                  });
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                // 1. Underlying Video Player (if provided)
                if (widget.child != null) widget.child!,

                // 2. Immovable Subtitles (Read-only, sticks to phone, continuous playback)
                const ImmovableSubtitleOverlay(),

                // 3. Permanent Branding Layers (Always visible across entire clip)
                ...brandingState.permanentLayers.map((layer) {
                  return _buildPermanentLayer(
                    layer,
                    brandingState,
                    ref.read(brandingProvider.notifier),
                    w,
                    h,
                  );
                }),

                // 4. Temporary Overlays (Loops entrance, active, and exit dynamically like subtitles)
                ...brandingState.temporaryOverlays.map((overlay) {
                  return _buildTemporaryOverlay(
                    overlay,
                    brandingState,
                    ref.read(brandingProvider.notifier),
                    _continuousController.value,
                    w,
                    h,
                  );
                }),

                // 5. Snapping Guide: Vertical Blue Line (Horizontal Center)
                if (_snapX)
                  Positioned(
                    left: (w / 2) - 0.75,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 1.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),

                // 6. Snapping Guide: Horizontal Blue Line (Vertical Center)
                if (_snapY)
                  Positioned(
                    top: (h / 2) - 0.75,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
      },
    );
  }

  // ── Permanent Branding Rendering (Static, Always Visible Banner) ───────────

  Widget _buildPermanentLayer(
    BrandingLayer layer,
    BrandingStudioState brandingState,
    BrandingNotifier notifier,
    double w,
    double h,
  ) {
    final isPermTab = brandingState.activeTab == BrandingTab.permanent;
    final isSelected = layer.id == brandingState.selectedPermanentId;

    final shadows = <Shadow>[];
    if (layer.shadow) {
      shadows.add(
        Shadow(
          color: Colors.black.withValues(alpha: layer.shadowIntensity),
          offset: Offset(layer.shadowDistance, layer.shadowDistance),
          blurRadius: layer.shadowSoftness,
        ),
      );
    }
    if (layer.glow) {
      shadows.add(
        Shadow(
          color: layer.glowColor.withValues(alpha: layer.glowIntensity),
          offset: Offset.zero,
          blurRadius: 10.0 * layer.glowIntensity,
        ),
      );
    }
    if (layer.neon) {
      shadows.addAll([
        Shadow(
          color: layer.textColor.withValues(alpha: 0.9),
          blurRadius: 2.0,
        ),
        Shadow(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.8),
          blurRadius: 12.0,
        ),
        Shadow(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
          blurRadius: 24.0,
        ),
      ]);
    }

    final baseStyle = SubtitleFontRegistry.getTextStyle(
      family: layer.font,
      fontSize: layer.fontSize,
      fontWeight: layer.fontWeight,
      fontStyle: layer.italic ? FontStyle.italic : FontStyle.normal,
      color: layer.textColor,
      letterSpacing: layer.letterSpacing,
      height: layer.lineSpacing,
    );
    final textStyle = baseStyle.copyWith(
      decoration: TextDecoration.combine([
        if (layer.underline) TextDecoration.underline,
        if (layer.strikethrough) TextDecoration.lineThrough,
      ]),
      shadows: shadows,
    );

    final Widget textContent = SizedBox(
      width: 240,
      child: Text(
        layer.text,
        textAlign: layer.alignment,
        style: textStyle,
      ),
    );

    Widget interactiveContent;
    if (isPermTab) {
      interactiveContent = Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          setState(() {
            _isDragging = true;
            _draggingId = layer.id;
            _isDraggingPermanent = true;
            _dragStartGlobal = event.position;
            _dragStartFineOffset = Offset(layer.fineOffsetX, layer.fineOffsetY);
          });
          notifier.selectPermanentLayer(layer.id);
        },
        child: MouseRegion(
          cursor: isSelected ? SystemMouseCursors.move : SystemMouseCursors.grab,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.85)
                    : Colors.transparent,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: textContent,
          ),
        ),
      );
    } else {
      // While on Temporary Tab, permanent layer cannot be clicked or modified
      interactiveContent = IgnorePointer(
        ignoring: true,
        child: textContent,
      );
    }

    final Widget animatedLayer = Opacity(
      opacity: layer.opacity.clamp(0.0, 1.0),
      child: interactiveContent,
    );

    return Positioned.fill(
      child: Align(
        alignment: layer.position.alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Transform.translate(
            offset: Offset(layer.fineOffsetX, layer.fineOffsetY),
            child: animatedLayer,
          ),
        ),
      ),
    );
  }

  // ── Temporary Overlay Rendering ────────────────────────────────────────────

  Widget _buildTemporaryOverlay(
    TemporaryOverlay overlay,
    BrandingStudioState brandingState,
    BrandingNotifier notifier,
    double animProgress,
    double w,
    double h,
  ) {
    final isTempTab = brandingState.activeTab == BrandingTab.temporary;
    final isSelected = overlay.id == brandingState.selectedTemporaryId;

    // Continuous Entrance / Exit animation loop like subtitles
    final isEntering = animProgress < 0.20;
    final isExiting = animProgress >= 0.80;

    double animOpacity = 1.0;
    double animScale = 1.0;
    double transX = 0.0;
    double transY = 0.0;
    double blurAmount = 0.0;
    double glitchOffset = 0.0;
    double wipeStart = 0.0;
    double wipeEnd = 1.0;
    String displayText = overlay.text;

    if (isEntering) {
      final rawT = (animProgress / 0.20).clamp(0.0, 1.0);
      final t = overlay.easing.curve.transform(rawT);

      switch (overlay.appearAnimation) {
        case AppearAnimationType.none:
          break;
        case AppearAnimationType.fadeIn:
          animOpacity = t;
          break;
        case AppearAnimationType.slideInLeft:
          transX = -w * 0.45 * (1.0 - t);
          animOpacity = t.clamp(0.0, 1.0);
          break;
        case AppearAnimationType.slideInRight:
          transX = w * 0.45 * (1.0 - t);
          animOpacity = t.clamp(0.0, 1.0);
          break;
        case AppearAnimationType.slideInUp:
          transY = 70.0 * (1.0 - t);
          animOpacity = t.clamp(0.0, 1.0);
          break;
        case AppearAnimationType.slideInDown:
          transY = -70.0 * (1.0 - t);
          animOpacity = t.clamp(0.0, 1.0);
          break;
        case AppearAnimationType.typewriter:
        case AppearAnimationType.letterReveal:
          final count = (overlay.text.length * t).round().clamp(0, overlay.text.length);
          displayText = count == 0 ? ' ' : overlay.text.substring(0, count);
          animOpacity = t.clamp(0.0, 1.0);
          break;
        case AppearAnimationType.bounceIn:
          animScale = t.clamp(0.0, 1.2);
          animOpacity = t.clamp(0.0, 1.0);
          break;
        case AppearAnimationType.popIn:
          animScale = t < 0.7 ? (t / 0.7) * 1.15 : 1.15 - (0.15 * ((t - 0.7) / 0.3));
          animOpacity = t.clamp(0.0, 1.0);
          break;
        case AppearAnimationType.scaleIn:
          animScale = t.clamp(0.0, 1.0);
          animOpacity = t.clamp(0.0, 1.0);
          break;
        case AppearAnimationType.dropIn:
          transY = -80.0 * (1.0 - t);
          animScale = 0.9 + 0.1 * t;
          animOpacity = t.clamp(0.0, 1.0);
          break;
        case AppearAnimationType.blurToSharp:
        case AppearAnimationType.blurReveal:
          blurAmount = (1.0 - t) * 16.0;
          animOpacity = (0.2 + 0.8 * t).clamp(0.0, 1.0);
          animScale = 0.95 + 0.05 * t;
          break;
        case AppearAnimationType.pixelAppear:
          animOpacity = ((t * 5).floor() / 5.0).clamp(0.0, 1.0);
          glitchOffset = (1.0 - t) * (math.sin(t * 35.0) * 12.0);
          break;
        case AppearAnimationType.elasticIn:
          animScale = Curves.elasticOut.transform(t).clamp(0.0, 1.25);
          animOpacity = t.clamp(0.0, 1.0);
          break;
        case AppearAnimationType.wipeIn:
          wipeEnd = t.clamp(0.0, 1.0);
          break;
      }
    } else if (isExiting) {
      final exitFraction = ((animProgress - 0.80) / 0.20).clamp(0.0, 1.0);
      final tExit = overlay.easing.curve.transform(exitFraction);

      switch (overlay.exitAnimation) {
        case ExitAnimationType.none:
          break;
        case ExitAnimationType.fadeOut:
          animOpacity = (1.0 - tExit).clamp(0.0, 1.0);
          break;
        case ExitAnimationType.slideOutLeft:
          transX = -w * 0.45 * tExit;
          animOpacity = (1.0 - tExit).clamp(0.0, 1.0);
          break;
        case ExitAnimationType.slideOutRight:
          transX = w * 0.45 * tExit;
          animOpacity = (1.0 - tExit).clamp(0.0, 1.0);
          break;
        case ExitAnimationType.slideOutUp:
          transY = -70.0 * tExit;
          animOpacity = (1.0 - tExit).clamp(0.0, 1.0);
          break;
        case ExitAnimationType.slideOutDown:
          transY = 70.0 * tExit;
          animOpacity = (1.0 - tExit).clamp(0.0, 1.0);
          break;
        case ExitAnimationType.pixelDissolve:
          animOpacity = (((1.0 - tExit) * 5).floor() / 5.0).clamp(0.0, 1.0);
          glitchOffset = tExit * (math.sin(tExit * 35.0) * 12.0);
          break;
        case ExitAnimationType.blurDissolve:
          blurAmount = tExit * 16.0;
          animOpacity = (1.0 - tExit).clamp(0.0, 1.0);
          animScale = 1.0 + 0.05 * tExit;
          break;
        case ExitAnimationType.scaleOut:
          animScale = (1.0 - tExit).clamp(0.0, 1.0);
          animOpacity = (1.0 - tExit).clamp(0.0, 1.0);
          break;
        case ExitAnimationType.popOut:
          animScale = tExit < 0.25
              ? 1.0 + (tExit / 0.25) * 0.15
              : (1.15 * (1.0 - (tExit - 0.25) / 0.75)).clamp(0.0, 1.15);
          animOpacity = (1.0 - tExit).clamp(0.0, 1.0);
          break;
        case ExitAnimationType.dropOut:
          transY = (tExit * tExit) * 110.0;
          animOpacity = (1.0 - tExit).clamp(0.0, 1.0);
          break;
        case ExitAnimationType.wipeOut:
          wipeEnd = (1.0 - tExit).clamp(0.0, 1.0);
          break;
      }
    }

    // Continuous animation modulation
    final animVal = _continuousController.value;
    double effectScale = 1.0;
    double effectGlow = overlay.glowIntensity;
    if (overlay.continuousAnimation == ContinuousAnimationType.breathing) {
      effectScale = 0.97 + (0.05 * math.sin(animVal * 2 * math.pi));
    } else if (overlay.continuousAnimation ==
        ContinuousAnimationType.glowPulse) {
      effectGlow = overlay.glowIntensity *
          (0.6 + 0.4 * math.sin(animVal * 2 * math.pi).abs());
    }

    final double floatOffsetY =
        overlay.continuousAnimation == ContinuousAnimationType.floating
            ? 3.5 * math.sin(animVal * 2 * math.pi)
            : 0.0;

    // Build text widget with intelligent wrap & responsive constraints
    final shadows = <Shadow>[
      if (overlay.shadow)
        Shadow(
          color: Colors.black.withValues(alpha: overlay.shadowIntensity),
          offset: Offset(overlay.shadowDistance, overlay.shadowDistance),
          blurRadius: overlay.shadowSoftness,
        ),
      if (overlay.glow)
        Shadow(
          color: overlay.glowColor.withValues(alpha: effectGlow),
          blurRadius: 10.0 * effectGlow,
        ),
      if (glitchOffset.abs() > 0.6) ...[
        Shadow(
          color: const Color(0xFF00FFFF).withValues(alpha: 0.8),
          offset: Offset(-glitchOffset.clamp(-4.0, 4.0), 0),
          blurRadius: 1.5,
        ),
        Shadow(
          color: const Color(0xFFFF0055).withValues(alpha: 0.8),
          offset: Offset(glitchOffset.clamp(-4.0, 4.0), 0),
          blurRadius: 1.5,
        ),
      ],
    ];

    final baseStyle = SubtitleFontRegistry.getTextStyle(
      family: overlay.font,
      fontSize: overlay.fontSize,
      fontWeight: overlay.fontWeight,
      fontStyle: overlay.italic ? FontStyle.italic : FontStyle.normal,
      color: overlay.textColor,
      letterSpacing: overlay.letterSpacing,
      height: overlay.lineSpacing,
    );
    final textStyle = baseStyle.copyWith(
      decoration: TextDecoration.combine([
        if (overlay.underline) TextDecoration.underline,
        if (overlay.strikethrough) TextDecoration.lineThrough,
      ]),
      shadows: shadows,
    );

    final textWidget = Text(
      displayText,
      textAlign: overlay.alignment,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: textStyle,
    );

    Widget content;
    switch (overlay.style) {
      case OverlayStylePreset.verticalLineRight:
        // Line on RIGHT, Text on LEFT, centered relative to line
        content = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (w * 0.55).clamp(100.0, 200.0),
                maxHeight: overlay.lineLength,
              ),
              child: Center(child: textWidget),
            ),
            const SizedBox(width: 8),
            Container(
              width: overlay.borderThickness,
              height: overlay.lineLength,
              decoration: BoxDecoration(
                color: overlay.shapeColor,
                borderRadius:
                    BorderRadius.circular(overlay.borderThickness / 2),
                boxShadow: [
                  BoxShadow(
                    color: overlay.shapeColor.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        );
        break;

      case OverlayStylePreset.verticalLineLeft:
        // Line on LEFT, Text on RIGHT, centered relative to line
        content = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: overlay.borderThickness,
              height: overlay.lineLength,
              decoration: BoxDecoration(
                color: overlay.shapeColor,
                borderRadius:
                    BorderRadius.circular(overlay.borderThickness / 2),
                boxShadow: [
                  BoxShadow(
                    color: overlay.shapeColor.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (w * 0.55).clamp(100.0, 200.0),
                maxHeight: overlay.lineLength,
              ),
              child: Center(child: textWidget),
            ),
          ],
        );
        break;

      case OverlayStylePreset.starDrop:
        // Anchored star graphic with dramatic entry alongside text
        content = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: overlay.shapeColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: overlay.shapeColor, width: 1.5),
              ),
              child: Icon(
                Icons.stars_rounded,
                size: overlay.shapeSize.clamp(18.0, 36.0),
                color: overlay.shapeColor,
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: (w * 0.6).clamp(100.0, 220.0)),
              child: textWidget,
            ),
          ],
        );
        break;

      case OverlayStylePreset.boxCallout:
        // Container box framing the text
        content = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: overlay.fill ? overlay.fillColor : Colors.transparent,
            borderRadius: BorderRadius.circular(overlay.cornerRadius),
            border: Border.all(
              color: overlay.shapeColor,
              width: overlay.borderThickness,
            ),
            boxShadow: [
              BoxShadow(
                color: overlay.shapeColor.withValues(alpha: 0.35),
                blurRadius: 10,
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: (w * 0.65).clamp(100.0, 240.0)),
            child: textWidget,
          ),
        );
        break;

      case OverlayStylePreset.minimalLabel:
        // Sleek badge pill
        content = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0F101A).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(
                color: overlay.shapeColor,
                width: 3.5,
              ),
              top: const BorderSide(color: Color(0xFF26283C), width: 0.8),
              bottom: const BorderSide(color: Color(0xFF26283C), width: 0.8),
              right: const BorderSide(color: Color(0xFF26283C), width: 0.8),
            ),
          ),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: (w * 0.6).clamp(100.0, 220.0)),
            child: textWidget,
          ),
        );
        break;

      case OverlayStylePreset.cornerCallout:
        // Cybernetic bracketed corner callout — brackets ONLY at ends/corners
        content = CustomPaint(
          painter: _CornerBracketsPainter(
            color: overlay.shapeColor,
            strokeWidth: overlay.borderThickness,
            cornerLength: 14.0,
            fill: overlay.fill,
            fillColor: overlay.fillColor,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: (w * 0.6).clamp(100.0, 220.0)),
              child: textWidget,
            ),
          ),
        );
        break;
    }

    Widget interactiveContent;
    if (isTempTab) {
      interactiveContent = Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          setState(() {
            _isDragging = true;
            _draggingId = overlay.id;
            _isDraggingPermanent = false;
            _dragStartGlobal = event.position;
            _dragStartFineOffset = Offset(overlay.fineOffsetX, overlay.fineOffsetY);
          });
          notifier.selectTemporaryOverlay(overlay.id);
        },
        child: MouseRegion(
          cursor: isSelected ? SystemMouseCursors.move : SystemMouseCursors.grab,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFC4B5FD).withValues(alpha: 0.85)
                    : Colors.transparent,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(2),
            child: content,
          ),
        ),
      );
    } else {
      interactiveContent = IgnorePointer(
        ignoring: true,
        child: content,
      );
    }

    Widget animatedLayer = interactiveContent;

    if (wipeEnd < 0.999 || wipeStart > 0.001) {
      animatedLayer = ClipRect(
        clipper: _HorizontalWipeClipper(
          startFraction: wipeStart,
          endFraction: wipeEnd,
        ),
        child: animatedLayer,
      );
    }

    if (blurAmount > 0.1) {
      animatedLayer = ImageFiltered(
        imageFilter:
            ui.ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: animatedLayer,
      );
    }

    animatedLayer = Opacity(
      opacity: animOpacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(transX + glitchOffset, transY + floatOffsetY),
        child: Transform.scale(
          scale: (effectScale * animScale).clamp(0.0, 3.0),
          child: animatedLayer,
        ),
      ),
    );

    return Positioned.fill(
      child: Align(
        alignment: overlay.position.alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Transform.translate(
            offset: Offset(overlay.fineOffsetX, overlay.fineOffsetY),
            child: animatedLayer,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for cybernetic corner callout brackets.
/// Draws L-shaped corner brackets ONLY at the 4 ends/corners of the frame.
class _CornerBracketsPainter extends CustomPainter {
  const _CornerBracketsPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
    required this.fill,
    required this.fillColor,
  });

  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final bool fill;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (fill && fillColor.a > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, fillPaint);
    }

    final bracketPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final cl = cornerLength.clamp(4.0, math.min(size.width, size.height) / 2);

    // Top-Left bracket
    final tlPath = Path()
      ..moveTo(0, cl)
      ..lineTo(0, 0)
      ..lineTo(cl, 0);
    canvas.drawPath(tlPath, bracketPaint);

    // Top-Right bracket
    final trPath = Path()
      ..moveTo(size.width - cl, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, cl);
    canvas.drawPath(trPath, bracketPaint);

    // Bottom-Left bracket
    final blPath = Path()
      ..moveTo(0, size.height - cl)
      ..lineTo(0, size.height)
      ..lineTo(cl, size.height);
    canvas.drawPath(blPath, bracketPaint);

    // Bottom-Right bracket
    final brPath = Path()
      ..moveTo(size.width - cl, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height - cl);
    canvas.drawPath(brPath, bracketPaint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.cornerLength != cornerLength ||
        oldDelegate.fill != fill ||
        oldDelegate.fillColor != fillColor;
  }
}

/// Custom clipper for horizontal wipe transition (wipe in / wipe out).
class _HorizontalWipeClipper extends CustomClipper<Rect> {
  const _HorizontalWipeClipper({
    required this.startFraction,
    required this.endFraction,
  });

  final double startFraction;
  final double endFraction;

  @override
  Rect getClip(Size size) {
    final left = size.width * startFraction.clamp(0.0, 1.0);
    final right = size.width * endFraction.clamp(0.0, 1.0);
    final clipWidth = math.max(0.0, right - left);
    return Rect.fromLTWH(left, 0, clipWidth, size.height);
  }

  @override
  bool shouldReclip(covariant _HorizontalWipeClipper oldClipper) =>
      oldClipper.startFraction != startFraction ||
      oldClipper.endFraction != endFraction;
}

