import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../../ui/tokens/motion.dart';
import '../auth_theme.dart';

/// The auth flow's submit control: a compact square tick that replaces the
/// wide "Continue" button.
///
/// Appearance, as requested:
///   * **incomplete** — grey-on-glass: a barely-there glass square with a
///     dim grey tick inside, so it reads as "not yet".
///   * **complete** — a blue rounded square with a dark tick inside.
///   * **pressed** — the square scales down slightly, then springs back with
///     a small, deliberate bounce.
///
/// Motion:
///   * Press-down is a short, eased scale to
///     [AuthColors.submitTickPressScale].
///   * Release is a [SpringSimulation] back to 1.0, which gives a natural
///     overshoot instead of a mechanical linear return. "The moment we
///     press on it add some animation" — the bounce IS that moment.
///   * Reduce-motion users get the state change with no movement at all.
///
/// Keyboard: focusable, Enter/Space submits, accent focus ring. The
/// [semanticsLabel] doubles as the tooltip, because the tick carries no
/// visible text of its own.
class AuthSubmitTick extends StatefulWidget {
  const AuthSubmitTick({
    required this.onPressed,
    required this.semanticsLabel,
    this.enabled = true,
    this.busy = false,
    super.key,
  });

  /// Submit callback, or null while the control is unavailable. A null
  /// callback makes the tick genuinely inert: no press feedback, no bounce,
  /// no submission.
  final VoidCallback? onPressed;

  /// Accessible name (also shown as the tooltip).
  final String semanticsLabel;

  /// False while the form is incomplete — grey instead of blue, inert.
  final bool enabled;

  /// True while a submission is in flight: the tick is replaced by a
  /// spinner and presses are ignored.
  final bool busy;

  @override
  State<AuthSubmitTick> createState() => _AuthSubmitTickState();
}

class _AuthSubmitTickState extends State<AuthSubmitTick>
    with SingleTickerProviderStateMixin {
  /// Drives the press/bounce scale. Rests at 1.0.
  late final AnimationController _scale = AnimationController(
    vsync: this,
    // Duration only matters for the press-down leg; the release leg is
    // driven by a spring simulation and completes on its own.
    duration: const Duration(milliseconds: 90),
    value: 1.0,
  );

  bool _hovered = false;
  bool _focused = false;

  /// Cached reduce-motion flag.
  ///
  /// IMPORTANT: it must be read here, not inside the gesture callbacks.
  /// [AppMotion.disabled] calls dependOnInheritedWidgetOfExactType, and
  /// doing that from an event callback (outside the build phase) can throw
  /// "Looking up a deactivated widget's ancestor is unsafe" — which
  /// silently killed the whole press animation. Caching it during
  /// didChangeDependencies is the supported pattern.
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = AppMotion.disabled(context);
  }

  bool get _active => widget.enabled && !widget.busy;

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  // ── Interaction ─────────────────────────────────────────────────────────

  void _onPressStart() {
    if (!_active) return;
    if (_reduceMotion) return;
    _scale.animateTo(
      AuthColors.submitTickPressScale,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
    );
  }

  void _onPressEnd() {
    if (!_active) return;
    if (_reduceMotion) {
      _scale.value = 1.0;
      return;
    }
    // Spring back with a small overshoot: this is the "cute bounce".
    // Damping 13 (below the critical value of 2*sqrt(stiffness)) gives a
    // gentle single overshoot rather than a wobbly multi-bounce.
    _scale.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 520, damping: 13),
        _scale.value,
        1.0,
        // A little upward velocity so the release "pops" rather than
        // merely returning.
        1.6,
      ),
    );
  }

  void _handleTap() {
    if (!_active) return;
    widget.onPressed!();
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = _reduceMotion;

    final Color fill;
    final Color border;
    final Color markColor;
    if (!_active) {
      fill = AuthColors.submitTickDisabledFill;
      border = AuthColors.submitTickDisabledBorder;
      markColor = AuthColors.submitTickDisabledMark;
    } else if (_hovered) {
      fill = AuthColors.submitTickEnabledHover;
      border = AuthColors.submitTickEnabledHover;
      markColor = AuthColors.submitTickMark;
    } else {
      fill = AuthColors.submitTickEnabledFill;
      border = AuthColors.submitTickEnabledFill;
      markColor = AuthColors.submitTickMark;
    }

    return RepaintBoundary(
      child: Center(
        child: Semantics(
          button: true,
          enabled: _active,
          label: widget.semanticsLabel,
          child: Tooltip(
            message: widget.semanticsLabel,
            child: Focus(
              onFocusChange: (v) => setState(() => _focused = v),
              onKeyEvent: (node, event) {
                if (!_active) return KeyEventResult.ignored;
                if (event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.space)) {
                  _handleTap();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: MouseRegion(
                cursor: _active
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleTap,
                  // The squash is driven by raw pointer events through a
                  // Listener, NOT by GestureDetector.onTapDown. The tap
                  // recognizer only reports onTapDown once the gesture arena
                  // resolves (the Tooltip's own recognizer competes for it),
                  // which happens on RELEASE — so a press-and-hold showed no
                  // feedback until the button came back up. A Listener gets
                  // the pointer down immediately, which is what "squashes the
                  // moment you press it" needs.
                  child: Listener(
                    onPointerDown: (_) => _onPressStart(),
                    onPointerUp: (_) => _onPressEnd(),
                    onPointerCancel: (_) => _onPressEnd(),
                    child: AnimatedBuilder(
                    animation: _scale,
                    builder: (BuildContext context, Widget? child) {
                      final double scale = reduceMotion ? 1.0 : _scale.value;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: AnimatedContainer(
                      duration: AppMotion.fastOf(context),
                      curve: AppMotion.curve,
                      width: AuthColors.submitTickSize,
                      height: AuthColors.submitTickSize,
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(
                          AuthColors.submitTickRadius,
                        ),
                        border: Border.all(
                          color: _focused ? AuthColors.focusRing : border,
                          width: _focused ? 2 : 1,
                        ),
                      ),
                      child: widget.busy
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AuthColors.submitTickMark,
                              ),
                            )
                          : Icon(
                              Icons.check_rounded,
                              size: 26,
                              color: markColor,
                            ),
                    ),
                  ),
                ),
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}