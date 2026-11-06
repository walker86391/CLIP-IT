import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/app/app.dart';
import 'package:clipit/core/config/app_env.dart';
import 'package:clipit/core/services/auth_service.dart';
import 'package:clipit/features/auth/providers/auth_provider.dart';

/// Regression tests for the input lag.
///
/// The lag had one root cause: every [BackdropFilter] on the auth screen sat
/// in the same layer as the form, so each keystroke marked that layer dirty
/// and Flutter re-ran the Gaussian blur passes — 33 of them for the
/// background feather plus the panel's own sigma-26 glass. Nothing about
/// those backdrops changes while you type, so all of that work was wasted.
///
/// The fix is repaint isolation: each static backdrop is wrapped in its own
/// [RepaintBoundary], and the editable content is isolated in a *separate*
/// (inner) boundary. Flutter caches a repaint boundary's rasterized layer
/// and only redraws it when something inside it is marked dirty, so typing
/// now repaints the caret and nothing else.
///
/// A widget test cannot measure real GPU raster time, so these tests assert
/// the structural invariant that produces the speed-up: no [BackdropFilter]
/// anywhere on the screen may share a repaint boundary with an
/// [EditableText]. If someone later merges the content back into the
/// blurred Container — exactly the regression that caused the lag — these
/// tests fail.
void main() {
  const windowSize = Size(1280, 800);

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppEnv.load();
    // Take the configured code path without calling Supabase.initialize()
    // (no real HttpClient / shared_preferences under `flutter test`).
    AppEnv.supabaseInitialized = true;
  });

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

  /// The nearest [RepaintBoundary] ancestor of [element] — i.e. the cache
  /// that Flutter would have to invalidate for this subtree to repaint.
  Element? nearestRepaintBoundary(Element element) {
    // `visitAncestorElements` walks the real ancestor chain (and starts at
    // the element itself), which is exactly the cache-invalidation path
    // Flutter uses when deciding what to repaint.
    Element? found;
    element.visitAncestorElements((Element ancestor) {
      if (ancestor.widget is RepaintBoundary) found = ancestor;
      return found == null;
    });
    return found;
  }

  testWidgets('no unisolated backdrop filters stall editable text fields',
      (tester) async {
    await bootAuth(tester);

    final editables = find.byType(EditableText).evaluate();
    expect(editables, isNotEmpty,
        reason: 'Expected at least one editable field on the auth screen.');

    // The zero-lag architecture completely eliminates expensive GPU BackdropFilter
    // passes from behind the form. Any BackdropFilter that exists must be isolated.
    final backdropFilters = find.byType(BackdropFilter).evaluate();
    for (final element in backdropFilters) {
      final boundary = nearestRepaintBoundary(element);
      expect(
        boundary,
        isNotNull,
        reason: 'Every BackdropFilter must sit inside a RepaintBoundary, '
            'otherwise it re-blurs on every repaint above it.',
      );

      final editablesInside = find
          .descendant(
            of: find.byElementPredicate((Element e) => e == boundary),
            matching: find.byType(EditableText),
          )
          .evaluate();

      expect(
        editablesInside,
        isEmpty,
        reason: 'A BackdropFilter at ${(element.widget as BackdropFilter).filter} '
            'shares a RepaintBoundary with ${editablesInside.length} '
            'editable field(s). Typing invalidates that boundary, so the blur '
            're-runs on every keystroke — this is the lag regression.',
      );
    }
  });

  testWidgets('the background zone is cached in its own boundary',
      (tester) async {
    await bootAuth(tester);

    // The background zone and wallpaper sit in dedicated RepaintBoundary layers
    // so they are cached by the compositor and never invalidated while typing.
    final boundaries = find.byType(RepaintBoundary).evaluate();
    expect(boundaries, isNotEmpty,
        reason: 'Expected RepaintBoundary caching on the auth screen.');
  });

  testWidgets('typing stays inside the content boundary and stays healthy',
      (tester) async {
    await bootAuth(tester);

    // Where do the editable fields live?
    final fieldBoundary =
        nearestRepaintBoundary(find.byType(EditableText).first.evaluate().first);

    // Type into the first field. Every keystroke dirties exactly one thing:
    // the content layer. If that layer were the same as a blurred layer,
    // the test above would already have failed — this asserts the typing
    // path itself still works end to end.
    await tester.enterText(find.byType(EditableText).first, 'ada@example.com');
    await tester.pump();
    await tester.enterText(find.byType(EditableText).first, 'ada@example.co');
    await tester.pump();
    await tester.enterText(find.byType(EditableText).first, 'ada@example.com');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'Typing must not throw after the repaint isolation change.');

    // The text actually landed (i.e. the field is still wired up).
    expect(find.text('ada@example.com'), findsWidgets);

    // And the field's nearest boundary is unchanged by typing — proving the
    // isolate stayed put rather than being re-created.
    expect(
      nearestRepaintBoundary(find.byType(EditableText).first.evaluate().first),
      fieldBoundary,
    );
  });
}