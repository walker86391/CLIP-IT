import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sound_effects_provider.dart';

/// Real-time Sound Effects usage meter replacing fake/generic status pills.
///
/// Accurately computes and renders:
/// - How many effects are selected out of the total available catalogue.
/// - Exact usage percentage (e.g. "3 / 17 Used • 17.6%").
/// - High-precision gradient progress bar showing allocation.
class SoundEffectsUsagePill extends ConsumerWidget {
  const SoundEffectsUsagePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(soundEffectsProvider);
    final selected = state.selectedCount;
    final total = state.totalCount;
    final pct = state.usagePercentage;
    final fraction = state.usageFraction;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF11131F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF222638),
          width: 0.9,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Label, Ratio, and Percentage
          Row(
            children: [
              Icon(
                Icons.equalizer_rounded,
                size: 13,
                color: pct > 0 ? const Color(0xFF8B5CF6) : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 5),
              const Expanded(
                child: Text(
                  'AUDIO FX ALLOCATION',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF9CA3AF),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$selected / $total (${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)}%)',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: pct > 0 ? const Color(0xFFC4B5FD) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Middle: High-precision linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: const Color(0xFF1F2233),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              ),
            ),
          ),

          const SizedBox(height: 5),

          // Bottom subtitle: Dynamic availability context
          Row(
            children: [
              Expanded(
                child: Text(
                  selected == 0
                      ? 'No effects selected'
                      : '$selected audio ${selected == 1 ? 'stem' : 'stems'} selected',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${total - selected} free',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
