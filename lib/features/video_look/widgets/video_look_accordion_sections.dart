import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/video_look_state.dart';
import '../providers/video_look_provider.dart';
import 'video_look_color_picker.dart';
import 'video_look_slider_row.dart';

/// Renders the 8 verified, hardware-accelerated accordion categories for Step 3 Video Look.
///
/// Critical Rules:
/// - ONLY ONE category can be open at a time.
/// - Opening any category closes whichever was open.
/// - Every category header contains: CATEGORY NAME + RESET ICON (icon only, NO text).
/// - Clicking the reset icon resets ONLY that category to its defaults.
/// - Number inputs and sliders are bidirectional and update live.
class VideoLookAccordionSections extends ConsumerWidget {
  const VideoLookAccordionSections({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoLookProvider);
    final notifier = ref.read(videoLookProvider.notifier);

    return Column(
      children: VideoLookCategory.values.map((category) {
        final isExpanded = state.activeCategory == category;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: _CategoryAccordionCard(
            category: category,
            isExpanded: isExpanded,
            onToggle: () => notifier.toggleCategory(category),
            onReset: () => notifier.resetCategory(category),
            child: isExpanded
                ? _buildCategoryContent(context, category, state, notifier)
                : const SizedBox.shrink(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryContent(
    BuildContext context,
    VideoLookCategory category,
    VideoLookState state,
    VideoLookNotifier notifier,
  ) {
    switch (category) {
      case VideoLookCategory.basic:
        return _buildBasicSection(state, notifier);
      case VideoLookCategory.color:
        return _buildColorSection(state, notifier);
      case VideoLookCategory.blackAndWhite:
        return _buildBlackAndWhiteSection(state, notifier);
      case VideoLookCategory.cinematic:
        return _buildCinematicSection(state, notifier);
      case VideoLookCategory.light:
        return _buildLightSection(state, notifier);
      case VideoLookCategory.blurAndSoftness:
        return _buildBlurSection(state, notifier);
      case VideoLookCategory.film:
        return _buildFilmSection(state, notifier);
      case VideoLookCategory.blendOverlay:
        return _buildBlendSection(state, notifier);
    }
  }

  // ── 1. BASIC ──────────────────────────────────────────────────────────────
  Widget _buildBasicSection(VideoLookState s, VideoLookNotifier n) {
    return Column(
      children: [
        VideoLookSliderRow(label: 'Brightness', value: s.brightness, onChanged: n.setBrightness),
        VideoLookSliderRow(label: 'Exposure', value: s.exposure, onChanged: n.setExposure),
        VideoLookSliderRow(label: 'Contrast', value: s.contrast, onChanged: n.setContrast),
        VideoLookSliderRow(label: 'Saturation', value: s.saturation, onChanged: n.setSaturation),
        VideoLookSliderRow(label: 'Vibrance', value: s.vibrance, onChanged: n.setVibrance),
        VideoLookSliderRow(label: 'Temperature', value: s.temperature, onChanged: n.setTemperature),
      ],
    );
  }

  // ── 2. COLOR ──────────────────────────────────────────────────────────────
  Widget _buildColorSection(VideoLookState s, VideoLookNotifier n) {
    return Column(
      children: [
        VideoLookSliderRow(label: 'Hue Shift', value: s.hue, min: -180.0, max: 180.0, onChanged: n.setHue),
        VideoLookSliderRow(label: 'Color Balance', value: s.colorBalance, onChanged: n.setColorBalance),
        VideoLookColorIntensityRow(
          label: 'Colorize',
          color: s.colorizeColor,
          onColorChanged: n.setColorizeColor,
          intensity: s.colorizeIntensity,
          onIntensityChanged: n.setColorizeIntensity,
        ),
        VideoLookSliderRow(label: 'Grayscale', value: s.grayscale, min: 0.0, max: 100.0, onChanged: n.setGrayscale),
        VideoLookSliderRow(label: 'Sepia', value: s.sepia, min: 0.0, max: 100.0, onChanged: n.setSepia),
      ],
    );
  }

  // ── 3. BLACK & WHITE / TONING ─────────────────────────────────────────────
  Widget _buildBlackAndWhiteSection(VideoLookState s, VideoLookNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Master B&W Toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF141624),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF26283C), width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Black & White Master Mode',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF3F4F8),
                    ),
                  ),
                  Text(
                    'Toggles full grayscale conversion across the video',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              Switch(
                value: s.bwEnabled,
                onChanged: (val) {
                  n.setBwEnabled(val);
                  if (val && s.bwAmount == 0) n.setBwAmount(100.0);
                },
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ),
        if (s.bwEnabled) ...[
          const SizedBox(height: 8),
          VideoLookSliderRow(
            label: 'B&W Amount',
            value: s.bwAmount,
            min: 0.0,
            max: 100.0,
            onChanged: n.setBwAmount,
          ),
        ],

        const SizedBox(height: 14),
        _buildSubHeader('TONING STYLES & SPLIT TONES'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ToningPreset.values.map((preset) {
            final isSel = s.toningPreset == preset;
            return _PresetPill(
              label: preset.displayName,
              isSelected: isSel,
              onTap: () => n.setToningPreset(preset),
            );
          }).toList(),
        ),

        if (s.toningPreset != ToningPreset.none) ...[
          const SizedBox(height: 10),
          VideoLookSliderRow(
            label: 'Toning Intensity',
            value: s.toningIntensity,
            min: 0.0,
            max: 100.0,
            defaultValue: 100.0,
            onChanged: n.setToningIntensity,
          ),
        ],

        if (s.toningPreset == ToningPreset.duotone) ...[
          const SizedBox(height: 8),
          _buildSubHeader('DUOTONE PALETTE'),
          Row(
            children: [
              Expanded(
                child: VideoLookColorPicker(
                  color: s.duotoneShadowColor,
                  onColorChanged: n.setDuotoneShadowColor,
                  title: 'Duotone Shadow Color',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: VideoLookColorPicker(
                  color: s.duotoneHighlightColor,
                  onColorChanged: n.setDuotoneHighlightColor,
                  title: 'Duotone Highlight Color',
                ),
              ),
            ],
          ),
        ],

        if (s.toningPreset == ToningPreset.tritone) ...[
          const SizedBox(height: 8),
          _buildSubHeader('TRITONE PALETTE (Shadow, Midtone, Highlight)'),
          Row(
            children: [
              Expanded(
                child: VideoLookColorPicker(
                  color: s.tritoneShadowColor,
                  onColorChanged: n.setTritoneShadowColor,
                  title: 'Tritone Shadow Color',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: VideoLookColorPicker(
                  color: s.tritoneMidtoneColor,
                  onColorChanged: n.setTritoneMidtoneColor,
                  title: 'Tritone Midtone Color',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: VideoLookColorPicker(
                  color: s.tritoneHighlightColor,
                  onColorChanged: n.setTritoneHighlightColor,
                  title: 'Tritone Highlight Color',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }


  // ── 5. CINEMATIC ──────────────────────────────────────────────────────────
  Widget _buildCinematicSection(VideoLookState s, VideoLookNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubHeader('COMPLETE CINEMATIC LOOKS'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: CinematicLookPreset.values.map((preset) {
            final isSel = s.cinematicPreset == preset;
            return _PresetPill(
              label: preset.displayName,
              isSelected: isSel,
              onTap: () => n.setCinematicPreset(preset),
            );
          }).toList(),
        ),
        if (s.cinematicPreset != CinematicLookPreset.none) ...[
          const SizedBox(height: 12),
          VideoLookSliderRow(
            label: 'Look Intensity',
            value: s.cinematicIntensity,
            min: 0.0,
            max: 100.0,
            defaultValue: 85.0,
            onChanged: n.setCinematicIntensity,
          ),
        ],
      ],
    );
  }

  // ── 5. LIGHT & ATMOSPHERE ─────────────────────────────────────────────────
  Widget _buildLightSection(VideoLookState s, VideoLookNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VideoLookSliderRow(label: 'Glow', value: s.glow, min: 0.0, max: 100.0, onChanged: n.setGlow),
        VideoLookSliderRow(label: 'Bloom', value: s.bloom, min: 0.0, max: 100.0, onChanged: n.setBloom),
        const SizedBox(height: 8),
        _buildSubHeader('LIGHT LEAKS & LENS FLARES'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: LightLeakPreset.values.map((p) {
            final isSel = s.lightLeakPreset == p;
            return _PresetPill(
              label: 'Leak: ${p.displayName}',
              isSelected: isSel,
              onTap: () {
                n.setLightLeakPreset(p);
                if (p != LightLeakPreset.none && s.lightLeakIntensity == 0) {
                  n.setLightLeakIntensity(60.0);
                }
              },
            );
          }).toList(),
        ),
        if (s.lightLeakPreset != LightLeakPreset.none) ...[
          const SizedBox(height: 6),
          VideoLookSliderRow(
            label: 'Leak Intensity',
            value: s.lightLeakIntensity,
            min: 0.0,
            max: 100.0,
            onChanged: n.setLightLeakIntensity,
          ),
        ],
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: LensFlarePreset.values.map((p) {
            final isSel = s.lensFlarePreset == p;
            return _PresetPill(
              label: 'Flare: ${p.displayName}',
              isSelected: isSel,
              onTap: () {
                n.setLensFlarePreset(p);
                if (p != LensFlarePreset.none && s.lensFlareIntensity == 0) {
                  n.setLensFlareIntensity(50.0);
                }
              },
            );
          }).toList(),
        ),
        if (s.lensFlarePreset != LensFlarePreset.none) ...[
          const SizedBox(height: 6),
          VideoLookSliderRow(
            label: 'Flare Intensity',
            value: s.lensFlareIntensity,
            min: 0.0,
            max: 100.0,
            onChanged: n.setLensFlareIntensity,
          ),
        ],
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: FilmBurnPreset.values.map((p) {
            final isSel = s.filmBurnPreset == p;
            return _PresetPill(
              label: 'Burn: ${p.displayName}',
              isSelected: isSel,
              onTap: () {
                n.setFilmBurnPreset(p);
                if (p != FilmBurnPreset.none && s.filmBurnIntensity == 0) {
                  n.setFilmBurnIntensity(65.0);
                }
              },
            );
          }).toList(),
        ),
        if (s.filmBurnPreset != FilmBurnPreset.none) ...[
          const SizedBox(height: 6),
          VideoLookSliderRow(
            label: 'Film Burn Intensity',
            value: s.filmBurnIntensity,
            min: 0.0,
            max: 100.0,
            onChanged: n.setFilmBurnIntensity,
          ),
        ],
        const SizedBox(height: 8),
        _buildSubHeader('VIGNETTE'),
        VideoLookSliderRow(label: 'Vignette Amount', value: s.vignetteAmount, min: -100.0, max: 100.0, onChanged: n.setVignetteAmount),
        VideoLookSliderRow(label: 'Vignette Softness', value: s.vignetteSoftness, min: 0.0, max: 100.0, defaultValue: 50.0, onChanged: n.setVignetteSoftness),
        const SizedBox(height: 6),
        _buildSubHeader('VIGNETTE STYLE'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: VignetteStyle.values.map((v) {
            final isSel = s.vignetteStyle == v;
            return _PresetPill(
              label: v.displayName,
              isSelected: isSel,
              onTap: () => n.setVignetteStyle(v),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        _buildSubHeader('DARKEN AT BOTTOM OF FRAME'),
        VideoLookSliderRow(
          label: 'Strength',
          value: s.darkenBottomStrength,
          min: 0.0,
          max: 100.0,
          defaultValue: 0.0,
          onChanged: n.setDarkenBottomStrength,
        ),
        VideoLookSliderRow(
          label: 'Spread',
          value: s.darkenBottomSpread,
          min: 0.0,
          max: 100.0,
          defaultValue: 50.0,
          onChanged: n.setDarkenBottomSpread,
        ),
      ],
    );
  }

  // ── 6. BLUR & SOFTNESS ────────────────────────────────────────────────────
  Widget _buildBlurSection(VideoLookState s, VideoLookNotifier n) {
    return Column(
      children: [
        VideoLookSliderRow(label: 'Blur', value: s.blur, min: 0.0, max: 100.0, onChanged: n.setBlur),
        VideoLookSliderRow(label: 'Soft Focus', value: s.softFocus, min: 0.0, max: 100.0, onChanged: n.setSoftFocus),
        VideoLookSliderRow(label: 'Dream Softness', value: s.dreamSoftness, min: 0.0, max: 100.0, onChanged: n.setDreamSoftness),
      ],
    );
  }

  // ── 10. FILM ──────────────────────────────────────────────────────────────
  Widget _buildFilmSection(VideoLookState s, VideoLookNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Film grain primary controls
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF141624),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF26283C), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubHeader('FILM GRAIN ENGINE'),
              VideoLookSliderRow(
                label: 'Grain Amount',
                value: s.filmGrainAmount,
                min: 0.0,
                max: 100.0,
                onChanged: n.setFilmGrainAmount,
              ),
              VideoLookSliderRow(
                label: 'Grain Size',
                value: s.grainSize,
                min: 1.0,
                max: 10.0,
                defaultValue: 2.0,
                onChanged: n.setGrainSize,
              ),
              VideoLookSliderRow(
                label: 'Grain Softness',
                value: s.grainSoftness,
                min: 0.0,
                max: 100.0,
                defaultValue: 30.0,
                onChanged: n.setGrainSoftness,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: FilmGrainType.values.map((gt) {
                  final isSel = s.grainType == gt;
                  return _PresetPill(
                    label: gt.displayName,
                    isSelected: isSel,
                    onTap: () => n.setGrainType(gt),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),
        _buildSubHeader('FILM CHARACTERISTICS & DAMAGE'),
        VideoLookSliderRow(label: 'Film Dust', value: s.filmDust, min: 0.0, max: 100.0, onChanged: n.setFilmDust),
        VideoLookSliderRow(label: 'Film Scratches', value: s.filmScratches, min: 0.0, max: 100.0, onChanged: n.setFilmScratches),

        const SizedBox(height: 8),
        _buildSubHeader('COMPLETE FILM LOOK PRESETS'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: FilmLookPreset.values.map((p) {
            final isSel = s.filmLookPreset == p;
            return _PresetPill(
              label: p.displayName,
              isSelected: isSel,
              onTap: () => n.setFilmLookPreset(p),
            );
          }).toList(),
        ),
        if (s.filmLookPreset != FilmLookPreset.none) ...[
          const SizedBox(height: 6),
          VideoLookSliderRow(
            label: 'Film Look Intensity',
            value: s.filmLookIntensity,
            min: 0.0,
            max: 100.0,
            defaultValue: 80.0,
            onChanged: n.setFilmLookIntensity,
          ),
        ],
        const SizedBox(height: 8),
        _buildSubHeader('ANALOG SCANLINES'),
        VideoLookSliderRow(label: 'CRT Scanlines', value: s.crtScanlines, min: 0.0, max: 100.0, onChanged: n.setCrtScanlines),

        const SizedBox(height: 12),
        // Live Professional Enhancement Disclaimer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF141624),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Color(0xFF60A5FA),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'THIS IS JUST A BASIC PREVIEW ON LIVE IT WOULD BE PROFESSIONALLY EDITED AND WOULD LOOK COOL IT JUST HELPS YOU DECIDE INTENSITY SOME EFFECTS MIGHT NOT EVEN PREVIEW.',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    height: 1.35,
                    color: Color(0xFF93C5FD),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 8. BLEND / OVERLAY ───────────────────────────────────────────────────
  Widget _buildBlendSection(VideoLookState s, VideoLookNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubHeader('COMPOSITING BLEND MODE'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF131522),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF26283C), width: 1.0),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<LookBlendMode>(
              value: s.blendMode,
              isExpanded: true,
              dropdownColor: const Color(0xFF161726),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8B5CF6)),
              items: LookBlendMode.values.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(
                    mode.displayName,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF3F4F8),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (mode) {
                if (mode != null) n.setBlendMode(mode);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        VideoLookSliderRow(
          label: 'Blend Opacity',
          value: s.blendOpacity,
          min: 0.0,
          max: 100.0,
          defaultValue: 100.0,
          onChanged: n.setBlendOpacity,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            VideoLookColorPicker(
              color: s.overlayTintColor,
              onColorChanged: n.setOverlayTintColor,
              title: 'Overlay Tint Color',
            ),
            const SizedBox(width: 10),
            const Text(
              'Overlay Tint Swatch',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Color(0xFF8B5CF6),
        ),
      ),
    );
  }
}

/// An accordion card enforcing:
/// - Category Name
/// - RESET ICON (Icon only, NO "Reset" text)
/// - Single accordion expansion
class _CategoryAccordionCard extends StatelessWidget {
  const _CategoryAccordionCard({
    required this.category,
    required this.isExpanded,
    required this.onToggle,
    required this.onReset,
    required this.child,
  });

  final VideoLookCategory category;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10121C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isExpanded ? const Color(0xFF33374D) : const Color(0xFF1E202E),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Bar
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Category Icon
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                            : const Color(0xFF181A26),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        category.icon,
                        size: 16,
                        color: isExpanded
                            ? const Color(0xFFC4B5FD)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Category Name & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: isExpanded
                                  ? Colors.white
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            category.subtitle,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Reset Control: ICON ONLY (NO "Reset" text)
                    Tooltip(
                      message: 'Reset ${category.displayName} to default',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: onReset,
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: const Icon(
                              Icons.restart_alt_rounded,
                              size: 16,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Chevron Indicator
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: const Color(0xFF8E92A6),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expanded Content Area
          if (isExpanded)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF1B1D2C), width: 1.0),
                ),
                color: Color(0xFF0B0C14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _PresetPill extends StatelessWidget {
  const _PresetPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                : const Color(0xFF141522),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : const Color(0xFF26283C),
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFFD1D5DB),
            ),
          ),
        ),
      ),
    );
  }
}
