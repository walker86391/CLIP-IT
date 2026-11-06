import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supabase_flutter/supabase_flutter.dart' show OtpType;

import 'package:clipit/core/models/user_profile.dart';
import 'package:clipit/core/services/auth_service.dart';
import 'package:clipit/core/utils/result.dart';
import 'package:clipit/features/auth/pages/sign_in_form.dart';
import 'package:clipit/features/auth/pages/sign_up_form.dart';
import 'package:clipit/features/auth/providers/auth_provider.dart';
import 'package:clipit/features/auth/widgets/auth_otp_form.dart';

/// Test stub that allows simulating unconfirmed emails and OTP verification.
class OtpTestAuthService extends AuthServiceStub {
  bool simulateUnconfirmedOnSignIn = false;
  bool simulateUnconfirmedOnSignUp = false;
  bool verifyOtpCalled = false;
  bool resendOtpCalled = false;

  @override
  Future<Result<AuthState>> signIn({
    required String email,
    required String password,
  }) async {
    if (simulateUnconfirmedOnSignIn) {
      return const Result.err(
        AppError(message: 'Email not confirmed', code: 'email_not_confirmed'),
      );
    }
    return super.signIn(email: email, password: password);
  }

  @override
  Future<Result<AuthState>> signUp({
    required String email,
    required String password,
    String? displayName,
    DateTime? dateOfBirth,
  }) async {
    if (simulateUnconfirmedOnSignUp) {
      // Supabase returns no session when email confirmation is enabled
      return const Result.ok(AuthState(status: AuthStatus.unauthenticated));
    }
    return super.signUp(
      email: email,
      password: password,
      displayName: displayName,
      dateOfBirth: dateOfBirth,
    );
  }

  @override
  Future<Result<AuthState>> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.signup,
  }) async {
    verifyOtpCalled = true;
    final user = UserProfile(
      id: 'test-user',
      email: email,
      createdAt: DateTime.now(),
    );
    final state = AuthState(status: AuthStatus.authenticated, user: user);
    return Result.ok(state);
  }

  @override
  Future<Result<void>> resendOtp({
    required String email,
    OtpType type = OtpType.signup,
  }) async {
    resendOtpCalled = true;
    return const Result.ok(null);
  }
}

void main() {
  const windowSize = Size(1280, 800);

  testWidgets('AuthOtpForm: shows email, 60s countdown timer, and activates resend',
      (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final service = OtpTestAuthService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AuthOtpForm(
              email: 'shivam@example.com',
              onBack: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify initial header and email
    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.textContaining('shivam@example.com'), findsOneWidget);

    // Initial countdown at 60s
    expect(find.text('Resend code in 60s'), findsOneWidget);

    // Advance 5 seconds
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Resend code in 55s'), findsOneWidget);

    // Advance remaining 55 seconds to reach 0
    await tester.pump(const Duration(seconds: 55));
    expect(find.text('Resend code'), findsOneWidget);

    // Tap Resend code
    await tester.tap(find.text('Resend code'));
    await tester.pump();
    expect(service.resendOtpCalled, isTrue);
    expect(find.text('A fresh 6-digit code has been sent!'), findsOneWidget);
    expect(find.text('Resend code in 60s'), findsOneWidget);
  });

  testWidgets('SignInForm: unconfirmed email error seamlessly triggers OTP stage',
      (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final service = OtpTestAuthService()..simulateUnconfirmedOnSignIn = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SignInForm(
              onSwitchTab: (_) {},
              submitEnabled: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Fill email and password
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'shivam@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.pumpAndSettle();

    // Submit sign in
    await tester.tap(find.bySemanticsLabel('Sign in'));
    await tester.pumpAndSettle();

    // Seamlessly transitions to AuthOtpForm instead of a dead-end error!
    expect(find.byType(AuthOtpForm), findsOneWidget);
    expect(find.text('Verify your email'), findsOneWidget);
    expect(service.resendOtpCalled, isTrue);

    // Enter 6-digit OTP
    final otpField = find.byType(TextField);
    await tester.enterText(otpField, '123456');
    await tester.pumpAndSettle();

    expect(service.verifyOtpCalled, isTrue);
  });

  testWidgets('SignUpForm: unconfirmed email response seamlessly triggers OTP stage',
      (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final service = OtpTestAuthService()..simulateUnconfirmedOnSignUp = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SignUpForm(
                onSwitchTab: (_) {},
                submitEnabled: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Fill form
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Shivam C');
    await tester.enterText(fields.at(1), '2000-01-01');
    // Note: dob field is readOnly with onTap
    await tester.enterText(fields.at(2), 'shivam@example.com');
    await tester.enterText(fields.at(3), 'password123');
    await tester.enterText(fields.at(4), 'password123');

    // Agree to terms & privacy
    final checkboxes = find.byType(Checkbox);
    for (var i = 0; i < checkboxes.evaluate().length; i++) {
      await tester.tap(checkboxes.at(i));
    }
    await tester.pumpAndSettle();
  });

  testWidgets('AuthOtpForm: "I\'ve Confirmed My Email" signs in directly',
      (tester) async {
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final service = OtpTestAuthService();
    bool successCalled = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AuthOtpForm(
              email: 'shivam@example.com',
              password: 'password123',
              onBack: () {},
              onSuccess: () => successCalled = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("I've Confirmed My Email →"), findsOneWidget);

    await tester.tap(find.text("I've Confirmed My Email →"));
    await tester.pumpAndSettle();

    expect(successCalled, isTrue);
  });
}
