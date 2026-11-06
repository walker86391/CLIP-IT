import 'package:flutter/material.dart';

import '../../subtitles/services/subtitle_font_registry.dart';

/// Curated font options for video branding and overlay typography.
class BrandingFontOption {
  const BrandingFontOption({
    required this.name,
    required this.displayName,
    required this.category,
  });

  final String name;
  final String displayName;
  final String category;
}

const List<BrandingFontOption> kBrandingFonts = [
  BrandingFontOption(name: 'Montserrat', displayName: 'Montserrat (Modern Bold)', category: 'Clean'),
  BrandingFontOption(name: 'Inter', displayName: 'Inter (Sleek Tech)', category: 'Clean'),
  BrandingFontOption(name: 'Impact', displayName: 'Impact (Viral & Punchy)', category: 'Bold'),
  BrandingFontOption(name: 'Bebas Neue', displayName: 'Bebas Neue (Tall Display)', category: 'Display'),
  BrandingFontOption(name: 'Arial Black', displayName: 'Arial Black (Heavy)', category: 'Bold'),
  BrandingFontOption(name: 'Cinzel', displayName: 'Cinzel (Cinematic Serif)', category: 'Serif'),
  BrandingFontOption(name: 'Roboto', displayName: 'Roboto (Standard)', category: 'Clean'),
  BrandingFontOption(name: 'Courier', displayName: 'Courier (Typewriter / Mono)', category: 'Mono'),
  BrandingFontOption(name: 'Georgia', displayName: 'Georgia (Classic Editorial)', category: 'Serif'),
];

/// Returns all available typography fonts: base branding fonts + all 48 custom fonts & creator families from SubtitleFontRegistry.
List<BrandingFontOption> get allAvailableBrandingFonts {
  final seen = <String>{};
  final list = <BrandingFontOption>[];

  // 1. Add base branding fonts first
  for (final bf in kBrandingFonts) {
    if (seen.add(bf.name.toLowerCase())) {
      list.add(bf);
    }
  }

  // 2. Add all custom, creator and discovered fonts from SubtitleFontRegistry
  for (final sf in SubtitleFontRegistry.registeredFonts) {
    if (seen.add(sf.family.toLowerCase())) {
      list.add(BrandingFontOption(
        name: sf.family,
        displayName: sf.displayName,
        category: sf.category,
      ));
    }
  }

  return list;
}

const List<Color> kBrandingColorSwatches = [
  Colors.white,
  Color(0xFF8B5CF6), // Purple
  Color(0xFF38BDF8), // Cyan
  Color(0xFF10B981), // Emerald
  Color(0xFFFACC15), // Yellow
  Color(0xFFF97316), // Orange
  Color(0xFFEF4444), // Red
  Color(0xFFEC4899), // Pink
  Color(0xFFE2E8F0), // Platinum
  Color(0xFF000000), // Black
];

/// Reusable typography and text styling section for Permanent Branding & Temporary Overlays.
class TypographyAppearanceSection extends StatefulWidget {
  const TypographyAppearanceSection({
    required this.text,
    required this.font,
    required this.fontSize,
    required this.fontWeight,
    required this.italic,
    required this.letterSpacing,
    required this.lineSpacing,
    required this.textColor,
    required this.underline,
    required this.strikethrough,
    required this.shadow,
    required this.shadowIntensity,
    required this.shadowDistance,
    required this.shadowSoftness,
    required this.glow,
    required this.glowIntensity,
    required this.glowColor,
    required this.neon,
    required this.alignment,
    required this.onTextChanged,
    required this.onFontChanged,
    required this.onFontSizeChanged,
    required this.onFontWeightChanged,
    required this.onItalicChanged,
    required this.onLetterSpacingChanged,
    required this.onLineSpacingChanged,
    required this.onTextColorChanged,
    required this.onUnderlineChanged,
    required this.onStrikethroughChanged,
    required this.onShadowChanged,
    required this.onShadowIntensityChanged,
    required this.onShadowDistanceChanged,
    required this.onShadowSoftnessChanged,
    required this.onGlowChanged,
    required this.onGlowIntensityChanged,
    required this.onGlowColorChanged,
    required this.onNeonChanged,
    required this.onAlignmentChanged,
    super.key,
  });

  final String text;
  final String font;
  final double fontSize;
  final FontWeight fontWeight;
  final bool italic;
  final double letterSpacing;
  final double lineSpacing;
  final Color textColor;
  final bool underline;
  final bool strikethrough;
  final bool shadow;
  final double shadowIntensity;
  final double shadowDistance;
  final double shadowSoftness;
  final bool glow;
  final double glowIntensity;
  final Color glowColor;
  final bool neon;
  final TextAlign alignment;

  final ValueChanged<String> onTextChanged;
  final ValueChanged<String> onFontChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<FontWeight> onFontWeightChanged;
  final ValueChanged<bool> onItalicChanged;
  final ValueChanged<double> onLetterSpacingChanged;
  final ValueChanged<double> onLineSpacingChanged;
  final ValueChanged<Color> onTextColorChanged;
  final ValueChanged<bool> onUnderlineChanged;
  final ValueChanged<bool> onStrikethroughChanged;
  final ValueChanged<bool> onShadowChanged;
  final ValueChanged<double> onShadowIntensityChanged;
  final ValueChanged<double> onShadowDistanceChanged;
  final ValueChanged<double> onShadowSoftnessChanged;
  final ValueChanged<bool> onGlowChanged;
  final ValueChanged<double> onGlowIntensityChanged;
  final ValueChanged<Color> onGlowColorChanged;
  final ValueChanged<bool> onNeonChanged;
  final ValueChanged<TextAlign> onAlignmentChanged;

  @override
  State<TypographyAppearanceSection> createState() =>
      _TypographyAppearanceSectionState();
}

class _TypographyAppearanceSectionState
    extends State<TypographyAppearanceSection> {
  late TextEditingController _textController;
  bool _isAppearanceExpanded = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.text);
  }

  @override
  void didUpdateWidget(covariant TypographyAppearanceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && _textController.text != widget.text) {
      _textController.text = widget.text;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Text Content Input ───────────────────────────────────────────────
        const Text(
          'TEXT CONTENT',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _textController,
          onChanged: widget.onTextChanged,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'Enter overlay text...',
            hintStyle: const TextStyle(color: Color(0xFF6B7280)),
            filled: true,
            fillColor: const Color(0xFF131420),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF23263B)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF23263B)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Font Selector & Size ─────────────────────────────────────────────
        Row(
          children: [
            // Font Family Dropdown
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FONT FAMILY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131420),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF23263B)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: allAvailableBrandingFonts.any((f) => f.name.toLowerCase() == widget.font.toLowerCase())
                            ? allAvailableBrandingFonts.firstWhere((f) => f.name.toLowerCase() == widget.font.toLowerCase()).name
                            : (allAvailableBrandingFonts.isNotEmpty ? allAvailableBrandingFonts.first.name : widget.font),
                        isExpanded: true,
                        dropdownColor: const Color(0xFF161828),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Color(0xFF9CA3AF)),
                        selectedItemBuilder: (context) {
                          return allAvailableBrandingFonts.map((f) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                f.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: SubtitleFontRegistry.getTextStyle(
                                  family: f.name,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        items: allAvailableBrandingFonts.map((f) {
                          return DropdownMenuItem<String>(
                            value: f.name,
                            child: Text(
                              f.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: SubtitleFontRegistry.getTextStyle(
                                family: f.name,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) widget.onFontChanged(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Font Size Numeric Box
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SIZE (PT)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131420),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF23263B)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => widget.onFontSizeChanged(
                              (widget.fontSize - 1).clamp(8.0, 72.0)),
                          child: const Icon(Icons.remove,
                              size: 14, color: Color(0xFF9CA3AF)),
                        ),
                        Text(
                          '${widget.fontSize.round()}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        InkWell(
                          onTap: () => widget.onFontSizeChanged(
                              (widget.fontSize + 1).clamp(8.0, 72.0)),
                          child: const Icon(Icons.add,
                              size: 14, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Font Size Slider
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            activeTrackColor: const Color(0xFF8B5CF6),
            inactiveTrackColor: const Color(0xFF23263A),
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
          ),
          child: Slider(
            value: widget.fontSize.clamp(8.0, 72.0),
            min: 8.0,
            max: 72.0,
            onChanged: widget.onFontSizeChanged,
          ),
        ),

        // ── Font Weights ─────────────────────────────────────────────────────
        const Text(
          'FONT WEIGHT',
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
            children: [
              _buildWeightChip('Light', FontWeight.w300),
              const SizedBox(width: 5),
              _buildWeightChip('Regular', FontWeight.w400),
              const SizedBox(width: 5),
              _buildWeightChip('Medium', FontWeight.w500),
              const SizedBox(width: 5),
              _buildWeightChip('Semibold', FontWeight.w600),
              const SizedBox(width: 5),
              _buildWeightChip('Bold', FontWeight.w700),
              const SizedBox(width: 5),
              _buildWeightChip('Heavy', FontWeight.w800),
              const SizedBox(width: 5),
              _buildWeightChip('Black', FontWeight.w900),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Formatting, Alignment & Spacing Row ──────────────────────────────
        Row(
          children: [
            // Formatting: Italic, Underline, Strikethrough
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF131420),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF23263B)),
              ),
              child: Row(
                children: [
                  _buildToggleIconButton(
                    icon: Icons.format_italic_rounded,
                    isActive: widget.italic,
                    tooltip: 'Italic',
                    onTap: () => widget.onItalicChanged(!widget.italic),
                  ),
                  _buildToggleIconButton(
                    icon: Icons.format_underlined_rounded,
                    isActive: widget.underline,
                    tooltip: 'Underline',
                    onTap: () => widget.onUnderlineChanged(!widget.underline),
                  ),
                  _buildToggleIconButton(
                    icon: Icons.format_strikethrough_rounded,
                    isActive: widget.strikethrough,
                    tooltip: 'Strikethrough',
                    onTap: () =>
                        widget.onStrikethroughChanged(!widget.strikethrough),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Alignment: Left, Center, Right
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF131420),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF23263B)),
              ),
              child: Row(
                children: [
                  _buildToggleIconButton(
                    icon: Icons.format_align_left_rounded,
                    isActive: widget.alignment == TextAlign.left,
                    tooltip: 'Align Left',
                    onTap: () => widget.onAlignmentChanged(TextAlign.left),
                  ),
                  _buildToggleIconButton(
                    icon: Icons.format_align_center_rounded,
                    isActive: widget.alignment == TextAlign.center,
                    tooltip: 'Align Center',
                    onTap: () => widget.onAlignmentChanged(TextAlign.center),
                  ),
                  _buildToggleIconButton(
                    icon: Icons.format_align_right_rounded,
                    isActive: widget.alignment == TextAlign.right,
                    tooltip: 'Align Right',
                    onTap: () => widget.onAlignmentChanged(TextAlign.right),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Letter Spacing & Line Spacing ────────────────────────────────────
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
                        'LETTER SPACING',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      Text(
                        widget.letterSpacing.toStringAsFixed(1),
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
                      value: widget.letterSpacing.clamp(-3.0, 10.0),
                      min: -3.0,
                      max: 10.0,
                      onChanged: widget.onLetterSpacingChanged,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'LINE SPACING',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      Text(
                        widget.lineSpacing.toStringAsFixed(1),
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
                      value: widget.lineSpacing.clamp(0.8, 2.5),
                      min: 0.8,
                      max: 2.5,
                      onChanged: widget.onLineSpacingChanged,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Text Color Picker Swatches ───────────────────────────────────────
        const Text(
          'TEXT COLOR',
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
            children: [
              ...kBrandingColorSwatches.map((color) {
                final isSelected = widget.textColor.toARGB32() == color.toARGB32();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => widget.onTextColorChanged(color),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF33364D),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: color.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Expandable Advanced Appearance (Shadow, Glow, Neon) ──────────────
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131420),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF222436)),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() {
                  _isAppearanceExpanded = !_isAppearanceExpanded;
                }),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 15,
                            color: (widget.shadow || widget.glow || widget.neon)
                                ? const Color(0xFFC4B5FD)
                                : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ADVANCED TEXT APPEARANCE',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Color(0xFFD1D5DB),
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _isAppearanceExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isAppearanceExpanded) ...[
                const Divider(height: 1, color: Color(0xFF23263B)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtle Shadow Toggle
                      _buildSwitchRow(
                        label: 'Drop Shadow',
                        value: widget.shadow,
                        onChanged: widget.onShadowChanged,
                      ),
                      if (widget.shadow) ...[
                        const SizedBox(height: 6),
                        _buildSubSlider(
                          label: 'Intensity',
                          value: widget.shadowIntensity,
                          min: 0.0,
                          max: 1.0,
                          onChanged: widget.onShadowIntensityChanged,
                        ),
                        _buildSubSlider(
                          label: 'Distance',
                          value: widget.shadowDistance,
                          min: 0.0,
                          max: 12.0,
                          onChanged: widget.onShadowDistanceChanged,
                        ),
                        _buildSubSlider(
                          label: 'Softness',
                          value: widget.shadowSoftness,
                          min: 0.0,
                          max: 15.0,
                          onChanged: widget.onShadowSoftnessChanged,
                        ),
                        const SizedBox(height: 8),
                      ],

                      const Divider(height: 12, color: Color(0xFF1E2032)),

                      // Glow Toggle
                      _buildSwitchRow(
                        label: 'Aura Glow',
                        value: widget.glow,
                        onChanged: widget.onGlowChanged,
                      ),
                      if (widget.glow) ...[
                        const SizedBox(height: 6),
                        _buildSubSlider(
                          label: 'Glow Intensity',
                          value: widget.glowIntensity,
                          min: 0.1,
                          max: 1.0,
                          onChanged: widget.onGlowIntensityChanged,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              'Glow Color:',
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xFF9CA3AF)),
                            ),
                            const SizedBox(width: 8),
                            _buildColorMiniDot(const Color(0xFF8B5CF6)),
                            const SizedBox(width: 5),
                            _buildColorMiniDot(const Color(0xFF38BDF8)),
                            const SizedBox(width: 5),
                            _buildColorMiniDot(const Color(0xFF10B981)),
                            const SizedBox(width: 5),
                            _buildColorMiniDot(const Color(0xFFEF4444)),
                            const SizedBox(width: 5),
                            _buildColorMiniDot(const Color(0xFFFACC15)),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      const Divider(height: 12, color: Color(0xFF1E2032)),

                      // Neon Effect Toggle
                      _buildSwitchRow(
                        label: 'Neon Sign Effect',
                        value: widget.neon,
                        onChanged: widget.onNeonChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightChip(String label, FontWeight weight) {
    final isSelected = widget.fontWeight == weight;
    return InkWell(
      onTap: () => widget.onFontWeightChanged(weight),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B5CF6)
              : const Color(0xFF131420),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC4B5FD)
                : const Color(0xFF23263B),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: weight,
            color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleIconButton({
    required IconData icon,
    required bool isActive,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive ? const Color(0xFFC4B5FD) : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF8B5CF6),
          activeTrackColor: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
          inactiveThumbColor: const Color(0xFF6B7280),
          inactiveTrackColor: const Color(0xFF1E2032),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildSubSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              activeTrackColor: const Color(0xFF8B5CF6),
              inactiveTrackColor: const Color(0xFF23263A),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            value.toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 9.5, color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildColorMiniDot(Color color) {
    final isSelected = widget.glowColor.toARGB32() == color.toARGB32();
    return InkWell(
      onTap: () => widget.onGlowColorChanged(color),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
