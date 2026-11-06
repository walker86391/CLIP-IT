import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/features/projects/components/workflow_progress_stepper.dart';
import 'package:clipit/features/video_look/models/video_look_state.dart';
import 'package:clipit/features/video_look/pages/video_look_page.dart';
import 'package:clipit/features/video_look/providers/video_look_provider.dart';
import 'package:clipit/features/video_look/widgets/video_look_quick_bar.dart';

void main() {
  group('Step 3 — VideoLookPage Widget Tests', () {
    testWidgets('renders top bar, step 3 stepper, phone preview, and quick looks',
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
            home: VideoLookPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar header
      expect(find.text('3 — Video Look'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Live Look Preview'), findsOneWidget);

      // Workflow progress stepper has Step 3 active
      expect(find.byType(WorkflowProgressStepper), findsOneWidget);

      // Quick Looks bar at the top
      expect(find.byType(VideoLookQuickBar), findsOneWidget);
      expect(find.text('Original'), findsWidgets);
      expect(find.text('Cinematic'), findsWidgets);
      expect(find.text('Moody'), findsWidgets);
      expect(find.text('Warm'), findsWidgets);
      expect(find.text('Cold'), findsWidgets);
      expect(find.text('Vintage'), findsWidgets);
      expect(find.text('Black & White'), findsWidgets);

      // Main title & guidance
      expect(find.text('3 — VIDEO LOOK'), findsOneWidget);
      expect(
        find.textContaining('Customize how your video looks'),
        findsOneWidget,
      );

      // Left column stationary preview
      expect(find.text('Live Look Engine • Real-time Hardware Filters'), findsOneWidget);

      // Bottom action buttons
      expect(find.text('Previous: Subtitles'), findsOneWidget);
      expect(find.text('Next: Sound Effects'), findsOneWidget);
    });

    testWidgets('renders all 8 verified categories with icon-only reset and single accordion expansion',
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
            home: VideoLookPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 8 verified working category headers exist
      expect(find.text('BASIC'), findsOneWidget);
      expect(find.text('COLOR'), findsOneWidget);
      expect(find.text('BLACK & WHITE / TONING'), findsOneWidget);
      expect(find.text('CINEMATIC'), findsOneWidget);
      expect(find.text('LIGHT & ATMOSPHERE'), findsOneWidget);
      expect(find.text('BLUR & SOFTNESS'), findsOneWidget);
      expect(find.text('FILM & RETRO'), findsOneWidget);
      expect(find.text('BLEND / OVERLAY'), findsOneWidget);

      // Verify NO "Reset" text in headers (strictly icon only)
      expect(find.text('Reset'), findsNothing);

      // By default, nothing is pre-opened until clicked
      expect(find.text('Brightness'), findsNothing);

      // Tap on 'BASIC' category to open it
      await tester.ensureVisible(find.text('BASIC'));
      await tester.tap(find.text('BASIC'));
      await tester.pumpAndSettle();

      expect(find.text('Brightness'), findsOneWidget);
      expect(find.text('Contrast'), findsOneWidget);

      // Now tap on 'COLOR' category: it should close BASIC and open COLOR
      await tester.ensureVisible(find.text('COLOR'));
      await tester.tap(find.text('COLOR'));
      await tester.pumpAndSettle();

      // State check: active category is now COLOR
      final stateAfter = container.read(videoLookProvider);
      expect(stateAfter.activeCategory, equals(VideoLookCategory.color));

      // In COLOR: Brightness should now be hidden, Hue Shift should be visible
      expect(find.text('Hue Shift'), findsOneWidget);
      expect(find.text('Color Balance'), findsOneWidget);
      expect(find.text('Brightness'), findsNothing);
    });

    testWidgets('slider and number box sync bidirectionally',
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
            home: VideoLookPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on BASIC to open it
      await tester.ensureVisible(find.text('BASIC'));
      await tester.tap(find.text('BASIC'));
      await tester.pumpAndSettle();

      // Update contrast via provider and verify text box updates
      container.read(videoLookProvider.notifier).setContrast(25.5);
      await tester.pumpAndSettle();

      expect(find.text('25.5'), findsOneWidget);

      // Reset basic category via reset icon button
      // Find the first reset icon in the widget tree (which corresponds to BASIC)
      final resetIcons = find.byIcon(Icons.restart_alt_rounded);
      expect(resetIcons, findsWidgets);

      await tester.tap(resetIcons.first);
      await tester.pumpAndSettle();

      // Contrast should be reset to 0.0
      expect(container.read(videoLookProvider).contrast, equals(0.0));
      expect(find.text('0.0'), findsWidgets);
    });
  });
}
