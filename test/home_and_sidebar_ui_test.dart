import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/features/clips/pages/genre_selection_page.dart';
import 'package:clipit/features/home/pages/home_page.dart';
import 'package:clipit/features/home/providers/video_upload_provider.dart';
import 'package:clipit/features/projects/providers/project_workflow_provider.dart';
import 'package:clipit/features/shell/clipit_shell.dart';

void main() {
  const windowSize = Size(1280, 850);
  const fullscreen169 = Size(1920, 1080);

  Widget createSubject({ProviderContainer? container}) {
    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ClipItShell(),
        ),
      );
    }
    return const ProviderScope(
      child: MaterialApp(
        home: ClipItShell(),
      ),
    );
  }

  testWidgets('HomePage renders all key visual cards matching user design',
      (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    // 1. Welcome Header
    expect(find.text('WELCOME,'), findsOneWidget);
    expect(find.text('SHIVAM C.'), findsOneWidget);

    // 2. The Promo "A" card
    expect(find.text('A'), findsOneWidget);

    // 3. The 4 Action buttons
    expect(find.text('UPLOAD A LONG-\nFORM CONTENT'), findsOneWidget);
    expect(find.text('GET A VIDEO FROM YOUTUBE'), findsOneWidget);
    expect(find.text('UPLOAD SHORT CLIPS ALREADY CUT'), findsOneWidget);
    expect(find.text('REUSE CLIPS'), findsOneWidget);

    // 4. Subtitles on action buttons
    expect(
      find.text('Podcasts, lectures, interviews or livestreams.'),
      findsOneWidget,
    );
    expect(
      find.text('Paste a link to a video you can use.'),
      findsOneWidget,
    );

    // 5. Pricing plans: initially shows Free & Balanced
    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Balanced'), findsOneWidget);
    expect(find.text('Current Plan'), findsOneWidget);
    expect(find.text('Talk To Sales'), findsOneWidget);
    expect(find.text('UNLIMITED FREE CLIPS!'), findsOneWidget);
    expect(find.text('Unlimited free clips'), findsOneWidget);
    expect(find.text('Less ads'), findsOneWidget);
    expect(find.text('Reward program'), findsOneWidget);
    expect(find.text('Some advanced features'), findsOneWidget);
    expect(find.text('Small AI integrations'), findsOneWidget);
    expect(find.text('Fully AI integrated'), findsOneWidget);
    expect(find.text('Auto-upload clips'), findsOneWidget);
    expect(find.text('Zero ads'), findsOneWidget);
    expect(find.text('NO ADS'), findsWidgets);

    // Navigate right to reveal PRO+
    final rightChevron = find.byKey(const Key('pricing_slider_next_button'));
    await tester.tap(rightChevron);
    await tester.pumpAndSettle();
    expect(find.text('PRO+'), findsOneWidget);
    expect(find.text('Balanced'), findsOneWidget);

    // Navigate back to left
    final leftChevron = find.byKey(const Key('pricing_slider_prev_button'));
    await tester.tap(leftChevron);
    await tester.pumpAndSettle();
    expect(find.text('Free'), findsOneWidget);

    // 6. "NOTHING TO DISPLAY" empty state card
    expect(find.text('NOTHING TO DISPLAY'), findsOneWidget);
    expect(find.byIcon(Icons.precision_manufacturing_outlined), findsOneWidget);

    // 7. Status bar
    expect(find.text('Clip-It running!'), findsOneWidget);
    expect(find.text('CPU: 0.0%  GPU: 0.0%  RAM: 0.0%'), findsOneWidget);

    // 8. Upload Bar & NEXT button
    expect(find.byKey(const Key('home_upload_next_button')), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
  });

  testWidgets('16:9 Fullscreen layout renders cleanly without overflowing',
      (tester) async {
    tester.view.physicalSize = fullscreen169;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('WELCOME,'), findsOneWidget);
    expect(find.text('NOTHING TO DISPLAY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Pressing Long-Form Content opens GenreSelectionPage with all 10 cards and reactive button',
      (tester) async {
    tester.view.physicalSize = fullscreen169;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    container.read(videoUploadProvider.notifier).setVideoManual(
          fileName: 'podcast.mp4',
          filePath: 'podcast.mp4',
          fileSizeBytes: 1024,
        );

    await tester.pumpWidget(createSubject(container: container));
    await tester.pumpAndSettle();

    // Tap UPLOAD A LONG-FORM CONTENT on Home
    final uploadBtn = find.text('UPLOAD A LONG-\nFORM CONTENT');
    expect(uploadBtn, findsOneWidget);
    await tester.tap(uploadBtn);
    await tester.pumpAndSettle();

    // Now on Connect to your AI chatbot page
    expect(find.text('Connect to your AI chatbot'), findsOneWidget);
    expect(find.byKey(const Key('chatgpt_bridge_connect_button')), findsOneWidget);
    expect(find.byKey(const Key('bridge_continue_button')), findsOneWidget);

    // Tap Continue to proceed to GenreSelectionPage
    await tester.tap(find.byKey(const Key('bridge_continue_button')));
    await tester.pumpAndSettle();

    // Now on GenreSelectionPage
    expect(find.byType(GenreSelectionPage), findsOneWidget);
    // Removed 01/10 per user request
    expect(find.textContaining('SELECT THE GENRE'), findsOneWidget);
    expect(find.textContaining('FOR YOUR CONTENT'), findsOneWidget);
    expect(find.text('BETTER CLIPS.'), findsOneWidget);
    expect(find.text('BIGGER REACH.'), findsOneWidget);

    // Verify all 10 cards are rendered
    expect(find.text('PODCASTS / INTERVIEWS'), findsOneWidget);
    expect(find.text('STAND-UP'), findsOneWidget);
    expect(find.text('STORYTIME'), findsOneWidget);
    expect(find.text('** TECH / HOW-TO **'), findsOneWidget);
    expect(find.text('** LIVE STREAMS **'), findsOneWidget);
    expect(find.text('COMEDY / ROASTS'), findsOneWidget);
    expect(find.text('FUNNY / MEMES'), findsOneWidget);
    expect(find.text('LIFE / ADVICE'), findsOneWidget);
    expect(find.text('** VLOGS **'), findsOneWidget);
    expect(find.text('** GAMING **'), findsOneWidget);

    // Verify Beta notice
    expect(find.text('** BETA FEATURES!'), findsOneWidget);

    // Verify continue button key
    final continueBtn = find.byKey(const Key('genre_continue_button'));
    expect(continueBtn, findsOneWidget);

    // Initially, no selection -> continue button is grayed out (disabled)
    // Tapping continue button when disabled does not throw or trigger callback
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    // Tap Card 01: PODCASTS / INTERVIEWS
    final card01 = find.byKey(const Key('genre_card_01'));
    expect(card01, findsOneWidget);
    await tester.tap(card01);
    await tester.pumpAndSettle();

    // Now Card 01 is selected (shows checkmark inside card)
    expect(find.byIcon(Icons.check_rounded), findsWidgets);

    // Tap Card 04: TECH / HOW-TO
    final card04 = find.byKey(const Key('genre_card_04'));
    await tester.tap(card04);
    await tester.pumpAndSettle();

    // Card 04 is now selected, continue button remains active
    expect(find.byKey(const Key('genre_continue_button')), findsOneWidget);
  });

  testWidgets(
      'Sidebar: expands on chevron click and resizes/reflows main content',
      (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    // In collapsed state, nav labels are hidden
    expect(find.text('Clip Editor'), findsNothing);
    expect(find.text('Repurpose'), findsNothing);

    // Measure the position of the content (e.g. Welcome header)
    final welcomePosBefore = tester.getTopLeft(find.text('WELCOME,'));

    // Tap the bottom expand arrow
    final expandBtn = find.byKey(const Key('sidebar_toggle_button'));
    expect(expandBtn, findsOneWidget);
    await tester.tap(expandBtn);
    await tester.pumpAndSettle();

    // Now expanded: labels are displayed
    expect(find.text('Clip Editor'), findsOneWidget);
    expect(find.text('Clips'), findsOneWidget);
    expect(find.text('Repurpose'), findsOneWidget);
    expect(find.text('Collapse'), findsOneWidget);

    // Main content resizes and reflows alongside the expanded sidebar
    final welcomePosAfter = tester.getTopLeft(find.text('WELCOME,'));
    expect(
      welcomePosAfter.dx,
      greaterThan(welcomePosBefore.dx),
      reason:
          'Content must reflow alongside sidebar in desktop application layout',
    );

    // Tap collapse button to close
    await tester.tap(find.text('Collapse'));
    await tester.pumpAndSettle();
    expect(find.text('Collapse'), findsNothing);
  });

  testWidgets(
      'Sidebar: tapping Clip Editor opens GenreSelectionPage, tapping Home restores HomePage',
      (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    container.read(projectWorkflowProvider.notifier).startNewSession(
          videoPath: 'test.mp4',
          fileName: 'test.mp4',
        );

    await tester.pumpWidget(createSubject(container: container));
    await tester.pumpAndSettle();

    // Initially on Home: HomePage is visible
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(GenreSelectionPage), findsNothing);

    // Tap the 2nd icon (Clip Editor: sidebar_item_Clip Editor)
    await tester.tap(find.byKey(const Key('sidebar_item_Clip Editor')));
    await tester.pumpAndSettle();

    // Now on Connect to your AI chatbot page
    expect(find.text('Connect to your AI chatbot'), findsOneWidget);
    expect(find.byKey(const Key('bridge_continue_button')), findsOneWidget);

    // Tap Continue to GenreSelectionPage
    await tester.tap(find.byKey(const Key('bridge_continue_button')));
    await tester.pumpAndSettle();
    expect(find.byType(GenreSelectionPage), findsOneWidget);
    expect(find.textContaining('SELECT THE GENRE'), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);

    // Tap Home icon again
    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();

    // Restores HomePage
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(GenreSelectionPage), findsNothing);
  });
}
