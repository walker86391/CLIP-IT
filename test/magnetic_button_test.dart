import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/features/auth/auth_theme.dart';
import 'package:clipit/features/auth/widgets/auth_button.dart';
import 'package:clipit/features/auth/widgets/magnetic_field.dart';
import 'package:clipit/ui/tokens/motion.dart';

/// Behavior tests for the magnetic Continue button.
///
/// The user asked for a "magnetic button effect": the button leans toward
/// the cursor when it gets close, and springs back when the cursor leaves.
/// Compiling is not proof of behavior — these tests drive a REAL mouse
/// pointer through the widget tree and read the resulting translate, so
/// the effect itself is verified, not just that the code builds.
///
/// Lives in its own file: it uses the real AuthButton with a synthetic
/// pointer, and does not need (or touch) Supabase wiring at all.
void main() {
  const Size windowSize = Size(800, 600);
  const Size buttonSize = Size(200, 40);

  /// Button rect for the harness below: centered in the window.
  Rect buttonRect() => Rect.fromCenter(
        center: Offset(windowSize.width / 2, windowSize.height / 2),
        width: buttonSize.width,
        height: buttonSize.height,
      );

  /// The magnetic translate currently applied to the button. The pull is a
  /// paint-time Transform.translate inside AuthButton, so the visual offset
  /// the user actually sees is exactly this value.
  Offset currentOffset(WidgetTester tester) {
    final Finder transforms = find.descendant(
      of: find.byType(AuthButton),
      matching: find.byType(Transform),
    );
    // There must be exactly one: the button chrome contains no other
    // Transform, so a second one would mean this finder is reading the
    // wrong thing.
    expect(transforms, findsOneWidget);
    // Matrix4.getTranslation() hands back a Vector3 (a vector_math type we do
    // not want to import just for a name), so let the type be inferred and
    // project the two components we care about into an Offset.
    final translation =
        tester.widget<Transform>(transforms).transform.getTranslation();
    return Offset(translation.x, translation.y);
  }

  /// Boots one AuthButton inside a MagneticFieldScope, exactly as the auth
  /// screen composes them.
  Future<void> pumpButton(
    WidgetTester tester, {
    bool reduceMotion = false,
    VoidCallback? onPressed,
  }) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Widget button = Center(
      child: SizedBox(
        width: buttonSize.width,
        height: buttonSize.height,
        child: AuthButton(
          label: 'Continue',
          onPressed: onPressed ?? () {},
        ),
      ),
    );
    if (reduceMotion) {
      button = ReduceMotion(enabled: true, child: button);
    }

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MagneticFieldScope(
          child: Scaffold(backgroundColor: const Color(0xFF14161B), body: button),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Creates a mouse pointer and moves it to [target], letting the chase
  /// animation finish. Mouse gestures are required here: a touch pointer
  /// produces no hover events, so MouseRegion.onHover would never fire.
  Future<void> hoverAt(
    WidgetTester tester,
    Offset target, {
    required TestGesture mouse,
  }) async {
    await mouse.moveTo(target);
    await tester.pump();
    // Long enough for the chase animation (140ms) to finish.
    await tester.pump(const Duration(milliseconds: 250));
  }

  Future<TestGesture> createMouse(WidgetTester tester) async {
    final TestGesture mouse =
        await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(4, 4));
    addTearDown(mouse.removePointer);
    await tester.pump();
    return mouse;
  }

  testWidgets('magnetic button: leans toward a nearby cursor', (tester) async {
    await pumpButton(tester);
    final TestGesture mouse = await createMouse(tester);

    // Sanity: at rest the button sits exactly on its layout slot.
    expect(currentOffset(tester), Offset.zero);

    // Park the cursor 20px ABOVE the button's top edge — outside the button,
    // but well inside the magnetic reach (64px). This is the anticipation
    // zone: the pull must engage before the cursor touches the button.
    final Offset target =
        Offset(buttonRect().center.dx, buttonRect().top - 20);
    await hoverAt(tester, target, mouse: mouse);

    final Offset offset = currentOffset(tester);

    // It must move TOWARD the cursor: the cursor is above, so dy < 0.
    expect(
      offset.dy,
      lessThan(0),
      reason: 'The button should lean up toward a cursor above it, '
          'but the translate was $offset.',
    );
    // ...and sideways it must stay put (the cursor is horizontally centered).
    expect(offset.dx.abs(), lessThan(0.01));

    // ...by a real, but bounded amount: never more than the cap.
    expect(
      offset.dy.abs(),
      greaterThan(1.0),
      reason: 'The pull was too small to read as magnetic: $offset',
    );

    // The pull is deliberately NOT asserted against an exact pixel value:
    // it is the product of cursor distance, the pull fraction and the
    // proximity ease, all of which changed when the user asked for a
    // gentler effect. What must hold is that it is a real, visible lean
    // that stays inside the cap.
    expect(
      offset.distance,
      lessThanOrEqualTo(AuthColors.magneticMaxOffset + 0.01),
      reason: 'The button slid further than magneticMaxOffset allows.',
    );
    expect(
      offset.distance,
      greaterThan(1.0),
      reason: 'The pull became too small to read as magnetic: $offset',
    );
  });

  testWidgets('magnetic button: springs back when the cursor leaves',
      (tester) async {
    await pumpButton(tester);
    final TestGesture mouse = await createMouse(tester);

    await hoverAt(
      tester,
      Offset(buttonRect().center.dx, buttonRect().top - 20),
      mouse: mouse,
    );
    expect(currentOffset(tester).dy, lessThan(0));

    // Move the cursor far away — past the reach band. The button must ease
    // all the way back to its slot (the easeOutBack return may overshoot
    // mid-flight, so settle completely before asserting).
    await mouse.moveTo(const Offset(40, 40));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      currentOffset(tester),
      Offset.zero,
      reason: 'The button must return to its layout slot when the cursor '
          'leaves the magnetic field.',
    );
  });

  testWidgets('magnetic button: pulls from every side', (tester) async {
    await pumpButton(tester);
    final TestGesture mouse = await createMouse(tester);

    // Bottom edge: the cursor is below → the button leans DOWN.
    await hoverAt(
      tester,
      Offset(buttonRect().center.dx, buttonRect().bottom + 20),
      mouse: mouse,
    );
    expect(currentOffset(tester).dy, greaterThan(0));

    // Right edge: the cursor is to the right → the button leans RIGHT.
    await hoverAt(
      tester,
      Offset(buttonRect().right + 20, buttonRect().center.dy),
      mouse: mouse,
    );
    final Offset right = currentOffset(tester);
    expect(right.dx, greaterThan(0));
    expect(right.dy.abs(), lessThan(0.01));

    // Top edge: back up again → leans UP.
    await hoverAt(
      tester,
      Offset(buttonRect().center.dx, buttonRect().top - 20),
      mouse: mouse,
    );
    expect(currentOffset(tester).dy, lessThan(0));
  });

  testWidgets('magnetic button: reduce-motion disables the pull',
      (tester) async {
    await pumpButton(tester, reduceMotion: true);
    final TestGesture mouse = await createMouse(tester);

    await hoverAt(
      tester,
      Offset(buttonRect().center.dx, buttonRect().top - 20),
      mouse: mouse,
    );

    expect(
      currentOffset(tester),
      Offset.zero,
      reason: 'Users who asked for reduced motion must not get movement.',
    );
  });

  testWidgets('magnetic button: still activates on tap', (tester) async {
    // Regression guard: the pull is a paint-time Transform inside a Stack,
    // so make sure the wrapping did not break hit testing / activation.
    int presses = 0;
    await pumpButton(tester, onPressed: () => presses++);
    final TestGesture mouse = await createMouse(tester);

    await hoverAt(tester, buttonRect().center, mouse: mouse);
    await tester.tap(find.byType(AuthButton));
    await tester.pumpAndSettle();

    expect(presses, 1, reason: 'The magnetic wrapper must not swallow taps.');
  });

  testWidgets('magnetic button: a disabled button does not pull',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MagneticFieldScope(
          child: Scaffold(
            backgroundColor: const Color(0xFF14161B),
            body: Center(
              child: SizedBox(
                width: buttonSize.width,
                height: buttonSize.height,
                // onPressed: null → the button is disabled.
                child: const AuthButton(label: 'Continue', onPressed: null),
              ),
            ),
          ),
        ),
      ),
    );
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();

    final TestGesture mouse = await createMouse(tester);
    await hoverAt(
      tester,
      Offset(buttonRect().center.dx, buttonRect().top - 20),
      mouse: mouse,
    );

    expect(
      currentOffset(tester),
      Offset.zero,
      reason: 'A disabled button must not move toward the cursor.',
    );
  });
}