import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/providers/video_upload_provider.dart';
import '../models/editing_effect.dart';
import '../providers/effects_provider.dart';

/// Polished Creator Effect Recipe card featuring:
/// - Distinct thumbnail icon with recipe accent color
/// - Bold creator recipe title & concise one-line description
/// - Recipe sub-components indicator pill (e.g. "3 layers")
/// - Dedicated selection CHECKBOX (no apply button!)
/// - Clicking focuses in top preview + toggles checkbox
/// - Internal code (CLP_FX_...) is strictly hidden from UI
class EffectCard extends ConsumerStatefulWidget {
  const EffectCard({
    required this.effect,
    super.key,
  });

  final EditingEffect effect;

  @override
  ConsumerState<EffectCard> createState() => _EffectCardState();
}

class _EffectCardState extends ConsumerState<EffectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effect = widget.effect;
    final uploadState = ref.watch(videoUploadProvider);
    final isSelected = ref.watch(
      effectsProvider.select((s) => s.isSelected(effect.id)),
    );
    final isFocused = ref.watch(
      effectsProvider.select((s) => s.focusedEffectId == effect.id),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          // Clicking anywhere on the card toggles its selection
          // and focuses it in the top preview banner
          ref.read(effectsProvider.notifier).toggleEffect(
                effect.id,
                videoFilePath: uploadState.filePath,
              );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  : isFocused
                      ? const Color(0xFF6366F1).withValues(alpha: 0.7)
                      : _isHovered
                          ? const Color(0xFF333852)
                          : const Color(0xFF1E2232),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.16),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── 1. Thumbnail Icon Box ─────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: effect.accentColor.withValues(
                    alpha: isSelected ? 0.22 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: effect.accentColor.withValues(
                      alpha: isSelected ? 0.6 : 0.25,
                    ),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Icon(
                    effect.badgeIcon ?? _resolveDefaultIcon(effect.category),
                    size: 20,
                    color: isSelected ? Colors.white : effect.accentColor,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ── 2. Effect Name, Layers Count & Description ────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            effect.name,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                              letterSpacing: 0.3,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFEDEDF2),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (effect.isTrending) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'HOT',
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF87171),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      effect.shortDescription,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E95A8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── 3. Checkbox (Actual Multi-Select Control) ─────────────────
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ref.read(effectsProvider.notifier).toggleEffect(
                        effect.id,
                        videoFilePath: uploadState.filePath,
                      );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF8B5CF6)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF8B5CF6)
                          : _isHovered
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF374151),
                      width: 1.6,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
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

  IconData _resolveDefaultIcon(EffectCategory cat) {
    return switch (cat) {
      EffectCategory.character => Icons.military_tech_rounded,
      EffectCategory.aura => Icons.auto_awesome_rounded,
      EffectCategory.face => Icons.face_retouching_natural_rounded,
      EffectCategory.meme => Icons.sentiment_very_satisfied_rounded,
      EffectCategory.digital => Icons.terminal_rounded,
    };
  }
}
