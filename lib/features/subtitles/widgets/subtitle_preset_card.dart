import 'package:flutter/material.dart';

import '../models/subtitle_models.dart';
import 'subtitle_phrase_renderer.dart';

/// Reusable preset card displaying animated demonstration of "Bhai ye kya hai?".
///
/// Features:
/// - Hover-to-preview: activates animation loop on hover and pauses when unhovered.
/// - Tap to select preset.
/// - Selection border and category tag.
/// - Visual differentiation based on typography, colors, shadows, and emphasis.
class SubtitlePresetCard extends StatefulWidget {
  const SubtitlePresetCard({
    required this.preset,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  final SubtitlePreset preset;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  State<SubtitlePresetCard> createState() => _SubtitlePresetCardState();
}

class _SubtitlePresetCardState extends State<SubtitlePresetCard>
    with WidgetsBindingObserver {
  bool _isHovered = false;
  bool _isForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isForeground = state == AppLifecycleState.resumed;
    if (_isForeground != isForeground && mounted) {
      setState(() => _isForeground = isForeground);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;
    final isSelected = widget.isSelected;

    return RepaintBoundary(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
        onTap: widget.onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF161528)
                : (_isHovered ? const Color(0xFF13141F) : const Color(0xFF0F1018)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : (_isHovered
                      ? const Color(0xFF3E4158)
                      : const Color(0xFF1F2130)),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.28),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : (_isHovered
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ]
                    : null),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header: Title & Category Pill ────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      preset.name,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFFF3F4F8)
                            : const Color(0xFFD1D5DB),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1C29),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF2E3147),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        preset.category.shortLabel,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Animated Preview Canvas Container ────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF08090E),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF171822),
                      width: 1.0,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Grid backdrop simulation
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GridBackgroundPainter(),
                        ),
                      ),

                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SubtitlePhraseRenderer(
                              config: preset.defaultConfig.copyWith(
                                fontSize: 14.0,
                              ),
                              isAnimated: _isForeground,
                            ),
                          ),
                        ),
                      ),

                      // Hover indicator badge
                      if (_isHovered && !isSelected)
                        Positioned(
                          bottom: 4,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'PREVIEWING',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Color(0xFFC4B5FD),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // ── Description ──────────────────────────────────────────────
              Text(
                preset.description,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF838896),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

/// Subtle dot/grid background for preset preview cards.
class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1B1D2C).withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    const step = 14.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
