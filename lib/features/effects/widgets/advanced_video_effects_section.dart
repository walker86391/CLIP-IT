import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/advanced_video_effects_models.dart';
import '../providers/advanced_video_effects_provider.dart';

/// Interactive configuration section for the 10 professional video effects.
class AdvancedVideoEffectsSection extends ConsumerWidget {
  const AdvancedVideoEffectsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(advancedVideoEffectsProvider);
    final notifier = ref.read(advancedVideoEffectsProvider.notifier);
    final activeType = state.activeEffectType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Effect Selector Grid / Horizontal Scroll ───────────────────────
        Container(
          height: 92,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AdvancedEffectType.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final type = AdvancedEffectType.values[index];
              final isSelected = type == activeType;
              final isEnabled = state.isEffectEnabled(type);

              return _EffectSelectorCard(
                type: type,
                isSelected: isSelected,
                isEnabled: isEnabled,
                onTap: () => notifier.setActiveEffectType(type),
                onToggleEnabled: (val) =>
                    notifier.toggleEffectEnabled(type, val),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // ── Active Effect Controls Panel ───────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131522),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF26293D),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Icon, Title, Enable Switch, Presets, Reset
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: activeType.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: activeType.accentColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      activeType.icon,
                      size: 20,
                      color: activeType.accentColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              activeType.displayName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Color(0xFFF3F4F8),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Pipeline Pending Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                'Pipeline Pending',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFCD34D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeType.tagline,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF8B92A8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reset Button
                  IconButton(
                    tooltip: 'Reset ${activeType.displayName} to default',
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: Color(0xFF8B92A8),
                    ),
                    onPressed: () => notifier.resetEffectToDefault(activeType),
                  ),
                  const SizedBox(width: 8),

                  // Master Toggle Switch
                  Switch(
                    value: state.isEffectEnabled(activeType),
                    activeThumbColor: activeType.accentColor,
                    activeTrackColor:
                        activeType.accentColor.withValues(alpha: 0.35),
                    inactiveThumbColor: const Color(0xFF6B7280),
                    inactiveTrackColor: const Color(0xFF1E2235),
                    onChanged: (val) =>
                        notifier.toggleEffectEnabled(activeType, val),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: Color(0xFF1E2235), height: 1),
              ),

              // Specific Parameter Controls per Effect
              _buildEffectControls(context, activeType, state, notifier),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEffectControls(
    BuildContext context,
    AdvancedEffectType type,
    AdvancedVideoEffectsState state,
    AdvancedVideoEffectsNotifier notifier,
  ) {
    return switch (type) {
      AdvancedEffectType.motionBlur => _buildMotionBlurControls(state.motionBlur, notifier),
      AdvancedEffectType.filmGrain => _buildFilmGrainControls(state.filmGrain, notifier),
      AdvancedEffectType.glitch => _buildGlitchControls(state.glitch, notifier),
      AdvancedEffectType.digitalNoise => _buildDigitalNoiseControls(state.digitalNoise, notifier),
      AdvancedEffectType.chromaticAberration => _buildChromaticAberrationControls(state.chromaticAberration, notifier),
      AdvancedEffectType.distortion => _buildDistortionControls(state.distortion, notifier),
      AdvancedEffectType.lensDispersion => _buildLensDispersionControls(state.lensDispersion, notifier),
      AdvancedEffectType.flicker => _buildFlickerControls(state.flicker, notifier),
      AdvancedEffectType.ghostTrail => _buildGhostTrailControls(state.ghostTrail, notifier),
      AdvancedEffectType.blurDetection => _buildBlurDetectionControls(state.blurDetection, notifier),
    };
  }

  // ── 1. Motion Blur Controls ───────────────────────────────────────────────
  Widget _buildMotionBlurControls(
      MotionBlurEffectConfig c, AdvancedVideoEffectsNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPresetRow(['Fast Action', 'Cinematic Shutter', 'Subtle Dream'],
            (preset) => n.applyMotionBlurPreset(preset)),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Effect Intensity',
          value: c.intensity,
          displayValue: '${(c.intensity * 100).round()}%',
          onChanged: (v) => n.updateMotionBlur((cfg) => cfg.copyWith(intensity: v)),
        ),
        _buildSlider(
          label: 'Blur Strength',
          value: c.blurStrengthPx,
          min: 1.0,
          max: 60.0,
          displayValue: '${c.blurStrengthPx.round()} px',
          onChanged: (v) => n.updateMotionBlur((cfg) => cfg.copyWith(blurStrengthPx: v)),
        ),
        _buildSlider(
          label: 'Motion Angle / Direction',
          value: c.directionDegrees,
          min: 0.0,
          max: 360.0,
          displayValue: '${c.directionDegrees.round()}°',
          onChanged: (v) => n.updateMotionBlur((cfg) => cfg.copyWith(directionDegrees: v)),
        ),
        _buildSlider(
          label: 'Virtual Shutter Angle',
          value: c.shutterAngle,
          min: 45.0,
          max: 360.0,
          displayValue: '${c.shutterAngle.round()}°',
          onChanged: (v) => n.updateMotionBlur((cfg) => cfg.copyWith(shutterAngle: v)),
        ),
        _buildSlider(
          label: 'Sample Steps',
          value: c.sampleCount.toDouble(),
          min: 4.0,
          max: 32.0,
          divisions: 7,
          displayValue: '${c.sampleCount} samples',
          onChanged: (v) => n.updateMotionBlur((cfg) => cfg.copyWith(sampleCount: v.round())),
        ),
      ],
    );
  }

  // ── 2. Film Grain Controls ────────────────────────────────────────────────
  Widget _buildFilmGrainControls(
      FilmGrainEffectConfig c, AdvancedVideoEffectsNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPresetRow(['16mm Indie', '35mm Fine', 'Vintage Celluloid'],
            (preset) => n.applyFilmGrainPreset(preset)),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Grain Intensity',
          value: c.intensity,
          displayValue: '${(c.intensity * 100).round()}%',
          onChanged: (v) => n.updateFilmGrain((cfg) => cfg.copyWith(intensity: v)),
        ),
        _buildSlider(
          label: 'Grain Amount',
          value: c.grainAmount,
          min: 0.0,
          max: 100.0,
          displayValue: '${c.grainAmount.round()}%',
          onChanged: (v) => n.updateFilmGrain((cfg) => cfg.copyWith(grainAmount: v)),
        ),
        // Grain Size Selector
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 170,
                child: Text(
                  'Grain Particle Size',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFFD1D5DB)),
                ),
              ),
              Expanded(
                child: SegmentedButton<FilmGrainSize>(
                  segments: const [
                    ButtonSegment(value: FilmGrainSize.fine, label: Text('Fine (35mm)')),
                    ButtonSegment(value: FilmGrainSize.medium, label: Text('Medium (16mm)')),
                    ButtonSegment(value: FilmGrainSize.coarse, label: Text('Coarse (8mm)')),
                  ],
                  selected: {c.grainSize},
                  onSelectionChanged: (set) =>
                      n.updateFilmGrain((cfg) => cfg.copyWith(grainSize: set.first)),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? const Color(0xFFFBBF24).withValues(alpha: 0.25)
                            : const Color(0xFF1B1D2D)),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildSlider(
          label: 'Celluloid Roughness',
          value: c.roughness,
          displayValue: '${(c.roughness * 100).round()}%',
          onChanged: (v) => n.updateFilmGrain((cfg) => cfg.copyWith(roughness: v)),
        ),
        _buildSwitch(
          label: 'Monochrome Grain (Black & White)',
          value: c.isMonochrome,
          onChanged: (v) => n.updateFilmGrain((cfg) => cfg.copyWith(isMonochrome: v)),
        ),
        _buildSlider(
          label: 'Layer Opacity',
          value: c.opacity,
          displayValue: '${(c.opacity * 100).round()}%',
          onChanged: (v) => n.updateFilmGrain((cfg) => cfg.copyWith(opacity: v)),
        ),
      ],
    );
  }

  // ── 3. Glitch Controls ────────────────────────────────────────────────────
  Widget _buildGlitchControls(
      GlitchEffectConfig c, AdvancedVideoEffectsNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPresetRow(['Cyberpunk Burst', 'VHS Tape Tear'],
            (preset) => n.applyGlitchPreset(preset)),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Glitch Intensity',
          value: c.intensity,
          displayValue: '${(c.intensity * 100).round()}%',
          onChanged: (v) => n.updateGlitch((cfg) => cfg.copyWith(intensity: v)),
        ),
        _buildSlider(
          label: 'Frequency (Hz)',
          value: c.frequencyHz,
          min: 0.5,
          max: 20.0,
          displayValue: '${c.frequencyHz.toStringAsFixed(1)} Hz',
          onChanged: (v) => n.updateGlitch((cfg) => cfg.copyWith(frequencyHz: v)),
        ),
        _buildSlider(
          label: 'Displacement Slice Count',
          value: c.sliceCount.toDouble(),
          min: 2.0,
          max: 40.0,
          displayValue: '${c.sliceCount} slices',
          onChanged: (v) => n.updateGlitch((cfg) => cfg.copyWith(sliceCount: v.round())),
        ),
        _buildSlider(
          label: 'RGB Split Distance',
          value: c.rgbSplitDistancePx,
          min: 1.0,
          max: 40.0,
          displayValue: '${c.rgbSplitDistancePx.round()} px',
          onChanged: (v) => n.updateGlitch((cfg) => cfg.copyWith(rgbSplitDistancePx: v)),
        ),
        _buildSlider(
          label: 'Speed & Jitter Chaos',
          value: c.speedJitter,
          displayValue: '${(c.speedJitter * 100).round()}%',
          onChanged: (v) => n.updateGlitch((cfg) => cfg.copyWith(speedJitter: v)),
        ),
      ],
    );
  }

  // ── 4. Digital Noise Controls ─────────────────────────────────────────────
  Widget _buildDigitalNoiseControls(
      DigitalNoiseEffectConfig c, AdvancedVideoEffectsNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSlider(
          label: 'Noise Intensity',
          value: c.intensity,
          displayValue: '${(c.intensity * 100).round()}%',
          onChanged: (v) => n.updateDigitalNoise((cfg) => cfg.copyWith(intensity: v)),
        ),
        _buildSlider(
          label: 'Noise Amount',
          value: c.amount,
          min: 0.0,
          max: 100.0,
          displayValue: '${c.amount.round()}%',
          onChanged: (v) => n.updateDigitalNoise((cfg) => cfg.copyWith(amount: v)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 170,
                child: Text(
                  'Distribution Type',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFFD1D5DB)),
                ),
              ),
              Expanded(
                child: SegmentedButton<DigitalNoiseType>(
                  segments: const [
                    ButtonSegment(value: DigitalNoiseType.gaussian, label: Text('Gaussian')),
                    ButtonSegment(value: DigitalNoiseType.uniform, label: Text('Uniform')),
                    ButtonSegment(value: DigitalNoiseType.saltAndPepper, label: Text('Salt & Pepper')),
                  ],
                  selected: {c.noiseType},
                  onSelectionChanged: (set) =>
                      n.updateDigitalNoise((cfg) => cfg.copyWith(noiseType: set.first)),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? const Color(0xFFA78BFA).withValues(alpha: 0.25)
                            : const Color(0xFF1B1D2D)),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildSwitch(
          label: 'Color Noise (Chroma Artifacts)',
          value: c.colorNoise,
          onChanged: (v) => n.updateDigitalNoise((cfg) => cfg.copyWith(colorNoise: v)),
        ),
        _buildSwitch(
          label: 'Temporal Motion (Animate Each Frame)',
          value: c.isTemporal,
          onChanged: (v) => n.updateDigitalNoise((cfg) => cfg.copyWith(isTemporal: v)),
        ),
      ],
    );
  }

  // ── 5. Chromatic Aberration Controls ──────────────────────────────────────
  Widget _buildChromaticAberrationControls(
      ChromaticAberrationEffectConfig c, AdvancedVideoEffectsNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSlider(
          label: 'Aberration Intensity',
          value: c.intensity,
          displayValue: '${(c.intensity * 100).round()}%',
          onChanged: (v) => n.updateChromaticAberration((cfg) => cfg.copyWith(intensity: v)),
        ),
        _buildSlider(
          label: 'Colour Separation Distance',
          value: c.colourSeparationPx,
          min: 1.0,
          max: 40.0,
          displayValue: '${c.colourSeparationPx.round()} px',
          onChanged: (v) => n.updateChromaticAberration((cfg) => cfg.copyWith(colourSeparationPx: v)),
        ),
        _buildSlider(
          label: 'Displacement Direction',
          value: c.directionDegrees,
          min: 0.0,
          max: 360.0,
          displayValue: '${c.directionDegrees.round()}°',
          onChanged: (v) => n.updateChromaticAberration((cfg) => cfg.copyWith(directionDegrees: v)),
        ),
        _buildSlider(
          label: 'Radial Edge Falloff',
          value: c.radialFalloff,
          displayValue: '${(c.radialFalloff * 100).round()}%',
          onChanged: (v) => n.updateChromaticAberration((cfg) => cfg.copyWith(radialFalloff: v)),
        ),
      ],
    );
  }

  // ── 6. Distortion Controls ────────────────────────────────────────────────
  Widget _buildDistortionControls(
      DistortionEffectConfig c, AdvancedVideoEffectsNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 170,
                child: Text(
                  'Distortion Geometry',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFFD1D5DB)),
                ),
              ),
              Expanded(
                child: SegmentedButton<DistortionMode>(
                  segments: const [
                    ButtonSegment(value: DistortionMode.barrel, label: Text('Barrel')),
                    ButtonSegment(value: DistortionMode.pincushion, label: Text('Pincushion')),
                    ButtonSegment(value: DistortionMode.wave, label: Text('Wave')),
                    ButtonSegment(value: DistortionMode.swirl, label: Text('Swirl')),
                  ],
                  selected: {c.distortionMode},
                  onSelectionChanged: (set) =>
                      n.updateDistortion((cfg) => cfg.copyWith(distortionMode: set.first)),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? const Color(0xFF34D399).withValues(alpha: 0.25)
                            : const Color(0xFF1B1D2D)),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildSlider(
          label: 'Curvature Amount',
          value: c.curvature,
          min: -1.0,
          max: 1.0,
          displayValue: c.curvature.toStringAsFixed(2),
          onChanged: (v) => n.updateDistortion((cfg) => cfg.copyWith(curvature: v)),
        ),
        _buildSlider(
          label: 'Oscillation Speed',
          value: c.speed,
          min: 0.1,
          max: 5.0,
          displayValue: '${c.speed.toStringAsFixed(1)}x',
          onChanged: (v) => n.updateDistortion((cfg) => cfg.copyWith(speed: v)),
        ),
      ],
    );
  }

  // ── 7. Lens Dispersion Controls ───────────────────────────────────────────
  Widget _buildLensDispersionControls(
      LensDispersionEffectConfig c, AdvancedVideoEffectsNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSlider(
          label: 'Dispersion Amount',
          value: c.dispersionAmount,
          displayValue: '${(c.dispersionAmount * 100).round()}%',
          onChanged: (v) => n.updateLensDispersion((cfg) => cfg.copyWith(dispersionAmount: v)),
        ),
        _buildSlider(
          label: 'Spectral Spread',
          value: c.spectralSpread,
          min: 0.1,
          max: 2.0,
          displayValue: '${c.spectralSpread.toStringAsFixed(1)}x',
          onChanged: (v) => n.updateLensDispersion((cfg) => cfg.copyWith(spectralSpread: v)),
        ),
        _buildSlider(
          label: 'Lens Edge Falloff',
          value: c.lensEdgeFalloff,
          displayValue: '${(c.lensEdgeFalloff * 100).round()}%',
          onChanged: (v) => n.updateLensDispersion((cfg) => cfg.copyWith(lensEdgeFalloff: v)),
        ),
      ],
    );
  }

  // ── 8. Flicker Controls ───────────────────────────────────────────────────
  Widget _buildFlickerControls(
      FlickerEffectConfig c, AdvancedVideoEffectsNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSlider(
          label: 'Flicker Frequency',
          value: c.frequencyHz,
          min: 1.0,
          max: 30.0,
          displayValue: '${c.frequencyHz.round()} Hz',
          onChanged: (v) => n.updateFlicker((cfg) => cfg.copyWith(frequencyHz: v)),
        ),
        _buildSlider(
          label: 'Strobe Amplitude',
          value: c.amplitude,
          displayValue: '${(c.amplitude * 100).round()}%',
          onChanged: (v) => n.updateFlicker((cfg) => cfg.copyWith(amplitude: v)),
        ),
        _buildSwitch(
          label: 'Stochastic Random Jitter',
          value: c.isRandom,
          onChanged: (v) => n.updateFlicker((cfg) => cfg.copyWith(isRandom: v)),
        ),
      ],
    );
  }

  // ── 9. Ghost Trail Controls ───────────────────────────────────────────────
  Widget _buildGhostTrailControls(
      GhostTrailEffectConfig c, AdvancedVideoEffectsNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSlider(
          label: 'Frame Spacing Delay',
          value: c.frameSpacing.toDouble(),
          min: 1.0,
          max: 10.0,
          displayValue: '${c.frameSpacing} frames',
          onChanged: (v) => n.updateGhostTrail((cfg) => cfg.copyWith(frameSpacing: v.round())),
        ),
        _buildSlider(
          label: 'Ghost Copies Count',
          value: c.ghostCount.toDouble(),
          min: 1.0,
          max: 8.0,
          divisions: 7,
          displayValue: '${c.ghostCount} echoes',
          onChanged: (v) => n.updateGhostTrail((cfg) => cfg.copyWith(ghostCount: v.round())),
        ),
        _buildSlider(
          label: 'Decay & Fade Rate',
          value: c.fadeDecayRate,
          displayValue: '${(c.fadeDecayRate * 100).round()}%',
          onChanged: (v) => n.updateGhostTrail((cfg) => cfg.copyWith(fadeDecayRate: v)),
        ),
      ],
    );
  }

  // ── 10. Blur Detection Controls ───────────────────────────────────────────
  Widget _buildBlurDetectionControls(
      BlurDetectionEffectConfig c, AdvancedVideoEffectsNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSlider(
          label: 'Focus Detection Threshold',
          value: c.detectionThreshold,
          displayValue: '${(c.detectionThreshold * 100).round()}%',
          onChanged: (v) => n.updateBlurDetection((cfg) => cfg.copyWith(detectionThreshold: v)),
        ),
        _buildSlider(
          label: 'Detection Sensitivity',
          value: c.sensitivity,
          displayValue: '${(c.sensitivity * 100).round()}%',
          onChanged: (v) => n.updateBlurDetection((cfg) => cfg.copyWith(sensitivity: v)),
        ),
        _buildSwitch(
          label: 'Show Visual Heatmap Overlay in Preview',
          value: c.showHeatmapOverlay,
          onChanged: (v) => n.updateBlurDetection((cfg) => cfg.copyWith(showHeatmapOverlay: v)),
        ),
      ],
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────

  Widget _buildPresetRow(List<String> presets, ValueChanged<String> onSelect) {
    return Row(
      children: [
        const Text(
          'Presets:',
          style: TextStyle(fontSize: 11.5, color: Color(0xFF8B92A8), fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        ...presets.map((preset) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                label: Text(preset, style: const TextStyle(fontSize: 11, color: Color(0xFFF3F4F8))),
                backgroundColor: const Color(0xFF1E2235),
                side: const BorderSide(color: Color(0xFF2E334D)),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                onPressed: () => onSelect(preset),
              ),
            )),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required String displayValue,
    required ValueChanged<double> onChanged,
    double min = 0.0,
    double max = 1.0,
    int? divisions,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFFD1D5DB)),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF8B5CF6),
                inactiveTrackColor: const Color(0xFF1F2233),
                thumbColor: const Color(0xFFF3F4F8),
                overlayColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                trackHeight: 3.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              displayValue,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC4B5FD),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFFD1D5DB)),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF8B5CF6),
            activeTrackColor: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
            inactiveThumbColor: const Color(0xFF6B7280),
            inactiveTrackColor: const Color(0xFF1E2235),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _EffectSelectorCard extends StatelessWidget {
  const _EffectSelectorCard({
    required this.type,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
    required this.onToggleEnabled,
  });

  final AdvancedEffectType type;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleEnabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E2238) : const Color(0xFF121420),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? type.accentColor
                : (isEnabled
                    ? type.accentColor.withValues(alpha: 0.4)
                    : const Color(0xFF23263B)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  type.icon,
                  size: 18,
                  color: isSelected || isEnabled
                      ? type.accentColor
                      : const Color(0xFF6B7280),
                ),
                GestureDetector(
                  onTap: () => onToggleEnabled(!isEnabled),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isEnabled ? type.accentColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: isEnabled
                            ? type.accentColor
                            : const Color(0xFF4B5563),
                        width: 1.2,
                      ),
                    ),
                    child: isEnabled
                        ? const Icon(Icons.check, size: 12, color: Colors.black)
                        : null,
                  ),
                ),
              ],
            ),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFFF3F4F8)
                    : (isEnabled
                        ? const Color(0xFFE5E7EB)
                        : const Color(0xFF9CA3AF)),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
