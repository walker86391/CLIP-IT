import 'package:flutter/material.dart';

import '../models/branding_models.dart';

/// 3x3 Screen Alignment Preset Grid & Fine X/Y Offset Controls.
class PositionMatrixSelector extends StatelessWidget {
  const PositionMatrixSelector({
    required this.selectedPreset,
    required this.fineOffsetX,
    required this.fineOffsetY,
    required this.onPresetChanged,
    required this.onOffsetChanged,
    super.key,
  });

  final PositionPreset selectedPreset;
  final double fineOffsetX;
  final double fineOffsetY;
  final ValueChanged<PositionPreset> onPresetChanged;
  final void Function(double x, double y) onOffsetChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131420),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF222436),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'POSITION & ALIGNMENT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              Text(
                selectedPreset.displayName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC4B5FD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3x3 Grid
              Container(
                width: 104,
                height: 104,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F101A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF23263B),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRow([
                      PositionPreset.topLeft,
                      PositionPreset.topCenter,
                      PositionPreset.topRight,
                    ]),
                    _buildRow([
                      PositionPreset.centerLeft,
                      PositionPreset.center,
                      PositionPreset.centerRight,
                    ]),
                    _buildRow([
                      PositionPreset.bottomLeft,
                      PositionPreset.bottomCenter,
                      PositionPreset.bottomRight,
                    ]),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Guide / Reset vertical position
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.touch_app_rounded,
                            size: 16, color: Color(0xFF8B5CF6)),
                        SizedBox(width: 6),
                        Text(
                          '2D Drag Enabled',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap any grid anchor to snap the overlay box to that position, or pick and drag freely in any direction on the video canvas.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (fineOffsetX != 0.0 || fineOffsetY != 0.0)
                      TextButton.icon(
                        onPressed: () => onOffsetChanged(0.0, 0.0),
                        icon: const Icon(Icons.refresh, size: 12),
                        label: const Text('Reset to Anchor',
                            style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFC4B5FD),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
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

  Widget _buildRow(List<PositionPreset> presets) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: presets.map(_buildPresetCell).toList(),
    );
  }

  Widget _buildPresetCell(PositionPreset preset) {
    final isSelected = selectedPreset == preset;
    return InkWell(
      onTap: () => onPresetChanged(preset),
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF191B28),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC4B5FD)
                : const Color(0xFF2C2F44),
            width: isSelected ? 1.4 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Container(
            width: isSelected ? 8 : 5,
            height: isSelected ? 8 : 5,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
