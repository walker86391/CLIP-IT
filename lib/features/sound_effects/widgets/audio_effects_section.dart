import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/audio_editing_models.dart';
import '../providers/audio_editing_provider.dart';

/// Audio Effects section hosting Fade In / Out, Reverb, and Silence Removal.
class AudioEffectsSection extends ConsumerWidget {
  const AudioEffectsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioEditingProvider);
    final notifier = ref.read(audioEditingProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Audio Fade In & Fade Out ────────────────────────────────────
        _buildFadeCard(state.fade, notifier),

        const SizedBox(height: 20),

        // ── 2. Spatial Acoustic Reverb ─────────────────────────────────────
        _buildReverbCard(state.reverb, notifier),

        const SizedBox(height: 20),

        // ── 3. Silence Removal & Speech Isolation ──────────────────────────
        _buildSilenceRemovalCard(state.silenceRemoval, notifier),
      ],
    );
  }

  // ── Audio Fade In / Out ───────────────────────────────────────────────────
  Widget _buildFadeCard(AudioFadeConfig c, AudioEditingNotifier n) {
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
              Icon(Icons.graphic_eq_rounded, size: 18, color: Color(0xFF60A5FA)),
              SizedBox(width: 8),
              Text(
                'AUDIO FADE IN & FADE OUT',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: Color(0xFFF3F4F8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Fade In Sub-card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF171928),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF282C40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Audio Fade In',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    Switch(
                      value: c.fadeInEnabled,
                      activeThumbColor: const Color(0xFF60A5FA),
                      activeTrackColor: const Color(0xFF60A5FA).withValues(alpha: 0.35),
                      inactiveThumbColor: const Color(0xFF6B7280),
                      inactiveTrackColor: const Color(0xFF1E2235),
                      onChanged: n.toggleFadeIn,
                    ),
                  ],
                ),
                if (c.fadeInEnabled) ...[
                  const SizedBox(height: 8),
                  _buildSlider(
                    label: 'Fade-In Duration',
                    value: c.fadeInDurationSec,
                    min: 0.1,
                    max: 10.0,
                    displayValue: '${c.fadeInDurationSec.toStringAsFixed(1)}s',
                    onChanged: n.setFadeInDuration,
                  ),
                  _buildCurveDropdown(
                    label: 'Fade-In Curve',
                    selected: c.fadeInCurve,
                    onChanged: n.setFadeInCurve,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Fade Out Sub-card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF171928),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF282C40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Audio Fade Out',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    Switch(
                      value: c.fadeOutEnabled,
                      activeThumbColor: const Color(0xFF60A5FA),
                      activeTrackColor: const Color(0xFF60A5FA).withValues(alpha: 0.35),
                      inactiveThumbColor: const Color(0xFF6B7280),
                      inactiveTrackColor: const Color(0xFF1E2235),
                      onChanged: n.toggleFadeOut,
                    ),
                  ],
                ),
                if (c.fadeOutEnabled) ...[
                  const SizedBox(height: 8),
                  _buildSlider(
                    label: 'Fade-Out Duration',
                    value: c.fadeOutDurationSec,
                    min: 0.1,
                    max: 10.0,
                    displayValue: '${c.fadeOutDurationSec.toStringAsFixed(1)}s',
                    onChanged: n.setFadeOutDuration,
                  ),
                  _buildCurveDropdown(
                    label: 'Fade-Out Curve',
                    selected: c.fadeOutCurve,
                    onChanged: n.setFadeOutCurve,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurveDropdown({
    required String label,
    required AudioFadeCurve selected,
    required ValueChanged<AudioFadeCurve> onChanged,
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1E2E),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF2E334D)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AudioFadeCurve>(
                  value: selected,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A1D2C),
                  style: const TextStyle(fontSize: 12, color: Color(0xFFF3F4F8)),
                  items: AudioFadeCurve.values.map((curve) {
                    return DropdownMenuItem(
                      value: curve,
                      child: Text('${curve.displayName} — ${curve.description}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) onChanged(val);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Audio Reverb ──────────────────────────────────────────────────────────
  Widget _buildReverbCard(AudioReverbConfig c, AudioEditingNotifier n) {
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
                  Icon(Icons.surround_sound_rounded, size: 18, color: Color(0xFFA78BFA)),
                  SizedBox(width: 8),
                  Text(
                    'REVERB & ACOUSTICS',
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
                activeThumbColor: const Color(0xFFA78BFA),
                activeTrackColor: const Color(0xFFA78BFA).withValues(alpha: 0.35),
                inactiveThumbColor: const Color(0xFF6B7280),
                inactiveTrackColor: const Color(0xFF1E2235),
                onChanged: n.toggleReverb,
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildSlider(
            label: 'Reverb Amount',
            value: c.reverbAmount,
            displayValue: '${(c.reverbAmount * 100).round()}%',
            onChanged: n.setReverbAmount,
          ),
          _buildSlider(
            label: 'Simulated Room Size',
            value: c.roomSize,
            displayValue: '${(c.roomSize * 100).round()}%',
            onChanged: n.setReverbRoomSize,
          ),
          _buildSlider(
            label: 'Reverberation Decay',
            value: c.decay,
            min: 0.1,
            max: 5.0,
            displayValue: '${c.decay.toStringAsFixed(1)}s',
            onChanged: n.setReverbDecay,
          ),
          _buildSlider(
            label: 'Wet / Dry Signal Mix',
            value: c.wetDryMix,
            displayValue: '${(c.wetDryMix * 100).round()}%',
            onChanged: n.setReverbWetDryMix,
          ),
        ],
      ),
    );
  }

  // ── Silence Removal ───────────────────────────────────────────────────────
  Widget _buildSilenceRemovalCard(
    SilenceRemovalConfig c,
    AudioEditingNotifier n,
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
                children: [
                  const Icon(Icons.mic_off_rounded, size: 18, color: Color(0xFF34D399)),
                  const SizedBox(width: 8),
                  const Text(
                    'SILENCE REMOVAL',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: Color(0xFFF3F4F8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
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
              Switch(
                value: c.isEnabled,
                activeThumbColor: const Color(0xFF34D399),
                activeTrackColor: const Color(0xFF34D399).withValues(alpha: 0.35),
                inactiveThumbColor: const Color(0xFF6B7280),
                inactiveTrackColor: const Color(0xFF1E2235),
                onChanged: n.toggleSilenceRemoval,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Automatically detects and cuts dead silence while safeguarding word boundaries with protective speech padding.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF8B92A8)),
          ),
          const SizedBox(height: 14),

          _buildSlider(
            label: 'Silence Threshold (dB)',
            value: c.thresholdDb,
            min: -60.0,
            max: -10.0,
            displayValue: '${c.thresholdDb.round()} dB',
            onChanged: n.setSilenceThresholdDb,
          ),
          _buildSlider(
            label: 'Minimum Silence Duration',
            value: c.minDurationMs.toDouble(),
            min: 100.0,
            max: 3000.0,
            displayValue: '${c.minDurationMs} ms',
            onChanged: (v) => n.setMinSilenceDurationMs(v.round()),
          ),
          _buildSlider(
            label: 'Preserve Speech Margin',
            value: c.speechPaddingMs.toDouble(),
            min: 0.0,
            max: 500.0,
            displayValue: '${c.speechPaddingMs} ms',
            onChanged: (v) => n.setSpeechPaddingMs(v.round()),
          ),
          _buildSlider(
            label: 'Detection Sensitivity',
            value: c.sensitivity,
            displayValue: '${(c.sensitivity * 100).round()}%',
            onChanged: n.setSilenceSensitivity,
          ),
          const SizedBox(height: 12),

          // Display Detected Silence Regions
          const Text(
            'Detected Silence Regions (Analysis Preview):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE5E7EB)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF171926),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF282C40)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF9CA3AF)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Silence regions will be analyzed during the pipeline rendering stage based on your threshold (-35 dB) and speech margin (150 ms).',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
                  ),
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
