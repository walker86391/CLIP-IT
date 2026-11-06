import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../ui/tokens/motion.dart';
import '../auth_theme.dart';
import 'magnetic_field.dart';

/// Primary action button for the auth flow (accent #6EA8FE, dark text).
///
/// States: hover / pressed / keyboard focus ring / disabled (clearly muted)
/// / busy (inline spinner replaces the icon + label).
///
/// MAGNETIC EFFECT
///
/// While the cursor is near the button — within
/// [AuthColors.magneticReach] of its edge — the button eases toward the
/// cursor, then springs back to rest when the cursor moves away. The
/// influence fades smoothly across the reach band, so there is no pop at
/// the field boundary, and the anticipation starts before the cursor even
/// touches the button. This is what makes the button feel "magnetic".
///
/// Implementation notes:
///
///   * Pointer tracking comes from the screen-level [MagneticFieldScope]
///     (see that file for why an oversized MouseRegion around the button
///     would not work — hit testing stops at layout bounds). The button
///     listens to the scope's pointer notifier and computes its own
///     proximity, so the effect adds ZERO layout padding around the button.
///   * The pull is a paint-time [Transform.translate] (a [TweenAnimationBuilder]
///     chases the target with a short easeOutCubic duration, and returns to
///     rest with a slightly longer easeOutBack "snap"). Layout is never
///     affected, and the tap target moves WITH the visual, since
///     RenderTransform hit-tests through its paint transform.
///   * The measured rect comes from a GlobalKey on the outer [Stack] — the
///     layout slot ABOVE the Transform. Measuring the transformed box
///     instead would feed the button's own movement back into the
///     proximity math.
///   * Disabled/busy buttons and reduce-motion users get no pull at all
///     (color hover states still work).
class AuthButton extends StatefulWidget {
  const AuthButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// When true the button shows a spinner and ignores presses.
  final bool busy;

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  /// Cached reduce-motion flag. Read in didChangeDependencies because
  /// listening to the pointer notifier happens outside the build phase,
  /// where depending on an inherited widget is not appropriate.
  bool _reduceMotion = false;

  /// Where the magnetic pull currently WANTS the button to be. The actual
  /// rendered position chases this via the TweenAnimationBuilder below.
  Offset _magneticTarget = Offset.zero;

  /// The button's layout slot (the Stack above the pull transform).
  final GlobalKey _slotKey = GlobalKey();

  MagneticFieldScopeState? _magneticField;

  bool get _enabled => widget.onPressed != null && !widget.busy;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = AppMotion.disabled(context);

    // Attach to the magnetic field exactly once (and re-attach if the
    // button is ever moved under a different scope).
    final MagneticFieldScopeState? field = MagneticFieldScope.maybeOf(context);
    if (!identical(field, _magneticField)) {
      _magneticField?.pointer.removeListener(_onPointerMoved);
      _magneticField = field;
      _magneticField?.pointer.addListener(_onPointerMoved);
    }
  }

  @override
  void dispose() {
    _magneticField?.pointer.removeListener(_onPointerMoved);
    _magneticField = null;
    super.dispose();
  }

  /// Magnetic effect active? Needs: enabled button, motion allowed, and a
  /// field to read the pointer from.
  bool get _magneticActive =>
      _enabled && !_reduceMotion && _magneticField != null;

  /// Recomputes the pull target from the current pointer position.
  /// Called on every mouse move across the screen (while the field exists).
  void _onPointerMoved() {
    // Guards for teardown races and disabled/busy transitions.
    if (!mounted || !_magneticActive) return;

    final Offset? pointer = _magneticField?.pointer.value;
    final RenderBox? slot =
        _slotKey.currentContext?.findRenderObject() as RenderBox?;
    if (pointer == null || slot == null || !slot.hasSize) return;

    // The layout slot's rect in global coordinates — the button's resting
    // position, before any magnetic translate.
    final Rect rect = Rect.fromPoints(
      slot.localToGlobal(Offset.zero),
      slot.localToGlobal(slot.size.bottomRight(Offset.zero)),
    );

    // Distance from the pointer to the NEAREST point on the button: 0
    // whenever the cursor is anywhere over the button itself.
    final Offset nearest = Offset(
      pointer.dx.clamp(rect.left, rect.right).toDouble(),
      pointer.dy.clamp(rect.top, rect.bottom).toDouble(),
    );
    final double distance = (pointer - nearest).distance;

    // Outside the reach band: spring back to rest.
    if (distance >= AuthColors.magneticReach) {
      if (_magneticTarget != Offset.zero) {
        setState(() => _magneticTarget = Offset.zero);
      }
      return;
    }

    // Proximity 1 on the button, fading to 0 at the edge of the reach
    // band. easeOutCubic keeps the fade gentle near the button (full
    // effect when close) and smooth as it dies off at the boundary.
    final double proximity = Curves.easeOutCubic.transform(
      1.0 - distance / AuthColors.magneticReach,
    );

    // Pull toward the cursor, scaled by proximity, then capped so the
    // button can never slide far from its slot.
    Offset pull = (pointer - rect.center) *
        (AuthColors.magneticPull * proximity);
    final double magnitude = pull.distance;
    if (magnitude > AuthColors.magneticMaxOffset) {
      pull = pull / magnitude * AuthColors.magneticMaxOffset;
    }

    if (pull != _magneticTarget) {
      setState(() => _magneticTarget = pull);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color background;
    if (!_enabled) {
      background = const Color(0x0FFFFFFF); // white ~6%
    } else if (_pressed) {
      background = AuthColors.accentPressed;
    } else if (_hovered) {
      background = AuthColors.accentHover;
    } else {
      background = AuthColors.accent;
    }

    final Color foreground =
        _enabled ? const Color(0xFF14161B) : const Color(0x73B7BCC6);

    // Chase duration while following the cursor; a longer, springy curve
    // (easeOutBack → soft overshoot "snap") for the return to rest.
    final bool returning = _magneticTarget == Offset.zero;

    return Stack(
      // The slot: sizes itself to the button and stays put while the inner
      // transform does the visual moving. Keyed for proximity measuring.
      key: _slotKey,
      clipBehavior: Clip.none,
      children: <Widget>[
        TweenAnimationBuilder<Offset>(
          // Rebuilt with a fresh tween whenever the pull target changes;
          // TweenAnimationBuilder re-targets from the CURRENT animated
          // value, which produces the smooth "chase" as the cursor moves.
          tween: Tween<Offset>(end: _magneticTarget),
          duration: returning
              ? AuthColors.magneticReturnDuration
              : AuthColors.magneticChaseDuration,
          curve:
              returning ? Curves.easeOutBack : Curves.easeOutCubic,
          builder: (BuildContext context, Offset offset, Widget? child) {
            return Transform.translate(offset: offset, child: child);
          },
          child: _buildButtonCore(background, foreground),
        ),
      ],
    );
  }

  /// The button's own interactive core: keyboard focus + activation,
  /// cursor, hover/press color states, and the animated surface.
  Widget _buildButtonCore(Color background, Color foreground) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (node, event) {
        if (!_enabled) return KeyEventResult.ignored;
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onPressed!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor:
            _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            if (_enabled) setState(() => _pressed = true);
          },
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: _enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: AppMotion.fastOf(context),
            curve: AppMotion.curve,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
              border: _focused
                  ? Border.all(color: AuthColors.focusRing, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.busy) ...[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF14161B),
                    ),
                  ),
                ] else if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: foreground),
                ],
                if (!widget.busy) ...[
                  if (widget.icon != null) const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
