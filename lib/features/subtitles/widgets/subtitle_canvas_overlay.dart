import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/subtitle_studio_provider.dart';
import 'subtitle_phrase_renderer.dart';

/// Interactive draggable & resizable subtitle canvas overlay inside the phone display.
///
/// Features:
/// - Subtitle moves independently of phone frame in 2D (left/right and up/down).
/// - Clamped normalized coordinates (0.05 to 0.95 X, -0.25 to 1.25 Y).
/// - Gentle 2-3px horizontal center snap with visual blue guideline.
/// - Unconstrained, smooth vertical motion for exact placement (lips, mouth, chest).
/// - Corner selection handles & subtle selection boundary.
/// - Interactive circular handles (bottom-left and bottom-right) to resize font size in real time.
/// - Synchronizes directly with SubtitleStudioProvider.
class SubtitleCanvasOverlay extends ConsumerStatefulWidget {
  const SubtitleCanvasOverlay({
    this.showGuides = true,
    super.key,
  });

  final bool showGuides;

  @override
  ConsumerState<SubtitleCanvasOverlay> createState() =>
      _SubtitleCanvasOverlayState();
}

class _SubtitleCanvasOverlayState extends ConsumerState<SubtitleCanvasOverlay> {
  bool _isDragging = false;
  bool _isResizing = false;
  bool _isResizingBottomLeft = false;
  bool _isSelected = true;

  bool _snapX = false;
  bool _snapY = false;

  // Track absolute pointer start so drag sticks 1:1 to the mouse without lag or jitter
  Offset _dragStartGlobal = Offset.zero;
  Offset _dragStartNormalized = Offset.zero;

  // Resize pointer tracking
  Offset _resizeStartGlobal = Offset.zero;
  double _resizeStartFontSize = 26.0;

  @override
  Widget build(BuildContext context) {
    final studioState = ref.watch(subtitleStudioProvider);
    final config = studioState.activeConfig;

    if (!config.subtitlesEnabled) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasW = constraints.maxWidth;
        final canvasH = constraints.maxHeight;

        // Subtitle pixel position calculated from normalized center
        final posX = config.positionX * canvasW;
        final posY = config.positionY * canvasH;

        // Note: Anchor is kept stationary at center (-0.5, -0.5) so changing
        // text alignment (Left, Center, Right) formats words inside the box
        // without shifting the subtitle position across the screen.

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerMove: (event) {
            if (_isResizing) {
              final delta = event.position - _resizeStartGlobal;
              final change = _isResizingBottomLeft
                  ? (-delta.dx + delta.dy) * 0.22
                  : (delta.dx + delta.dy) * 0.22;
              final newFontSize =
                  (_resizeStartFontSize + change).clamp(14.0, 48.0);
              ref
                  .read(subtitleStudioProvider.notifier)
                  .updateTypography(fontSize: newFontSize);
            } else if (_isDragging) {
              if (canvasW <= 0 || canvasH <= 0) return;

              // Delta from pointer start in canvas normalized coordinates (allows dragging over black bars)
              final deltaPixels = event.position - _dragStartGlobal;
              final rawX = (_dragStartNormalized.dx + (deltaPixels.dx / canvasW))
                  .clamp(-0.10, 1.10);
              final rawY = (_dragStartNormalized.dy + (deltaPixels.dy / canvasH))
                  .clamp(-0.25, 1.25);

              // Gentle 2-3px horizontal center snap (~0.007 on phone screen)
              double targetX = rawX;
              bool snapXNow = false;
              if ((rawX - 0.50).abs() < 0.007) {
                targetX = 0.50;
                snapXNow = true;
              }

              // Smooth vertical positioning without harsh snapping (allows fine placement near lips)
              double targetY = rawY;
              bool snapYNow = false;
              if ((rawY - 0.50).abs() < 0.002) {
                targetY = 0.50;
                snapYNow = true;
              }

              setState(() {
                _snapX = snapXNow;
                _snapY = snapYNow;
              });

              ref
                  .read(subtitleStudioProvider.notifier)
                  .updatePosition(targetX, targetY);
            }
          },
          onPointerUp: (_) {
            if (_isDragging || _isResizing) {
              setState(() {
                _isDragging = false;
                _isResizing = false;
                _isResizingBottomLeft = false;
                _snapX = false;
                _snapY = false;
              });
            }
          },
          onPointerCancel: (_) {
            if (_isDragging || _isResizing) {
              setState(() {
                _isDragging = false;
                _isResizing = false;
                _isResizingBottomLeft = false;
                _snapX = false;
                _snapY = false;
              });
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Background Tap to Deselect/Select ─────────────────────────
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    setState(() => _isSelected = true);
                  },
                ),
              ),

              // ── Snapping Guide: Vertical Blue Line (Horizontal Center) ───
              if (_snapX && widget.showGuides)
                Positioned(
                  left: (canvasW / 2) - 0.75,
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

              // ── Snapping Guide: Horizontal Blue Line (Vertical Center) ────
              if (_snapY && widget.showGuides)
                Positioned(
                  top: (canvasH / 2) - 0.75,
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

              // ── Draggable & Resizable Subtitle Box ─────────────────────────
              Positioned(
                left: posX,
                top: posY,
                child: FractionalTranslation(
                  key: const ValueKey('subtitle_box_translation'),
                  translation: const Offset(-0.5, -0.5),
                  child: MouseRegion(
                    cursor: _isDragging
                        ? SystemMouseCursors.move
                        : SystemMouseCursors.click,
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (event) {
                        if (_isResizing) return;
                        setState(() {
                          _isDragging = true;
                          _isSelected = true;
                          _dragStartGlobal = event.position;
                          _dragStartNormalized =
                              Offset(config.positionX, config.positionY);
                        });
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Subtitle Selection Box Outline
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _isSelected
                                    ? const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.75)
                                    : Colors.transparent,
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: SubtitlePhraseRenderer(
                              config: config,
                              isAnimated: studioState.isPlayingPreview,
                            ),
                          ),

                          // Corner Resize Handle (Bottom Left - circular interactive button)
                          if (_isSelected)
                            Positioned(
                              left: -7,
                              bottom: -7,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeDownLeft,
                                child: Listener(
                                  behavior: HitTestBehavior.opaque,
                                  onPointerDown: (event) {
                                    setState(() {
                                      _isResizing = true;
                                      _isDragging = false;
                                      _isSelected = true;
                                      _isResizingBottomLeft = true;
                                      _resizeStartGlobal = event.position;
                                      _resizeStartFontSize = config.fontSize;
                                    });
                                  },
                                  child: _buildResizeHandle(
                                    isResizing: _isResizing &&
                                        _isResizingBottomLeft,
                                  ),
                                ),
                              ),
                            ),

                          // Corner Resize Handle (Bottom Right - circular interactive button)
                          if (_isSelected)
                            Positioned(
                              right: -7,
                              bottom: -7,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeDownRight,
                                child: Listener(
                                  behavior: HitTestBehavior.opaque,
                                  onPointerDown: (event) {
                                    setState(() {
                                      _isResizing = true;
                                      _isDragging = false;
                                      _isSelected = true;
                                      _isResizingBottomLeft = false;
                                      _resizeStartGlobal = event.position;
                                      _resizeStartFontSize = config.fontSize;
                                    });
                                  },
                                  child: _buildResizeHandle(
                                    isResizing: _isResizing &&
                                        !_isResizingBottomLeft,
                                  ),
                                ),
                              ),
                            ),

                          // Corner Anchor Markers (Visual top anchors)
                          if (_isSelected) ...[
                            _buildCornerDot(top: -4, left: -4),
                            _buildCornerDot(top: -4, right: -4),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResizeHandle({required bool isResizing}) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: isResizing ? const Color(0xFFC4B5FD) : const Color(0xFF8B5CF6),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildCornerDot({
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2032),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF8B5CF6),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}
