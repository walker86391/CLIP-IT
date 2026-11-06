import 'package:flutter/material.dart';

import 'video_look_slider_row.dart';

/// Interactive visual color swatch and picker.
/// Avoids forcing users to type hexadecimal strings.
/// Provides instant visual selection from curated palette swatches and custom picker.
class VideoLookColorPicker extends StatelessWidget {
  const VideoLookColorPicker({
    required this.color,
    required this.onColorChanged,
    this.title = 'Select Color',
    super.key,
  });

  final Color color;
  final ValueChanged<Color> onColorChanged;
  final String title;

  static const List<Color> curatedPalette = [
    // Cool & Cinematic Shadows
    Color(0xFF0F172A),
    Color(0xFF1E1B4B),
    Color(0xFF0C4A6E),
    Color(0xFF064E3B),
    Color(0xFF311042),
    // Midtones & Vibrance
    Color(0xFF3B82F6),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF43F5E),
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF06B6D4),
    // Warm Highlights & Creams
    Color(0xFFFEF3C7),
    Color(0xFFFEF08A),
    Color(0xFFFFFBEB),
    Color(0xFFE0F2FE),
    Color(0xFFF3F4F6),
    Colors.white,
    Colors.black,
  ];

  void _showColorPickerModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return _ColorPickerDialog(
          initialColor: color,
          title: title,
          onSelected: (newColor) {
            onColorChanged(newColor);
            Navigator.of(ctx).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showColorPickerModal(context),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.colorize_rounded,
              size: 14,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

/// Combined Row: [Label] [Color Swatch] [Intensity Slider] [Number Box]
class VideoLookColorIntensityRow extends StatelessWidget {
  const VideoLookColorIntensityRow({
    required this.label,
    required this.color,
    required this.onColorChanged,
    required this.intensity,
    required this.onIntensityChanged,
    super.key,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onColorChanged;
  final double intensity;
  final ValueChanged<double> onIntensityChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Color Swatch Button
          VideoLookColorPicker(
            color: color,
            onColorChanged: onColorChanged,
            title: label,
          ),
          const SizedBox(width: 10),

          // Intensity Slider + Number Input
          Expanded(
            child: VideoLookSliderRow(
              label: label,
              value: intensity,
              min: 0.0,
              max: 100.0,
              defaultValue: 0.0,
              onChanged: onIntensityChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({
    required this.initialColor,
    required this.title,
    required this.onSelected,
  });

  final Color initialColor;
  final String title;
  final ValueChanged<Color> onSelected;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _currentColor;
  late double _hue;
  late double _saturation;
  late double _value;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  void _updateFromHsv() {
    setState(() {
      _currentColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF131522),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF26283C), width: 1.0),
      ),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF3F4F8),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _currentColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Curated Quick Palette Swatches
            const Text(
              'CURATED PALETTE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VideoLookColorPicker.curatedPalette.map((c) {
                final isSelected = c.toARGB32() == _currentColor.toARGB32();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentColor = c;
                      final hsv = HSVColor.fromColor(c);
                      _hue = hsv.hue;
                      _saturation = hsv.saturation;
                      _value = hsv.value;
                    });
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white12,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(Icons.check, size: 14, color: Colors.white),
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),
            const Divider(color: Color(0xFF26283C), height: 1),
            const SizedBox(height: 14),

            // Visual Hue Slider
            const Text(
              'HUE SPECTRUM',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF9CA3AF),
              ),
            ),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 12,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                value: _hue,
                min: 0.0,
                max: 360.0,
                onChanged: (val) {
                  _hue = val;
                  _updateFromHsv();
                },
              ),
            ),

            // Saturation Slider
            const Text(
              'SATURATION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF9CA3AF),
              ),
            ),
            Slider(
              value: _saturation,
              min: 0.0,
              max: 1.0,
              activeColor: const Color(0xFF8B5CF6),
              onChanged: (val) {
                _saturation = val;
                _updateFromHsv();
              },
            ),

            // Brightness / Value Slider
            const Text(
              'SHADE / BRIGHTNESS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF9CA3AF),
              ),
            ),
            Slider(
              value: _value,
              min: 0.0,
              max: 1.0,
              activeColor: const Color(0xFF8B5CF6),
              onChanged: (val) {
                _value = val;
                _updateFromHsv();
              },
            ),

            const SizedBox(height: 14),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => widget.onSelected(_currentColor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Apply Color'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
