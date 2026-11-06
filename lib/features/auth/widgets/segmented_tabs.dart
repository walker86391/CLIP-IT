import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../ui/tokens/motion.dart';
import '../auth_theme.dart';

/// Segmented tab control with a sliding "glass pill" indicator.
///
/// Keyboard accessible: each tab is focusable, Enter/Space activates, and a
/// visible focus ring appears on focus.
class AuthSegmentedTabs extends StatelessWidget {
  const AuthSegmentedTabs({
    required this.labels,
    required this.index,
    required this.onChanged,
    super.key,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  /// Horizontal alignment for the sliding pill, in [-1.0, +1.0].
  ///
  /// Distributes the pill evenly across [labels.length] slots:
  ///   n == 1 → 0.0                (single tab, centered)
  ///   n == 2 → -1.0 / +1.0        (two tabs, flush edges)
  ///   n == 3 → -1.0 / 0.0 / +1.0  (three tabs, center slot truly centered)
  ///
  /// The division by (n - 1) is what makes this correct for any tab count
  /// instead of only two.
  double _pillAlignmentX(int tabIndex) {
    final int count = labels.length;
    // Guard against a zero/negative count so this can never divide by zero.
    if (count <= 1) return 0.0;
    final int safeIndex = tabIndex.clamp(0, count - 1);
    // -1.0 at the first tab, +1.0 at the last, linear in between.
    return (safeIndex / (count - 1)) * 2.0 - 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.disabled(context);

    return RepaintBoundary(
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AuthColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AuthColors.glassBorder, width: 1),
        ),
        child: Stack(
          children: [
            // Sliding pill (one third of the inner width, aligned per tab).
            //
            // NOTE: the alignment must be computed for the ACTUAL tab count.
            // The previous expression `index * 2.0 - 1.0` is only correct for
            // exactly two tabs (it yields -1.0 / +1.0). With three tabs it
            // produced -1.0 / +1.0 / +3.0, so selecting "Sign In" threw the
            // pill onto the right edge (visually landing on "Secret Code") and
            // selecting "Secret Code" pushed it off-screen entirely. That is
            // what made the tabs look like they were redirecting to the admin
            // code screen.
            //
            // General formula: map index onto [-1.0, +1.0] across n tabs.
            //   x = -1.0            when index == 0        (left edge)
            //   x =  0.0            when index == (n-1)/2  (center)
            //   x = +1.0            when index == n-1      (right edge)
            AnimatedAlign(
              duration: reduceMotion ? Duration.zero : AppMotion.fastOf(context),
              curve: Curves.fastOutSlowIn,
              alignment: Alignment(_pillAlignmentX(index), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / labels.length,
                child: Container(
                  decoration: BoxDecoration(
                    color: AuthColors.tabPill,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: const Color(0x26FFFFFF), // white ~15%
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            // Tab hit targets + labels.
            Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: _TabTile(
                      label: labels[i],
                      selected: i == index,
                      onTap: () => onChanged(i),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabTile extends StatefulWidget {
  const _TabTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_TabTile> createState() => _TabTileState();
}

class _TabTileState extends State<_TabTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _hovered;

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onTap();
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
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppMotion.fastOf(context),
            curve: AppMotion.curve,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              // Keyboard focus ring (accent at 40%).
              border: _focused
                  ? Border.all(color: AuthColors.focusRing, width: 2)
                  : null,
            ),
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: widget.selected
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: widget.selected
                    ? AuthColors.textPrimary
                    : active
                        ? AuthColors.textPrimary.withValues(alpha: 0.85)
                        : AuthColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
