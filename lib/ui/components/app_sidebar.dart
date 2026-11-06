import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// A single sidebar navigation destination.
class AppSidebarItem {
  const AppSidebarItem({
    required this.label,
    required this.icon,
    required this.route,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final String route;
  final bool enabled;
}

/// Desktop sidebar navigation.
///
/// Dark ink surface on light scheme creates durable chrome/content
/// separation (premium-windows-ui: deliberate surfaces, clear navigation).
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    required this.items,
    required this.currentRoute,
    required this.onNavigate,
    this.header,
    this.footer,
    super.key,
  });

  final List<AppSidebarItem> items;
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.darkSurfaceChrome,
        border: Border(
          right: BorderSide(color: AppColors.darkBorder),
        ),
      ),
      child: Column(
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: header,
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.sm),
            children: [
              for (final item in items)
                _SidebarTile(
                  item: item,
                  selected: currentRoute.startsWith(item.route),
                  onNavigate: onNavigate,
                ),
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: footer,
          ),
      ],
      ),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onNavigate,
  });

  final AppSidebarItem item;
  final bool selected;
  final ValueChanged<String> onNavigate;

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final selected = widget.selected;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onNavigate(item.route);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () => widget.onNavigate(item.route),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.darkSurface
                    : _hovered
                        ? AppColors.darkSurfaceHover
                        : Colors.transparent,
                borderRadius: AppRadius.rMd,
                border: _focused
                    ? Border.all(color: AppColors.focusRing, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 16,
                    color: selected
                        ? AppColors.darkTextPrimary
                        : AppColors.darkTextSecondary,
                  ),
                  const SizedBox(width: Spacing.md),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: AppTypography.sizeMd,
                      fontWeight:
                          selected ? AppTypography.wMedium : AppTypography.wRegular,
                      color: selected
                          ? AppColors.darkTextPrimary
                          : AppColors.darkTextSecondary,
                    ),
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
