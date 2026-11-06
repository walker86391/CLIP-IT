import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' show OtpType;

import '../models/user_profile.dart';
import '../utils/result.dart';

/// Auth state exposed by any AuthService implementation.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Auth state snapshot.
class AuthState {
  const AuthState({required this.status, this.user});

  final AuthStatus status;
  final UserProfile? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  static const initial = AuthState(status: AuthStatus.unknown);
}

/// Auth boundary.
///
/// Step 0: [AuthServiceStub] keeps state in memory. Later this is backed by
/// Supabase auth (gotrue). UI and providers only see this interface.
abstract class AuthService {
  AuthState get currentState;

  Stream<AuthState> onAuthStateChanged();

  Future<Result<AuthState>> init();

  Future<Result<AuthState>> signIn({
    required String email,
    required String password,
  });

  /// [displayName] and [dateOfBirth] are stored with the account
  /// (Supabase: user metadata + public.profiles row).
  Future<Result<AuthState>> signUp({
    required String email,
    required String password,
    String? displayName,
    DateTime? dateOfBirth,
  });

  /// Alternate sign-in via secret admin code (auth tab 3).
  ///
  /// Calls `verify_secret_admin_code` in Supabase.
  /// If expired, returns error with message 'Code expired. Sign up / login now'.
  Future<Result<AuthState>> signInWithSecretCode(String code);

  Future<Result<void>> signOut();

  /// Verifies an OTP code sent to [email].
  ///
  /// Used for email confirmation upon sign-up or unverified sign-in.
  Future<Result<AuthState>> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.signup,
  });

  /// Resends an OTP verification code to [email].
  Future<Result<void>> resendOtp({
    required String email,
    OtpType type = OtpType.signup,
  });

  /// Best-effort profile update for the signed-in user
  /// (Supabase: public.profiles display_name / date_of_birth).
  Future<Result<void>> updateProfile({
    String? displayName,
    DateTime? dateOfBirth,
  });
}

/// In-memory stub so the auth gate and routing can be exercised without a
/// backend. TODO(user): wire Supabase client when backend is ready.
class AuthServiceStub implements AuthService {
  final StreamController<AuthState> _controller =
      StreamController<AuthState>.broadcast();

  AuthState _state = AuthState.initial;

  @override
  AuthState get currentState => _state;

  @override
  Stream<AuthState> onAuthStateChanged() => _controller.stream;

  void _set(AuthState state) {
    _state = state;
    if (!_controller.isClosed) _controller.add(state);
  }

  @override
  Future<Result<AuthState>> init() async {
    // No persistence in the stub: always starts unauthenticated.
    _set(const AuthState(status: AuthStatus.unauthenticated));
    return Result.ok(_state);
  }

  @override
  Future<Result<AuthState>> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final user = UserProfile(
      id: 'stub-${email.hashCode.abs()}',
      email: email,
      displayName: email.split('@').first,
      createdAt: DateTime.now(),
    );
    _set(AuthState(status: AuthStatus.authenticated, user: user));
    return Result.ok(_state);
  }

  @override
  Future<Result<AuthState>> signUp({
    required String email,
    required String password,
    String? displayName,
    DateTime? dateOfBirth,
  }) async {
    // Stub ignores profile fields; they exist only for the real backend.
    // TODO(user): keep stub metadata in memory if forms ever need it.
    return signIn(email: email, password: password);
  }

  @override
  Future<Result<AuthState>> signInWithSecretCode(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) {
      return const Result.err(
        AppError(message: 'Please enter a secret code', code: 'empty'),
      );
    }
    if (trimmed == 'EXPIRED' || trimmed == 'EXPIRED-TEST') {
      return const Result.err(
        AppError(
          message: 'Code expired. Sign up / login now',
          code: 'expired',
        ),
      );
    }
    if (trimmed == 'INVALID') {
      return const Result.err(
        AppError(message: 'Invalid secret code', code: 'invalid'),
      );
    }
    final user = UserProfile(
      id: 'stub-admin',
      email: 'walker86391@gmail.com',
      displayName: 'Admin',
      createdAt: DateTime.now(),
    );
    final next = AuthState(status: AuthStatus.authenticated, user: user);
    _set(next);
    return Result.ok(next);
  }

  @override
  Future<Result<void>> signOut() async {
    _set(const AuthState(status: AuthStatus.unauthenticated));
    return const Result.ok(null);
  }

  @override
  Future<Result<AuthState>> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.signup,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final trimmed = token.trim();
    if (trimmed.length != 6) {
      return const Result.err(
        AppError(message: 'Invalid code. Please enter 6 digits.', code: 'invalid_otp'),
      );
    }
    final user = UserProfile(
      id: 'stub-${email.hashCode.abs()}',
      email: email,
      displayName: email.split('@').first,
      createdAt: DateTime.now(),
    );
    final next = AuthState(status: AuthStatus.authenticated, user: user);
    _set(next);
    return Result.ok(next);
  }

  @override
  Future<Result<void>> resendOtp({
    required String email,
    OtpType type = OtpType.signup,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> updateProfile({
    String? displayName,
    DateTime? dateOfBirth,
  }) async {
    // No persistence in the stub.
    // TODO(user): mirror into the users table when a local store is needed.
    return const Result.ok(null);
  }

  void dispose() => _controller.close();
}
