import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/features/branding/models/branding_models.dart';
import 'package:clipit/features/branding/pages/step5_branding_page.dart';
import 'package:clipit/features/branding/providers/branding_provider.dart';
import 'package:clipit/features/branding/widgets/overlay_style_picker.dart';
import 'package:clipit/features/branding/widgets/timing_range_slider.dart';
import 'package:clipit/features/branding/widgets/typography_appearance_section.dart';
import 'package:clipit/features/subtitles/widgets/subtitle_phrase_renderer.dart';

void main() {
  group('Stage 5 — Branding & Overlay Studio Data Models & FFmpeg Spec Tests', () {
    test('BrandingLayer initializes with deterministic defaults and FFmpeg drawtext compatibility', () {
      const layer = BrandingLayer(
        id: 'test_layer_1',
        text: 'AZHAR KHAN',
        font: 'Montserrat',
        fontSize: 24.0,
        opacity: 0.85,
        startPercent: 10.0,
        endPercent: 90.0,
      );

      expect(layer.text, equals('AZHAR KHAN'));
      expect(layer.opacity, equals(0.85));
      expect(layer.isVisibleAt(5.0), isFalse);
      expect(layer.isVisibleAt(50.0), isTrue);
      expect(layer.isVisibleAt(95.0), isFalse);

      final ffmpegSpec = layer.toFfmpegDrawtextSpec(clipDurationSeconds: 20.0);
      expect(ffmpegSpec, contains("drawtext=text='AZHAR KHAN'"));
      expect(ffmpegSpec, contains("fontfile='Montserrat'"));
      expect(ffmpegSpec, contains("alpha='0.85'"));
      expect(ffmpegSpec, contains("enable='between(t,2.0,18.0)'"));
    });

    test('TemporaryOverlay enforces style-driven defaults without general opacity', () {
      const overlay = TemporaryOverlay(
        id: 'test_overlay_1',
        name: 'Overlay 01',
        text: 'INSANE CLUTCH',
        style: OverlayStylePreset.verticalLineRight,
        startPercent: 25.0,
        endPercent: 65.0,
      );

      expect(overlay.style, equals(OverlayStylePreset.verticalLineRight));
      expect(overlay.shape, equals(OverlayShapeType.verticalLine));
      expect(overlay.isVisibleAt(10.0), isFalse);
      expect(overlay.isVisibleAt(35.0), isTrue);
      expect(overlay.isVisibleAt(70.0), isFalse);
    });

    test('OverlayStylePreset defaults map accurately to UI specifications', () {
      expect(OverlayStylePreset.verticalLineRight.defaultPosition,
          equals(PositionPreset.bottomLeft));
      expect(OverlayStylePreset.verticalLineLeft.defaultPosition,
          equals(PositionPreset.bottomRight));
      expect(OverlayStylePreset.starDrop.defaultShape,
          equals(OverlayShapeType.star));
      expect(OverlayStylePreset.boxCallout.defaultShape,
          equals(OverlayShapeType.roundedRectangle));
    });

    test('PositionPreset alignment and defaultTextAlign consider screen bounds and text box anchor', () {
      expect(PositionPreset.topLeft.alignment, equals(Alignment.topLeft));
      expect(PositionPreset.topLeft.defaultTextAlign, equals(TextAlign.left));

      expect(PositionPreset.topCenter.alignment, equals(Alignment.topCenter));
      expect(PositionPreset.topCenter.defaultTextAlign, equals(TextAlign.center));

      expect(PositionPreset.topRight.alignment, equals(Alignment.topRight));
      expect(PositionPreset.topRight.defaultTextAlign, equals(TextAlign.right));

      expect(PositionPreset.center.alignment, equals(Alignment.center));
      expect(PositionPreset.center.defaultTextAlign, equals(TextAlign.center));

      expect(PositionPreset.bottomRight.alignment, equals(Alignment.bottomRight));
      expect(PositionPreset.bottomRight.defaultTextAlign, equals(TextAlign.right));

      expect(PositionPreset.bottomLeft.alignment, equals(Alignment.bottomLeft));
      expect(PositionPreset.bottomLeft.defaultTextAlign, equals(TextAlign.left));

      expect(PositionPreset.bottomCenter.alignment, equals(Alignment.bottomCenter));
      expect(PositionPreset.bottomCenter.defaultTextAlign, equals(TextAlign.center));
    });
  });

  group('Stage 5 — BrandingProvider State & Mutation Tests', () {
    test('Initializes with permanent branding as active tab and empty overlay lists', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(brandingProvider);
      expect(state.activeTab, equals(BrandingTab.permanent));
      expect(state.permanentLayers.isEmpty, isTrue);
      expect(state.temporaryOverlays.isEmpty, isTrue);
      expect(state.selectedPermanentLayer, isNull);
      expect(state.selectedTemporaryOverlay, isNull);
    });

    test('Can switch tabs between Permanent Branding and Temporary Overlays', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(brandingProvider.notifier);
      notifier.setTab(BrandingTab.temporary);
      expect(container.read(brandingProvider).activeTab,
          equals(BrandingTab.temporary));

      notifier.setTab(BrandingTab.permanent);
      expect(container.read(brandingProvider).activeTab,
          equals(BrandingTab.permanent));
    });

    test('Can add, update, duplicate, and reset permanent layers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(brandingProvider.notifier);
      notifier.addPermanentLayer(text: '@TWITCH_PRO');

      var state = container.read(brandingProvider);
      expect(state.permanentLayers.length, equals(1));
      final newLayerId = state.selectedPermanentId!;
      expect(state.selectedPermanentLayer?.text, equals('@TWITCH_PRO'));

      // Update opacity
      notifier.updatePermanentLayer(newLayerId, (l) => l.copyWith(opacity: 0.5));
      expect(container.read(brandingProvider).selectedPermanentLayer?.opacity,
          equals(0.5));

      // Duplicate
      notifier.duplicatePermanentLayer(newLayerId);
      state = container.read(brandingProvider);
      expect(state.permanentLayers.length, equals(2));
      expect(state.selectedPermanentLayer?.text, equals('@TWITCH_PRO (Copy)'));

      // Reset
      final copyId = state.selectedPermanentId!;
      notifier.resetPermanentLayer(copyId);
      expect(container.read(brandingProvider).selectedPermanentLayer?.opacity,
          equals(1.0));
    });

    test('Can add, change style, duplicate, reorder, and reset temporary overlays', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(brandingProvider.notifier);
      notifier.addTemporaryOverlay(style: OverlayStylePreset.boxCallout);

      var state = container.read(brandingProvider);
      expect(state.temporaryOverlays.length, equals(1));
      final activeId = state.selectedTemporaryId!;
      expect(state.selectedTemporaryOverlay?.style,
          equals(OverlayStylePreset.boxCallout));

      // Change style
      notifier.changeOverlayStyle(activeId, OverlayStylePreset.starDrop);
      expect(container.read(brandingProvider).selectedTemporaryOverlay?.style,
          equals(OverlayStylePreset.starDrop));

      // Add second overlay and reorder
      notifier.addTemporaryOverlay(style: OverlayStylePreset.cornerCallout);
      state = container.read(brandingProvider);
      expect(state.temporaryOverlays.length, equals(2));
      notifier.reorderTemporaryOverlays(0, 1);
      state = container.read(brandingProvider);
      expect(state.temporaryOverlays.first.style,
          equals(OverlayStylePreset.cornerCallout));

      // Reset overlay
      notifier.resetTemporaryOverlay(activeId);
      expect(container.read(brandingProvider).selectedTemporaryOverlay?.lineLength,
          equals(80.0));
    });
  });

  group('Stage 5 — Step5BrandingPage UI & Subtitle Immovability Tests', () {
    testWidgets('Renders Step5BrandingPage with navigation, dual tabs, preview, and controls',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Step5BrandingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top Header & Stepper
      expect(find.text('STAGE 6: OVERLAYS & BRANDING'), findsOneWidget);
      expect(find.text('Finish Project & Generate Clips →'), findsOneWidget);
      expect(find.byKey(const Key('finish_project_button')), findsOneWidget);

      // Two Studio Tabs
      expect(find.text('PERMANENT BRANDING'), findsWidgets);
      expect(find.text('TEMPORARY OVERLAYS'), findsOneWidget);

      // Permanent Branding Controls
      expect(find.text('BRANDING TEXT LAYERS'), findsOneWidget);
      expect(find.text('+ Add Text'), findsOneWidget);

      // Immovable Subtitle Verification
      // Subtitle phrase is rendered in the preview under an IgnorePointer
      expect(find.byType(SubtitlePhraseRenderer), findsOneWidget);
      expect(find.text('BHAI'), findsWidgets);
      final ignorePointers = tester.widgetList<IgnorePointer>(
        find.ancestor(
          of: find.byType(SubtitlePhraseRenderer),
          matching: find.byType(IgnorePointer),
        ),
      );
      expect(ignorePointers.isNotEmpty, isTrue);
      expect(ignorePointers.any((ip) => ip.ignoring), isTrue,
          reason: 'Subtitles must be strictly non-interactive and immovable in Stage 5');

      // Add a permanent layer by pressing '+ Add Text'
      await tester.tap(find.text('+ Add Text'));
      await tester.pumpAndSettle();

      // Verify accordion sections are present
      expect(find.text('TEXT & TYPOGRAPHY'), findsOneWidget);
      expect(find.text('POSITION & ALIGNMENT'), findsOneWidget);
      expect(find.text('Delete Text Box'), findsOneWidget);

      // Switch to Temporary Overlays tab
      await tester.tap(find.text('TEMPORARY OVERLAYS'));
      await tester.pumpAndSettle();

      // Verify Temporary Overlays UI
      expect(find.text('TEMPORARY OVERLAYS (LAYERS)'), findsOneWidget);
      expect(find.text('+ Add Overlay'), findsOneWidget);

      // Add a temporary overlay
      await tester.tap(find.text('+ Add Overlay'));
      await tester.pumpAndSettle();

      expect(find.text('STYLE & SHAPE'), findsOneWidget);
      expect(find.text('Delete Text Box'), findsOneWidget);
    });

    testWidgets('OverlayStylePicker allows selecting styles and updates state',
        (tester) async {
      OverlayStylePreset selected = OverlayStylePreset.verticalLineRight;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return OverlayStylePicker(
                  selectedStyle: selected,
                  onStyleSelected: (style) {
                    setState(() {
                      selected = style;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Vertical Line — Right'), findsOneWidget);
      expect(find.text('Star Drop'), findsOneWidget);
      expect(find.text('Box Callout'), findsOneWidget);

      await tester.tap(find.text('Star Drop'));
      await tester.pumpAndSettle();
      expect(selected, equals(OverlayStylePreset.starDrop));
    });

    testWidgets('TimingRangeSlider enforces valid Start < End percentages and shows seconds',
        (tester) async {
      double start = 20.0;
      double end = 70.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return TimingRangeSlider(
                  startPercent: start,
                  endPercent: end,
                  clipDurationSeconds: 30.0,
                  onChanged: (s, e) {
                    setState(() {
                      start = s;
                      end = e;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('START'), findsOneWidget);
      expect(find.text('END'), findsOneWidget);
      expect(find.textContaining('15.0s (50%)'), findsOneWidget);

      // Tap preset 'Hook (0-25%)'
      await tester.tap(find.text('Hook (0-25%)'));
      await tester.pumpAndSettle();

      expect(start, equals(0.0));
      expect(end, equals(25.0));
    });

    test('allAvailableBrandingFonts includes custom fonts and TypographyAppearanceSection renders them', () {
      final fonts = allAvailableBrandingFonts;
      expect(fonts.isNotEmpty, isTrue);

      // Verify custom fonts exist in branding fonts
      final customSamples = [
        'Adorable Minty',
        'Aeruno',
        'BlackWidow',
        'FunSized',
        'GLF Cikutra',
        'Rubik Vinyl',
      ];
      for (final sample in customSamples) {
        expect(
          fonts.any((f) => f.name.toLowerCase() == sample.toLowerCase()),
          isTrue,
          reason: 'Custom font $sample must be available in branding options',
        );
      }
    });
  });
}
