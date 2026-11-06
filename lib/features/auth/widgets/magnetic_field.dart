import 'package:flutter/material.dart';

/// A screen-level cursor tracker used by "magnetic" widgets (see
/// [AuthButton] — the Continue button leans toward the cursor).
///
/// WHY THIS EXISTS
///
/// The naive way to build a magnetic button is an oversized invisible
/// MouseRegion around the button (Positioned with negative insets inside a
/// Stack with Clip.none). That does NOT work in Flutter: hit testing stops
/// at the parent's layout bounds even when painting with Clip.none, so an
/// oversized hover region never receives events outside the button's own
/// box. The reliable pattern is the inverse — ONE MouseRegion covering an
/// ancestor that already spans the area (here: the whole auth screen),
/// publishing the pointer position to descendants. Widgets opt in by
/// reading [pointer] and computing their own proximity to the cursor.
///
/// Coordinates: the published value is the pointer position in GLOBAL
/// coordinates (PointerEvent.position, not localPosition), so consumers can
/// compare it directly against `RenderBox.localToGlobal` results regardless
/// of where this widget sits in the tree.
///
/// Nothing here consumes pointer events: the MouseRegion is `opaque: false`,
/// so hit testing, clicks, and hover styling of everything beneath it are
/// completely unaffected.
class MagneticFieldScope extends StatefulWidget {
  const MagneticFieldScope({required this.child, super.key});

  final Widget child;

  /// Nearest enclosing scope's state, or null if there is none. Widgets
  /// must treat null as "magnetic effects disabled" (e.g. in widget tests
  /// or when the button is reused outside the auth screen).
  static MagneticFieldScopeState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<MagneticFieldScopeState>();

  @override
  State<MagneticFieldScope> createState() => MagneticFieldScopeState();
}

class MagneticFieldScopeState extends State<MagneticFieldScope> {
  /// Current pointer position in global coordinates, or null when the
  /// cursor has left the window / the scope has no pointer yet.
  ///
  /// Public so consumers can addListener/removeListener directly; the
  /// notifier fires on every mouse move, and each consumer decides whether
  /// that means "update my pull target" or "ignore".
  final ValueNotifier<Offset?> pointer = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
    pointer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      // opaque: false — the field must NEVER interfere with hit testing.
      // It only observes the pointer as it moves across the subtree.
      opaque: false,
      onHover: (PointerEvent event) {
        // `.position` is the GLOBAL pointer position (unlike
        // `.localPosition`, which would be relative to this MouseRegion).
        pointer.value = event.position;
      },
      onExit: (PointerEvent event) {
        pointer.value = null;
      },
      child: widget.child,
    );
  }
}
