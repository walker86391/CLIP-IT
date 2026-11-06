import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// ClipIt button.
///
/// Desktop-density control with deliberate hover/pressed/focus states.
/// Variants: [primary], [secondary] (tonal), [ghost], [danger].
enum AppButtonVariant { primary, secondary, ghost, danger }

enum AppButtonSize { regular, small }

class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.secondary,
    this.size = AppButtonSize.regular,
    this.icon,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;

  /// Stretch to available width (e.g. form rows).
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final height =
        widget.size == AppButtonSize.small
            ? AppSizes.controlHeightSm
            : AppSizes.controlHeight;
    final hPad = widget.size == AppButtonSize.small ? 10.0 : 14.0;
    final fontSize =
        widget.size == AppButtonSize.small ? AppTypography.sizeSm : AppTypography.sizeMd;

    final fg = _foregroundColor();
    final bg = _backgroundColor();
    final border = _borderColor();

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: widget.size == AppButtonSize.small ? 14 : 16, color: fg),
          const SizedBox(width: Spacing.sm),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: AppTypography.wMedium,
            color: fg,
          ),
        ),
      ],
    );

    return Focus(
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
        cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: _enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            height: height,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.rMd,
              border: Border.all(color: border, width: AppBorders.thin),
              boxShadow: _pressed
                  ? null
                  : (widget.variant == AppButtonVariant.primary && _enabled
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: _hovered ? 0.30 : 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null),
            ),
            child: FocusScope(
              canRequestFocus: false,
              child: Focus(
                onFocusChange: (v) => setState(() => _focused = v),
                child: Container(
                  alignment: Alignment.center,
                  decoration: _focused
                      ? BoxDecoration(
                          borderRadius: AppRadius.rSm,
                          border: Border.all(color: AppColors.focusRing, width: 2),
                        )
                      : null,
                  width: widget.expand ? double.infinity : null,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _foregroundColor() {
    if (!_enabled) return AppColors.textDisabled;
    return switch (widget.variant) {
      AppButtonVariant.primary => AppColors.textOnAccent,
      AppButtonVariant.secondary => AppColors.textPrimary,
      AppButtonVariant.ghost => AppColors.textSecondary,
      AppButtonVariant.danger => AppColors.textOnAccent,
    };
  }

  Color _backgroundColor() {
    if (!_enabled) return AppColors.surfaceHover;
    final hover = _hovered;
    final press = _pressed;
    return switch (widget.variant) {
      AppButtonVariant.primary => press
          ? AppColors.accentPressed
          : hover
              ? AppColors.accentHover
              : AppColors.accent,
      AppButtonVariant.secondary => press
          ? AppColors.surfacePressed
          : hover
              ? AppColors.surfaceHover
              : AppColors.surface,
      AppButtonVariant.ghost => press
          ? AppColors.surfacePressed
          : hover
              ? AppColors.surfaceHover
              : Colors.transparent,
      AppButtonVariant.danger => press
          ? AppColors.dangerHover
          : hover
              ? AppColors.dangerHover
              : AppColors.danger,
    };
  }

  Color _borderColor() {
    if (!_enabled) return AppColors.border;
    return switch (widget.variant) {
      AppButtonVariant.primary ||
      AppButtonVariant.danger ||
      AppButtonVariant.ghost =>
        Colors.transparent,
      AppButtonVariant.secondary => _hovered ? AppColors.borderStrong : AppColors.border,
    };
  }
}
