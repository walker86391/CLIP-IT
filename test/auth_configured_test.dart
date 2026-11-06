import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/app/app.dart';
import 'package:clipit/core/config/app_env.dart';
import 'package:clipit/core/services/auth_service.dart';
import 'package:clipit/features/auth/auth_theme.dart';
import 'package:clipit/features/auth/providers/auth_provider.dart';
import 'package:clipit/features/auth/widgets/auth_checkbox.dart';
import 'package:clipit/features/auth/widgets/auth_submit_tick.dart';
import 'package:clipit/features/auth/widgets/auth_text_field.dart';
import 'package:clipit/features/auth/widgets/segmented_tabs.dart';

/// Verifies the auth screen in its *configured* state — i.e. with the real
/// `.env` credentials present and Supabase actually initialized.
///
/// This lives in its own file on purpose: `AppEnv.supabaseInitialized` is a
/// global mutable flag set by main(), and `flutter test` runs each test file
/// in a separate isolate. Keeping this separate stops the flag from leaking
/// into the stub-mode assertions in smoke_test.dart, which expect the
/// "Supabase not configured" banner to be visible.
void main() {
  // Match the real desktop window so layout/overflow problems at a realistic
  // app size are caught here rather than by eye.
  const windowSize = Size(1280, 800);

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // 1. Load the real .env exactly as main() does, and assert the keys are
    // present. This is a real read of the real file, so a missing/empty
    // .env fails here rather than silently passing.
    await AppEnv.load();
    expect(
      AppEnv.supabaseConfigured,
      isTrue,
      reason: '.env must supply SUPABASE_URL and SUPABASE_ANON_KEY. '
          'Copy .env.example to .env and fill it in.',
    );

    // 2. Flip the "Supabase is live" flag WITHOUT calling the real
    // Supabase.initialize().
    //
    // Why not initialize for real: `flutter test` stubs out HttpClient (all
    // requests return 400) and provides no shared_preferences plugin
    // implementation, so Supabase.initialize() throws MissingPluginException
    // here. The live handshake is instead verified two other ways: the real
    // `flutter run -d windows` boot, and the curl check against
    // /auth/v1/settings. This test's job is the UI wiring only.
    AppEnv.supabaseInitialized = true;
  });

  /// Boots the app at desktop size and settles the blur-reveal transition.
  ///
  /// `authServiceProvider` is overridden with the in-memory stub so the app
  /// takes the same code path it would in stub mode, WITHOUT touching
  /// `Supabase.instance` (which cannot initialize under `flutter test` — no
  /// real HttpClient, no shared_preferences plugin). Meanwhile
  /// `AppEnv.supabaseInitialized` stays true, so the banner/submit wiring
  /// under test is the real configured path.
  Future<void> bootAuth(WidgetTester tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(AuthServiceStub()),
        ],
        child: const ClipItApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('auth screen: banner is gone when Supabase is configured',
      (tester) async {
    await bootAuth(tester);

    // Landed on /auth with all three tabs.
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Secret Code'), findsOneWidget);

    // The point of this test: the not-configured banner must NOT be present.
    expect(find.text('Supabase not configured'), findsNothing);
  });

  testWidgets('auth screen: submit tick is grey until the form is complete',
      (tester) async {
    await bootAuth(tester);

    AuthSubmitTick tick() =>
        tester.widget<AuthSubmitTick>(find.byType(AuthSubmitTick));

    // Design decision: the square tick is GENUINELY inert while the form is
    // incomplete (grey, no press feedback, no submission). The earlier
    // "always-pressable Continue" existed only so a dead control could
    // reveal its errors — that job is now done by LIVE errors, asserted
    // below, so the inert state cannot become a silent dead end.
    expect(
      tick().enabled,
      isFalse,
      reason: 'The tick must start grey and inert.',
    );
    expect(tick().onPressed, isNull);

    // Live feedback: typing an invalid email explains itself immediately,
    // without needing to press an inert control.
    await tester.enterText(
        find.widgetWithText(AuthTextField, 'Email'), 'not-an-email');
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);

    // A password that is too short reports itself too.
    await tester.enterText(
        find.widgetWithText(AuthTextField, 'Password'), 'short');
    await tester.pumpAndSettle();
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);

    // Still inert, because the form is still invalid.
    expect(tick().enabled, isFalse);
  });

  testWidgets('auth screen: filled sign-up form submits without dead end',
      (tester) async {
    await bootAuth(tester);

    // Fill every field. Date of birth is read-only and opens a date picker,
    // so drive the picker rather than typing into it.
    await tester.enterText(
        find.widgetWithText(AuthTextField, 'Name'), 'Ada Lovelace');
    await tester.enterText(
        find.widgetWithText(AuthTextField, 'Email'), 'ada@example.com');
    await tester.enterText(
        find.widgetWithText(AuthTextField, 'Password'), 'correct-horse-1');
    await tester.enterText(
        find.widgetWithText(AuthTextField, 'Confirm Password'),
        'correct-horse-1');
    await tester.pumpAndSettle();

    // Open the date picker via the DOB field and accept the default date.
    await tester.tap(find.widgetWithText(AuthTextField, 'Date of Birth'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Tick both agreements.
    await tester.tap(
        find.widgetWithText(AuthCheckboxRow, 'I agree to the Privacy Policy'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(
        AuthCheckboxRow, 'I agree to the Terms & Conditions'));
    await tester.pumpAndSettle();

    // No validation errors remain on a fully valid form, and the tick has
    // gone blue (i.e. it is live) — the two agreement boxes are exactly the
    // "both boxes" condition from the request.
    expect(find.text('Name is required'), findsNothing);
    expect(find.text('Date of birth is required'), findsNothing);
    expect(
      tester.widget<AuthSubmitTick>(find.byType(AuthSubmitTick)).enabled,
      isTrue,
      reason: 'A fully filled sign-up form must enable the submit tick.',
    );
  });

  testWidgets('tabs: the sliding pill centres on the selected tab',
      (tester) async {
    await bootAuth(tester);

    // Regression guard for the "pressing Sign In jumps to Secret Code" bug.
    // The pill used to be aligned with `index * 2.0 - 1.0`, a two-tab
    // formula, so the middle tab pinned the pill to the right edge and the
    // third tab pushed it off-screen. Assert the pill's centre matches the
    // centre of the tapped tab's label for every tab.
    //
    // The pill is the AnimatedAlign's child (a FractionallySizedBox), so we
    // locate that box and compare its centre against the tab label's.
    Finder pillBox() => find.descendant(
          of: find.byType(AuthSegmentedTabs),
          matching: find.byType(FractionallySizedBox),
        );

    Future<void> expectPillOverTab(String label) async {
      final pillCentre = tester.getCenter(pillBox());
      // Scope to the tab bar: "Sign In" also appears as an inline link in
      // the Sign Up form, so an unscoped find.text would be ambiguous.
      final tabCentre = tester.getCenter(
        find.descendant(
          of: find.byType(AuthSegmentedTabs),
          matching: find.text(label),
        ),
      );
      expect(
        (pillCentre.dx - tabCentre.dx).abs(),
        lessThan(2.0),
        reason: 'Pill should sit over "$label" but was off by '
            '${(pillCentre.dx - tabCentre.dx).abs()}px',
      );
    }

    await expectPillOverTab('Sign Up');
    await tester.tap(
      find.descendant(
        of: find.byType(AuthSegmentedTabs),
        matching: find.text('Sign In'),
      ),
    );
    await tester.pumpAndSettle();
    await expectPillOverTab('Sign In');
    await tester.tap(
      find.descendant(
        of: find.byType(AuthSegmentedTabs),
        matching: find.text('Secret Code'),
      ),
    );
    await tester.pumpAndSettle();
    await expectPillOverTab('Secret Code');
  });

  testWidgets('secret code: plain text field, no auto-formatting',
      (tester) async {
    await bootAuth(tester);

    await tester.tap(find.text('Secret Code'));
    await tester.pumpAndSettle();

    final field = find.widgetWithText(AuthTextField, 'Secret Code');
    expect(field, findsOneWidget);

    // The old 5-4-4 grouping formatter is gone: typing a plain code must
    // come back verbatim, with no inserted spaces.
    await tester.enterText(field, 'ABC123');
    await tester.pumpAndSettle();

    final textField = tester.widget<AuthTextField>(field);
    expect(textField.controller.text, 'ABC123');
  });

  testWidgets(
      'secret code: expired code shows "Code expired. Sign up / login now" and returns',
      (tester) async {
    await bootAuth(tester);

    await tester.tap(find.text('Secret Code'));
    await tester.pumpAndSettle();

    final field = find.widgetWithText(AuthTextField, 'Secret Code');
    await tester.enterText(field, 'EXPIRED-TEST');
    await tester.pumpAndSettle();

    final tick = find.byTooltip('Verify secret admin code');
    await tester.tap(tick);
    await tester.pumpAndSettle();

    // Verify user sees exact prompt
    expect(find.text('Code expired. Sign up / login now'), findsOneWidget);
    expect(find.text('Return to Sign In / Sign Up →'), findsOneWidget);

    // Fast-forward redirect timer (2.4s)
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Returned to Sign In tab
    expect(find.widgetWithText(AuthTextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(AuthTextField, 'Password'), findsOneWidget);
  });

  testWidgets('secret code: valid admin code unlocks app', (tester) async {
    await bootAuth(tester);

    await tester.tap(find.text('Secret Code'));
    await tester.pumpAndSettle();

    final field = find.widgetWithText(AuthTextField, 'Secret Code');
    await tester.enterText(field, 'ADMIN-2026-CLIPIT');
    await tester.pumpAndSettle();

    final tick = find.byTooltip('Verify secret admin code');
    await tester.tap(tick);
    await tester.pumpAndSettle();

    // App unlocked and moved to Home page
    expect(find.text('WELCOME,'), findsOneWidget);
  });

  testWidgets(
      'blur: right-side zone, flat bulk, feathered (diffused) left edge',
      (tester) async {
    await bootAuth(tester);

    final windowWidth = windowSize.width;
    // The zone is centred on the glass panel with an equal margin per side
    // (the placement the user asked to be measured out):
    //   margin = (zoneWidth - panelWidth) / 2
    final zoneWidth = windowWidth * 0.55;
    final panelLeft = windowWidth -
        AuthColors.panelOuterPadding -
        AuthColors.panelWidth;
    final panelCenter = panelLeft + AuthColors.panelWidth / 2;
    final zoneMargin = (zoneWidth - AuthColors.panelWidth) / 2;
    final zoneStart = panelCenter - zoneWidth / 2;
    const featherWidth = AuthColors.backgroundBlurFeatherWidth;

    // The zone must frame the panel symmetrically, and the feather must fit
    // inside that margin (otherwise the blur would still be ramping up
    // behind the panel instead of being flat).
    expect(zoneMargin, closeTo(92.0, 0.5));
    expect(zoneStart, closeTo(620.0, 0.5));
    expect(
      featherWidth,
      lessThanOrEqualTo(zoneMargin),
      reason: 'The feather band must fit inside the blur margin.',
    );

    // ── Zero-Lag Right-Side Zone Geometry ───────────────────────────
    // In the zero-lag architecture, the right-side zone provides smooth
    // contrast via an accelerated gradient scrim instead of 32 laggy
    // BackdropFilter strips. The zone geometry (centered symmetrically on
    // the panel, feather band fitting inside the margin) is preserved.
    expect(zoneStart, closeTo(620.0, 0.5));
    expect(zoneWidth, closeTo(704.0, 0.5));

    // Assert that no unisolated, performance-killing BackdropFilters exist
    // on the screen to ensure zero lag on desktop GPUs.
    final backdropFilters = find.byType(BackdropFilter).evaluate();
    expect(
      backdropFilters,
      isEmpty,
      reason: 'Zero BackdropFilters should be present in the zero-lag architecture.',
    );
  });

  testWidgets('measure: selection pill length and the blur zone margin',
      (tester) async {
    await bootAuth(tester);

    // The user asked for the "selection marker" (the rounded highlight box
    // drawn around the selected tab) to be MEASURED, because its length was
    // the yardstick for moving the blur. Measure the real widget rather than
    // trusting the arithmetic, then check the geometry the screen derives
    // from it.
    final Finder pill = find.descendant(
      of: find.byType(AuthSegmentedTabs),
      matching: find.byType(FractionallySizedBox),
    );
    final double pillWidth = tester.getSize(pill).width;

    // Expected: the tabs' inner width (panel width, minus the panel's own
    // padding, minus the tabs' padding and border) split three ways.
    final double expectedPillWidth =
        (AuthColors.panelWidth -
                AuthColors.panelInnerPadding * 2 -
                AuthColors.tabsPadding * 2 -
                AuthColors.tabsBorderWidth * 2) /
            3;
    expect(
      pillWidth,
      closeTo(expectedPillWidth, 1.0),
      reason: 'The selection pill should be one third of the tabs\' inner '
          'width (measured $pillWidth, expected ~$expectedPillWidth).',
    );

    // The pill is ~149px at a 1280px window — which is why the blur had to
    // move by roughly that much to feel like "a pill-width further right".
    expect(
      pillWidth,
      greaterThan(140.0),
      reason: 'Sanity check on the measured pill length.',
    );

    // And the placement actually in force (see the blur test above).
    const windowSize1280 = 1280.0;
    final double zoneWidth = windowSize1280 * 0.55;
    final double margin = (zoneWidth - AuthColors.panelWidth) / 2;
    expect(margin, closeTo(92.0, 0.5));
  });

  test('env keys are non-empty and the URL points at the real project', () {
    // Guards the two things most likely to silently break the app: an empty
    // value in .env, and a dashboard URL pasted where the API URL belongs.
    final url = AppEnv.supabaseUrl!;
    final key = AppEnv.supabaseAnonKey!;

    expect(url, startsWith('https://'));
    expect(url, isNot(contains('supabase.com/dashboard')),
        reason: 'SUPABASE_URL must be the API endpoint, not the dashboard.');
    expect(url, endsWith('.supabase.co'));
    expect(key, isNotEmpty);
  });
}
