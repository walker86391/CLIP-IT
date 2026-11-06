import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/audio_editing_provider.dart';

/// Professional 3-Channel Master Volume Mixer for ClipIt.
///
/// Channels:
/// - Channel 1: Main Audio (Original video sound, 0-100%, mute/unmute)
/// - Channel 2: Background Music (Only visible when user has imported an MP3, 0-100%, mute/unmute)
/// - Channel 3: Sound Effects (Added sound effects, 0-100%, mute/unmute)
class ThreeChannelMixerWidget extends ConsumerWidget {
  const ThreeChannelMixerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioEditingProvider);
    final notifier = ref.read(audioEditingProvider.notifier);
    final mixer = state.mixer;
    final hasMusicTrack = state.customMusic.hasTrack;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131522),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26293D)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.equalizer_rounded,
                      size: 20, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 8),
                  Text(
                    'THREE-CHANNEL VOLUME MIXER',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Color(0xFFF3F4F8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2235),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF2E334D)),
                ),
                child: Text(
                  hasMusicTrack ? '3 CHANNELS ACTIVE' : '2 CHANNELS ACTIVE',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Master acoustic mixing console. Adjust audio balance across speech, background music, and sound effects independently.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF8B92A8)),
          ),
          const SizedBox(height: 20),

          // ── The 3 Channel Mixer Strips ───────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── CHANNEL 1: Main Audio ────────────────────────────────────
              Expanded(
                child: _MixerChannelStrip(
                  channelNumber: 1,
                  channelTitle: 'MAIN AUDIO',
                  subtitle: 'Original Video Track',
                  icon: Icons.mic_rounded,
                  accentColor: const Color(0xFF38BDF8),
                  volume: mixer.channel1MainVolume,
                  isMuted: mixer.channel1MainMuted,
                  onVolumeChanged: notifier.setMainAudioVolume,
                  onToggleMute: notifier.toggleMainAudioMute,
                ),
              ),

              const SizedBox(width: 14),

              // ── CHANNEL 2: Background Music (Only appears if user imported MP3)
              Expanded(
                child: hasMusicTrack
                    ? _MixerChannelStrip(
                        channelNumber: 2,
                        channelTitle: 'BACKGROUND MUSIC',
                        subtitle: state.customMusic.fileName ?? 'Imported Track',
                        icon: Icons.music_note_rounded,
                        accentColor: const Color(0xFFEC4899),
                        volume: mixer.channel2MusicVolume,
                        isMuted: mixer.channel2MusicMuted,
                        onVolumeChanged: notifier.setMusicChannelVolume,
                        onToggleMute: notifier.toggleMusicChannelMute,
                        badgeText: state.autoDucking.isEnabled
                            ? 'DUCKING ON'
                            : null,
                      )
                    : _buildEmptyMusicChannelPlaceholder(context),
              ),

              const SizedBox(width: 14),

              // ── CHANNEL 3: Sound Effects ─────────────────────────────────
              Expanded(
                child: _MixerChannelStrip(
                  channelNumber: 3,
                  channelTitle: 'SOUND EFFECTS',
                  subtitle: 'Meme & Impact FX',
                  icon: Icons.surround_sound_rounded,
                  accentColor: const Color(0xFFF59E0B),
                  volume: mixer.channel3SfxVolume,
                  isMuted: mixer.channel3SfxMuted,
                  onVolumeChanged: notifier.setSfxVolume,
                  onToggleMute: notifier.toggleSfxMute,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMusicChannelPlaceholder(BuildContext context) {
    return Container(
      height: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11131E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF202334),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.music_off_rounded,
            size: 28,
            color: Color(0xFF4B5563),
          ),
          SizedBox(height: 10),
          Text(
            'CHANNEL 2 — MUSIC',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Channel 2 will appear here automatically once you import an MP3 background track in the Music section.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}

class _MixerChannelStrip extends StatelessWidget {
  const _MixerChannelStrip({
    required this.channelNumber,
    required this.channelTitle,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.volume,
    required this.isMuted,
    required this.onVolumeChanged,
    required this.onToggleMute,
    this.badgeText,
  });

  final int channelNumber;
  final String channelTitle;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final double volume;
  final bool isMuted;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onToggleMute;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final percent = isMuted ? 0 : (volume * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171926),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Channel Title & Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'CH $channelNumber',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
              if (badgeText != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    badgeText!,
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC4B5FD),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Channel Icon & Name
          Icon(icon, size: 22, color: isMuted ? const Color(0xFF6B7280) : accentColor),
          const SizedBox(height: 6),
          Text(
            channelTitle,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: isMuted ? const Color(0xFF9CA3AF) : const Color(0xFFF3F4F8),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 14),

          // Percentage Readout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F111B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF282C40)),
            ),
            child: Text(
              isMuted ? 'MUTED' : '$percent%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isMuted ? const Color(0xFFEF4444) : accentColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Volume Slider
          SizedBox(
            height: 36,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: isMuted ? const Color(0xFF4B5563) : accentColor,
                inactiveTrackColor: const Color(0xFF23263B),
                thumbColor: const Color(0xFFF3F4F8),
                trackHeight: 3.5,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6.5),
              ),
              child: Slider(
                value: volume,
                onChanged: onVolumeChanged,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Mute Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(
                isMuted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                size: 14,
              ),
              label: Text(isMuted ? 'UNMUTE' : 'MUTE'),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isMuted ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
                side: BorderSide(
                  color: isMuted
                      ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                      : const Color(0xFF2E334D),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: onToggleMute,
            ),
          ),
        ],
      ),
    );
  }
}
