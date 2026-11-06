import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subtitle_models.dart';
import '../models/subtitle_presets_library.dart';
import '../providers/subtitle_studio_provider.dart';
import '../../branding/models/branding_models.dart';
import 'subtitle_color_capsule.dart';
import 'subtitle_preset_card.dart';
import '../services/subtitle_font_registry.dart';
import 'subtitle_color_palette_picker.dart';

/// The three expandable accordion sections:
/// 1. STYLE (60-preset library grid, search, categories)
/// 2. SETTINGS (Color capsule, typography, conditional outline/shadow/glow, position)
/// 3. EFFECTS (Entrance/Exit animations, word emphasis modes, box/underline parameters)
class SubtitleAccordionSections extends ConsumerStatefulWidget {
  const SubtitleAccordionSections({super.key});

  @override
  ConsumerState<SubtitleAccordionSections> createState() =>
      _SubtitleAccordionSectionsState();
}

class _SubtitleAccordionSectionsState
    extends ConsumerState<SubtitleAccordionSections> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(subtitleStudioProvider.notifier);
    final isStyleExpanded = ref.watch(
      subtitleStudioProvider.select((s) => s.isStyleSectionExpanded),
    );
    final isSettingsExpanded = ref.watch(
      subtitleStudioProvider.select((s) => s.isSettingsSectionExpanded),
    );
    final isEffectsExpanded = ref.watch(
      subtitleStudioProvider.select((s) => s.isEffectsSectionExpanded),
    );

    return Column(
      children: [
        // ── 1. STYLE ACCORDION ──────────────────────────────────────────────
        _buildAccordionHeader(
          title: 'STYLE',
          subtitle: '${SubtitlePresetsLibrary.allPresets.length} presets across ${SubtitleCategory.values.length} viral categories',
          icon: Icons.palette_outlined,
          isExpanded: isStyleExpanded,
          onToggle: notifier.toggleStyleSection,
          action: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2032),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF32364D), width: 0.8),
            ),
            child: Text(
              '${SubtitlePresetsLibrary.allPresets.length} PRESETS',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFFC4B5FD),
              ),
            ),
          ),
        ),
        if (isStyleExpanded)
          Consumer(
            builder: (context, ref, _) {
              final filteredPresets = ref.watch(
                subtitleStudioProvider.select((s) => s.filteredPresets),
              );
              final selectedCategory = ref.watch(
                subtitleStudioProvider.select((s) => s.selectedCategory),
              );
              final selectedPresetId = ref.watch(
                subtitleStudioProvider.select((s) => s.selectedPreset.id),
              );
              return _buildStyleContent(
                filteredPresets,
                selectedCategory,
                selectedPresetId,
                notifier,
              );
            },
          ),

        const SizedBox(height: 12),

        // ── 2. SETTINGS ACCORDION ───────────────────────────────────────────
        _buildAccordionHeader(
          title: 'SETTINGS',
          subtitle: 'Colors, typography, alignment, outlines and effects',
          icon: Icons.tune_rounded,
          isExpanded: isSettingsExpanded,
          onToggle: notifier.toggleSettingsSection,
          action: TextButton.icon(
            onPressed: () => notifier.resetToPreset(),
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text(
              'Reset to Preset',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF9CA3AF),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
        if (isSettingsExpanded)
          Consumer(
            builder: (context, ref, _) {
              final studioState = ref.watch(subtitleStudioProvider);
              return _buildSettingsContent(studioState, notifier);
            },
          ),

        const SizedBox(height: 12),

        // ── 3. EFFECTS ACCORDION ────────────────────────────────────────────
        _buildAccordionHeader(
          title: 'EFFECTS',
          subtitle: 'Word emphasis, entrance & exit animations, box and underline',
          icon: Icons.auto_awesome_rounded,
          isExpanded: isEffectsExpanded,
          onToggle: notifier.toggleEffectsSection,
        ),
        if (isEffectsExpanded)
          Consumer(
            builder: (context, ref, _) {
              final studioState = ref.watch(subtitleStudioProvider);
              return _buildEffectsContent(studioState, notifier);
            },
          ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ACCORDION HEADER BUILDER
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildAccordionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    Widget? action,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10121C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isExpanded ? const Color(0xFF33374D) : const Color(0xFF1E202E),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.18)
                        : const Color(0xFF181A26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isExpanded
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                          : const Color(0xFF262838),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: isExpanded
                        ? const Color(0xFFC4B5FD)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: Color(0xFFF3F4F8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF808597),
                        ),
                      ),
                    ],
                  ),
                ),
                if (action != null) ...[
                  action,
                  const SizedBox(width: 8),
                ],
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. STYLE CONTENT (60-Preset Browser)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildStyleContent(
    List<SubtitlePreset> filteredPresets,
    SubtitleCategory? selectedCategory,
    String selectedPresetId,
    SubtitleStudioNotifier notifier,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0D15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E202E), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search & Category Bar
          Row(
            children: [
              // Search input
              Expanded(
                flex: 4,
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141520),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF262838),
                      width: 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search ${SubtitlePresetsLibrary.allPresets.length} presets by name or style...',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: notifier.setSearchQuery,
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            notifier.setSearchQuery('');
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Category Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryPill(
                  label: 'All (${SubtitlePresetsLibrary.allPresets.length})',
                  isSelected: selectedCategory == null,
                  onTap: () => notifier.setCategory(null),
                ),
                ...SubtitleCategory.values.map((cat) {
                  return _buildCategoryPill(
                    label: cat.displayName,
                    isSelected: selectedCategory == cat,
                    onTap: () => notifier.setCategory(cat),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Presets Grid (Responsive cards)
          filteredPresets.isEmpty
              ? Container(
                  height: 180,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.search_off_rounded,
                        size: 36,
                        color: Color(0xFF4B5563),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No presets match your search query.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 154,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredPresets.length,
                  itemBuilder: (context, index) {
                    final preset = filteredPresets[index];
                    final isSelected =
                        preset.id == selectedPresetId;
                    return SubtitlePresetCard(
                      preset: preset,
                      isSelected: isSelected,
                      onSelected: () => notifier.selectPreset(preset),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : const Color(0xFF141624),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF282B3E),
                width: 1.0,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. SETTINGS CONTENT
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSettingsContent(
    SubtitleStudioState state,
    SubtitleStudioNotifier notifier,
  ) {
    final config = state.activeConfig;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0D15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E202E), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Color Capsule & Palette Manager
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSubheader(
                'ACTIVE COLOR PALETTE',
                'Click any segment or open the full palette manager:',
              ),
              TextButton.icon(
                onPressed: () async {
                  final picked = await SubtitleColorPickerDialog.show(
                    context: context,
                    initialColor: config.highlightColor,
                    title: 'Subtitle Color & Palette Manager',
                    originalColor: state.selectedPreset.defaultConfig.highlightColor,
                  );
                  if (picked != null) {
                    notifier.updateColors(highlightColor: picked);
                  }
                },
                icon: const Icon(Icons.palette_outlined, size: 14),
                label: const Text(
                  'Palette Manager',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC4B5FD),
                  backgroundColor: const Color(0xFF1E2034),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFF383C56), width: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const SubtitleColorCapsule(),

          const SizedBox(height: 20),

          // B. Typography
          _buildSubheader('TYPOGRAPHY & SIZING', null),
          const SizedBox(height: 10),

          // Font Family Dropdown & Font Size Slider
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Font Family',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141624),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF2B2E42),
                          width: 1.0,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: SubtitleFontRegistry.registeredFonts.any(
                                  (f) => f.family.toLowerCase() == config.fontFamily.toLowerCase())
                              ? SubtitleFontRegistry.registeredFonts
                                  .firstWhere((f) => f.family.toLowerCase() == config.fontFamily.toLowerCase())
                                  .family
                              : (SubtitleFontRegistry.registeredFonts.isNotEmpty
                                  ? SubtitleFontRegistry.registeredFonts.first.family
                                  : 'Impact'),
                          isExpanded: true,
                          dropdownColor: const Color(0xFF161826),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Color(0xFF9CA3AF),
                          ),
                          selectedItemBuilder: (context) {
                            final seen = <String>{};
                            final uniqueFonts = SubtitleFontRegistry.registeredFonts
                                .where((f) => seen.add(f.family.toLowerCase()))
                                .toList();
                            return uniqueFonts.map((font) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  font.displayName,
                                  style: SubtitleFontRegistry.getTextStyle(
                                    family: font.family,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFC4B5FD),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList();
                          },
                          items: () {
                            final seen = <String>{};
                            final uniqueFonts = SubtitleFontRegistry.registeredFonts
                                .where((f) => seen.add(f.family.toLowerCase()))
                                .toList();
                            return uniqueFonts.map((font) {
                              return DropdownMenuItem<String>(
                                value: font.family,
                                child: Text(
                                  font.displayName,
                                  style: SubtitleFontRegistry.getTextStyle(
                                    family: font.family,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFF3F4F8),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList();
                          }(),
                          onChanged: (val) {
                            if (val != null) {
                              notifier.updateTypography(fontFamily: val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Font Size Slider
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Font Size',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${config.fontSize.round()} px',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC4B5FD),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        activeTrackColor: const Color(0xFF8B5CF6),
                        inactiveTrackColor: const Color(0xFF222538),
                        thumbColor: const Color(0xFF8B5CF6),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: config.fontSize,
                        min: 14.0,
                        max: 48.0,
                        onChanged: (v) => notifier.updateTypography(fontSize: v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Font Weight Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Font Weight',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final entry in [
                      (FontWeight.w300, 'Light'),
                      (FontWeight.w400, 'Regular'),
                      (FontWeight.w600, 'Semi-Bold'),
                      (FontWeight.w700, 'Bold'),
                      (FontWeight.w800, 'Extra-Bold'),
                      (FontWeight.w900, 'Black'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => notifier.updateTypography(fontWeight: entry.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: config.fontWeight == entry.$1
                                    ? const Color(0xFF8B5CF6)
                                    : const Color(0xFF141624),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: config.fontWeight == entry.$1
                                      ? const Color(0xFF8B5CF6)
                                      : const Color(0xFF2B2E42),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                entry.$2,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: config.fontWeight == entry.$1
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: config.fontWeight == entry.$1
                                      ? Colors.white
                                      : const Color(0xFFD1D5DB),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Text Casing Selector (Normal, UPPERCASE, lowercase)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Text Case Transformation',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final entry in [
                    ('Normal (Aa)', !config.isUppercase && !config.isLowercase, () => notifier.updateTypography(isUppercase: false, isLowercase: false)),
                    ('UPPERCASE (AA)', config.isUppercase, () => notifier.updateTypography(isUppercase: true, isLowercase: false)),
                    ('lowercase (aa)', config.isLowercase, () => notifier.updateTypography(isUppercase: false, isLowercase: true)),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: entry.$3,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: entry.$2
                                    ? const Color(0xFF8B5CF6)
                                    : const Color(0xFF141624),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: entry.$2
                                      ? const Color(0xFF8B5CF6)
                                      : const Color(0xFF2B2E42),
                                  width: 1.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  entry.$1,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: entry.$2
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: entry.$2
                                        ? Colors.white
                                        : const Color(0xFFD1D5DB),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Text Opacity & Line Spacing
          Row(
            children: [
              // Text Opacity Slider
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Text Opacity',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(config.textOpacity * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC4B5FD),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        activeTrackColor: const Color(0xFF8B5CF6),
                        inactiveTrackColor: const Color(0xFF222538),
                        thumbColor: const Color(0xFF8B5CF6),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: config.textOpacity,
                        min: 0.2,
                        max: 1.0,
                        onChanged: (v) => notifier.updateTypography(textOpacity: v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Line Spacing Slider
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Line Spacing',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${config.lineSpacing.toStringAsFixed(1)}x',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC4B5FD),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        activeTrackColor: const Color(0xFF8B5CF6),
                        inactiveTrackColor: const Color(0xFF222538),
                        thumbColor: const Color(0xFF8B5CF6),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: config.lineSpacing,
                        min: 0.8,
                        max: 2.2,
                        onChanged: (v) => notifier.updateTypography(lineSpacing: v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Words Per Line & Letter Spacing
          Row(
            children: [
              // Words per line (1 to 4)
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Words Per Line',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (final count in [1, 2, 3, 4])
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => notifier.updateLineLayout(wordsPerLine: count),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: config.wordsPerLine == count
                                        ? const Color(0xFF8B5CF6)
                                        : const Color(0xFF161826),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: config.wordsPerLine == count
                                          ? const Color(0xFF8B5CF6)
                                          : const Color(0xFF2C2F44),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: config.wordsPerLine == count
                                            ? Colors.white
                                            : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Letter Spacing Slider
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Letter Spacing',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          config.letterSpacing.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC4B5FD),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        activeTrackColor: const Color(0xFF8B5CF6),
                        inactiveTrackColor: const Color(0xFF222538),
                        thumbColor: const Color(0xFF8B5CF6),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: config.letterSpacing,
                        min: -1.0,
                        max: 4.0,
                        onChanged: (v) => notifier.updateTypography(letterSpacing: v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // C. Effects: Glow, Outline, Shadow
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubheader('EFFECTS & GLOW RADIANCE', 'Customize glow strength, flow, and caption outlines:'),
              const SizedBox(height: 10),

              // Glow Card with Toggle, Strength, Flow, and Color
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141523),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: config.hasGlow
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.6)
                        : const Color(0xFF242636),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: config.hasGlow
                              ? const Color(0xFFA78BFA)
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Glow Effect',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Radiant neon bloom around caption words',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: config.hasGlow,
                          activeThumbColor: const Color(0xFF8B5CF6),
                          onChanged: (enabled) {
                            notifier.updateEffects(hasGlow: enabled);
                          },
                        ),
                      ],
                    ),
                    if (config.hasGlow) ...[
                      const Divider(color: Color(0xFF26283C), height: 18),
                      // Glow Color row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Glow Color',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD1D5DB),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              SubtitleColorCapsule.showEditor(
                                context: context,
                                label: 'Glow',
                                color: config.glowColor,
                                originalColor: state.selectedPreset.defaultConfig.glowColor,
                                onChanged: (c) => notifier.updateColors(glowColor: c),
                              );
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E2030),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF383C56), width: 1.0),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: config.glowColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: config.glowColor.withValues(alpha: 0.6),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '#${config.glowColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Glow Strength
                      _buildSliderRow(
                        label: 'Glow Strength',
                        value: config.glowIntensity * 100,
                        min: 10.0,
                        max: 100.0,
                        unit: '%',
                        onChanged: (v) => notifier.updateEffects(glowIntensity: v / 100),
                      ),
                      // Glow Flow / Radius
                      _buildSliderRow(
                        label: 'Glow Flow / Radius',
                        value: config.glowBlur,
                        min: 2.0,
                        max: 36.0,
                        unit: 'px',
                        onChanged: (v) => notifier.updateEffects(glowBlur: v),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Outline Stroke Width
              _buildSliderRow(
                label: 'Outline Stroke Width',
                value: config.outlineWidth,
                min: 0.0,
                max: 7.0,
                unit: 'px',
                onChanged: (v) => notifier.updateEffects(outlineWidth: v, hasOutline: v > 0),
              ),

              // Shadow Drop Blur
              _buildSliderRow(
                label: 'Shadow Drop Blur',
                value: config.shadowBlur,
                min: 0.0,
                max: 16.0,
                unit: 'px',
                onChanged: (v) => notifier.updateEffects(shadowBlur: v, hasShadow: v > 0),
              ),

              const SizedBox(height: 16),
            ],
          ),

          // D. Positioning & Alignment (3x3 Matrix Grid)
          _buildSubtitlePositionMatrix(state, notifier),
        ],
      ),
    );
  }

  Widget _buildColorPickerRow({
    required String label,
    required Color color,
    required Color originalColor,
    required ValueChanged<Color> onChanged,
  }) {
    final effectiveColor = (color != Colors.transparent && color.a > 0)
        ? color
        : const Color(0xFF8B5CF6);
    final hexCode =
        '#${effectiveColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD1D5DB),
          ),
        ),
        GestureDetector(
          onTap: () {
            SubtitleColorCapsule.showEditor(
              context: context,
              label: label,
              color: effectiveColor,
              originalColor: originalColor,
              onChanged: onChanged,
            );
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2030),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF383C56), width: 1.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: effectiveColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: effectiveColor.withValues(alpha: 0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hexCode,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. EFFECTS CONTENT (Two-Layer Animation + Markers + Textures + Emphasis)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildEffectsContent(
    SubtitleStudioState state,
    SubtitleStudioNotifier notifier,
  ) {
    final config = state.activeConfig;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0D15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E202E), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Replay Preview button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSubheader(
                'ANIMATION & MOTION SUITE',
                'Layer 1 reveals, Layer 2 motion, markers and textures',
              ),
              TextButton.icon(
                onPressed: () => notifier.replayAnimation(),
                icon: const Icon(Icons.play_circle_outline_rounded, size: 14),
                label: const Text(
                  'Replay Preview',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC4B5FD),
                  backgroundColor: const Color(0xFF1E2034),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFF383C56), width: 0.8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── ALIGNMENT & ANCHOR ──────────────────────────────────────────
          _buildSubheader(
            'ALIGNMENT & FLOW ANCHOR',
            'Text anchor direction (Left anchor grows text towards right):',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildAlignmentSegmentButton(
                icon: Icons.format_align_left_rounded,
                label: 'Left',
                isSelected: config.textAlign == TextAlign.left ||
                    config.textAlign == TextAlign.start,
                onTap: () =>
                    notifier.updateLineLayout(textAlign: TextAlign.left),
              ),
              const SizedBox(width: 8),
              _buildAlignmentSegmentButton(
                icon: Icons.format_align_center_rounded,
                label: 'Center',
                isSelected: config.textAlign == TextAlign.center,
                onTap: () =>
                    notifier.updateLineLayout(textAlign: TextAlign.center),
              ),
              const SizedBox(width: 8),
              _buildAlignmentSegmentButton(
                icon: Icons.format_align_right_rounded,
                label: 'Right',
                isSelected: config.textAlign == TextAlign.right ||
                    config.textAlign == TextAlign.end,
                onTap: () =>
                    notifier.updateLineLayout(textAlign: TextAlign.right),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── LAYER 1: TEXT REVEAL / ENTRANCE ANIMATION ───────────────────
          _buildSubheader(
            'LAYER 1 — TEXT REVEAL ANIMATION',
            'Dynamic text entrance (line blur, word blur, typewriter, directional, mask, scramble, scale, tracking):',
          ),
          const SizedBox(height: 10),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF141624),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2B2E42),
                width: 1.0,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SubtitleLayer1Animation>(
                value: config.layer1Animation,
                isExpanded: true,
                dropdownColor: const Color(0xFF161826),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
                items: SubtitleLayer1Animation.values.map((anim) {
                  return DropdownMenuItem<SubtitleLayer1Animation>(
                    value: anim,
                    child: Text(
                      anim.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: anim == config.layer1Animation
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: anim == config.layer1Animation
                            ? const Color(0xFFC4B5FD)
                            : const Color(0xFFF3F4F8),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    notifier.updateLayer1(animation: val);
                  }
                },
              ),
            ),
          ),

          if (config.layer1Animation != SubtitleLayer1Animation.none) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF121422),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF232538)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntSliderRow(
                    label: 'Reveal Duration',
                    value: config.layer1DurationMs,
                    min: 100,
                    max: 1500,
                    unit: 'ms',
                    onChanged: (v) => notifier.updateLayer1(durationMs: v),
                  ),
                  _buildIntSliderRow(
                    label: 'Reveal Delay',
                    value: config.layer1DelayMs,
                    min: 0,
                    max: 500,
                    unit: 'ms',
                    onChanged: (v) => notifier.updateLayer1(delayMs: v),
                  ),
                  _buildSliderRow(
                    label: 'Reveal Intensity',
                    value: config.layer1Intensity,
                    min: 0.2,
                    max: 2.0,
                    unit: 'x',
                    onChanged: (v) => notifier.updateLayer1(intensity: v),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SizedBox(
                        width: 140,
                        child: Text(
                          'Easing Curve',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF191B2C),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF2B2E44)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<SubtitleEasing>(
                              value: config.layer1Easing,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF161826),
                              icon: const Icon(Icons.arrow_drop_down, size: 16),
                              items: SubtitleEasing.values.map((e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e.displayName,
                                    style: const TextStyle(fontSize: 11, color: Colors.white),
                                  ),
                                );
                              }).toList(),
                              onChanged: (e) {
                                if (e != null) notifier.updateLayer1(easing: e);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (config.layer1Animation == SubtitleLayer1Animation.directionalSlide) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(
                          width: 140,
                          child: Text(
                            'Slide Direction',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: SubtitleAnimationDirection.values.map((dir) {
                              final isSel = config.layer1Direction == dir;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () => notifier.updateLayer1(direction: dir),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 140),
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSel
                                              ? const Color(0xFF8B5CF6)
                                              : const Color(0xFF191B2C),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: isSel
                                                ? const Color(0xFF8B5CF6)
                                                : const Color(0xFF2B2E44),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            dir.displayName,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                              color: isSel ? Colors.white : const Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── LAYER 2: SECONDARY MOTION / EMPHASIS ANIMATION ──────────────
          _buildSubheader(
            'LAYER 2 — SECONDARY MOTION & EMPHASIS',
            'Independent kinetic layer combined with Layer 1 (pop bounce, elastic, punch, floating, shake, pulse, spring):',
          ),
          const SizedBox(height: 10),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF141624),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2B2E42),
                width: 1.0,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SubtitleLayer2Animation>(
                value: config.layer2Animation,
                isExpanded: true,
                dropdownColor: const Color(0xFF161826),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
                items: SubtitleLayer2Animation.values.map((anim) {
                  return DropdownMenuItem<SubtitleLayer2Animation>(
                    value: anim,
                    child: Text(
                      anim.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: anim == config.layer2Animation
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: anim == config.layer2Animation
                            ? const Color(0xFFC4B5FD)
                            : const Color(0xFFF3F4F8),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    notifier.updateLayer2(animation: val);
                  }
                },
              ),
            ),
          ),

          if (config.layer2Animation != SubtitleLayer2Animation.none) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF121422),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF232538)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntSliderRow(
                    label: 'Motion Duration',
                    value: config.layer2DurationMs,
                    min: 100,
                    max: 1500,
                    unit: 'ms',
                    onChanged: (v) => notifier.updateLayer2(durationMs: v),
                  ),
                  _buildIntSliderRow(
                    label: 'Motion Delay',
                    value: config.layer2DelayMs,
                    min: 0,
                    max: 500,
                    unit: 'ms',
                    onChanged: (v) => notifier.updateLayer2(delayMs: v),
                  ),
                  _buildSliderRow(
                    label: 'Motion Intensity',
                    value: config.layer2Intensity,
                    min: 0.2,
                    max: 2.0,
                    unit: 'x',
                    onChanged: (v) => notifier.updateLayer2(intensity: v),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SizedBox(
                        width: 140,
                        child: Text(
                          'Easing Curve',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF191B2C),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF2B2E44)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<SubtitleEasing>(
                              value: config.layer2Easing,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF161826),
                              icon: const Icon(Icons.arrow_drop_down, size: 16),
                              items: SubtitleEasing.values.map((e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e.displayName,
                                    style: const TextStyle(fontSize: 11, color: Colors.white),
                                  ),
                                );
                              }).toList(),
                              onChanged: (e) {
                                if (e != null) notifier.updateLayer2(easing: e);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (config.layer2Animation == SubtitleLayer2Animation.directionalExit) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(
                          width: 140,
                          child: Text(
                            'Exit Direction',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: SubtitleAnimationDirection.values.map((dir) {
                              final isSel = config.layer2Direction == dir;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () => notifier.updateLayer2(direction: dir),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 140),
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSel
                                              ? const Color(0xFF8B5CF6)
                                              : const Color(0xFF191B2C),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: isSel
                                                ? const Color(0xFF8B5CF6)
                                                : const Color(0xFF2B2E44),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            dir.displayName,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                              color: isSel ? Colors.white : const Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── IMPORTANT WORD MARKERS ──────────────────────────────────────
          _buildSubheader(
            'IMPORTANT WORD MARKERS',
            'Independent graphical markers framing or underlining emphasized words:',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: SubtitleMarkerStyle.values.map((style) {
              final isSel = config.markerStyle == style;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => notifier.updateMarker(style: style),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF8B5CF6) : const Color(0xFF141624),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSel ? const Color(0xFF8B5CF6) : const Color(0xFF2C2F44),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      style.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? Colors.white : const Color(0xFFD1D5DB),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          if (config.markerStyle != SubtitleMarkerStyle.none) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF121422),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF232538)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildColorPickerRow(
                    label: 'Marker Color',
                    color: config.markerColor,
                    originalColor: state.selectedPreset.defaultConfig.markerColor,
                    onChanged: (c) => notifier.updateMarker(markerColor: c),
                  ),
                  const SizedBox(height: 8),
                  _buildSliderRow(
                    label: 'Marker Thickness',
                    value: config.markerThickness,
                    min: 1.0,
                    max: 10.0,
                    unit: 'px',
                    onChanged: (v) => notifier.updateMarker(thickness: v),
                  ),
                  _buildSliderRow(
                    label: 'Distance From Text',
                    value: config.markerDistance,
                    min: -5.0,
                    max: 20.0,
                    unit: 'px',
                    onChanged: (v) => notifier.updateMarker(distance: v),
                  ),
                  _buildSliderRow(
                    label: 'Marker Padding',
                    value: config.markerPaddingH,
                    min: 0.0,
                    max: 24.0,
                    unit: 'px',
                    onChanged: (v) => notifier.updateMarker(paddingH: v, paddingV: v * 0.4),
                  ),
                  _buildSliderRow(
                    label: 'Marker Opacity',
                    value: config.markerOpacity * 100,
                    min: 10.0,
                    max: 100.0,
                    unit: '%',
                    onChanged: (v) => notifier.updateMarker(opacity: v / 100),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SizedBox(
                        width: 140,
                        child: Text(
                          'Animation Behavior',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: MarkerAnimationBehavior.values.map((anim) {
                              final isSel = config.markerAnimation == anim;
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => notifier.updateMarker(animation: anim),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 140),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? const Color(0xFF8B5CF6)
                                            : const Color(0xFF191B2C),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isSel
                                              ? const Color(0xFF8B5CF6)
                                              : const Color(0xFF2B2E44),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          anim.displayName,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                            color: isSel ? Colors.white : const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildIntSliderRow(
                    label: 'Marker Speed',
                    value: config.markerDurationMs,
                    min: 100,
                    max: 1000,
                    unit: 'ms',
                    onChanged: (v) => notifier.updateMarker(durationMs: v),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── MARKER & STROKE TEXTURES ────────────────────────────────────
          _buildSubheader(
            'MARKER TEXTURE & BRUSH STYLE',
            'Applies physical medium textures or natural hand-drawing to markers:',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: MarkerTexture.values.map((tex) {
              final isSel = config.markerTexture == tex;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => notifier.updateMarkerTexture(tex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF8B5CF6) : const Color(0xFF141624),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSel ? const Color(0xFF8B5CF6) : const Color(0xFF2C2F44),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      tex.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? Colors.white : const Color(0xFFD1D5DB),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // ── INACTIVE WORDS & KARAOKE FOCUS ──────────────────────────────
          _buildSubheader(
            'KARAOKE WORD FOCUS',
            'Controls contrast between spoken words and inactive line context:',
          ),
          const SizedBox(height: 10),

          // Dim Inactive Words Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF141523),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF242636)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dim Inactive Words',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD1D5DB),
                      ),
                    ),
                    Text(
                      'Highlights currently spoken karaoke words',
                      style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
                Switch(
                  value: config.dimInactiveWords,
                  activeThumbColor: const Color(0xFF8B5CF6),
                  onChanged: (v) =>
                      notifier.updateEmphasis(dimInactiveWords: v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Translucent Inactive Words Toggle & Transparency Slider
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF141523),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF242636)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Translucent Inactive Words',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                        Text(
                          'Makes non-active words semi-transparent with custom opacity',
                          style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                    Switch(
                      value: config.translucentInactiveWords,
                      activeThumbColor: const Color(0xFF8B5CF6),
                      onChanged: (v) =>
                          notifier.updateEmphasis(translucentInactiveWords: v),
                    ),
                  ],
                ),
                if (config.translucentInactiveWords) ...[
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFF242636), height: 1),
                  const SizedBox(height: 10),
                  _buildSliderRow(
                    label: 'Transparency',
                    value: (1.0 - config.inactiveWordTransparency) * 100,
                    min: 0.0,
                    max: 95.0,
                    unit: '%',
                    onChanged: (v) => notifier.updateEmphasis(
                      inactiveWordTransparency: (1.0 - (v / 100.0)).clamp(0.05, 1.0),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── CLASSIC WORD EMPHASIS & TRANSITIONS (PRESERVED) ─────────────
          _buildSubheader(
            'CLASSIC WORD EMPHASIS & TRANSITIONS',
            'Backwards-compatible legacy highlighting and line transitions:',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SubtitleEmphasisMode.values.map((mode) {
              final isSel = config.emphasisMode == mode;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => notifier.updateEmphasis(emphasisMode: mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSel
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF141624),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSel
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF2C2F44),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      mode.displayName,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? Colors.white : const Color(0xFFD1D5DB),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Conditional Emphasis Box & Underline settings
          if (config.emphasisMode == SubtitleEmphasisMode.boxedWord)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubheader('HIGHLIGHT PILL / BOX SETTINGS', null),
                const SizedBox(height: 8),
                _buildColorPickerRow(
                  label: 'Box Background Color',
                  color: config.boxColor,
                  originalColor: state.selectedPreset.defaultConfig.boxColor,
                  onChanged: (c) => notifier.updateColors(boxColor: c),
                ),
                const SizedBox(height: 8),
                _buildSliderRow(
                  label: 'Pill / Box Padding',
                  value: config.boxPadding,
                  min: 2.0,
                  max: 20.0,
                  unit: 'px',
                  onChanged: (v) => notifier.updateEmphasis(boxPadding: v),
                ),
                _buildSliderRow(
                  label: 'Corner Radius',
                  value: config.boxRadius,
                  min: 0.0,
                  max: 20.0,
                  unit: 'px',
                  onChanged: (v) => notifier.updateEmphasis(boxRadius: v),
                ),
                _buildSliderRow(
                  label: 'Box Opacity',
                  value: config.backgroundOpacity * 100,
                  min: 15.0,
                  max: 100.0,
                  unit: '%',
                  onChanged: (v) =>
                      notifier.updateEmphasis(boxOpacity: v / 100),
                ),
                const SizedBox(height: 14),
              ],
            ),

          if (config.emphasisMode == SubtitleEmphasisMode.underline)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubheader('UNDERLINE SETTINGS', null),
                const SizedBox(height: 8),
                _buildColorPickerRow(
                  label: 'Underline Color',
                  color: config.underlineColor != Colors.transparent
                      ? config.underlineColor
                      : config.highlightColor,
                  originalColor:
                      state.selectedPreset.defaultConfig.underlineColor,
                  onChanged: (c) => notifier.updateColors(underlineColor: c),
                ),
                const SizedBox(height: 8),
                _buildSliderRow(
                  label: 'Line Thickness',
                  value: config.underlineThickness,
                  min: 1.0,
                  max: 8.0,
                  unit: 'px',
                  onChanged: (v) =>
                      notifier.updateEmphasis(underlineThickness: v),
                ),
                _buildSliderRow(
                  label: 'Baseline Offset',
                  value: config.underlineOffset,
                  min: 0.0,
                  max: 10.0,
                  unit: 'px',
                  onChanged: (v) =>
                      notifier.updateEmphasis(underlineOffset: v),
                ),
                const SizedBox(height: 14),
              ],
            ),

          // Classic Entrance & Exit Styles
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Classic Entrance',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141624),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF2B2E42), width: 1.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SubtitleEntranceAnimation>(
                          value: config.entranceAnimation,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF161826),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: Color(0xFF9CA3AF)),
                          items: SubtitleEntranceAnimation.values.map((anim) {
                            return DropdownMenuItem(
                                value: anim, child: Text(anim.displayName));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              notifier.updateAnimations(entrance: val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Classic Exit',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141624),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF2B2E42), width: 1.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SubtitleExitAnimation>(
                          value: config.exitAnimation,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF161826),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: Color(0xFF9CA3AF)),
                          items: SubtitleExitAnimation.values.map((anim) {
                            return DropdownMenuItem(
                                value: anim, child: Text(anim.displayName));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              notifier.updateAnimations(exit: val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Subtitle Canvas Position & Alignment Matrix ──────────────────────────

  Widget _buildSubtitlePositionMatrix(
    SubtitleStudioState state,
    SubtitleStudioNotifier notifier,
  ) {
    final config = state.activeConfig;
    final currentPreset = _calculateSubtitlePreset(config.position);

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
                'POSITION & ALIGNMENT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              Text(
                currentPreset.displayName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC4B5FD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3x3 Grid
              Container(
                width: 104,
                height: 104,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F101A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF23263B),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSubtitlePresetRow([
                      PositionPreset.topLeft,
                      PositionPreset.topCenter,
                      PositionPreset.topRight,
                    ], currentPreset, notifier),
                    _buildSubtitlePresetRow([
                      PositionPreset.centerLeft,
                      PositionPreset.center,
                      PositionPreset.centerRight,
                    ], currentPreset, notifier),
                    _buildSubtitlePresetRow([
                      PositionPreset.bottomLeft,
                      PositionPreset.bottomCenter,
                      PositionPreset.bottomRight,
                    ], currentPreset, notifier),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Guide / Reset vertical position
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.touch_app_rounded,
                            size: 16, color: Color(0xFF8B5CF6)),
                        SizedBox(width: 6),
                        Text(
                          'Screen Alignment',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap any anchor point to snap subtitles to that screen position, or pick and drag freely on the video canvas.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => notifier.updatePosition(0.50, 0.78),
                      icon: const Icon(Icons.refresh, size: 12),
                      label: const Text('Reset to Bottom',
                          style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFC4B5FD),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitlePresetRow(
    List<PositionPreset> presets,
    PositionPreset selectedPreset,
    SubtitleStudioNotifier notifier,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: presets
          .map((p) => _buildSubtitlePresetCell(p, selectedPreset == p, notifier))
          .toList(),
    );
  }

  Widget _buildSubtitlePresetCell(
    PositionPreset preset,
    bool isSelected,
    SubtitleStudioNotifier notifier,
  ) {
    return InkWell(
      onTap: () => _applySubtitlePreset(preset, notifier),
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF191B28),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC4B5FD)
                : const Color(0xFF2C2F44),
            width: isSelected ? 1.4 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Container(
            width: isSelected ? 8 : 5,
            height: isSelected ? 8 : 5,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  void _applySubtitlePreset(
    PositionPreset preset,
    SubtitleStudioNotifier notifier,
  ) {
    switch (preset) {
      case PositionPreset.topLeft:
        notifier.updatePosition(0.20, 0.16);
        break;
      case PositionPreset.topCenter:
        notifier.updatePosition(0.50, 0.16);
        break;
      case PositionPreset.topRight:
        notifier.updatePosition(0.80, 0.16);
        break;
      case PositionPreset.centerLeft:
        notifier.updatePosition(0.20, 0.50);
        break;
      case PositionPreset.center:
        notifier.updatePosition(0.50, 0.50);
        break;
      case PositionPreset.centerRight:
        notifier.updatePosition(0.80, 0.50);
        break;
      case PositionPreset.bottomLeft:
        notifier.updatePosition(0.20, 0.78);
        break;
      case PositionPreset.bottomCenter:
        notifier.updatePosition(0.50, 0.78);
        break;
      case PositionPreset.bottomRight:
        notifier.updatePosition(0.80, 0.78);
        break;
      case PositionPreset.custom:
        notifier.updatePosition(0.50, 0.50);
        break;
    }
  }

  PositionPreset _calculateSubtitlePreset(Offset position) {
    final x = position.dx;
    final y = position.dy;

    final isLeft = x < 0.35;
    final isRight = x > 0.65;
    final isTop = y < 0.35;
    final isBottom = y > 0.65;

    if (isTop) {
      if (isLeft) return PositionPreset.topLeft;
      if (isRight) return PositionPreset.topRight;
      return PositionPreset.topCenter;
    } else if (isBottom) {
      if (isLeft) return PositionPreset.bottomLeft;
      if (isRight) return PositionPreset.bottomRight;
      return PositionPreset.bottomCenter;
    } else {
      if (isLeft) return PositionPreset.centerLeft;
      if (isRight) return PositionPreset.centerRight;
      return PositionPreset.center;
    }
  }

  Widget _buildAlignmentSegmentButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : const Color(0xFF141624),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF2C2F44),
                width: 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFFD1D5DB),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubheader(String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: Color(0xFF8B5CF6),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                activeTrackColor: const Color(0xFF8B5CF6),
                inactiveTrackColor: const Color(0xFF222538),
                thumbColor: const Color(0xFF8B5CF6),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
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
              '${value.toStringAsFixed(1)} $unit',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC4B5FD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntSliderRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required String unit,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                activeTrackColor: const Color(0xFF8B5CF6),
                inactiveTrackColor: const Color(0xFF222538),
                thumbColor: const Color(0xFF8B5CF6),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              ),
              child: Slider(
                value: value.clamp(min, max).toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: (max - min) ~/ 25 > 0 ? (max - min) ~/ 25 : 10,
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '$value $unit',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC4B5FD),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
