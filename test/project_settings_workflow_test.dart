import 'package:clipit/features/clips/pages/genre_selection_page.dart';
import 'package:clipit/features/projects/models/project_workflow_state.dart';
import 'package:clipit/features/projects/pages/project_settings_page.dart';
import 'package:clipit/features/projects/providers/project_workflow_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectWorkflowState and Prompt Presets', () {
    test('GenrePromptPresets returns distinct prompts for all 10 genres', () {
      final prompts = <String>{};
      for (int i = 0; i < 10; i++) {
        final prompt = GenrePromptPresets.getPromptForGenre(i);
        expect(prompt.isNotEmpty, isTrue);
        prompts.add(prompt);
      }
      expect(prompts.length, equals(10));
    });

    test('ProjectWorkflowNotifier updates state accurately', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Select genre 3: TECH / HOW-TO
      container
          .read(projectWorkflowProvider.notifier)
          .selectGenre(3, 'TECH / HOW-TO');

      final state = container.read(projectWorkflowProvider);
      expect(state.selectedGenreIndex, equals(3));
      expect(state.genreTitle, equals('TECH / HOW-TO'));
      expect(state.aiPrompt, contains('architectural'));

      // Switch device to laptop
      container
          .read(projectWorkflowProvider.notifier)
          .selectDevice(PreviewDeviceType.laptop);
      expect(
        container.read(projectWorkflowProvider).selectedDevice,
        equals(PreviewDeviceType.laptop),
      );

      // Switch ratio to 9:16
      container
          .read(projectWorkflowProvider.notifier)
          .selectRatio(VideoAspectRatio.ratio9x16);
      expect(
        container.read(projectWorkflowProvider).selectedRatio,
        equals(VideoAspectRatio.ratio9x16),
      );

      // Toggle head tracking
      container
          .read(projectWorkflowProvider.notifier)
          .toggleHeadTracking(false);
      expect(
        container.read(projectWorkflowProvider).headTrackingEnabled,
        isFalse,
      );
    });
  });

  group('ProjectSettingsPage Widget Tests', () {
    testWidgets('renders top bar, ratios, devices, and action button',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(projectWorkflowProvider.notifier)
          .selectGenre(0, 'PODCASTS / INTERVIEWS');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ProjectSettingsPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar header
      expect(find.text('Project Settings'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);

      // Ratio buttons (also matches preview ratio badge if shown)
      expect(find.text('16:9'), findsWidgets);
      expect(find.text('9:16'), findsWidgets);
      expect(find.text('1:1'), findsWidgets);

      // Head tracking section
      expect(find.text('Head Tracking & Speaker Reframing'), findsOneWidget);

      // Inbuilt AI prompt textarea
      expect(
        find.textContaining(
            'WHAT IS THE VIDEO ABOUT / PASTE THE TITLE OF THE VIDEO IF RELEVENT!'),
        findsOneWidget,
      );

      // Platform blocks toggle pill
      expect(find.text('preview platform blocks'), findsOneWidget);
    });

    testWidgets('GenreSelectionPage connects with provider on choice selection',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      int? selectedOut;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: GenreSelectionPage(
                onContinue: (val) {
                  selectedOut = val;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Removed 01/10 per user request
      expect(find.text('PODCASTS / INTERVIEWS'), findsOneWidget);
      expect(find.text('STAND-UP'), findsOneWidget);

      // Tap on GAMING (card 10)
      await tester.tap(find.text('** GAMING **'));
      await tester.pumpAndSettle();

      final state = container.read(projectWorkflowProvider);
      expect(state.selectedGenreIndex, equals(9));
      expect(state.genreTitle, equals('** GAMING **'));

      // Tap continue button
      await tester.tap(find.byKey(const Key('genre_continue_button')));
      await tester.pumpAndSettle();

      expect(selectedOut, equals(9));
    });
  });
}
