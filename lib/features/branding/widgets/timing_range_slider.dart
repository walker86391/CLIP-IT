import 'package:flutter/material.dart';

/// Interactive percentage-based dual range slider for overlay and branding timing.
///
/// Features:
/// - Visual range control: 0% ──●──●── 100%
/// - Dual thumbs with purple accent and active range highlight.
/// - Precise numeric percentage inputs with validation (Start < End).
/// - Shows computed timestamp in seconds based on clip duration.
/// - Quick preset chips for rapid selection.
class TimingRangeSlider extends StatelessWidget {
  const TimingRangeSlider({
    required this.startPercent,
    required this.endPercent,
    required this.onChanged,
    this.clipDurationSeconds = 30.0,
    this.label = 'TIMING RANGE',
    super.key,
  });

  final double startPercent;
  final double endPercent;
  final void Function(double start, double end) onChanged;
  final double clipDurationSeconds;
  final String label;

  @override
  Widget build(BuildContext context) {
    final startSec = (startPercent / 100.0) * clipDurationSeconds;
    final endSec = (endPercent / 100.0) * clipDurationSeconds;
    final durationSec = endSec - startSec;

    final rangeValues = RangeValues(
      startPercent.clamp(0.0, 99.0),
      endPercent.clamp(startPercent + 1.0, 100.0),
    );

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
          // Header row with title and live duration badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'Duration: ${durationSec.toStringAsFixed(1)}s (${(endPercent - startPercent).round()}%)',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC4B5FD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Visual Range Slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: const Color(0xFF8B5CF6),
              inactiveTrackColor: const Color(0xFF23263A),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 8,
                elevation: 3,
              ),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              rangeValueIndicatorShape:
                  const PaddleRangeSliderValueIndicatorShape(),
              showValueIndicator: ShowValueIndicator.onDrag,
            ),
            child: RangeSlider(
              values: rangeValues,
              min: 0.0,
              max: 100.0,
              divisions: 100,
              labels: RangeLabels(
                '${startPercent.round()}%',
                '${endPercent.round()}%',
              ),
              onChanged: (newValues) {
                if (newValues.end > newValues.start) {
                  onChanged(newValues.start, newValues.end);
                }
              },
            ),
          ),

          // Numeric Percentage and Timestamp Row
          Row(
            children: [
              // Start %
              Expanded(
                child: _buildTimeInputBox(
                  label: 'START',
                  percent: startPercent,
                  seconds: startSec,
                  onChanged: (val) {
                    final newStart = val.clamp(0.0, endPercent - 1.0);
                    onChanged(newStart, endPercent);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
              // End %
              Expanded(
                child: _buildTimeInputBox(
                  label: 'END',
                  percent: endPercent,
                  seconds: endSec,
                  onChanged: (val) {
                    final newEnd = val.clamp(startPercent + 1.0, 100.0);
                    onChanged(startPercent, newEnd);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Quick Presets Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip('Full (0-100%)', 0, 100),
                const SizedBox(width: 6),
                _buildPresetChip('Hook (0-25%)', 0, 25),
                const SizedBox(width: 6),
                _buildPresetChip('Mid (25-75%)', 25, 75),
                const SizedBox(width: 6),
                _buildPresetChip('Climax (50-80%)', 50, 80),
                const SizedBox(width: 6),
                _buildPresetChip('Outro (75-100%)', 75, 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInputBox({
    required String label,
    required double percent,
    required double seconds,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F101A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF26283C),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                '${percent.round()}%  (${seconds.toStringAsFixed(1)}s)',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStepButton(
                icon: Icons.remove,
                onTap: () => onChanged((percent - 5.0).clamp(0.0, 100.0)),
              ),
              const SizedBox(width: 4),
              _buildStepButton(
                icon: Icons.add,
                onTap: () => onChanged((percent + 5.0).clamp(0.0, 100.0)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1D2C),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 12, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, double s, double e) {
    final isSelected =
        (startPercent - s).abs() < 1.0 && (endPercent - e).abs() < 1.0;
    return InkWell(
      onTap: () => onChanged(s, e),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.25)
              : const Color(0xFF181A26),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF26283C),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFFC4B5FD) : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}
