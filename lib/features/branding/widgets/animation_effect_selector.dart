import 'package:flutter/material.dart';

import '../models/branding_models.dart';

/// Animation and visual effect configuration selector for Stage 5.
///
/// Features:
/// - Entrance / IN Animations (Slide In, Pixel Appear, Blur Reveal, Fade In, Bounce, Pop, Typewriter, etc.)
/// - Exit / OUT Animations (Slide Out, Pixel Dissolve, Blur Dissolve, Fade Out, Scale Out, Pop Out, Drop Out, Wipe Out)
/// - In & Out Duration sliders (0.2s - 2.5s)
/// - Continuous Visual Effects (Shimmer, Glow Pulse, Neon Pulse, Breathing, Floating, Soft Flicker, etc.)
/// - Easing curve selector (Linear, Ease In, Ease Out, Ease In Out, Spring)
class AnimationEffectSelector extends StatelessWidget {
  const AnimationEffectSelector({
    required this.appearAnimation,
    required this.continuousAnimation,
    required this.animationDuration,
    required this.easing,
    required this.onAppearChanged,
    required this.onContinuousChanged,
    required this.onDurationChanged,
    required this.onEasingChanged,
    this.exitAnimation = ExitAnimationType.fadeOut,
    this.exitDuration = 0.5,
    this.onExitChanged,
    this.onExitDurationChanged,
    this.allowDropIn = false,
    super.key,
  });

  final AppearAnimationType appearAnimation;
  final ExitAnimationType exitAnimation;
  final ContinuousAnimationType continuousAnimation;
  final double animationDuration;
  final double exitDuration;
  final AnimationEasingType easing;

  final ValueChanged<AppearAnimationType> onAppearChanged;
  final ValueChanged<ExitAnimationType>? onExitChanged;
  final ValueChanged<ContinuousAnimationType> onContinuousChanged;
  final ValueChanged<double> onDurationChanged;
  final ValueChanged<double>? onExitDurationChanged;
  final ValueChanged<AnimationEasingType> onEasingChanged;
  final bool allowDropIn;

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
          const Text(
            'ANIMATIONS & TRANSITIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 12),

          // ── 1. ENTRANCE (IN) ANIMATION ────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.login_rounded, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 5),
                  Text(
                    'IN / ENTRANCE ANIMATION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              Text(
                appearAnimation.displayName,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC4B5FD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F101A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF23263B)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AppearAnimationType>(
                value: appearAnimation,
                isExpanded: true,
                dropdownColor: const Color(0xFF161828),
                icon: const Icon(Icons.arrow_drop_down,
                    color: Color(0xFF9CA3AF)),
                items: AppearAnimationType.values.map((anim) {
                  return DropdownMenuItem<AppearAnimationType>(
                    value: anim,
                    child: Text(
                      anim.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) onAppearChanged(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // In Duration slider
          if (appearAnimation != AppearAnimationType.none) ...[
            Row(
              children: [
                const SizedBox(
                  width: 75,
                  child: Text(
                    'IN TIME',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2.5,
                      activeTrackColor: const Color(0xFF10B981),
                      inactiveTrackColor: const Color(0xFF23263A),
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5),
                    ),
                    child: Slider(
                      value: animationDuration.clamp(0.2, 2.5),
                      min: 0.2,
                      max: 2.5,
                      onChanged: onDurationChanged,
                    ),
                  ),
                ),
                SizedBox(
                  width: 38,
                  child: Text(
                    '${animationDuration.toStringAsFixed(1)}s',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFF1E2032)),
          const SizedBox(height: 10),

          // ── 2. EXIT (OUT) ANIMATION ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.logout_rounded, size: 14, color: Color(0xFFF59E0B)),
                  SizedBox(width: 5),
                  Text(
                    'OUT / EXIT ANIMATION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              Text(
                exitAnimation.displayName,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFDE68A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F101A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF23263B)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ExitAnimationType>(
                value: exitAnimation,
                isExpanded: true,
                dropdownColor: const Color(0xFF161828),
                icon: const Icon(Icons.arrow_drop_down,
                    color: Color(0xFF9CA3AF)),
                items: ExitAnimationType.values.map((anim) {
                  return DropdownMenuItem<ExitAnimationType>(
                    value: anim,
                    child: Text(
                      anim.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onExitChanged != null
                    ? (val) {
                        if (val != null) onExitChanged!(val);
                      }
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Out Duration slider
          if (exitAnimation != ExitAnimationType.none &&
              onExitDurationChanged != null) ...[
            Row(
              children: [
                const SizedBox(
                  width: 75,
                  child: Text(
                    'OUT TIME',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2.5,
                      activeTrackColor: const Color(0xFFF59E0B),
                      inactiveTrackColor: const Color(0xFF23263A),
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5),
                    ),
                    child: Slider(
                      value: exitDuration.clamp(0.2, 2.5),
                      min: 0.2,
                      max: 2.5,
                      onChanged: onExitDurationChanged,
                    ),
                  ),
                ),
                SizedBox(
                  width: 38,
                  child: Text(
                    '${exitDuration.toStringAsFixed(1)}s',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFDE68A),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFF1E2032)),
          const SizedBox(height: 10),

          // ── 3. EASING CURVE ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ANIMATION EASING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F101A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF23263B)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AnimationEasingType>(
                    value: easing,
                    dropdownColor: const Color(0xFF161828),
                    icon: const Icon(Icons.arrow_drop_down,
                        size: 16, color: Color(0xFF9CA3AF)),
                    items: AnimationEasingType.values.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(
                          e.displayName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) onEasingChanged(val);
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFF1E2032)),
          const SizedBox(height: 10),

          // ── 4. CONTINUOUS VISUAL EFFECT ───────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CONTINUOUS ONGOING EFFECT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                continuousAnimation.displayName,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC4B5FD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ContinuousAnimationType.values.map((anim) {
                final isSelected = continuousAnimation == anim;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => onContinuousChanged(anim),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF0F101A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFC4B5FD)
                              : const Color(0xFF23263B),
                          width: isSelected ? 1.2 : 0.8,
                        ),
                      ),
                      child: Text(
                        anim.displayName,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color:
                              isSelected ? Colors.white : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
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
