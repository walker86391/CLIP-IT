import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/video_repair_models.dart';
import '../providers/video_repair_provider.dart';

/// Dedicated Video Repair subsection with Denoising, Blur Detection Analysis,
/// Quality Metrics, Noise Reduction, Before/After Comparison, and Pipeline Pending status.
class VideoRepairSection extends ConsumerWidget {
  const VideoRepairSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoRepairProvider);
    final notifier = ref.read(videoRepairProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Pipeline Pending Status Banner ──────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  size: 16,
                  color: Color(0xFFFCD34D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Text(
                          'VIDEO REPAIR — PIPELINE PENDING',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Color(0xFFFCD34D),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ready for Processing',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFDE68A),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Video repair settings and blur detection thresholds are configured locally. Heavy spatio-temporal denoising and frame restoration will run during the automated pipeline render stage.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFFD1D5DB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── 2. Video Quality Analysis Overview ─────────────────────────────
        _buildQualityAnalysisCard(state.qualityReport),

        const SizedBox(height: 20),

        // ── 3. Interactive Before / After Comparison ───────────────────────
        _buildComparisonCard(context, state, notifier),

        const SizedBox(height: 20),

        // ── 4. Video Denoising Controls ────────────────────────────────────
        _buildDenoiseCard(state.denoise, notifier),

        const SizedBox(height: 20),

        // ── 5. Blur Detection Analysis Panel ───────────────────────────────
        _buildBlurDetectionCard(state.blurAnalysis, notifier),

        const SizedBox(height: 20),

        // ── 6. Repair Intensity & Detail Preservation ──────────────────────
        _buildNoiseReductionCard(state.noiseReduction, notifier),
      ],
    );
  }

  // ── Video Quality Analysis ────────────────────────────────────────────────
  Widget _buildQualityAnalysisCard(VideoQualityAnalysisReport report) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131522),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26293D)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.analytics_rounded, size: 18, color: Color(0xFF38BDF8)),
              SizedBox(width: 8),
              Text(
                'VIDEO QUALITY ANALYSIS',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: Color(0xFFF3F4F8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Score Gauge Pill
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${report.overallScore}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF34D399),
                      ),
                    ),
                    const Text(
                      'HEALTH / 100',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Color(0xFF6EE7B7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.statusMessage,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF3F4F8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _buildMetricChip('Resolution', report.resolution),
                        _buildMetricChip('Framerate', '${report.frameRate.round()} fps'),
                        _buildMetricChip('Bitrate', '${report.estimatedBitrateKbps} kbps'),
                        _buildMetricChip('Codec', report.codec),
                      ],
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

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E2E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E334D)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
      ),
    );
  }

  // ── Interactive Before / After Comparison ─────────────────────────────────
  Widget _buildComparisonCard(
    BuildContext context,
    VideoRepairState state,
    VideoRepairNotifier notifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131522),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26293D)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.compare_rounded, size: 18, color: Color(0xFFA78BFA)),
                  SizedBox(width: 8),
                  Text(
                    'BEFORE / AFTER REPAIR PREVIEW',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: Color(0xFFF3F4F8),
                    ),
                  ),
                ],
              ),
              // Mode Selector
              SegmentedButton<ComparisonDisplayMode>(
                segments: const [
                  ButtonSegment(
                    value: ComparisonDisplayMode.splitScreen,
                    label: Text('Split Slider'),
                  ),
                  ButtonSegment(
                    value: ComparisonDisplayMode.sideBySide,
                    label: Text('Side-by-Side'),
                  ),
                  ButtonSegment(
                    value: ComparisonDisplayMode.toggle,
                    label: Text('Toggle View'),
                  ),
                ],
                selected: {state.comparisonMode},
                onSelectionChanged: (set) =>
                    notifier.setComparisonMode(set.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.25)
                        : const Color(0xFF1B1E2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Comparison Visualizer Box
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF090A10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF23263B)),
            ),
            child: Stack(
              children: [
                // Background simulated frames
                Positioned.fill(
                  child: Row(
                    children: [
                      // Before (Left / Raw with grain)
                      Expanded(
                        flex: (state.splitPosition * 100).round(),
                        child: Container(
                          color: const Color(0xFF1A1C28),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.grain, size: 28, color: Color(0xFF6B7280)),
                              SizedBox(height: 6),
                              Text(
                                'ORIGINAL FOOTAGE (NOISY)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Split Divider Line
                      Container(width: 2, color: const Color(0xFF8B5CF6)),
                      // After (Right / Restored)
                      Expanded(
                        flex: ((1.0 - state.splitPosition) * 100).round(),
                        child: Container(
                          color: const Color(0xFF131525),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.auto_fix_high, size: 28, color: Color(0xFFC4B5FD)),
                              SizedBox(height: 6),
                              Text(
                                'REPAIRED (DENOISED & SHARP)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFC4B5FD),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Interactive Split Position Drag Controller
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF383C5A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Split Position: ',
                            style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                          ),
                          Text(
                            '${(state.splitPosition * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF3F4F8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Split Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF8B5CF6),
              inactiveTrackColor: const Color(0xFF1E2235),
              thumbColor: const Color(0xFFF3F4F8),
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
            ),
            child: Slider(
              value: state.splitPosition,
              onChanged: notifier.setSplitPosition,
            ),
          ),
        ],
      ),
    );
  }

  // ── Video Denoising ───────────────────────────────────────────────────────
  Widget _buildDenoiseCard(VideoDenoiseConfig c, VideoRepairNotifier n) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131522),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26293D)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.cleaning_services_rounded, size: 18, color: Color(0xFF60A5FA)),
                  SizedBox(width: 8),
                  Text(
                    'VIDEO DENOISING',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: Color(0xFFF3F4F8),
                    ),
                  ),
                ],
              ),
              Switch(
                value: c.isEnabled,
                activeThumbColor: const Color(0xFF60A5FA),
                activeTrackColor: const Color(0xFF60A5FA).withValues(alpha: 0.35),
                inactiveThumbColor: const Color(0xFF6B7280),
                inactiveTrackColor: const Color(0xFF1E2235),
                onChanged: n.toggleDenoise,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Algorithm dropdown / selector
          Row(
            children: [
              const SizedBox(
                width: 170,
                child: Text(
                  'Denoising Filter',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFFD1D5DB)),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1E2E),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2E334D)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<VideoDenoiseAlgorithm>(
                      value: c.algorithm,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1A1D2C),
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFFF3F4F8)),
                      items: VideoDenoiseAlgorithm.values.map((algo) {
                        return DropdownMenuItem(
                          value: algo,
                          child: Text(algo.displayName),
                        );
                      }).toList(),
                      onChanged: (algo) {
                        if (algo != null) n.setDenoiseAlgorithm(algo);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          _buildSlider(
            label: 'Denoising Strength',
            value: c.strength,
            displayValue: '${(c.strength * 100).round()}%',
            onChanged: n.setDenoiseStrength,
          ),
          _buildSlider(
            label: 'Luma Spatial Threshold',
            value: c.lumaThreshold,
            min: 1.0,
            max: 20.0,
            displayValue: c.lumaThreshold.toStringAsFixed(1),
            onChanged: n.setLumaThreshold,
          ),
          _buildSlider(
            label: 'Chroma Spatial Threshold',
            value: c.chromaThreshold,
            min: 1.0,
            max: 20.0,
            displayValue: c.chromaThreshold.toStringAsFixed(1),
            onChanged: n.setChromaThreshold,
          ),
          _buildSlider(
            label: 'Temporal Frame Blend',
            value: c.temporalBlend,
            displayValue: '${(c.temporalBlend * 100).round()}%',
            onChanged: n.setTemporalBlend,
          ),
        ],
      ),
    );
  }

  // ── Blur Detection Analysis ───────────────────────────────────────────────
  Widget _buildBlurDetectionCard(
    BlurDetectionAnalysisConfig c,
    VideoRepairNotifier n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131522),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26293D)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.center_focus_strong_rounded, size: 18, color: Color(0xFF2DD4BF)),
                  SizedBox(width: 8),
                  Text(
                    'BLUR DETECTION & FRAME ANALYSIS',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: Color(0xFFF3F4F8),
                    ),
                  ),
                ],
              ),
              Switch(
                value: c.isEnabled,
                activeThumbColor: const Color(0xFF2DD4BF),
                activeTrackColor: const Color(0xFF2DD4BF).withValues(alpha: 0.35),
                inactiveThumbColor: const Color(0xFF6B7280),
                inactiveTrackColor: const Color(0xFF1E2235),
                onChanged: n.toggleBlurDetection,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Scans video frames using Laplacian sharpness variance to identify defocus, motion blur, and low-contrast segments without modifying the original video.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF8B92A8)),
          ),
          const SizedBox(height: 14),

          _buildSlider(
            label: 'Blur Detection Threshold',
            value: c.threshold,
            displayValue: '${(c.threshold * 100).round()}%',
            onChanged: n.setBlurThreshold,
          ),
          _buildSlider(
            label: 'Sampling Interval',
            value: c.sampleRateFrames.toDouble(),
            min: 5.0,
            max: 60.0,
            divisions: 11,
            displayValue: 'Every ${c.sampleRateFrames} frames',
            onChanged: (v) => n.setBlurSampleRate(v.round()),
          ),
          const SizedBox(height: 12),

          // Scan Action Button
          Row(
            children: [
              ElevatedButton.icon(
                icon: c.isScanning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.radar_rounded, size: 16),
                label: Text(c.isScanning ? 'Scanning Frames...' : 'Analyze Blurry Sections'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: c.isScanning ? null : n.runBlurScan,
              ),
              if (c.isScanning) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: LinearProgressIndicator(
                    value: c.scanProgress,
                    backgroundColor: const Color(0xFF1E2235),
                    color: const Color(0xFF14B8A6),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Detected Blurry Segments List
          const Text(
            'Identified Blurry Segments:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE5E7EB)),
          ),
          const SizedBox(height: 8),
          if (c.detectedSegments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No blurry frames detected in the current pass.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
              ),
            )
          else
            ...c.detectedSegments.map((seg) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171926),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF282C40)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: seg.severityColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: seg.severityColor),
                            ),
                            child: Text(
                              seg.severity.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: seg.severityColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            seg.timeLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF3F4F8),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${seg.reason} (Score ${(seg.blurScore * 100).round()}%)',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  // ── Noise Reduction & Intensity ───────────────────────────────────────────
  Widget _buildNoiseReductionCard(
    NoiseReductionConfig c,
    VideoRepairNotifier n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131522),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26293D)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.tune_rounded, size: 18, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text(
                'REPAIR INTENSITY & DETAIL PRESERVATION',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: Color(0xFFF3F4F8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Intensity Level Selector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const SizedBox(
                  width: 170,
                  child: Text(
                    'Preset Repair Intensity',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFFD1D5DB)),
                  ),
                ),
                Expanded(
                  child: SegmentedButton<RepairIntensityLevel>(
                    segments: const [
                      ButtonSegment(value: RepairIntensityLevel.subtle, label: Text('Subtle')),
                      ButtonSegment(value: RepairIntensityLevel.moderate, label: Text('Moderate')),
                      ButtonSegment(value: RepairIntensityLevel.aggressive, label: Text('Aggressive')),
                      ButtonSegment(value: RepairIntensityLevel.custom, label: Text('Custom')),
                    ],
                    selected: {c.level},
                    onSelectionChanged: (set) =>
                        n.setRepairIntensityLevel(set.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                            : const Color(0xFF1B1E2E),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (c.level == RepairIntensityLevel.custom)
            _buildSlider(
              label: 'Custom Repair Weight',
              value: c.customIntensity,
              displayValue: '${(c.customIntensity * 100).round()}%',
              onChanged: n.setCustomRepairIntensity,
            ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Preserve Fine Facial Detail & Film Textures',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFFD1D5DB)),
                ),
                Switch(
                  value: c.preserveFineDetail,
                  activeThumbColor: const Color(0xFFF59E0B),
                  activeTrackColor: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  inactiveThumbColor: const Color(0xFF6B7280),
                  inactiveTrackColor: const Color(0xFF1E2235),
                  onChanged: n.togglePreserveFineDetail,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Slider ─────────────────────────────────────────────────────────
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
