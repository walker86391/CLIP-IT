import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/branding_models.dart';
import '../providers/branding_provider.dart';
import 'animation_effect_selector.dart';
import 'overlay_style_picker.dart';
import 'position_matrix_selector.dart';
import 'shape_customization_section.dart';
import 'timing_range_slider.dart';
import 'typography_appearance_section.dart';

/// Control panel for Tab 2: Temporary Overlays Studio.
///
/// Features:
/// - Layer management list with reordering, duplicate, delete, rename, reset.
/// - `[ + Add Overlay ]` button (user must click to add, none auto-added).
/// - Prominent unconditional `[ Delete Text Box ]` button.
/// - Accordion dropdown sections (mutually exclusive: opening one closes any open one).
/// - No numeric X/Y position inputs (vertical movement handled by dragging on preview).
class TemporaryOverlaysPanel extends ConsumerStatefulWidget {
  const TemporaryOverlaysPanel({super.key});

  @override
  ConsumerState<TemporaryOverlaysPanel> createState() =>
      _TemporaryOverlaysPanelState();
}

class _TemporaryOverlaysPanelState
    extends ConsumerState<TemporaryOverlaysPanel> {
  // Mutually exclusive accordion state (only 1 section can be open at a time)
  String? _expandedSection = 'style';

  void _toggleSection(String section) {
    setState(() {
      _expandedSection = _expandedSection == section ? null : section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final studioState = ref.watch(brandingProvider);
    final notifier = ref.read(brandingProvider.notifier);
    final activeOverlay = studioState.selectedTemporaryOverlay;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Layer Management Header & Add Button ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TEMPORARY OVERLAYS (LAYERS)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Color(0xFFC4B5FD),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => notifier.addTemporaryOverlay(),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('+ Add Overlay',
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
          const SizedBox(height: 8),

          // Layer List (Determines Z-Index: later index appears on top)
          if (studioState.temporaryOverlays.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F101A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF23263B)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: studioState.temporaryOverlays.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFF1E2032)),
                itemBuilder: (context, index) {
                  final overlay = studioState.temporaryOverlays[index];
                  final isSelected =
                      overlay.id == studioState.selectedTemporaryId;
                  final layerNum = (index + 1).toString().padLeft(2, '0');

                  return InkWell(
                    onTap: () => notifier.selectTemporaryOverlay(overlay.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      color: isSelected
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.16)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          // Selection indicator bar
                          Container(
                            width: 3,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF8B5CF6)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Layer index & text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$layerNum — "${overlay.text}"',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFFD1D5DB),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E2032),
                                        borderRadius:
                                            BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        overlay.style.displayName,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFC4B5FD),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${overlay.startPercent.round()}% → ${overlay.endPercent.round()}%',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Layer Order Actions (Move Up, Move Down)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: index > 0
                                    ? () => notifier.reorderTemporaryOverlays(
                                        index, index - 1)
                                    : null,
                                icon: const Icon(Icons.arrow_upward_rounded,
                                    size: 14),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 24, minHeight: 24),
                                color: const Color(0xFF9CA3AF),
                              ),
                              IconButton(
                                onPressed: index <
                                        studioState.temporaryOverlays.length - 1
                                    ? () => notifier.reorderTemporaryOverlays(
                                        index, index + 2)
                                    : null,
                                icon: const Icon(Icons.arrow_downward_rounded,
                                    size: 14),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 24, minHeight: 24),
                                color: const Color(0xFF9CA3AF),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (activeOverlay == null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.layers_clear_rounded,
                      size: 32, color: Color(0xFF6B7280)),
                  const SizedBox(height: 8),
                  const Text(
                    'No temporary overlays created yet.',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => notifier.addTemporaryOverlay(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Callout Overlay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Layer Action Toolbar: Rename, Duplicate, Reset, Delete
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
                      'Editing: ${activeOverlay.name}',
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
                        message: 'Reset overlay to defaults',
                        child: TextButton.icon(
                          onPressed: () =>
                              notifier.resetTemporaryOverlay(activeOverlay.id),
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
                        message: 'Duplicate overlay',
                        child: TextButton.icon(
                          onPressed: () => notifier
                              .duplicateTemporaryOverlay(activeOverlay.id),
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
                        message: 'Delete overlay',
                        child: TextButton.icon(
                          onPressed: () => notifier
                              .deleteTemporaryOverlay(activeOverlay.id),
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

            // ── Accordion 1: Style & Shape Customization ─────────────────────
            _AccordionSectionCard(
              title: 'STYLE & SHAPE',
              icon: Icons.interests_rounded,
              isExpanded: _expandedSection == 'style',
              onToggle: () => _toggleSection('style'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OverlayStylePicker(
                    selectedStyle: activeOverlay.style,
                    onStyleSelected: (style) =>
                        notifier.changeOverlayStyle(activeOverlay.id, style),
                  ),
                  const SizedBox(height: 14),
                  ShapeCustomizationSection(
                    shape: activeOverlay.shape,
                    shapeColor: activeOverlay.shapeColor,
                    shapeSize: activeOverlay.shapeSize,
                    lineLength: activeOverlay.lineLength,
                    borderThickness: activeOverlay.borderThickness,
                    borderStyle: activeOverlay.borderStyle,
                    cornerRadius: activeOverlay.cornerRadius,
                    fill: activeOverlay.fill,
                    fillColor: activeOverlay.fillColor,
                    onShapeChanged: (s) => notifier.updateTemporaryOverlay(
                        activeOverlay.id, (o) => o.copyWith(shape: s)),
                    onShapeColorChanged: (c) => notifier.updateTemporaryOverlay(
                        activeOverlay.id, (o) => o.copyWith(shapeColor: c)),
                    onShapeSizeChanged: (sz) => notifier.updateTemporaryOverlay(
                        activeOverlay.id, (o) => o.copyWith(shapeSize: sz)),
                    onLineLengthChanged: (l) => notifier.updateTemporaryOverlay(
                        activeOverlay.id, (o) => o.copyWith(lineLength: l)),
                    onBorderThicknessChanged: (b) =>
                        notifier.updateTemporaryOverlay(activeOverlay.id,
                            (o) => o.copyWith(borderThickness: b)),
                    onBorderStyleChanged: (bs) =>
                        notifier.updateTemporaryOverlay(activeOverlay.id,
                            (o) => o.copyWith(borderStyle: bs)),
                    onCornerRadiusChanged: (cr) =>
                        notifier.updateTemporaryOverlay(activeOverlay.id,
                            (o) => o.copyWith(cornerRadius: cr)),
                    onFillChanged: (f) => notifier.updateTemporaryOverlay(
                        activeOverlay.id, (o) => o.copyWith(fill: f)),
                    onFillColorChanged: (fc) =>
                        notifier.updateTemporaryOverlay(activeOverlay.id,
                            (o) => o.copyWith(fillColor: fc)),
                  ),
                ],
              ),
            ),

            // ── Accordion 2: Text & Typography ───────────────────────────────
            _AccordionSectionCard(
              title: 'TEXT & TYPOGRAPHY',
              icon: Icons.text_fields_rounded,
              isExpanded: _expandedSection == 'typography',
              onToggle: () => _toggleSection('typography'),
              child: TypographyAppearanceSection(
                text: activeOverlay.text,
                font: activeOverlay.font,
                fontSize: activeOverlay.fontSize,
                fontWeight: activeOverlay.fontWeight,
                italic: activeOverlay.italic,
                letterSpacing: activeOverlay.letterSpacing,
                lineSpacing: activeOverlay.lineSpacing,
                textColor: activeOverlay.textColor,
                underline: activeOverlay.underline,
                strikethrough: activeOverlay.strikethrough,
                shadow: activeOverlay.shadow,
                shadowIntensity: activeOverlay.shadowIntensity,
                shadowDistance: activeOverlay.shadowDistance,
                shadowSoftness: activeOverlay.shadowSoftness,
                glow: activeOverlay.glow,
                glowIntensity: activeOverlay.glowIntensity,
                glowColor: activeOverlay.glowColor,
                neon: activeOverlay.neon,
                alignment: activeOverlay.alignment,
                onTextChanged: (val) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(text: val)),
                onFontChanged: (val) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(font: val)),
                onFontSizeChanged: (val) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(fontSize: val)),
                onFontWeightChanged: (val) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(fontWeight: val)),
                onItalicChanged: (val) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(italic: val)),
                onLetterSpacingChanged: (val) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(letterSpacing: val)),
                onLineSpacingChanged: (val) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(lineSpacing: val)),
                onTextColorChanged: (val) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(textColor: val)),
                onUnderlineChanged: (val) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(underline: val)),
                onStrikethroughChanged: (val) =>
                    notifier.updateTemporaryOverlay(activeOverlay.id,
                        (o) => o.copyWith(strikethrough: val)),
                onShadowChanged: (val) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(shadow: val)),
                onShadowIntensityChanged: (val) =>
                    notifier.updateTemporaryOverlay(activeOverlay.id,
                        (o) => o.copyWith(shadowIntensity: val)),
                onShadowDistanceChanged: (val) =>
                    notifier.updateTemporaryOverlay(activeOverlay.id,
                        (o) => o.copyWith(shadowDistance: val)),
                onShadowSoftnessChanged: (val) =>
                    notifier.updateTemporaryOverlay(activeOverlay.id,
                        (o) => o.copyWith(shadowSoftness: val)),
                onGlowChanged: (val) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(glow: val)),
                onGlowIntensityChanged: (val) =>
                    notifier.updateTemporaryOverlay(activeOverlay.id,
                        (o) => o.copyWith(glowIntensity: val)),
                onGlowColorChanged: (val) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(glowColor: val)),
                onNeonChanged: (val) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(neon: val)),
                onAlignmentChanged: (val) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(alignment: val)),
              ),
            ),

            // ── Accordion 3: Position & Alignment Matrix ─────────────────────
            _AccordionSectionCard(
              title: 'POSITION & ALIGNMENT',
              icon: Icons.grid_3x3_rounded,
              isExpanded: _expandedSection == 'position',
              onToggle: () => _toggleSection('position'),
              child: PositionMatrixSelector(
                selectedPreset: activeOverlay.position,
                fineOffsetX: activeOverlay.fineOffsetX,
                fineOffsetY: activeOverlay.fineOffsetY,
                onPresetChanged: (preset) => notifier.updateTemporaryOverlay(
                    activeOverlay.id,
                    (o) => o.copyWith(
                      position: preset,
                      alignment: preset.defaultTextAlign,
                      fineOffsetX: 0.0,
                      fineOffsetY: 0.0,
                    ),
                ),
                onOffsetChanged: (x, y) => notifier.updateTemporaryOverlay(
                    activeOverlay.id,
                    (o) => o.copyWith(fineOffsetX: x, fineOffsetY: y)),
              ),
            ),

            // ── Accordion 4: Animations ──────────────────────────────────────
            _AccordionSectionCard(
              title: 'ANIMATION & EFFECTS',
              icon: Icons.auto_awesome_rounded,
              isExpanded: _expandedSection == 'animation',
              onToggle: () => _toggleSection('animation'),
              child: AnimationEffectSelector(
                appearAnimation: activeOverlay.appearAnimation,
                exitAnimation: activeOverlay.exitAnimation,
                continuousAnimation: activeOverlay.continuousAnimation,
                animationDuration: activeOverlay.animationDuration,
                exitDuration: activeOverlay.exitDuration,
                easing: activeOverlay.easing,
                allowDropIn: true,
                onAppearChanged: (anim) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(appearAnimation: anim)),
                onExitChanged: (exitAnim) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(exitAnimation: exitAnim)),
                onContinuousChanged: (anim) => notifier.updateTemporaryOverlay(
                    activeOverlay.id,
                    (o) => o.copyWith(continuousAnimation: anim)),
                onDurationChanged: (dur) => notifier.updateTemporaryOverlay(
                    activeOverlay.id,
                    (o) => o.copyWith(animationDuration: dur)),
                onExitDurationChanged: (dur) => notifier.updateTemporaryOverlay(
                    activeOverlay.id,
                    (o) => o.copyWith(exitDuration: dur)),
                onEasingChanged: (ease) => notifier.updateTemporaryOverlay(
                    activeOverlay.id, (o) => o.copyWith(easing: ease)),
              ),
            ),

            // ── Accordion 5: Timing & Duration Range ─────────────────────────
            _AccordionSectionCard(
              title: 'TIMING & DURATION',
              icon: Icons.timer_rounded,
              isExpanded: _expandedSection == 'timing',
              onToggle: () => _toggleSection('timing'),
              child: TimingRangeSlider(
                startPercent: activeOverlay.startPercent,
                endPercent: activeOverlay.endPercent,
                clipDurationSeconds: studioState.clipDurationSeconds,
                label: 'OVERLAY TIMING RANGE',
                onChanged: (s, e) => notifier.updateTemporaryOverlay(
                    activeOverlay.id,
                    (o) => o.copyWith(startPercent: s, endPercent: e)),
              ),
            ),

            const SizedBox(height: 16),

            // ── Prominent Delete Text Box Button ─────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    notifier.deleteTemporaryOverlay(activeOverlay.id),
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
