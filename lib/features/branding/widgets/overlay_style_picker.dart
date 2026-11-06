import 'package:flutter/material.dart';

import '../models/branding_models.dart';

/// Style preset selection cards displayed FIRST before fine-tuning temporary overlay controls.
class OverlayStylePicker extends StatelessWidget {
  const OverlayStylePicker({
    required this.selectedStyle,
    required this.onStyleSelected,
    super.key,
  });

  final OverlayStylePreset selectedStyle;
  final ValueChanged<OverlayStylePreset> onStyleSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '1. CHOOSE OVERLAY STYLE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: Color(0xFFC4B5FD),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Structure First',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC4B5FD),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.3,
          ),
          itemCount: OverlayStylePreset.values.length,
          itemBuilder: (context, index) {
            final style = OverlayStylePreset.values[index];
            final isSelected = selectedStyle == style;

            return InkWell(
              onTap: () => onStyleSelected(style),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                      : const Color(0xFF131420),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF222436),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    _buildStyleIcon(style, isSelected),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            style.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFFD1D5DB),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            style.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: isSelected
                                  ? const Color(0xFFC4B5FD)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStyleIcon(OverlayStylePreset style, bool isSelected) {
    final accentColor =
        isSelected ? const Color(0xFFC4B5FD) : const Color(0xFF8B5CF6);

    switch (style) {
      case OverlayStylePreset.verticalLineRight:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF0F101A),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 14, height: 2, color: Colors.white70),
                  const SizedBox(height: 2),
                  Container(width: 10, height: 2, color: Colors.white70),
                ],
              ),
              const SizedBox(width: 3),
              Container(width: 2.5, height: 20, color: accentColor),
            ],
          ),
        );

      case OverlayStylePreset.verticalLineLeft:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF0F101A),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 2.5, height: 20, color: accentColor),
              const SizedBox(width: 3),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 14, height: 2, color: Colors.white70),
                  const SizedBox(height: 2),
                  Container(width: 10, height: 2, color: Colors.white70),
                ],
              ),
            ],
          ),
        );

      case OverlayStylePreset.starDrop:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF0F101A),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.stars_rounded,
            size: 20,
            color: accentColor,
          ),
        );

      case OverlayStylePreset.boxCallout:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF0F101A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accentColor, width: 1.2),
          ),
          child: const Center(
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 16,
              color: Colors.white70,
            ),
          ),
        );

      case OverlayStylePreset.minimalLabel:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF0F101A),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Container(width: 14, height: 4, color: accentColor),
            ),
          ),
        );

      case OverlayStylePreset.cornerCallout:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF0F101A),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(
              Icons.crop_free_rounded,
              size: 20,
              color: accentColor,
            ),
          ),
        );
    }
  }
}
