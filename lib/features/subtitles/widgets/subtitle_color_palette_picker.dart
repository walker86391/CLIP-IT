import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Predefined curated colour palette.
class CuratedColorPalette {
  const CuratedColorPalette({
    required this.name,
    required this.colors,
    this.description,
  });

  final String name;
  final List<Color> colors;
  final String? description;
}

/// Global manager maintaining recent colors and user-saved palettes throughout the session.
class SubtitleColorHistoryManager {
  SubtitleColorHistoryManager._();

  static final SubtitleColorHistoryManager instance = SubtitleColorHistoryManager._();

  static final List<Color> _recentColors = [
    const Color(0xFFFFFFFF),
    const Color(0xFFFFE600),
    const Color(0xFF22C55E),
    const Color(0xFF06B6D4),
    const Color(0xFFEF4444),
    const Color(0xFF8B5CF6),
    const Color(0xFFF97316),
    const Color(0xFFEC4899),
  ];

  static final List<CuratedColorPalette> _curatedPalettes = [
    const CuratedColorPalette(
      name: 'Viral High-Contrast',
      description: 'Signature MrBeast & Shorts punchy captions',
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFFFE600),
        Color(0xFF22C55E),
        Color(0xFFEF4444),
        Color(0xFF000000),
      ],
    ),
    const CuratedColorPalette(
      name: 'Hormozi Lime & Gold',
      description: 'Business & educational high-retention captions',
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFF84CC16),
        Color(0xFFEAB308),
        Color(0xFF10B981),
        Color(0xFF0F172A),
      ],
    ),
    const CuratedColorPalette(
      name: 'Cyberpunk & Electric',
      description: 'Gaming, tech & futuristic videos',
      colors: [
        Color(0xFF00F0FF),
        Color(0xFFFF0055),
        Color(0xFF7000FF),
        Color(0xFF00FF66),
        Color(0xFF0D0E15),
      ],
    ),
    const CuratedColorPalette(
      name: 'Cinematic Gold & Slate',
      description: 'Documentary, dramatic and film noir titles',
      colors: [
        Color(0xFFF59E0B),
        Color(0xFFFCD34D),
        Color(0xFFE2E8F0),
        Color(0xFF64748B),
        Color(0xFF0F172A),
      ],
    ),
    const CuratedColorPalette(
      name: 'Editorial Minimal',
      description: 'Clean aesthetic, podcasts & lifestyle vlogs',
      colors: [
        Color(0xFFF8FAFC),
        Color(0xFFCBD5E1),
        Color(0xFF38BDF8),
        Color(0xFF818CF8),
        Color(0xFF1E293B),
      ],
    ),
    const CuratedColorPalette(
      name: 'Pastel Pop',
      description: 'Friendly, warm and soft creator vibes',
      colors: [
        Color(0xFFFDE68A),
        Color(0xFFF472B6),
        Color(0xFFA78BFA),
        Color(0xFF6EE7B7),
        Color(0xFF3B82F6),
      ],
    ),
  ];

  static final List<CuratedColorPalette> _savedUserPalettes = [];

  List<Color> get recentColors => List.unmodifiable(_recentColors);
  List<CuratedColorPalette> get curatedPalettes => List.unmodifiable(_curatedPalettes);
  List<CuratedColorPalette> get savedUserPalettes => List.unmodifiable(_savedUserPalettes);

  void recordColor(Color color) {
    if (color == Colors.transparent || color.a == 0) return;
    _recentColors.removeWhere((c) => c.toARGB32() == color.toARGB32());
    _recentColors.insert(0, color);
    if (_recentColors.length > 16) {
      _recentColors.removeLast();
    }
  }

  void saveUserPalette(String name, List<Color> colors) {
    if (name.trim().isEmpty || colors.isEmpty) return;
    _savedUserPalettes.removeWhere((p) => p.name.toLowerCase() == name.trim().toLowerCase());
    _savedUserPalettes.add(CuratedColorPalette(
      name: name.trim(),
      description: 'Custom saved palette',
      colors: List.from(colors),
    ));
  }
}

/// Advanced modal color picker featuring Recommended Palettes, Recent Colors,
/// Interactive Spectrum, HEX input, and RGB sliders.
class SubtitleColorPickerDialog extends StatefulWidget {
  const SubtitleColorPickerDialog({
    required this.initialColor,
    required this.title,
    this.originalColor,
    this.enableAlpha = true,
    super.key,
  });

  final Color initialColor;
  final String title;
  final Color? originalColor;
  final bool enableAlpha;

  static Future<Color?> show({
    required BuildContext context,
    required Color initialColor,
    required String title,
    Color? originalColor,
    bool enableAlpha = true,
  }) {
    return showDialog<Color>(
      context: context,
      barrierDismissible: true,
      builder: (context) => SubtitleColorPickerDialog(
        initialColor: initialColor,
        title: title,
        originalColor: originalColor,
        enableAlpha: enableAlpha,
      ),
    );
  }

  @override
  State<SubtitleColorPickerDialog> createState() => _SubtitleColorPickerDialogState();
}

class _SubtitleColorPickerDialogState extends State<SubtitleColorPickerDialog> {
  late Color _currentColor;
  late TextEditingController _hexController;
  late TextEditingController _paletteNameController;
  int _activeTab = 0; // 0: Curated, 1: Spectrum, 2: RGB

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _hexController = TextEditingController(text: _formatHex(_currentColor));
    _paletteNameController = TextEditingController();
  }

  @override
  void dispose() {
    _hexController.dispose();
    _paletteNameController.dispose();
    super.dispose();
  }

  String _formatHex(Color color) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    if (!widget.enableAlpha || color.a == 1.0) {
      return '#${hex.substring(2)}';
    }
    return '#$hex';
  }

  void _setColor(Color color) {
    setState(() {
      _currentColor = color;
      _hexController.text = _formatHex(color);
    });
  }

  void _onHexSubmitted(String value) {
    var clean = value.replaceAll('#', '').trim();
    if (clean.length == 6) {
      clean = 'FF$clean';
    }
    if (clean.length == 8) {
      final intVal = int.tryParse(clean, radix: 16);
      if (intVal != null) {
        _setColor(Color(intVal));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF10121C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF26293D), width: 1.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Header ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _currentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1.0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF3F4F8),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9CA3AF)),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Tab Bar (Curated / Spectrum / RGB) ─────────────────────────
              Container(
                height: 34,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF161826),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF26293D)),
                ),
                child: Row(
                  children: [
                    _buildTabButton(0, 'Curated Palettes', Icons.palette_outlined),
                    _buildTabButton(1, 'Spectrum', Icons.gradient_rounded),
                    _buildTabButton(2, 'Sliders & RGB', Icons.tune_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Main Tab Content ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: _buildActiveTabContent(),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(color: Color(0xFF222538), height: 1),
              const SizedBox(height: 12),

              // ── Recently Used Colors Row ──────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECENTLY USED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: SubtitleColorHistoryManager.instance.recentColors.map((c) {
                      final isSelected = c.toARGB32() == _currentColor.toARGB32();
                      return GestureDetector(
                        onTap: () => _setColor(c),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF33374D),
                              width: isSelected ? 2.5 : 1.0,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Color Swatch & HEX Input ──────────────────────────────────
              Row(
                children: [
                  // Before / After Preview Swatches
                  Container(
                    width: 48,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2D3148)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        if (widget.originalColor != null)
                          Expanded(
                            child: Container(color: widget.originalColor),
                          ),
                        Expanded(
                          child: Container(color: _currentColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // HEX Input Field
                  Expanded(
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141624),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2B2E42)),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'HEX',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _hexController,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF3F4F8),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: _onHexSubmitted,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF9CA3AF)),
                            tooltip: 'Copy HEX',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _hexController.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  duration: Duration(milliseconds: 900),
                                  content: Text('Color hex copied to clipboard'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Action Buttons ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.originalColor != null)
                    TextButton(
                      onPressed: () => _setColor(widget.originalColor!),
                      child: const Text('Reset', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2B2E42)),
                      foregroundColor: const Color(0xFFD1D5DB),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      SubtitleColorHistoryManager.instance.recordColor(_currentColor);
                      Navigator.of(context).pop(_currentColor);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Apply Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: isSelected ? Colors.white : const Color(0xFF9CA3AF)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildCuratedPalettesTab();
      case 1:
        return _buildSpectrumTab();
      case 2:
      default:
        return _buildRgbSlidersTab();
    }
  }

  // ── Tab 0: Curated Palettes ────────────────────────────────────────────────
  Widget _buildCuratedPalettesTab() {
    final palettes = [
      ...SubtitleColorHistoryManager.instance.curatedPalettes,
      ...SubtitleColorHistoryManager.instance.savedUserPalettes,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: palettes.map((palette) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF141624),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF222538)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    palette.name,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                  if (palette.description != null)
                    Text(
                      palette.description!,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: palette.colors.map((c) {
                  final isSelected = c.toARGB32() == _currentColor.toARGB32();
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _setColor(c),
                      child: Container(
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white12,
                            width: isSelected ? 2.0 : 0.8,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Tab 1: Spectrum Picker ────────────────────────────────────────────────
  Widget _buildSpectrumTab() {
    final hsv = HSVColor.fromColor(_currentColor);

    return Column(
      children: [
        // 2D Saturation / Value Box
        GestureDetector(
          onPanUpdate: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final sat = (details.localPosition.dx / 380).clamp(0.0, 1.0);
            final val = (1.0 - (details.localPosition.dy / 140)).clamp(0.0, 1.0);
            _setColor(hsv.withSaturation(sat).withValue(val).toColor());
          },
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  HSVColor.fromAHSV(1.0, hsv.hue, 1.0, 1.0).toColor(),
                ],
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Hue Slider
        _buildSlider(
          label: 'Hue',
          value: hsv.hue,
          min: 0,
          max: 360,
          onChanged: (v) => _setColor(hsv.withHue(v).toColor()),
        ),
        // Saturation Slider
        _buildSlider(
          label: 'Saturation',
          value: hsv.saturation * 100,
          min: 0,
          max: 100,
          unit: '%',
          onChanged: (v) => _setColor(hsv.withSaturation(v / 100).toColor()),
        ),
        // Brightness Slider
        _buildSlider(
          label: 'Brightness',
          value: hsv.value * 100,
          min: 0,
          max: 100,
          unit: '%',
          onChanged: (v) => _setColor(hsv.withValue(v / 100).toColor()),
        ),
      ],
    );
  }

  // ── Tab 2: RGB Sliders ────────────────────────────────────────────────────
  Widget _buildRgbSlidersTab() {
    return Column(
      children: [
        _buildSlider(
          label: 'Red (R)',
          value: ((_currentColor.r * 255).round()).toDouble(),
          min: 0,
          max: 255,
          color: Colors.redAccent,
          onChanged: (v) => _setColor(_currentColor.withValues(red: v / 255.0)),
        ),
        _buildSlider(
          label: 'Green (G)',
          value: ((_currentColor.g * 255).round()).toDouble(),
          min: 0,
          max: 255,
          color: Colors.greenAccent,
          onChanged: (v) => _setColor(_currentColor.withValues(green: v / 255.0)),
        ),
        _buildSlider(
          label: 'Blue (B)',
          value: ((_currentColor.b * 255).round()).toDouble(),
          min: 0,
          max: 255,
          color: Colors.blueAccent,
          onChanged: (v) => _setColor(_currentColor.withValues(blue: v / 255.0)),
        ),
        if (widget.enableAlpha)
          _buildSlider(
            label: 'Opacity (A)',
            value: (_currentColor.a * 100),
            min: 0,
            max: 100,
            unit: '%',
            color: const Color(0xFFC4B5FD),
            onChanged: (v) => _setColor(_currentColor.withValues(alpha: v / 100.0)),
          ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    String? unit,
    Color? color,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color ?? const Color(0xFF9CA3AF),
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color ?? const Color(0xFF8B5CF6),
                inactiveTrackColor: const Color(0xFF222538),
                thumbColor: color ?? const Color(0xFF8B5CF6),
                trackHeight: 3.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
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
            width: 44,
            child: Text(
              '${value.round()}${unit ?? ''}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: Color(0xFFD1D5DB),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
