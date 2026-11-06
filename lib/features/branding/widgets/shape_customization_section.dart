import 'package:flutter/material.dart';

import '../models/branding_models.dart';
import 'typography_appearance_section.dart'; // For color swatches

/// Detailed shape and container framing controls for Temporary Overlays.
class ShapeCustomizationSection extends StatelessWidget {
  const ShapeCustomizationSection({
    required this.shape,
    required this.shapeColor,
    required this.shapeSize,
    required this.lineLength,
    required this.borderThickness,
    required this.borderStyle,
    required this.cornerRadius,
    required this.fill,
    required this.fillColor,
    required this.onShapeChanged,
    required this.onShapeColorChanged,
    required this.onShapeSizeChanged,
    required this.onLineLengthChanged,
    required this.onBorderThicknessChanged,
    required this.onBorderStyleChanged,
    required this.onCornerRadiusChanged,
    required this.onFillChanged,
    required this.onFillColorChanged,
    super.key,
  });

  final OverlayShapeType shape;
  final Color shapeColor;
  final double shapeSize;
  final double lineLength;
  final double borderThickness;
  final OverlayBorderStyle borderStyle;
  final double cornerRadius;
  final bool fill;
  final Color fillColor;

  final ValueChanged<OverlayShapeType> onShapeChanged;
  final ValueChanged<Color> onShapeColorChanged;
  final ValueChanged<double> onShapeSizeChanged;
  final ValueChanged<double> onLineLengthChanged;
  final ValueChanged<double> onBorderThicknessChanged;
  final ValueChanged<OverlayBorderStyle> onBorderStyleChanged;
  final ValueChanged<double> onCornerRadiusChanged;
  final ValueChanged<bool> onFillChanged;
  final ValueChanged<Color> onFillColorChanged;

  @override
  Widget build(BuildContext context) {
    final isLine = shape == OverlayShapeType.verticalLine;
    final isBox = shape == OverlayShapeType.rectangle ||
        shape == OverlayShapeType.roundedRectangle ||
        shape == OverlayShapeType.square;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131420),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF222436),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SHAPE & CONTAINER STYLING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              Text(
                shape.displayName,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC4B5FD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Shape Type Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: OverlayShapeType.values.map((s) {
                final isSelected = shape == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => onShapeChanged(s),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF0F101A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFC4B5FD)
                              : const Color(0xFF23263B),
                          width: isSelected ? 1.2 : 0.8,
                        ),
                      ),
                      child: Text(
                        s.displayName,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color:
                              isSelected ? Colors.white : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Line Length Control (Mandatory for Vertical Line styles)
          if (isLine) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'VERTICAL LINE LENGTH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                Text(
                  '${lineLength.round()} px (~${(lineLength / 37.8).toStringAsFixed(1)} cm)',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC4B5FD),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                activeTrackColor: const Color(0xFF8B5CF6),
                inactiveTrackColor: const Color(0xFF23263A),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: lineLength.clamp(30.0, 240.0),
                min: 30.0,
                max: 240.0,
                onChanged: onLineLengthChanged,
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Shape Size (if not a pure line)
          if (!isLine) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SHAPE SIZE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                Text(
                  '${shapeSize.round()} px',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC4B5FD),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                activeTrackColor: const Color(0xFF8B5CF6),
                inactiveTrackColor: const Color(0xFF23263A),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: shapeSize.clamp(16.0, 140.0),
                min: 16.0,
                max: 140.0,
                onChanged: onShapeSizeChanged,
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Shape Color Picker Swatches
          const Text(
            'SHAPE / ACCENT COLOR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: kBrandingColorSwatches.map((color) {
                final isSelected = shapeColor.toARGB32() == color.toARGB32();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => onShapeColorChanged(color),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF33364D),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 13,
                              color: color.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Border Controls
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'BORDER THICKNESS',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        Text(
                          '${borderThickness.toStringAsFixed(1)}px',
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFFC4B5FD)),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2.5,
                        activeTrackColor: const Color(0xFF8B5CF6),
                        inactiveTrackColor: const Color(0xFF23263A),
                        thumbColor: Colors.white,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 5),
                      ),
                      child: Slider(
                        value: borderThickness.clamp(0.5, 8.0),
                        min: 0.5,
                        max: 8.0,
                        onChanged: onBorderThicknessChanged,
                      ),
                    ),
                  ],
                ),
              ),
              if (shape == OverlayShapeType.roundedRectangle) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CORNER RADIUS',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          Text(
                            '${cornerRadius.round()}px',
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFFC4B5FD)),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2.5,
                          activeTrackColor: const Color(0xFF8B5CF6),
                          inactiveTrackColor: const Color(0xFF23263A),
                          thumbColor: Colors.white,
                          thumbShape:
                              const RoundSliderThumbShape(enabledThumbRadius: 5),
                        ),
                        child: Slider(
                          value: cornerRadius.clamp(0.0, 24.0),
                          min: 0.0,
                          max: 24.0,
                          onChanged: onCornerRadiusChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Fill Toggle & Fill Color (for Box/Shape containers)
          if (isBox) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CONTAINER FILL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                Switch(
                  value: fill,
                  onChanged: onFillChanged,
                  activeThumbColor: const Color(0xFF8B5CF6),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
