import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/audio_editing_models.dart';
import '../providers/audio_editing_provider.dart';

/// Dedicated Background Music and Auto Ducking interface.
class CustomMusicSection extends ConsumerWidget {
  const CustomMusicSection({super.key});

  Future<void> _handlePickMusic(
      BuildContext context, AudioEditingNotifier notifier) async {
    try {
      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'ogg'],
      );

      if (files.isNotEmpty) {
        final picked = files.first;
        final path = picked.path;
        final name = picked.name;
        int? size;
        if (path != null) {
          try {
            size = File(path).lengthSync();
          } catch (_) {}
        }

        notifier.importMusicFile(
          filePath: path ?? name,
          fileName: name,
          fileSizeBytes: size,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import audio: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioEditingProvider);
    final notifier = ref.read(audioEditingProvider.notifier);
    final music = state.customMusic;
    final ducking = state.autoDucking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Custom Background Music Card ────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131522),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF26293D)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.music_note_rounded,
                          size: 20, color: Color(0xFFEC4899)),
                      SizedBox(width: 8),
                      Text(
                        'BACKGROUND MUSIC TRACK',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: Color(0xFFF3F4F8),
                        ),
                      ),
                    ],
                  ),
                  if (music.hasTrack)
                    Switch(
                      value: music.isEnabled,
                      activeThumbColor: const Color(0xFFEC4899),
                      activeTrackColor:
                          const Color(0xFFEC4899).withValues(alpha: 0.35),
                      inactiveThumbColor: const Color(0xFF6B7280),
                      inactiveTrackColor: const Color(0xFF1E2235),
                      onChanged: notifier.toggleMusicEnabled,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Import local MP3 audio to accompany your video clip with custom level mixing, fade transitions, and speech ducking.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF8B92A8)),
              ),
              const SizedBox(height: 16),

              // File Import / File Display Box
              if (!music.hasTrack)
                _buildEmptyTrackImportBox(context, notifier)
              else
                _buildActiveTrackCard(context, music, notifier),

              if (music.hasTrack) ...[
                const SizedBox(height: 16),

                // Music Volume Slider
                _buildSlider(
                  label: 'Music Track Volume',
                  value: music.volume,
                  displayValue: '${music.volumePercent}%',
                  onChanged: notifier.setMusicVolume,
                ),

                // Music Fade In / Fade Out
                _buildSlider(
                  label: 'Music Fade In',
                  value: music.fadeInSec,
                  min: 0.0,
                  max: 10.0,
                  displayValue: '${music.fadeInSec.toStringAsFixed(1)}s',
                  onChanged: notifier.setMusicFadeIn,
                ),
                _buildSlider(
                  label: 'Music Fade Out',
                  value: music.fadeOutSec,
                  min: 0.0,
                  max: 10.0,
                  displayValue: '${music.fadeOutSec.toStringAsFixed(1)}s',
                  onChanged: notifier.setMusicFadeOut,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── 2. Automatic Audio Ducking (With 30% Volume Rule) ───────────────
        _buildAutoDuckingCard(context, music, ducking, notifier),
      ],
    );
  }

  // ── Empty State: Import MP3 Box ───────────────────────────────────────────
  Widget _buildEmptyTrackImportBox(
      BuildContext context, AudioEditingNotifier notifier) {
    return GestureDetector(
      onTap: () => _handlePickMusic(context, notifier),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF171928),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFEC4899).withValues(alpha: 0.35),
            style: BorderStyle.solid,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.file_upload_outlined,
                size: 22,
                color: Color(0xFFF472B6),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Click to Import Local MP3 Audio',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF3F4F8),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Supports MP3, WAV, AAC, M4A local audio files',
              style: TextStyle(fontSize: 11, color: Color(0xFF8B92A8)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active State: Imported Music Track Card ───────────────────────────────
  Widget _buildActiveTrackCard(
    BuildContext context,
    CustomMusicTrack music,
    AudioEditingNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF181B2B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFEC4899).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.audiotrack_rounded,
                  size: 22,
                  color: Color(0xFFF472B6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      music.fileName ?? 'Custom Audio Track',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF3F4F8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (music.formattedFileSize.isNotEmpty)
                          Text(
                            music.formattedFileSize,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'READY',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF34D399),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Replace Button
              TextButton.icon(
                icon: const Icon(Icons.sync_rounded, size: 14),
                label: const Text('Replace'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC4B5FD),
                  textStyle: const TextStyle(fontSize: 11.5),
                ),
                onPressed: () => _handlePickMusic(context, notifier),
              ),
              const SizedBox(width: 4),

              // Remove Button
              IconButton(
                tooltip: 'Remove audio track',
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: Color(0xFFEF4444)),
                onPressed: notifier.removeMusicFile,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Visual Waveform Representation
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF10121D),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF23263B)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(40, (i) {
                // Waveform bar simulation based on pattern
                final heights = [
                  8.0, 14.0, 22.0, 18.0, 28.0, 32.0, 16.0, 24.0, 30.0, 12.0,
                  18.0, 26.0, 34.0, 22.0, 14.0, 20.0, 28.0, 18.0, 24.0, 30.0,
                  10.0, 16.0, 28.0, 32.0, 20.0, 14.0, 22.0, 26.0, 34.0, 18.0,
                  12.0, 24.0, 30.0, 16.0, 22.0, 28.0, 20.0, 14.0, 18.0, 10.0,
                ];
                final height = heights[i % heights.length];
                return Container(
                  width: 3,
                  height: height,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Auto Ducking Card ─────────────────────────────────────────────────────
  Widget _buildAutoDuckingCard(
    BuildContext context,
    CustomMusicTrack music,
    AutoDuckingConfig ducking,
    AudioEditingNotifier notifier,
  ) {
    final isVolumeAboveThreshold = music.volume > 0.30;
    final isLocked = !isVolumeAboveThreshold;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131522),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLocked
              ? const Color(0xFF26293D)
              : const Color(0xFF8B5CF6).withValues(alpha: 0.4),
        ),
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
                  Icon(
                    isLocked ? Icons.lock_outline_rounded : Icons.record_voice_over_rounded,
                    size: 18,
                    color: isLocked ? const Color(0xFF6B7280) : const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AUTOMATIC AUDIO DUCKING',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: isLocked
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFFF3F4F8),
                    ),
                  ),
                ],
              ),

              // Toggle Switch (Visually & functionally locked if volume <= 30%)
              Switch(
                value: ducking.isEnabled,
                activeThumbColor: const Color(0xFF8B5CF6),
                activeTrackColor: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                inactiveThumbColor: const Color(0xFF6B7280),
                inactiveTrackColor: const Color(0xFF1E2235),
                onChanged: isLocked
                    ? null // Visually & functionally disabled when volume <= 30%
                    : (_) => notifier.toggleAutoDucking(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Automatically attenuates background music when speech or vocal activity is detected in the primary audio stream, restoring full volume during pauses.',
            style: TextStyle(
              fontSize: 11.5,
              color: isLocked ? const Color(0xFF6B7280) : const Color(0xFF8B92A8),
            ),
          ),
          const SizedBox(height: 14),

          // ── Explanatory Message / Lock Warning Banner ──────────────────────
          if (isLocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Color(0xFFF87171),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Increase MP3 volume above 30% to enable Auto Ducking.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFCA5A5),
                      ),
                    ),
                  ),
                  Text(
                    'Current: ${music.volumePercent}%',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF87171),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Active Auto Ducking Settings
            _buildSlider(
              label: 'Ducking Attenuation Strength',
              value: ducking.duckingStrength,
              displayValue: '${(ducking.duckingStrength * 100).round()}%',
              onChanged: notifier.setDuckingStrength,
            ),
            _buildSlider(
              label: 'Attack Time (Speech Onset)',
              value: ducking.attackMs.toDouble(),
              min: 10.0,
              max: 500.0,
              displayValue: '${ducking.attackMs} ms',
              onChanged: (v) => notifier.setDuckingAttackMs(v.round()),
            ),
            _buildSlider(
              label: 'Release Time (Restore Music)',
              value: ducking.releaseMs.toDouble(),
              min: 50.0,
              max: 2000.0,
              displayValue: '${ducking.releaseMs} ms',
              onChanged: (v) => notifier.setDuckingReleaseMs(v.round()),
            ),
            _buildSlider(
              label: 'Ducked Target Floor Volume',
              value: ducking.targetVolume,
              min: 0.0,
              max: 0.5,
              displayValue: '${(ducking.targetVolume * 100).round()}%',
              onChanged: notifier.setDuckingTargetVolume,
            ),
          ],
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
