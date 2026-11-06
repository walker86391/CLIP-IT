import 'package:flutter/material.dart';

import '../models/video_look_state.dart';

/// Top horizontal bar providing one-click "Quick Looks" shortcuts:
/// Original, Cinematic, Moody, Warm, Cold, Vintage, Black & White, Dream, High Contrast, Retro.
/// Selecting one immediately populates and adjusts the underlying settings across all categories.
class VideoLookQuickBar extends StatelessWidget {
  const VideoLookQuickBar({
    required this.selectedQuickLook,
    required this.onSelectQuickLook,
    super.key,
  });

  final QuickLookPreset selectedQuickLook;
  final ValueChanged<QuickLookPreset> onSelectQuickLook;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10121C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2132), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK LOOKS',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: QuickLookPreset.values.map((preset) {
                final isSelected = preset == selectedQuickLook;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _QuickLookPill(
                    preset: preset,
                    isSelected: isSelected,
                    onTap: () => onSelectQuickLook(preset),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLookPill extends StatefulWidget {
  const _QuickLookPill({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  final QuickLookPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_QuickLookPill> createState() => _QuickLookPillState();
}

class _QuickLookPillState extends State<_QuickLookPill> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final preset = widget.preset;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : (_hovered ? 1.04 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.22)
                  : _hovered
                      ? const Color(0xFF1C1E30)
                      : const Color(0xFF151726),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : _hovered
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.6)
                        : const Color(0xFF26283C),
                width: isSelected ? 1.4 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : _hovered
                      ? [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  preset.icon,
                  size: 13,
                  color: isSelected
                      ? const Color(0xFFC4B5FD)
                      : _hovered
                          ? const Color(0xFFA78BFA)
                          : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 6),
                Text(
                  preset.displayName,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : _hovered
                            ? const Color(0xFFF3F4F8)
                            : const Color(0xFFD1D5DB),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
