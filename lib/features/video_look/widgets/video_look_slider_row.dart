import 'package:flutter/material.dart';

/// Reusable Slider + Number Input control for numerical visual adjustments.
///
/// Specification:
/// - Supports negative values (e.g. -100 to +100)
/// - Supports positive values
/// - Supports decimal values (e.g. 12.5)
/// - Direct numerical typing in the input box
/// - Dragging the slider updates the number box immediately
/// - Typing in the number box updates the slider immediately
/// - Double-clicking label or reset dot resets to [defaultValue]
class VideoLookSliderRow extends StatefulWidget {
  const VideoLookSliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = -100.0,
    this.max = 100.0,
    this.defaultValue = 0.0,
    this.step = 0.5,
    this.decimals = 1,
    this.unit,
    super.key,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double defaultValue;
  final double step;
  final int decimals;
  final String? unit;

  @override
  State<VideoLookSliderRow> createState() => _VideoLookSliderRowState();
}

class _VideoLookSliderRowState extends State<VideoLookSliderRow> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  bool _isHovered = false;
  bool _isResetHovered = false;
  bool _isResetPressed = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _formatValue(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant VideoLookSliderRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      final formatted = _formatValue(widget.value);
      if (_textController.text != formatted) {
        _textController.text = formatted;
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitTextValue();
    }
  }

  String _formatValue(double val) {
    if (widget.decimals == 0) {
      return val.round().toString();
    }
    return val.toStringAsFixed(widget.decimals);
  }

  void _commitTextValue() {
    final parsed = double.tryParse(_textController.text.trim());
    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
      _textController.text = _formatValue(clamped);
    } else {
      _textController.text = _formatValue(widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isModified = (widget.value - widget.defaultValue).abs() > 0.001;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Label and Reset affordance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onDoubleTap: () => widget.onChanged(widget.defaultValue),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isModified ? FontWeight.w700 : FontWeight.w500,
                      color: isModified ? const Color(0xFFF3F4F8) : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                if (isModified)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _isResetHovered = true),
                    onExit: (_) => setState(() => _isResetHovered = false),
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _isResetPressed = true),
                      onTapUp: (_) => setState(() => _isResetPressed = false),
                      onTapCancel: () => setState(() => _isResetPressed = false),
                      onTap: () => widget.onChanged(widget.defaultValue),
                      child: Tooltip(
                        message: 'Reset to default (${widget.defaultValue})',
                        child: AnimatedScale(
                          scale: _isResetPressed
                              ? 0.88
                              : (_isResetHovered ? 1.15 : 1.0),
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOutCubic,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _isResetHovered
                                  ? const Color(0xFF2E274A)
                                  : const Color(0xFF1E2032),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _isResetHovered
                                    ? const Color(0xFF8B5CF6)
                                    : const Color(0xFF2E3146),
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              Icons.refresh_rounded,
                              size: 11,
                              color: _isResetHovered
                                  ? const Color(0xFFC4B5FD)
                                  : const Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),

            // Bottom Row: Slider + Text Input Box
            Row(
              children: [
                // Slider
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3.2,
                      activeTrackColor: const Color(0xFF8B5CF6),
                      inactiveTrackColor: const Color(0xFF26283C),
                      thumbColor: Colors.white,
                      overlayColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6.0,
                        elevation: 2.0,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12.0,
                      ),
                    ),
                    child: Slider(
                      value: widget.value.clamp(widget.min, widget.max),
                      min: widget.min,
                      max: widget.max,
                      onChanged: (val) {
                        widget.onChanged(val);
                        _textController.text = _formatValue(val);
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Numerical Direct Input Box
                Container(
                  width: 58,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF131422),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _focusNode.hasFocus
                          ? const Color(0xFF8B5CF6)
                          : (_isHovered ? const Color(0xFF383B52) : const Color(0xFF26283C)),
                      width: 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF3F4F8),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    onSubmitted: (_) => _commitTextValue(),
                    onChanged: (text) {
                      final val = double.tryParse(text);
                      if (val != null) {
                        widget.onChanged(val.clamp(widget.min, widget.max));
                      }
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      suffixText: widget.unit,
                      suffixStyle: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }
}
