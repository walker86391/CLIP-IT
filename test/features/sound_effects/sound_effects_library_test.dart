import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/features/projects/components/workflow_progress_stepper.dart';
import 'package:clipit/features/sound_effects/data/sound_effects_catalogue.dart';
import 'package:clipit/features/sound_effects/models/sound_effect_item.dart';
import 'package:clipit/features/sound_effects/pages/sound_effects_library_page.dart';
import 'package:clipit/features/sound_effects/providers/sound_effects_provider.dart';
import 'package:clipit/features/sound_effects/widgets/sound_effect_card.dart';
import 'package:clipit/features/sound_effects/widgets/sound_effects_usage_pill.dart';

void main() {
  group('Stage 4 — Sound Effects Data Models & Catalogue Tests', () {
    test('SoundEffectsCatalogue contains all 48 sound effects with valid FFmpeg identifiers and tags', () {
      final all = SoundEffectsCatalogue.all;
      expect(all.length, equals(48));

      for (final sfx in all) {
        expect(sfx.id.isNotEmpty, isTrue);
        expect(sfx.name.isNotEmpty, isTrue);
        expect(sfx.fileName.endsWith('.mp3'), isTrue);
        expect(sfx.internalFfmpegName.startsWith('CLP_SFX_'), isTrue);
        expect(sfx.durationSeconds > 0, isTrue);
        expect(sfx.formattedDuration.endsWith('s'), isTrue);
        expect(sfx.tags.isNotEmpty, isTrue);
      }
    });

    test('SoundEffectItem formats visual name, tags, and asset path correctly', () {
      const item = SoundEffectItem(
        id: 'sfx_vine_boom',
        name: 'Vine Boom',
        fileName: 'vine-boom.mp3',
        internalFfmpegName: 'CLP_SFX_VINE_BOOM',
        category: 'Impact',
        durationSeconds: 1.3,
        tags: ['ONLY SOUND', 'IMPACT', 'MEME'],
      );

      expect(item.name, equals('Vine Boom'));
      expect(item.fileName, equals('vine-boom.mp3'));
      expect(item.internalFfmpegName, equals('CLP_SFX_VINE_BOOM'));
      expect(item.assetPath, equals('assets/sound_effects/vine-boom.mp3'));
      expect(item.formattedDuration, equals('1.3s'));
      expect(item.matchesFilter('ONLY SOUND'), isTrue);
      expect(item.matchesFilter('HINDI'), isFalse);
    });
  });

  group('Stage 4 — SoundEffectsProvider State, Multi-Filters & Calculations', () {
    test('Calculates real-time usage count and percentage accurately', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(soundEffectsProvider.notifier);
      notifier.clearAll();

      var state = container.read(soundEffectsProvider);
      expect(state.selectedCount, equals(0));
      expect(state.usagePercentage, equals(0.0));
      expect(state.usageFraction, equals(0.0));

      // Select 1 effect
      notifier.toggleSelection('sfx_vine_boom');
      state = container.read(soundEffectsProvider);
      expect(state.selectedCount, equals(1));
      expect(state.isSelected('sfx_vine_boom'), isTrue);
      final expectedPct = (1.0 / 48.0) * 100.0;
      expect((state.usagePercentage - expectedPct).abs() < 0.01, isTrue);

      // Select another
      notifier.toggleSelection('sfx_anime_wow');
      state = container.read(soundEffectsProvider);
      expect(state.selectedCount, equals(2));
      expect((state.usagePercentage - ((2.0 / 48.0) * 100.0)).abs() < 0.01, isTrue);
    });

    test('Multi-select filters for ENGLISH, HINDI, and ONLY SOUND work accurately', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(soundEffectsProvider.notifier);

      // 1. Single filter: HINDI
      notifier.toggleFilter('HINDI');
      var state = container.read(soundEffectsProvider);
      expect(state.selectedFilters, equals({'HINDI'}));
      var filtered = container.read(filteredSoundEffectsProvider);
      expect(filtered.every((f) => f.matchesFilter('HINDI')), isTrue);
      expect(filtered.length, equals(9));

      // 2. Multi-select: HINDI + ENGLISH
      notifier.toggleFilter('ENGLISH');
      state = container.read(soundEffectsProvider);
      expect(state.selectedFilters, equals({'HINDI', 'ENGLISH'}));
      expect(state.selectedFilters.length, equals(2));
      filtered = container.read(filteredSoundEffectsProvider);
      expect(
        filtered.every((f) => f.matchesFilter('HINDI') || f.matchesFilter('ENGLISH')),
        isTrue,
      );
      expect(filtered.length, equals(19)); // 9 Hindi + 10 English

      // 3. Clear filters
      notifier.clearFilters();
      state = container.read(soundEffectsProvider);
      expect(state.selectedFilters.isEmpty, isTrue);
      filtered = container.read(filteredSoundEffectsProvider);
      expect(filtered.length, equals(48));

      // 4. Single filter: ONLY SOUND
      notifier.toggleFilter('ONLY SOUND');
      filtered = container.read(filteredSoundEffectsProvider);
      expect(filtered.every((f) => f.matchesFilter('ONLY SOUND')), isTrue);
      expect(filtered.length, equals(29));
    });

    test('Search keyword filtering works with multi-select filters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(soundEffectsProvider.notifier);

      // Search by keyword "quandale"
      notifier.clearFilters();
      notifier.setSearchQuery('quandale');
      var filtered = container.read(filteredSoundEffectsProvider);
      expect(filtered.length, equals(2));
      expect(filtered.every((f) => f.name.contains('Quandale')), isTrue);
    });
  });

  group('Stage 4 — SoundEffectsLibraryPage UI & Widget Tests', () {
    testWidgets('Renders SoundEffectsLibraryPage with clean video preview, usage pill, filter tabs, and sound cards',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SoundEffectsLibraryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top Bar & Stepper
      expect(find.text('Back'), findsOneWidget);
      expect(find.byType(WorkflowProgressStepper), findsOneWidget);
      expect(find.text('4 — SOUND EFFECT LIBRARY'), findsOneWidget);

      // Left Column: Usage Pill with real calculation
      expect(find.byType(SoundEffectsUsagePill), findsOneWidget);
      expect(find.text('AUDIO FX ALLOCATION'), findsOneWidget);
      expect(find.textContaining('/ 48'), findsWidgets);

      // Category / Filter Tabs
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('ENGLISH'), findsOneWidget);
      expect(find.text('HINDI'), findsOneWidget);
      expect(find.text('ONLY SOUND'), findsOneWidget);
      expect(find.text('MEME'), findsWidgets);

      // Sound Effect Cards
      expect(find.byType(SoundEffectCard), findsWidgets);
      expect(find.text('Vine Boom'), findsOneWidget);
      expect(find.text('Bhai Ne Bola Karne Ka'), findsOneWidget);
      expect(find.text('Bruh Sound Effect'), findsOneWidget);

      // Play buttons are present without scrubbers
      expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);

      // Bottom Navigation Buttons
      expect(find.text('Previous: Video Look'), findsOneWidget);
      expect(find.text('Next: Branding Studio'), findsOneWidget);
    });

    testWidgets('Selecting 2 filters shows CLEAR ALL option, and tapping it resets filters',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SoundEffectsLibraryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially no CLEAR ALL button (0 filters selected)
      expect(find.byKey(const Key('sound_effects_clear_filters_button')), findsNothing);

      // Tap 1 filter: ENGLISH
      await tester.tap(find.text('ENGLISH'));
      await tester.pumpAndSettle();
      expect(container.read(soundEffectsProvider).selectedFilters.length, equals(1));
      expect(find.byKey(const Key('sound_effects_clear_filters_button')), findsNothing);

      // Tap 2nd filter: ONLY SOUND
      await tester.tap(find.text('ONLY SOUND'));
      await tester.pumpAndSettle();
      expect(container.read(soundEffectsProvider).selectedFilters.length, equals(2));

      // Now CLEAR ALL button appears because 2 filters are selected
      expect(find.byKey(const Key('sound_effects_clear_filters_button')), findsOneWidget);
      expect(find.text('CLEAR ALL (2)'), findsOneWidget);

      // Tap CLEAR ALL
      await tester.tap(find.byKey(const Key('sound_effects_clear_filters_button')));
      await tester.pumpAndSettle();

      // Filters are reset
      expect(container.read(soundEffectsProvider).selectedFilters.isEmpty, isTrue);
      expect(find.byKey(const Key('sound_effects_clear_filters_button')), findsNothing);
    });

    testWidgets('Tapping sound effect card toggles selection and updates real usage percentage',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Start with empty selection
      container.read(soundEffectsProvider.notifier).clearAll();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SoundEffectsLibraryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(soundEffectsProvider).selectedCount, equals(0));

      // Tap on 'Vine Boom' card
      await tester.tap(find.text('Vine Boom'));
      await tester.pumpAndSettle();

      expect(container.read(soundEffectsProvider).selectedCount, equals(1));
      expect(container.read(soundEffectsProvider).isSelected('sfx_vine_boom'), isTrue);

      // Tap 'Clear' button
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(container.read(soundEffectsProvider).selectedCount, equals(0));
    });
  });
}
