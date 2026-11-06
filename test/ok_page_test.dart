import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:clipit/app/routes.dart';
import 'package:clipit/features/auth/pages/ok_page.dart';

void main() {
  const windowSize = Size(1280, 800);

  testWidgets('OkPage renders title and both action buttons', (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    String? currentRoute;

    final router = GoRouter(
      initialLocation: Routes.ok,
      routes: [
        GoRoute(
          path: Routes.ok,
          builder: (context, state) => const OkPage(),
        ),
        GoRoute(
          path: Routes.home,
          builder: (context, state) {
            currentRoute = Routes.home;
            return const Scaffold(body: Text('Home Dashboard'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('How would you like to continue?'), findsOneWidget);

    // Verify both action buttons
    expect(find.text('Continue to app'), findsOneWidget);
    expect(find.text('Watch tutorial'), findsOneWidget);

    // Tap "Watch tutorial" → does nothing, no route change
    await tester.tap(find.text('Watch tutorial'));
    await tester.pumpAndSettle();
    expect(currentRoute, isNull);

    // Tap "Continue to app" → navigates to Routes.home
    await tester.tap(find.text('Continue to app'));
    await tester.pumpAndSettle();
    expect(currentRoute, equals(Routes.home));
    expect(find.text('Home Dashboard'), findsOneWidget);
  });
}
