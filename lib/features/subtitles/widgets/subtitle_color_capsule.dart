import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subtitle_models.dart';
import '../providers/subtitle_studio_provider.dart';
import 'subtitle_color_palette_picker.dart';

/// Segmented Color Capsule that shows all currently active colors in the selected preset.
///
/// Clicking a segment opens a popover color editor to modify the color via swatches,
/// hex code input, and reset to original preset color.
class SubtitleColorCapsule extends ConsumerWidget {
  const SubtitleColorCapsule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studioState = ref.watch(subtitleStudioProvider);
    final config = studioState.activeConfig;

    final segments = <_ColorSegmentData>[];

    // 1. Primary Text Color (always present)
    segments.add(_ColorSegmentData(
      id: 'primary',
      label: 'Text',
      color: config.primaryTextColor,
      originalColor: studioState.selectedPreset.defaultConfig.primaryTextColor,
      onChanged: (color) =>
          ref.read(subtitleStudioProvider.notifier).updateColors(primaryTextColor: color),
    ));

    // 2. Active Highlight Color
    if (config.emphasisMode != SubtitleEmphasisMode.none) {
      segments.add(_ColorSegmentData(
        id: 'highlight',
        label: 'Highlight',
        color: config.highlightColor,
        originalColor: studioState.selectedPreset.defaultConfig.highlightColor,
        onChanged: (color) =>
            ref.read(subtitleStudioProvider.notifier).updateColors(highlightColor: color),
      ));
    }

    // 3. Outline Color (only if preset supports outline)
    if (config.supportsOutline) {
      segments.add(_ColorSegmentData(
        id: 'outline',
        label: 'Outline',
        color: config.outlineColor,
        originalColor: studioState.selectedPreset.defaultConfig.outlineColor,
        onChanged: (color) =>
            ref.read(subtitleStudioProvider.notifier).updateColors(outlineColor: color),
      ));
    }

    // 4. Glow Color (if preset supports glow or hasGlow is enabled)
    if (config.supportsGlow || config.hasGlow) {
      segments.add(_ColorSegmentData(
        id: 'glow',
        label: 'Glow',
        color: config.glowColor,
        originalColor: studioState.selectedPreset.defaultConfig.glowColor,
        onChanged: (color) =>
            ref.read(subtitleStudioProvider.notifier).updateColors(glowColor: color),
      ));
    }

    // 5. Shadow Color (only if preset supports shadow)
    if (config.supportsShadow) {
      segments.add(_ColorSegmentData(
        id: 'shadow',
        label: 'Shadow',
        color: config.shadowColor,
        originalColor: studioState.selectedPreset.defaultConfig.shadowColor,
        onChanged: (color) =>
            ref.read(subtitleStudioProvider.notifier).updateColors(shadowColor: color),
      ));
    }

    // 6. Box Color (only if boxed word mode is active)
    if (config.emphasisMode == SubtitleEmphasisMode.boxedWord) {
      segments.add(_ColorSegmentData(
        id: 'box',
        label: 'Box',
        color: config.boxColor,
        originalColor: studioState.selectedPreset.defaultConfig.boxColor,
        onChanged: (color) =>
            ref.read(subtitleStudioProvider.notifier).updateColors(boxColor: color),
      ));
    }

    // 7. Underline Color (only if underline mode is active)
    if (config.emphasisMode == SubtitleEmphasisMode.underline ||
        config.markerStyle == SubtitleMarkerStyle.singleUnderline ||
        config.markerStyle == SubtitleMarkerStyle.animatedUnderline) {
      segments.add(_ColorSegmentData(
        id: 'underline',
        label: 'Line',
        color: config.underlineColor,
        originalColor: studioState.selectedPreset.defaultConfig.underlineColor,
        onChanged: (color) =>
            ref.read(subtitleStudioProvider.notifier).updateColors(underlineColor: color),
      ));
    }

    // 8. Marker Color (when any advanced marker is active)
    if (config.isMarkerActive &&
        config.markerStyle != SubtitleMarkerStyle.none &&
        config.markerStyle != SubtitleMarkerStyle.filledBox &&
        config.markerStyle != SubtitleMarkerStyle.singleUnderline &&
        config.markerStyle != SubtitleMarkerStyle.animatedUnderline) {
      segments.add(_ColorSegmentData(
        id: 'marker',
        label: 'Marker',
        color: config.effectiveMarkerColor,
        originalColor: studioState.selectedPreset.defaultConfig.effectiveMarkerColor,
        onChanged: (color) =>
            ref.read(subtitleStudioProvider.notifier).updateMarker(markerColor: color),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13141F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF282B3E),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: segments.map((seg) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  _showColorEditorDialog(context, seg);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1C29),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF33374D),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: seg.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: seg.color.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        seg.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showColorEditorDialog(BuildContext context, _ColorSegmentData segment) async {
    final picked = await SubtitleColorPickerDialog.show(
      context: context,
      initialColor: segment.color,
      title: 'Edit ${segment.label} Color',
      originalColor: segment.originalColor,
    );
    if (picked != null) {
      segment.onChanged(picked);
    }
  }

  /// Public static helper to open color picker dialog anywhere in Subtitle Studio.
  static Future<void> showEditor({
    required BuildContext context,
    required String label,
    required Color color,
    required Color originalColor,
    required ValueChanged<Color> onChanged,
  }) async {
    final picked = await SubtitleColorPickerDialog.show(
      context: context,
      initialColor: color,
      title: 'Edit $label Color',
      originalColor: originalColor,
    );
    if (picked != null) {
      onChanged(picked);
    }
  }
}

class _ColorSegmentData {
  _ColorSegmentData({
    required this.id,
    required this.label,
    required this.color,
    required this.originalColor,
    required this.onChanged,
  });

  final String id;
  final String label;
  final Color color;
  final Color originalColor;
  final ValueChanged<Color> onChanged;
}

/// In-editor color picker dialog with preset swatches, hex input, and reset button.
class _InEditorColorPickerDialog extends StatefulWidget {
  const _InEditorColorPickerDialog({required this.segment});

  final _ColorSegmentData segment;

  @override
  State<_InEditorColorPickerDialog> createState() =>
      _InEditorColorPickerDialogState();
}

class _InEditorColorPickerDialogState
    extends State<_InEditorColorPickerDialog> {
  late Color _currentColor;
  late TextEditingController _hexController;

  late double _hue;
  late double _saturation;
  late double _value;

  // 0: Custom Mixer, 1: Quick Swatches
  int _tabIndex = 0;

  static const List<Color> _swatches = [
    Color(0xFFFFFFFF), // White
    Color(0xFFFFFF00), // Yellow
    Color(0xFF00FF66), // Neon Green
    Color(0xFF00E5FF), // Cyan
    Color(0xFFFF3366), // Neon Pink
    Color(0xFFFF6600), // Orange
    Color(0xFFFF0033), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFFACC15), // Gold
    Color(0xFF9CA3AF), // Silver/Gray
    Color(0xFF1F2937), // Dark Charcoal
    Color(0xFF000000), // Pitch Black
  ];

  @override
  void initState() {
    super.initState();
    _currentColor = widget.segment.color;
    final hsv = HSVColor.fromColor(_currentColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
    _hexController = TextEditingController(text: _colorToHex(_currentColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  }

  void _updateColor(Color newColor, {bool syncHsv = true}) {
    setState(() {
      _currentColor = newColor;
      _hexController.text = _colorToHex(newColor);
      if (syncHsv) {
        final hsv = HSVColor.fromColor(newColor);
        _hue = hsv.hue;
        _saturation = hsv.saturation;
        _value = hsv.value;
      }
    });
    widget.segment.onChanged(newColor);
  }

  void _onHsvChanged() {
    final newColor = HSVColor.fromAHSV(
      1.0,
      _hue,
      _saturation.clamp(0.0, 1.0),
      _value.clamp(0.0, 1.0),
    ).toColor();
    _updateColor(newColor, syncHsv: false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF121420),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF2A2D40), width: 1.0),
      ),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with current color bubble
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _currentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _currentColor.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.segment.label} Color',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF3F4F8),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: const Color(0xFF9CA3AF),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Segmented Tab Switcher: Custom Mixer vs Swatches
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0C0D17),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF23263B), width: 1.0),
              ),
              padding: const EdgeInsets.all(2),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tabIndex = 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _tabIndex == 0
                              ? const Color(0xFF282B42)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Custom Mixer',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _tabIndex == 0
                                ? Colors.white
                                : const Color(0xFF8C93A8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tabIndex = 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _tabIndex == 1
                              ? const Color(0xFF282B42)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Preset Swatches',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _tabIndex == 1
                                ? Colors.white
                                : const Color(0xFF8C93A8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            if (_tabIndex == 0) ...[
              // ── Tab 0: Custom Color Mixer (Hue, Saturation, Brightness) ──
              _buildMixerSlider(
                label: 'HUE SPECTRUM',
                value: _hue,
                min: 0.0,
                max: 360.0,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF0000),
                    Color(0xFFFFFF00),
                    Color(0xFF00FF00),
                    Color(0xFF00FFFF),
                    Color(0xFF0000FF),
                    Color(0xFFFF00FF),
                    Color(0xFFFF0000),
                  ],
                ),
                onChanged: (v) {
                  setState(() => _hue = v);
                  _onHsvChanged();
                },
              ),
              const SizedBox(height: 10),
              _buildMixerSlider(
                label: 'SATURATION',
                value: _saturation,
                min: 0.0,
                max: 1.0,
                gradient: LinearGradient(
                  colors: [
                    HSVColor.fromAHSV(1.0, _hue, 0.0, _value.clamp(0.2, 1.0)).toColor(),
                    HSVColor.fromAHSV(1.0, _hue, 1.0, _value.clamp(0.2, 1.0)).toColor(),
                  ],
                ),
                onChanged: (v) {
                  setState(() => _saturation = v);
                  _onHsvChanged();
                },
              ),
              const SizedBox(height: 10),
              _buildMixerSlider(
                label: 'BRIGHTNESS',
                value: _value,
                min: 0.0,
                max: 1.0,
                gradient: LinearGradient(
                  colors: [
                    Colors.black,
                    HSVColor.fromAHSV(1.0, _hue, _saturation, 1.0).toColor(),
                  ],
                ),
                onChanged: (v) {
                  setState(() => _value = v);
                  _onHsvChanged();
                },
              ),
            ] else ...[
              // ── Tab 1: Palette Swatches ──
              const Text(
                'PALETTE SWATCHES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Color(0xFF7B8196),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _swatches.map((swatch) {
                  final isSelected =
                      swatch.toARGB32() == _currentColor.toARGB32();
                  return GestureDetector(
                    onTap: () => _updateColor(swatch),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: swatch,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8B5CF6)
                                : Colors.white.withValues(alpha: 0.25),
                            width: isSelected ? 2.4 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: swatch.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 14),

            // Hex Code Input
            Row(
              children: [
                const Text(
                  'HEX COLOR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFF7B8196),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _currentColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0B0C14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF26293A),
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Text(
                    '#',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _hexController,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (text) {
                        final clean = text.replaceAll('#', '').trim();
                        if (clean.length == 6) {
                          final parsed = int.tryParse('FF$clean', radix: 16);
                          if (parsed != null) {
                            final col = Color(parsed);
                            _updateColor(col);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bottom Actions: Reset to Preset & Done
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _updateColor(widget.segment.originalColor);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text(
                    'Reset to Preset',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF9CA3AF),
                    padding: EdgeInsets.zero,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMixerSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Gradient gradient,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF7B8196),
              ),
            ),
            Text(
              max <= 1.0 ? '${(value * 100).toInt()}%' : '${value.toInt()}°',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC4B5FD),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: gradient,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 0.8,
                ),
              ),
            ),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 12,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 7,
                  elevation: 2,
                ),
                overlayColor: Colors.white.withValues(alpha: 0.2),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
