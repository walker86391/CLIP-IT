import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../ui/tokens/motion.dart';
import '../auth_theme.dart';

/// Custom checkbox row matching the glass aesthetic.
///
/// Keyboard: focusable, Enter/Space toggles, visible accent focus ring.
class AuthCheckboxRow extends StatefulWidget {
  const AuthCheckboxRow({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<AuthCheckboxRow> createState() => _AuthCheckboxRowState();
}

class _AuthCheckboxRowState extends State<AuthCheckboxRow>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _focused = false;

  /// Drives the tiny "bounce" played when the box is ticked.
  ///
  /// The change itself is only a colour swap, which is easy to miss on a
  /// fast click — so the box dips slightly, then springs just past its
  /// resting size and settles. Deliberately small: a "very little
  /// noticeable bounce", not a cartoon pop.
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  late final Animation<double> _bounceScale = TweenSequence<double>([
    // Dip in (fast, eased out).
    TweenSequenceItem<double>(
      tween: Tween<double>(
        begin: 1.0,
        end: AuthColors.checkboxTickBounceScale,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    // Spring back out, overshooting a touch.
    TweenSequenceItem<double>(
      tween: Tween<double>(
        begin: AuthColors.checkboxTickBounceScale,
        end: 1.07,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 40,
    ),
    // Settle back to exactly 1.0.
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 1.07, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 25,
    ),
  ]).animate(_bounce);

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  /// Cached reduce-motion flag. Read during didChangeDependencies rather
  /// than inside [ _playBounce]: AppMotion.disabled() calls
  /// dependOnInheritedWidgetOfExactType, which is unsafe to call from a
  /// gesture callback (it can throw "Looking up a deactivated widget's
  /// ancestor"), and doing so silently cancelled the bounce.
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = AppMotion.disabled(context);
  }

  /// Plays the bounce. Skipped for reduce-motion users.
  void _playBounce() {
    if (_reduceMotion) return;
    _bounce.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            _playBounce();
            widget.onChanged(!widget.value);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _playBounce();
              widget.onChanged(!widget.value);
            },
            child: Container(
              // Focus ring drawn as a full-row outline so it's clearly visible.
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: _focused
                    ? Border.all(color: AuthColors.focusRing, width: 2)
                    : null,
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Row(
                children: [
                  // The bounce scales the box only — the label beside it must
                  // not move, or the row would appear to jump sideways.
                  AnimatedBuilder(
                    animation: _bounceScale,
                    builder: (BuildContext context, Widget? child) {
                      return Transform.scale(
                        scale: _bounceScale.value,
                        child: child,
                      );
                    },
                    child: AnimatedContainer(
                      duration: AppMotion.fastOf(context),
                      curve: AppMotion.curve,
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: widget.value
                            ? AuthColors.accent
                            : _hovered
                                ? const Color(0x1FFFFFFF)
                                : const Color(0x0FFFFFFF),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: widget.value
                              ? AuthColors.accent
                              : AuthColors.fieldBorderStrong,
                          width: 1,
                        ),
                      ),
                      child: widget.value
                          ? const Icon(
                              Icons.check,
                              size: 13,
                              color: Color(0xFF14161B),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.label, style: AuthText.secondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
