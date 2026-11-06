import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../ui/tokens/motion.dart';
import '../auth_theme.dart';
import 'chromatic_glass_border.dart';

/// Apple-style glass text field with label above and inline error below.
///
/// Visual design (v2, per user feedback):
///
/// The previous field was a flat white-8% box with a white-12% border. Over
/// the glass panel that stacked into a milky grey slab — "what's the grey
/// thing in it?". The field is now ONE smooth glass surface:
///
///   * Fill: a single vertical gradient — a specular sheen at the top edge
///     (white ~9%) fading into a barely-there base (white ~3.5%) and a hint
///     of depth at the bottom (white ~4.5%). No separate fill layer.
///   * Edge: a 1px hairline with a vertical white gradient, painted by
///     [ChromaticGlassBorderPainter] together with sub-pixel red/cyan
///     chromatic-aberration fringes — the Apple liquid-glass look.
///   * No inner boxes, no layered containers: fill gradient + edge stroke
///     are the only chrome around the transparent TextField.
///
/// Focus is shown by swapping the hairline to the accent; errors swap it to
/// the error color and render a concise message underneath. Hover brightens
/// the fill one small step (desktop-first affordance). Fully keyboard
/// navigable (standard TextField focus handling).
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.obscure = false,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.suffixIcon,
    this.onSuffixTap,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final bool obscure;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  /// Optional trailing icon (e.g. calendar for the DOB picker).
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;

  /// Tap on the field itself (used by read-only pickers like DOB).
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    // ── Hairline edge colors by state ───────────────────────────────────
    // Focus wins over error (both can technically be true while typing in
    // an invalid field — focus is the "live" state, error stays readable
    // via the message below).
    final Color edgeTop = _focused
        ? AuthColors.fieldGlassBorderFocus
        : hasError
            ? AuthColors.fieldGlassBorderError
            : AuthColors.fieldGlassBorderTop;
    const Color edgeBottom = AuthColors.fieldGlassBorderBottom;

    // ── Fill gradient by hover state (single gradient, no layers) ───────
    final List<Color> fillColors = _hovered
        ? const [
            AuthColors.fieldGlassFillTopHover,
            AuthColors.fieldGlassFillBaseHover,
            AuthColors.fieldGlassFillBottomHover,
          ]
        : const [
            AuthColors.fieldGlassFillTop,
            AuthColors.fieldGlassFillBase,
            AuthColors.fieldGlassFillBottom,
          ];

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: AuthText.label),
          const SizedBox(height: 6),
          MouseRegion(
            cursor: widget.readOnly
                ? SystemMouseCursors.click
                : SystemMouseCursors.text,
            onEnter: (_) {
              if (!_hovered) setState(() => _hovered = true);
            },
            onExit: (_) {
              if (_hovered) setState(() => _hovered = false);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (widget.readOnly) {
                  widget.onTap?.call();
                } else {
                  if (!_focusNode.hasFocus) {
                    _focusNode.requestFocus();
                  }
                  widget.onTap?.call();
                }
              },
              child: AnimatedContainer(
                duration: AppMotion.fastOf(context),
                curve: AppMotion.curve,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // stops chosen so the sheen occupies only the top ~45% of
                    // the surface — the classic glass highlight position.
                    stops: const [0.0, 0.45, 1.0],
                    colors: fillColors,
                  ),
                ),
                child: CustomPaint(
                  // The edge (hairline + aberration fringes) paints ABOVE the
                  // fill gradient but BELOW nothing else — one unified surface.
                  foregroundPainter: ChromaticGlassBorderPainter(
                    radius: 10,
                    borderColorTop: edgeTop,
                    borderColorBottom: edgeBottom,
                  ),
                  child: RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: widget.controller,
                              focusNode: _focusNode,
                              obscureText: widget.obscure,
                              readOnly: widget.readOnly,
                              keyboardType: widget.keyboardType,
                              textInputAction: widget.textInputAction,
                              inputFormatters: widget.inputFormatters,
                              onChanged: widget.onChanged,
                              onSubmitted: widget.onSubmitted,
                              onTap: widget.onTap,
                              style: AuthText.fieldText,
                              cursorColor: AuthColors.accent,
                              // Keep desktop text selection controls default; the
                              // glass surface owns all visual chrome.
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: widget.hint,
                                hintStyle: AuthText.fieldHint,
                              ),
                            ),
                          ),
                          if (widget.suffixIcon != null)
                            GestureDetector(
                              onTap: widget.onSuffixTap,
                              child: MouseRegion(
                                cursor: widget.onSuffixTap != null
                                    ? SystemMouseCursors.click
                                    : MouseCursor.defer,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(
                                    widget.suffixIcon,
                                    size: 16,
                                    color: AuthColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(widget.errorText!, style: AuthText.errorText),
            ),
        ],
      ),
    );
  }
}
