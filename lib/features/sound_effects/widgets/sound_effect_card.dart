import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sound_effect_item.dart';
import '../providers/sound_effects_provider.dart';

/// Clean block-like sound effect card featuring:
/// - Leading sound wave thumbnail with theme accent color.
/// - Proper visual name and concise duration badge.
/// - Dedicated instant Play / Stop button (no scrubbers, seeking, or next/back bars).
/// - Dedicated selection checkbox for including the effect in video rendering.
/// - Hover state with subtle ambient glow.
class SoundEffectCard extends ConsumerStatefulWidget {
  const SoundEffectCard({
    required this.effect,
    super.key,
  });

  final SoundEffectItem effect;

  @override
  ConsumerState<SoundEffectCard> createState() => _SoundEffectCardState();
}

class _SoundEffectCardState extends ConsumerState<SoundEffectCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effect = widget.effect;
    final isSelected = ref.watch(
      soundEffectsProvider.select((s) => s.isSelected(effect.id)),
    );
    final isPlaying = ref.watch(
      soundEffectsProvider.select((s) => s.isPlaying(effect.id)),
    );

    if (isPlaying) {
      if (!_waveController.isAnimating) {
        _waveController.repeat(reverse: true);
      }
    } else {
      if (_waveController.isAnimating) {
        _waveController.stop();
        _waveController.reset();
      }
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          ref.read(soundEffectsProvider.notifier).toggleSelection(effect.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF161528)
                : _isHovered
                    ? const Color(0xFF141724)
                    : const Color(0xFF0F111A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : isPlaying
                      ? const Color(0xFF38BDF8)
                      : _isHovered
                          ? const Color(0xFF333852)
                          : const Color(0xFF1E2232),
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.16),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              if (isPlaying)
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.20),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── 1. Accent Audio Icon / Wave Box ─────────────────────────────
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: effect.accentColor.withValues(
                    alpha: isSelected ? 0.22 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: effect.accentColor.withValues(
                      alpha: isSelected ? 0.55 : 0.25,
                    ),
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: isPlaying
                    ? AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, _) {
                          return Icon(
                            Icons.graphic_eq_rounded,
                            size: 20 + (_waveController.value * 2),
                            color: effect.accentColor,
                          );
                        },
                      )
                    : Icon(
                        effect.icon,
                        size: 20,
                        color: effect.accentColor,
                      ),
              ),

              const SizedBox(width: 12),

              // ── 2. Title & Metadata Pill ──────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      effect.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFFF3F4F8)
                            : const Color(0xFFD1D5DB),
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        // Category Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B1E2D),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            effect.category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Duration Tag
                        Text(
                          effect.formattedDuration,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── 3. Quick Play / Audition Button (Pure instant trigger) ──────
              Tooltip(
                message: isPlaying ? 'Stop playback' : 'Play sound effect preview',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(soundEffectsProvider.notifier).togglePlaySound(
                            effect.id,
                            effect.assetPath,
                          );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isPlaying
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.22)
                            : const Color(0xFF191C2B),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isPlaying
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF2C3044),
                          width: 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        size: 18,
                        color: isPlaying
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // ── 4. Dedicated Selection Checkbox ────────────────────────────
              Tooltip(
                message: isSelected ? 'Remove from video' : 'Include in video',
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF8B5CF6)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF3B4058),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
