import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/features/effects/data/effect_catalogue.dart';
import 'package:clipit/features/effects/models/editing_effect.dart';
import 'package:clipit/features/effects/pages/step4_effects_page.dart';
import 'package:clipit/features/effects/providers/effects_provider.dart';
import 'package:clipit/features/effects/widgets/effect_card.dart';

void main() {
  group('Step 4 — 10 High-Energy Creator Effects Catalogue Tests', () {
    test('Catalogue contains exactly the 10 specified creator effects', () {
      expect(EffectCatalogue.allEffects.length, equals(10));
    });

    test('All 10 effects have unique internal codes starting with CLP_FX_', () {
      final ids = EffectCatalogue.allEffects.map((e) => e.id).toSet();
      expect(ids.length, equals(10));

      const expectedIds = {
        'CLP_FX_RAGE_SCREEN',
        'CLP_FX_RED_PARTICLE_STORM',
        'CLP_FX_RED_FILTER',
        'CLP_FX_GOLDEN_OP',
        'CLP_FX_CROWN',
        'CLP_FX_FIRE_AURA',
        'CLP_FX_LIGHTNING',
        'CLP_FX_CINEMATIC_BW',
        'CLP_FX_GLITCH',
        'CLP_FX_EMOJI_BURST',
      };

      expect(ids, equals(expectedIds));
    });

    test('Contains the exact 10 required creator effect names', () {
      final names = EffectCatalogue.allEffects.map((e) => e.name).toSet();

      expect(names.contains('RAGE SCREEN'), isTrue);
      expect(names.contains('RED PARTICLE STORM'), isTrue);
      expect(names.contains('RED FILTER'), isTrue);
      expect(names.contains('GOLDEN / OP'), isTrue);
      expect(names.contains('CROWN MOMENT'), isTrue);
      expect(names.contains('FIRE AURA'), isTrue);
      expect(names.contains('LIGHTNING FLASH'), isTrue);
      expect(names.contains('CINEMATIC B&W'), isTrue);
      expect(names.contains('GLITCH / CHROMATIC'), isTrue);
      expect(names.contains('EMOJI BURST'), isTrue);
    });

    test('Crown Moment is the only effect requiring face tracking in this batch', () {
      for (final fx in EffectCatalogue.allEffects) {
        if (fx.id == 'CLP_FX_CROWN') {
          expect(fx.requiresFaceTracking, isTrue);
        } else {
          expect(fx.requiresFaceTracking, isFalse,
              reason: '${fx.name} should not require face tracking in this batch');
        }
      }
    });

    test('Every effect has recipe layers and descriptions', () {
      for (final fx in EffectCatalogue.allEffects) {
        expect(fx.id.isNotEmpty, isTrue);
        expect(fx.name.isNotEmpty, isTrue);
        expect(fx.shortDescription.isNotEmpty, isTrue);
        expect(fx.visualDirection.isNotEmpty, isTrue);
        expect(fx.recipeLayers.isNotEmpty, isTrue,
            reason: '${fx.name} has no recipe layers');
        expect(fx.category, isNotNull);
      }
    });
  });

  group('Step 4 — EffectsNotifier & Live Selection Tests', () {
    test('Notifier toggles effect selection and updates focused effect', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(effectsProvider.notifier);
      expect(container.read(effectsProvider).isSelected('CLP_FX_RAGE_SCREEN'), isFalse);

      // Select Rage Screen
      notifier.toggleEffect('CLP_FX_RAGE_SCREEN');
      expect(container.read(effectsProvider).isSelected('CLP_FX_RAGE_SCREEN'), isTrue);
      expect(container.read(effectsProvider).focusedEffectId, equals('CLP_FX_RAGE_SCREEN'));

      // Deselect Rage Screen
      notifier.toggleEffect('CLP_FX_RAGE_SCREEN');
      expect(container.read(effectsProvider).isSelected('CLP_FX_RAGE_SCREEN'), isFalse);
    });

    test('Select All and Clear All operate properly on the 10 effects', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(effectsProvider.notifier);

      notifier.selectAll();
      expect(container.read(effectsProvider).selectedCount, equals(10));

      notifier.clearAll();
      expect(container.read(effectsProvider).selectedCount, equals(0));
    });

    test('Search query matches name and description', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(effectsProvider.notifier);

      notifier.setSearchQuery('Crown');
      final results = notifier.getFilteredEffects();
      expect(results.length, equals(1));
      expect(results.first.name, equals('CROWN MOMENT'));

      notifier.setSearchQuery('Red');
      final redResults = notifier.getFilteredEffects();
      expect(redResults.length, equals(3)); // Red Particle Storm, Red Filter & Rage Screen
    });

    test('selectedEffectCodes formats sorted internal IDs for AI handoff', () {
      final state = const EffectsState(
        selectedEffectIds: {
          'CLP_FX_RAGE_SCREEN',
          'CLP_FX_CROWN',
          'CLP_FX_GOLDEN_OP',
        },
      );
      expect(
        state.selectedEffectCodes,
        equals(['CLP_FX_CROWN', 'CLP_FX_GOLDEN_OP', 'CLP_FX_RAGE_SCREEN']),
      );
    });
  });

  group('Step 4 — Step4EffectsPage UI Tests', () {
    testWidgets('Renders top bar, header, and the 10 effect cards',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Step4EffectsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar & page header
      expect(find.text('4 — EFFECTS LIBRARY'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Next: Overlays'), findsOneWidget);

      // Effect cards should show the 10 effects
      expect(find.text('RAGE SCREEN'), findsWidgets);
      expect(find.text('RED PARTICLE STORM'), findsWidgets);
      expect(find.text('RED FILTER'), findsWidgets);
      expect(find.text('GOLDEN / OP'), findsWidgets);
      expect(find.text('CROWN MOMENT'), findsWidgets);
      expect(find.text('FIRE AURA'), findsWidgets);
      expect(find.text('LIGHTNING FLASH'), findsWidgets);
      expect(find.text('CINEMATIC B&W'), findsWidgets);
      expect(find.text('GLITCH / CHROMATIC'), findsWidgets);
      expect(find.text('EMOJI BURST'), findsWidgets);

      // Old effects must NEVER be shown
      expect(find.text('SIGMA MOMENT'), findsNothing);
      expect(find.text('GOAT MOMENT'), findsNothing);
      expect(find.text('CAUGHT IN 4K'), findsNothing);
      expect(find.text('NEON BODY'), findsNothing);

      // Internal effect codes (CLP_FX_XXX) must NEVER be visible anywhere in the UI
      expect(find.textContaining('CLP_FX_'), findsNothing);

      // NO Apply button
      expect(find.text('Apply'), findsNothing);
    });

    testWidgets('Tapping effect checkbox toggles selection in live preview',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Step4EffectsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially 0 selected
      expect(find.text('Live Preview (0 Active)'), findsOneWidget);

      // Tap first EffectCard (RAGE SCREEN)
      await tester.tap(find.byType(EffectCard).first);
      await tester.pumpAndSettle();

      // Now 1 selected
      expect(find.text('Live Preview (1 Active)'), findsOneWidget);
    });
  });
}
