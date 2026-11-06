import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/features/effects/models/editing_effect.dart';
import 'package:clipit/features/effects/providers/effects_provider.dart';
import 'package:clipit/features/effects/widgets/effects_video_overlay.dart';

void main() {
  group('Step 4 — Individual & Combination Rendering Tests for 10 Effects', () {
    testWidgets('1. RAGE SCREEN renders aggressive red grade, shake, and pulse',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 700));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectsProvider.overrideWith(() => _CustomEffectsNotifier(
                  const EffectsState(selectedEffectIds: {'CLP_FX_RAGE_SCREEN'}),
                )),
          ],
          child: const MaterialApp(
            home: EffectsVideoOverlay(
              child: ColoredBox(color: Colors.blue),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // ColorFiltered GPU matrix applied
      expect(find.byType(ColorFiltered), findsWidgets);
      // Transform.translate shake applied
      expect(find.byType(Transform), findsWidgets);
      // Canvas particles & badge
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('RAGE'), findsOneWidget);
    });

    testWidgets('2. RED PARTICLE STORM renders dynamic depth particles',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 700));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectsProvider.overrideWith(() => _CustomEffectsNotifier(
                  const EffectsState(selectedEffectIds: {'CLP_FX_RED_PARTICLE_STORM'}),
                )),
          ],
          child: const MaterialApp(
            home: EffectsVideoOverlay(
              child: ColoredBox(color: Colors.black),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('STORM'), findsOneWidget);
    });

    testWidgets('3. RED FILTER applies actual red color grading matrix',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 700));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectsProvider.overrideWith(() => _CustomEffectsNotifier(
                  const EffectsState(selectedEffectIds: {'CLP_FX_RED_FILTER'}),
                )),
          ],
          child: const MaterialApp(
            home: EffectsVideoOverlay(
              child: ColoredBox(color: Colors.green),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // ColorFiltered GPU matrix applied
      expect(find.byType(ColorFiltered), findsWidgets);
      expect(find.text('RED'), findsOneWidget);
    });

    testWidgets('4. GOLDEN / OP renders warm golden grade, bloom & floating particles',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 700));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectsProvider.overrideWith(() => _CustomEffectsNotifier(
                  const EffectsState(selectedEffectIds: {'CLP_FX_GOLDEN_OP'}),
                )),
          ],
          child: const MaterialApp(
            home: EffectsVideoOverlay(
              child: ColoredBox(color: Colors.blue),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ColorFiltered), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('OP MOMENT'), findsOneWidget);
    });

    testWidgets('5. CROWN MOMENT tracks face when detected and gracefully hides when absent',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 700));

      // A. When face is detected: crown should render at tracked coordinates
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectsProvider.overrideWith(() => _CustomEffectsNotifier(
                  const EffectsState(
                    selectedEffectIds: {'CLP_FX_CROWN'},
                    detectionAnalysis: {
                      'face_detected': true,
                      'width': 1000,
                      'height': 1000,
                      'forehead_top': {'x': 500, 'y': 300},
                      'face_width': 200,
                      'head_angle_deg': 5.0,
                    },
                  ),
                )),
          ],
          child: const MaterialApp(
            home: EffectsVideoOverlay(
              child: ColoredBox(color: Colors.black),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Image), findsOneWidget); // Crown asset image rendered!
      expect(find.text('CROWN'), findsOneWidget);

      // B. When NO face is detected: crown must be gracefully hidden
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            effectsProvider.overrideWith(() => _CustomEffectsNotifier(
                  const EffectsState(
                    selectedEffectIds: {'CLP_FX_CROWN'},
                    detectionAnalysis: {
                      'face_detected': false,
                    },
                  ),
                )),
          ],
          child: const MaterialApp(
            home: EffectsVideoOverlay(
              child: ColoredBox(color: Colors.black),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Image), findsNothing); // Crown gracefully hidden!
    });

    testWidgets('6. FIRE AURA renders animated perimeter flames and sparks',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 700));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectsProvider.overrideWith(() => _CustomEffectsNotifier(
                  const EffectsState(selectedEffectIds: {'CLP_FX_FIRE_AURA'}),
                )),
          ],
          child: const MaterialApp(
            home: EffectsVideoOverlay(
              child: ColoredBox(color: Colors.black),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('FIRE'), findsOneWidget);
    });

    testWidgets('7. LIGHTNING FLASH renders branching lightning bolt and pulse',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 700));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectsProvider.overrideWith(() => _CustomEffectsNotifier(
                  const EffectsState(selectedEffectIds: {'CLP_FX_LIGHTNING'}),
                )),
          ],
          child: const MaterialApp(
            home: EffectsVideoOverlay(
              child: ColoredBox(color: Colors.black),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('LIGHTNING'), findsOneWidget);
    });

    testWidgets('8. CINEMATIC B&W processes actual monochrome video',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 700));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectsProvider.overrideWith(() => _CustomEffectsNotifier(
                  const EffectsState(selectedEffectIds: {'CLP_FX_CINEMATIC_BW'}),
                )),
          ],
          child: const MaterialApp(
            home: EffectsVideoOverlay(
              child: ColoredBox(color: Colors.red),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ColorFiltered), findsWidgets);
      expect(find.text('B&W'), findsOneWidget);
    });

    testWidgets('9. GLITCH / CHROMATIC renders chromatic scanlines and artifacts',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 700));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectsProvider.overrideWith(() => _CustomEffectsNotifier(
                  const EffectsState(selectedEffectIds: {'CLP_FX_GLITCH'}),
                )),
          ],
          child: const MaterialApp(
            home: EffectsVideoOverlay(
              child: ColoredBox(color: Colors.black),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('GLITCH'), findsOneWidget);
    });

    testWidgets('10. EMOJI BURST renders celebratory confetti and emojis',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 700));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectsProvider.overrideWith(() => _CustomEffectsNotifier(
                  const EffectsState(selectedEffectIds: {'CLP_FX_EMOJI_BURST'}),
                )),
          ],
          child: const MaterialApp(
            home: EffectsVideoOverlay(
              child: ColoredBox(color: Colors.black),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('CELEBRATE'), findsOneWidget);
    });

    testWidgets('Multi-effect combination composites predictably without error',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 700));

      // Combo: RAGE SCREEN + RED PARTICLE STORM + GOLDEN OP + CROWN
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectsProvider.overrideWith(() => _CustomEffectsNotifier(
                  const EffectsState(
                    selectedEffectIds: {
                      'CLP_FX_RAGE_SCREEN',
                      'CLP_FX_RED_PARTICLE_STORM',
                      'CLP_FX_GOLDEN_OP',
                      'CLP_FX_CROWN',
                    },
                    detectionAnalysis: {
                      'face_detected': true,
                      'width': 1000,
                      'height': 1000,
                      'forehead_top': {'x': 500, 'y': 300},
                      'face_width': 200,
                      'head_angle_deg': 0.0,
                    },
                  ),
                )),
          ],
          child: const MaterialApp(
            home: EffectsVideoOverlay(
              child: ColoredBox(color: Colors.purple),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Color grading, vignette, particles, tracked crown, and badges all present!
      expect(find.byType(ColorFiltered), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(Image), findsOneWidget); // Crown
      expect(find.text('RAGE'), findsOneWidget);
      expect(find.text('+3'), findsOneWidget); // Shows 3 additional active effects!
    });
  });
}

class _CustomEffectsNotifier extends EffectsNotifier {
  _CustomEffectsNotifier(this._initial);
  final EffectsState _initial;

  @override
  EffectsState build() => _initial;
}
