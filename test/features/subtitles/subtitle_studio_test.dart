import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/features/projects/components/workflow_progress_stepper.dart';
import 'package:clipit/features/subtitles/models/subtitle_models.dart';
import 'package:clipit/features/subtitles/models/subtitle_presets_library.dart';
import 'package:clipit/features/subtitles/pages/subtitle_studio_page.dart';
import 'package:clipit/features/subtitles/providers/subtitle_studio_provider.dart';
import 'package:clipit/features/subtitles/services/subtitle_font_registry.dart';
import 'package:clipit/features/subtitles/services/subtitle_renderer_service.dart';
import 'package:clipit/features/subtitles/widgets/subtitle_canvas_overlay.dart';
import 'package:clipit/features/subtitles/widgets/subtitle_phrase_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part 5 & 10: 70 Subtitle Presets Library & Data Contracts', () {
    test('Library defines exactly 70 presets across 7 categories (10 each)', () {
      final all = SubtitlePresetsLibrary.allPresets;
      expect(all.length, 70);

      // Verify each category has exactly 10 presets
      expect(SubtitleCategory.values.length, 7);
      for (final category in SubtitleCategory.values) {
        final categoryPresets =
            all.where((p) => p.category == category).toList();
        expect(categoryPresets.length, 10,
            reason: 'Category ${category.displayName} must have 10 presets');
      }

      // Verify IDs are all unique
      final ids = all.map((p) => p.id).toSet();
      expect(ids.length, 70);
    });

    test('Motion Typography category has 10 distinct, customizable presets', () {
      final motionPresets = SubtitlePresetsLibrary.search(category: SubtitleCategory.motionTypography);
      expect(motionPresets.length, 10);

      final expectedIds = [
        'motion_animated_underline',
        'motion_kinetic_velocity',
        'motion_focus_horizon',
        'motion_aperture_word_reveal',
        'motion_cyber_terminal',
        'motion_velocity_cascade',
        'motion_titan_impact',
        'motion_two_stage_surge',
        'motion_noir_editorial',
        'motion_editorial_vogue',
      ];

      for (final id in expectedIds) {
        expect(motionPresets.any((p) => p.id == id), true,
            reason: 'Expected preset $id in motionTypography category');
      }
    });

    test('Two-layer animation system supports independent layer configuration and combination', () {
      final preset = SubtitlePresetsLibrary.getById('motion_kinetic_velocity');
      final config = preset.toConfiguration();

      expect(config.layer1Animation, SubtitleLayer1Animation.trackingReveal);
      expect(config.layer2Animation, SubtitleLayer2Animation.elasticMotion);

      // Test combination: Word Blur Reveal (Layer 1) + Pop Bounce (Layer 2)
      final combined = config.copyWith(
        layer1Animation: SubtitleLayer1Animation.wordBlur,
        layer1DurationMs: 400,
        layer1DelayMs: 50,
        layer1Easing: SubtitleEasing.easeInOut,
        layer1Intensity: 1.2,
        layer2Animation: SubtitleLayer2Animation.popBounce,
        layer2DurationMs: 350,
        layer2DelayMs: 80,
        layer2Easing: SubtitleEasing.bounceOut,
        layer2Intensity: 1.5,
      );

      expect(combined.layer1Animation, SubtitleLayer1Animation.wordBlur);
      expect(combined.layer2Animation, SubtitleLayer2Animation.popBounce);
      expect(combined.layer1DurationMs, 400);
      expect(combined.layer2DurationMs, 350);

      // Verify serialization round-trip
      final json = combined.toJson();
      final restored = SubtitleConfiguration.fromJson(json);
      expect(restored.layer1Animation, SubtitleLayer1Animation.wordBlur);
      expect(restored.layer2Animation, SubtitleLayer2Animation.popBounce);
      expect(restored.layer1DurationMs, 400);
      expect(restored.layer2DurationMs, 350);
    });

    test('Important-word markers system provides 11 distinct styles with customizable properties', () {
      expect(SubtitleMarkerStyle.values.length, 12); // none + 11 styles

      final config = SubtitlePresetsLibrary.allPresets.first.toConfiguration().copyWith(
        markerStyle: SubtitleMarkerStyle.animatedUnderline,
        markerColor: const Color(0xFFFF5722),
        markerThickness: 4.5,
        markerDistance: 6.0,
        markerPaddingH: 14.0,
        markerOpacity: 0.85,
        markerAnimation: MarkerAnimationBehavior.drawIn,
        markerDurationMs: 400,
      );

      expect(config.markerStyle, SubtitleMarkerStyle.animatedUnderline);
      expect(config.markerColor, const Color(0xFFFF5722));
      expect(config.markerThickness, 4.5);
      expect(config.markerDistance, 6.0);
      expect(config.markerPaddingH, 14.0);
      expect(config.markerOpacity, 0.85);
      expect(config.markerAnimation, MarkerAnimationBehavior.drawIn);

      final json = config.toJson();
      final restored = SubtitleConfiguration.fromJson(json);
      expect(restored.markerStyle, SubtitleMarkerStyle.animatedUnderline);
      expect(restored.markerColor, const Color(0xFFFF5722));
      expect(restored.markerThickness, 4.5);
    });

    test('Marker texture selector supports 8 organic textures', () {
      expect(MarkerTexture.values.length, 8);
      for (final tex in MarkerTexture.values) {
        expect(tex.displayName.isNotEmpty, true);
      }
    });

    test('Font registry contains dynamic discovered fonts and curated kinetic typography families', () {
      final fonts = SubtitleFontRegistry.registeredFonts;
      expect(fonts.isNotEmpty, true);

      final curated = [
        'Anton',
        'Bebas Neue',
        'Montserrat',
        'Oswald',
        'Poppins',
        'Archivo Black',
        'League Spartan',
        'Roboto Condensed',
      ];

      for (final family in curated) {
        expect(fonts.any((f) => f.family.toLowerCase() == family.toLowerCase()), true,
            reason: 'Curated font $family must be in font registry');
      }

      // Verify font file path lookup returns valid disk path for discovered or asset font
      final fontPath = SubtitleFontRegistry.getFontFilePath('Rubik Vinyl') ??
          SubtitleFontRegistry.getFontFilePath('Adorable Minty') ??
          SubtitleFontRegistry.getFontFilePath('Impact');
      expect(fontPath, isNotNull);
      expect(fontPath!.isNotEmpty, true);
    });

    test('Search and category filtering work correctly', () {
      final viral = SubtitlePresetsLibrary.search(
          category: SubtitleCategory.viralBold);
      expect(viral.length, 10);

      final searchHinglish =
          SubtitlePresetsLibrary.search(query: 'Desi');
      expect(searchHinglish.isNotEmpty, true);
      expect(
          searchHinglish.every((p) =>
              p.name.toLowerCase().contains('desi') ||
              p.description.toLowerCase().contains('desi')),
          true);
    });

    test('Preset toConfiguration generates serializable SubtitleConfiguration', () {
      final preset = SubtitlePresetsLibrary.allPresets.first;
      final config = preset.toConfiguration();

      expect(config.presetId, preset.id);
      expect(config.fontFamily, preset.fontFamily);
      expect(config.fontSize, preset.fontSize);
      expect(config.primaryTextColor, preset.textColor);
      expect(config.positionX, 0.5);
      expect(config.positionY, 0.78);

      final json = config.toJson();
      final restored = SubtitleConfiguration.fromJson(json);
      expect(restored.presetId, config.presetId);
      expect(restored.fontFamily, config.fontFamily);
      expect(restored.fontSize, config.fontSize);
      expect(restored.wordsPerLine, config.wordsPerLine);
    });

    test('TimedWord data model holds speech timing data correctly', () {
      const word = TimedWord(
        text: 'Bhai',
        startTimeMs: 200,
        endTimeMs: 650,
        confidence: 0.98,
        originalText: 'भाई',
      );

      expect(word.duration, const Duration(milliseconds: 450));
      final json = word.toJson();
      final restored = TimedWord.fromJson(json);
      expect(restored.text, 'Bhai');
      expect(restored.startTime, const Duration(milliseconds: 200));
      expect(restored.endTime, const Duration(milliseconds: 650));
    });

    test('SubtitleRendererPlaceholder conforms to SubtitleRendererService contract', () async {
      final service = SubtitleRendererPlaceholder();
      final preset = SubtitlePresetsLibrary.allPresets.first;
      final request = SubtitleRenderRequest(
        inputVideoPath: 'dummy_in.mp4',
        outputVideoPath: 'dummy_out.mp4',
        timedWords: const [
          TimedWord(
            text: 'Bhai',
            startTimeMs: 0,
            endTimeMs: 1000,
          ),
        ],
        preset: preset,
        configuration: preset.toConfiguration(),
      );

      final assScript = await service.generateAssScript(request);
      expect(assScript.contains('[Script Info]'), true);
      expect(assScript.contains('[V4+ Styles]'), true);

      final rendered = await service.renderSubtitles(request);
      expect(rendered, true);
      service.dispose();
    });

    test('SubtitleFontRegistry metadata contains registered fonts with fallbacks', () {
      expect(SubtitleFontRegistry.registeredFonts.isNotEmpty, true);
      final impact = SubtitleFontRegistry.registeredFonts
          .firstWhere((f) => f.family == 'Impact');
      expect(impact.displayName.contains('Impact'), true);
      expect(impact.assetPath.startsWith('assets/fonts/subtitles/'), true);

      final style = SubtitleFontRegistry.getTextStyle(
        family: 'Impact',
        fontSize: 24,
      );
      expect(style.fontFamily, 'Impact');
      expect(style.fontSize, 24);
    });
  });

  group('Part 8 & 9: Subtitle Studio Riverpod State Management', () {
    test('State initializes with default preset and collapsed secondary sections', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(subtitleStudioProvider);
      expect(state.selectedPreset.id, 'viral_beast_yellow');
      expect(state.isCustomized, false);
      expect(state.isStyleSectionExpanded, false);
      expect(state.isSettingsSectionExpanded, false);
      expect(state.isEffectsSectionExpanded, false);
    });

    test('Selecting preset preserves position and resets customization state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(subtitleStudioProvider.notifier);
      notifier.updatePosition(0.4, 0.6);

      final targetPreset = SubtitlePresetsLibrary.allPresets[12];
      notifier.selectPreset(targetPreset);

      final updatedState = container.read(subtitleStudioProvider);
      expect(updatedState.selectedPreset.id, targetPreset.id);
      expect(updatedState.configuration.positionX, 0.4);
      expect(updatedState.configuration.positionY, 0.6);
      expect(updatedState.isCustomized, false);
    });

    test('Modifying colors and typography marks isCustomized and updates activeConfig', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(subtitleStudioProvider.notifier);
      notifier.updateColors(primaryTextColor: const Color(0xFF00FF66));
      notifier.updateTypography(fontSize: 36.0);

      final updatedState = container.read(subtitleStudioProvider);
      expect(updatedState.isCustomized, true);
      expect(updatedState.activeConfig.primaryTextColor, const Color(0xFF00FF66));
      expect(updatedState.activeConfig.fontSize, 36.0);

      // Reset restores original preset color
      notifier.resetToPreset();
      final resetState = container.read(subtitleStudioProvider);
      expect(resetState.isCustomized, false);
      expect(resetState.activeConfig.primaryTextColor,
          resetState.selectedPreset.textColor);
    });

    test('Center snapping helper methods snap coordinates', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(subtitleStudioProvider.notifier);
      notifier.updatePosition(0.32, 0.84);
      notifier.centerHorizontally();
      expect(container.read(subtitleStudioProvider).activeConfig.positionX, 0.5);
      expect(container.read(subtitleStudioProvider).activeConfig.positionY, 0.84);

      notifier.centerVertically();
      expect(container.read(subtitleStudioProvider).activeConfig.positionX, 0.5);
      expect(container.read(subtitleStudioProvider).activeConfig.positionY, 0.5);
    });

    test('Accordion expansion enforces single-section exclusive mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(subtitleStudioProvider.notifier);
      expect(container.read(subtitleStudioProvider).isStyleSectionExpanded, false);
      expect(container.read(subtitleStudioProvider).isSettingsSectionExpanded, false);
      expect(container.read(subtitleStudioProvider).isEffectsSectionExpanded, false);

      // Opening style expands style
      notifier.toggleStyleSection();
      expect(container.read(subtitleStudioProvider).isStyleSectionExpanded, true);

      // Opening settings closes style
      notifier.toggleSettingsSection();
      expect(container.read(subtitleStudioProvider).isSettingsSectionExpanded, true);
      expect(container.read(subtitleStudioProvider).isStyleSectionExpanded, false);
      expect(container.read(subtitleStudioProvider).isEffectsSectionExpanded, false);

      // Opening effects closes settings
      notifier.toggleEffectsSection();
      expect(container.read(subtitleStudioProvider).isEffectsSectionExpanded, true);
      expect(container.read(subtitleStudioProvider).isSettingsSectionExpanded, false);
      expect(container.read(subtitleStudioProvider).isStyleSectionExpanded, false);

      // Opening style closes effects
      notifier.toggleStyleSection();
      expect(container.read(subtitleStudioProvider).isStyleSectionExpanded, true);
      expect(container.read(subtitleStudioProvider).isEffectsSectionExpanded, false);
    });
  });

  group('Part 2 & 4: Subtitle Studio Widgets & UI Verification', () {
    testWidgets('WorkflowProgressStepper displays 4 steps with completed and active styling',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkflowProgressStepper(
              currentStep: 2,
              totalSteps: 4,
            ),
          ),
        ),
      );

      // Verify checkmark for completed Step 1
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      // Verify text '2' for active Step 2
      expect(find.text('2'), findsOneWidget);
      // Verify upcoming steps '3' and '4'
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('SubtitlePhraseRenderer displays demo phrase "Bhai ye kya hai?"',
        (tester) async {
      final preset = SubtitlePresetsLibrary.allPresets.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtitlePhraseRenderer(
              config: preset.toConfiguration().copyWith(isUppercase: false),
              isAnimated: false,
            ),
          ),
        ),
      );

      expect(find.text('Bhai'), findsWidgets);
      expect(find.text('ye'), findsWidgets);
      expect(find.text('kya'), findsWidgets);
      expect(find.text('hai?'), findsWidgets);
    });

    testWidgets('SubtitleCanvasOverlay keeps translation fixed at (-0.5, -0.5) when textAlign changes',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 600,
                child: SubtitleCanvasOverlay(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Find the FractionalTranslation widget holding the subtitle box
      final boxTranslation = tester.widget<FractionalTranslation>(
        find.byKey(const ValueKey('subtitle_box_translation')),
      );
      expect(boxTranslation.translation, equals(const Offset(-0.5, -0.5)));

      // Change text alignment to Left
      container
          .read(subtitleStudioProvider.notifier)
          .updateLineLayout(textAlign: TextAlign.left);
      await tester.pump();

      final fractionalLeft = tester.widget<FractionalTranslation>(
        find.byKey(const ValueKey('subtitle_box_translation')),
      );
      expect(fractionalLeft.translation, equals(const Offset(-0.5, -0.5)),
          reason:
              'Subtitle position on screen must not change when textAlign is left');

      // Change text alignment to Right
      container
          .read(subtitleStudioProvider.notifier)
          .updateLineLayout(textAlign: TextAlign.right);
      await tester.pump();

      final fractionalRight = tester.widget<FractionalTranslation>(
        find.byKey(const ValueKey('subtitle_box_translation')),
      );
      expect(fractionalRight.translation, equals(const Offset(-0.5, -0.5)),
          reason:
              'Subtitle position on screen must not change when textAlign is right');
    });

    testWidgets('SubtitleStudioPage mounts with Left phone preview and Right editor sections',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SubtitleStudioPage(),
          ),
        ),
      );
      await tester.pump();

      // Top bar title & status
      expect(find.text('Subtitle Studio'), findsOneWidget);
      expect(find.text('Interactive Style Preview'), findsOneWidget);

      // Editor header
      expect(find.text('Subtitles'), findsOneWidget);
      expect(find.text('Choose your caption style, customize its appearance, and control how every word appears.'),
          findsOneWidget);

      // Accordion sections
      expect(find.text('STYLE'), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('EFFECTS'), findsOneWidget);

      // Canvas overlay guidance
      expect(find.text('Drag subtitle to position • Center snaps blue'), findsOneWidget);

      // Action buttons
      expect(find.text('Previous: Reframing'), findsOneWidget);
      expect(find.text('Next: Video Look'), findsOneWidget);
    });
  });
}
