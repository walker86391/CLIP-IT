import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/branding_models.dart';
import '../providers/branding_provider.dart';
import 'position_matrix_selector.dart';
import 'typography_appearance_section.dart';

/// Control panel for Tab 1: Permanent Branding.
///
/// Features:
/// - Multiple permanent branding text layers with selection chips.
/// - `[ + Add Text ]` button (user must click to add, none auto-added).
/// - Prominent unconditional `[ Delete Text Box ]` button.
/// - Accordion dropdown sections (mutually exclusive: opening one closes any open one).
/// - No numeric X/Y position inputs (vertical movement handled by dragging on preview).
class PermanentBrandingPanel extends ConsumerStatefulWidget {
  const PermanentBrandingPanel({super.key});

  @override
  ConsumerState<PermanentBrandingPanel> createState() =>
      _PermanentBrandingPanelState();
}

class _PermanentBrandingPanelState
    extends ConsumerState<PermanentBrandingPanel> {
  // Mutually exclusive accordion state (only 1 section can be open at a time)
  String? _expandedSection = 'typography';

  void _toggleSection(String section) {
    setState(() {
      _expandedSection = _expandedSection == section ? null : section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final studioState = ref.watch(brandingProvider);
    final notifier = ref.read(brandingProvider.notifier);
    final activeLayer = studioState.selectedPermanentLayer;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Layer Header & Add Button ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BRANDING TEXT LAYERS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Color(0xFFC4B5FD),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => notifier.addPermanentLayer(),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('+ Add Text',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Layer Selection Chips
          if (studioState.permanentLayers.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: studioState.permanentLayers.map((layer) {
                  final isSelected =
                      layer.id == studioState.selectedPermanentId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => notifier.selectPermanentLayer(layer.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF8B5CF6).withValues(alpha: 0.25)
                              : const Color(0xFF131420),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8B5CF6)
                                : const Color(0xFF222436),
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.text_fields_rounded,
                              size: 14,
                              color: isSelected
                                  ? const Color(0xFFC4B5FD)
                                  : const Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              layer.text.isEmpty ? 'Untitled' : layer.text,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (activeLayer == null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.title_rounded,
                      size: 32, color: Color(0xFF6B7280)),
                  const SizedBox(height: 8),
                  const Text(
                    'No branding layers created yet.',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => notifier.addPermanentLayer(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Creator Watermark'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Layer Action Toolbar: Duplicate, Reset, Delete
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F101A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF23263B)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Editing: "${activeLayer.text}"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // Reset Button
                      Tooltip(
                        message: 'Reset layer to defaults',
                        child: TextButton.icon(
                          onPressed: () =>
                              notifier.resetPermanentLayer(activeLayer.id),
                          icon: const Icon(Icons.refresh, size: 12),
                          label: const Text('Reset',
                              style: TextStyle(fontSize: 10.5)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF9CA3AF),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Duplicate Button
                      Tooltip(
                        message: 'Duplicate layer',
                        child: TextButton.icon(
                          onPressed: () =>
                              notifier.duplicatePermanentLayer(activeLayer.id),
                          icon: const Icon(Icons.copy_rounded, size: 12),
                          label: const Text('Duplicate',
                              style: TextStyle(fontSize: 10.5)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFC4B5FD),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Delete Button (Unconditional)
                      Tooltip(
                        message: 'Delete layer',
                        child: TextButton.icon(
                          onPressed: () =>
                              notifier.deletePermanentLayer(activeLayer.id),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 13, color: Color(0xFFEF4444)),
                          label: const Text('Delete',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFFEF4444))),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Accordion 1: Text & Typography ───────────────────────────────
            _AccordionSectionCard(
              title: 'TEXT & TYPOGRAPHY',
              icon: Icons.text_fields_rounded,
              isExpanded: _expandedSection == 'typography',
              onToggle: () => _toggleSection('typography'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Opacity Slider
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F101A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF23263B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'LAYER OPACITY',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                            Text(
                              '${(activeLayer.opacity * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFC4B5FD),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            activeTrackColor: const Color(0xFF8B5CF6),
                            inactiveTrackColor: const Color(0xFF23263A),
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5.5),
                            overlayColor: const Color(0xFF8B5CF6)
                                .withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: activeLayer.opacity.clamp(0.0, 1.0),
                            min: 0.0,
                            max: 1.0,
                            divisions: 100,
                            onChanged: (val) {
                              notifier.updatePermanentLayer(
                                activeLayer.id,
                                (l) => l.copyWith(opacity: val),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  TypographyAppearanceSection(
                    text: activeLayer.text,
                    font: activeLayer.font,
                    fontSize: activeLayer.fontSize,
                    fontWeight: activeLayer.fontWeight,
                    italic: activeLayer.italic,
                    letterSpacing: activeLayer.letterSpacing,
                    lineSpacing: activeLayer.lineSpacing,
                    textColor: activeLayer.textColor,
                    underline: activeLayer.underline,
                    strikethrough: activeLayer.strikethrough,
                    shadow: activeLayer.shadow,
                    shadowIntensity: activeLayer.shadowIntensity,
                    shadowDistance: activeLayer.shadowDistance,
                    shadowSoftness: activeLayer.shadowSoftness,
                    glow: activeLayer.glow,
                    glowIntensity: activeLayer.glowIntensity,
                    glowColor: activeLayer.glowColor,
                    neon: activeLayer.neon,
                    alignment: activeLayer.alignment,
                    onTextChanged: (val) => notifier.updatePermanentLayer(
                        activeLayer.id, (l) => l.copyWith(text: val)),
                    onFontChanged: (val) => notifier.updatePermanentLayer(
                        activeLayer.id, (l) => l.copyWith(font: val)),
                    onFontSizeChanged: (val) => notifier.updatePermanentLayer(
                        activeLayer.id, (l) => l.copyWith(fontSize: val)),
                    onFontWeightChanged: (val) => notifier.updatePermanentLayer(
                        activeLayer.id, (l) => l.copyWith(fontWeight: val)),
                    onItalicChanged: (val) => notifier.updatePermanentLayer(
                        activeLayer.id, (l) => l.copyWith(italic: val)),
                    onLetterSpacingChanged: (val) =>
                        notifier.updatePermanentLayer(activeLayer.id,
                            (l) => l.copyWith(letterSpacing: val)),
                    onLineSpacingChanged: (val) =>
                        notifier.updatePermanentLayer(
                            activeLayer.id, (l) => l.copyWith(lineSpacing: val)),
                    onTextColorChanged: (val) => notifier.updatePermanentLayer(
                        activeLayer.id, (l) => l.copyWith(textColor: val)),
                    onUnderlineChanged: (val) => notifier.updatePermanentLayer(
                        activeLayer.id, (l) => l.copyWith(underline: val)),
                    onStrikethroughChanged: (val) =>
                        notifier.updatePermanentLayer(activeLayer.id,
                            (l) => l.copyWith(strikethrough: val)),
                    onShadowChanged: (val) => notifier.updatePermanentLayer(
                        activeLayer.id, (l) => l.copyWith(shadow: val)),
                    onShadowIntensityChanged: (val) =>
                        notifier.updatePermanentLayer(activeLayer.id,
                            (l) => l.copyWith(shadowIntensity: val)),
                    onShadowDistanceChanged: (val) =>
                        notifier.updatePermanentLayer(activeLayer.id,
                            (l) => l.copyWith(shadowDistance: val)),
                    onShadowSoftnessChanged: (val) =>
                        notifier.updatePermanentLayer(activeLayer.id,
                            (l) => l.copyWith(shadowSoftness: val)),
                    onGlowChanged: (val) => notifier.updatePermanentLayer(
                        activeLayer.id, (l) => l.copyWith(glow: val)),
                    onGlowIntensityChanged: (val) =>
                        notifier.updatePermanentLayer(activeLayer.id,
                            (l) => l.copyWith(glowIntensity: val)),
                    onGlowColorChanged: (val) => notifier.updatePermanentLayer(
                        activeLayer.id, (l) => l.copyWith(glowColor: val)),
                    onNeonChanged: (val) => notifier.updatePermanentLayer(
                        activeLayer.id, (l) => l.copyWith(neon: val)),
                    onAlignmentChanged: (val) => notifier.updatePermanentLayer(
                        activeLayer.id, (l) => l.copyWith(alignment: val)),
                  ),
                ],
              ),
            ),

            // ── Accordion 2: Position & Alignment Matrix ─────────────────────
            _AccordionSectionCard(
              title: 'POSITION & ALIGNMENT',
              icon: Icons.grid_3x3_rounded,
              isExpanded: _expandedSection == 'position',
              onToggle: () => _toggleSection('position'),
              child: PositionMatrixSelector(
                selectedPreset: activeLayer.position,
                fineOffsetX: activeLayer.fineOffsetX,
                fineOffsetY: activeLayer.fineOffsetY,
                onPresetChanged: (preset) => notifier.updatePermanentLayer(
                    activeLayer.id,
                    (l) => l.copyWith(
                      position: preset,
                      alignment: preset.defaultTextAlign,
                      fineOffsetX: 0.0,
                      fineOffsetY: 0.0,
                    ),
                ),
                onOffsetChanged: (x, y) => notifier.updatePermanentLayer(
                    activeLayer.id,
                    (l) => l.copyWith(fineOffsetX: x, fineOffsetY: y)),
              ),
            ),

            const SizedBox(height: 16),

            // ── Prominent Delete Text Box Button ─────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => notifier.deletePermanentLayer(activeLayer.id),
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: Color(0xFFEF4444)),
                label: const Text(
                  'Delete Text Box',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  ),
                  backgroundColor:
                      const Color(0xFFEF4444).withValues(alpha: 0.06),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Reusable clean Accordion Card matching Stage 3 design patterns.
class _AccordionSectionCard extends StatelessWidget {
  const _AccordionSectionCard({
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131420),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isExpanded
              ? const Color(0xFF8B5CF6)
              : const Color(0xFF222436),
          width: isExpanded ? 1.4 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              color: isExpanded
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
                  : const Color(0xFF161826),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isExpanded
                        ? const Color(0xFFC4B5FD)
                        : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isExpanded
                            ? Colors.white
                            : const Color(0xFFD1D5DB),
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    size: 18,
                    color: isExpanded
                        ? const Color(0xFFC4B5FD)
                        : const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
        ],
      ),
    );
  }
}
