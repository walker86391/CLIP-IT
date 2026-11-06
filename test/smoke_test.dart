import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/app/app.dart';
import 'package:clipit/features/auth/widgets/auth_submit_tick.dart';

void main() {
  testWidgets('boot: loading brand screen, then auth screen with tabs',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ClipItApp()));

    // First frame: the branded loading screen.
    expect(find.text('ClipIt'), findsOneWidget);

    // Let auth init resolve, the ~900 ms branding gate elapse, and the
    // blur-reveal entrance transition finish.
    await tester.pumpAndSettle();

    // Landed on /auth: all three tabs present, Sign Up is the default.
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Secret Code'), findsOneWidget);
  });

  testWidgets('auth screen: banner + disabled submit without Supabase',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ClipItApp()));
    await tester.pumpAndSettle();

    // No env keys in the test environment → non-blocking banner + an inert
    // submit tick. (The wide "Continue" button it replaced had a visible
    // text label; the tick is an icon control, so this asserts the widget
    // and its disabled state instead of searching for text.)
    expect(find.text('Supabase not configured'), findsOneWidget);
    expect(find.byType(AuthSubmitTick), findsWidgets);
    for (final tick in tester
        .widgetList<AuthSubmitTick>(find.byType(AuthSubmitTick))) {
      expect(tick.enabled, isFalse);
      expect(tick.onPressed, isNull);
    }
  });
}
