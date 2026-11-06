import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../models/user_profile.dart';
import '../utils/app_logger.dart';
import '../utils/result.dart';
import 'auth_service.dart';

/// Real Supabase-backed auth.
///
/// - init(): restores any existing session and subscribes to
///   onAuthStateChange so the app stays in sync with the backend.
/// - signUp(): supabase.auth.signUp; if email confirmation is enabled the
///   response has no session and the UI shows the "check your email" note.
/// - signIn(): supabase.auth.signInWithPassword.
/// - updateProfile(): writes display_name / date_of_birth into
///   public.profiles (see the SQL the user must run once in Supabase).
///
/// NOTE: Supabase also exports a class named `AuthState` (their session
/// event wrapper). We hide it here — this app's `AuthState` from
/// auth_service.dart is the one in use.
final class SupabaseAuthService implements AuthService {
  final StreamController<AuthState> _controller =
      StreamController<AuthState>.broadcast();

  StreamSubscription<dynamic>? _supabaseSub;
  bool _listenerStarted = false;
  AuthState _state = AuthState.initial;

  GoTrueClient get _auth => Supabase.instance.client.auth;

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Starts the onAuthStateChange subscription (once). Maps Supabase
  /// session events onto our [AuthState] stream.
  void _ensureListener() {
    if (_listenerStarted) return;
    _listenerStarted = true;

    _supabaseSub = _auth.onAuthStateChange.listen(
      (event) {
        // `event` is supabase's AuthState (event + session) — kept dynamic
        // because we hid that class name in the import.
        final session = event.session;
        _apply(_mapSession(session));
      },
      onError: (Object e) {
        AppLog.e('Supabase auth stream error', e);
      },
    );
  }

  AuthState _mapSession(Session? session) {
    if (session == null) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }
    final user = session.user;
    final meta = user.userMetadata;
    final profile = UserProfile(
      id: user.id,
      email: user.email ?? '',
      displayName: meta == null ? null : meta['display_name'] as String?,
      // Supabase gives created_at as an ISO string.
      createdAt:
          DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
    return AuthState(status: AuthStatus.authenticated, user: profile);
  }

  void _apply(AuthState next) {
    _state = next;
    if (!_controller.isClosed) _controller.add(next);
  }

  static AppError _error(Object e) {
    if (e is AuthException) {
      return AppError(
        message: e.message,
        code: e.statusCode,
        cause: e,
      );
    }
    return AppError(message: 'Authentication failed', cause: e);
  }

  /// Supabase's way of saying "the row insert into auth.users was rejected".
  ///
  /// GoTrue collapses every reason that insert can fail into one generic
  /// sentence, which reaches the user as a dead end:
  ///
  ///     Database error saving new user
  ///
  /// In practice it is almost always the `handle_new_user` trigger on
  /// auth.users throwing while it writes to public.profiles — most often
  /// because `profiles.date_of_birth` is NOT NULL but the trigger fires
  /// before the app has a session to supply a date.
  ///
  /// We cannot make the server more specific, so we do the next best thing:
  /// log the raw exception (status code included) and give the UI one
  /// sentence that names the place to look. `supabase/001_profiles.sql`
  /// contains the idempotent fix.
  static AppError _signUpError(Object e) {
    final AppError base = _error(e);
    if (base.message.toLowerCase().contains('database error')) {
      return AppError(
        message: 'The database rejected the save, so the account was not '
            'created. This is a server-side setup issue, not your details — '
            'run supabase/001_profiles.sql once in the Supabase SQL editor.',
        code: base.code,
        cause: e,
      );
    }
    return base;
  }

  // ── AuthService ─────────────────────────────────────────────────────────

  @override
  AuthState get currentState => _state;

  @override
  Stream<AuthState> onAuthStateChanged() => _controller.stream;

  @override
  Future<Result<AuthState>> init() async {
    try {
      _ensureListener();

      final session = _auth.currentSession;
      final restored = _mapSession(session);
      _apply(restored);

      if (restored.isAuthenticated) {
        AppLog.i('Supabase session restored for ${restored.user?.email}');
      }
      return Result.ok(restored);
    } catch (e, s) {
      AppLog.e('Supabase auth init failed', e, s);
      return Result.err(_error(e));
    }
  }

  @override
  Future<Result<AuthState>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );

      final next = _mapSession(response.session);
      _apply(next);
      AppLog.i('Supabase signIn → ${next.status.name}');
      return Result.ok(next);
    } catch (e) {
      AppLog.w('Supabase signIn failed: $e');
      return Result.err(_error(e));
    }
  }

  @override
  Future<Result<AuthState>> signUp({
    required String email,
    required String password,
    String? displayName,
    DateTime? dateOfBirth,
  }) async {
    try {
      // display_name rides along in user metadata; the profiles row update
      // (incl. date_of_birth) happens via updateProfile once a session is
      // active.
      final data = <String, dynamic>{
        if (displayName != null && displayName.isNotEmpty)
          'display_name': displayName,
      };

      final response = await _auth.signUp(
        email: email,
        password: password,
        data: data,
      );

      final next = _mapSession(response.session);
      _apply(next);

      if (next.isAuthenticated) {
        AppLog.i('Supabase signUp → session active');
      } else {
        // Email confirmation enabled: no session yet.
        AppLog.i('Supabase signUp → awaiting email confirmation');
      }
      return Result.ok(next);
    } catch (e) {
      // Status code is logged alongside the message so a 500 from the
      // trigger is distinguishable from a 422 (password too short) etc.
      AppLog.w('Supabase signUp failed: $e');
      return Result.err(_signUpError(e));
    }
  }

  @override
  Future<Result<AuthState>> signInWithSecretCode(String code) async {
    try {
      final cleanCode = code.trim();
      if (cleanCode.isEmpty) {
        return const Result.err(
          AppError(message: 'Please enter a secret code', code: 'empty'),
        );
      }

      final response = await Supabase.instance.client.rpc(
        'verify_secret_admin_code',
        params: {'input_code': cleanCode},
      );

      final Map<String, dynamic> data = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};

      final bool success = data['success'] == true;
      final String status = (data['status'] as String?) ?? '';
      final String message =
          (data['message'] as String?) ?? 'Verification failed';

      if (!success) {
        return Result.err(AppError(message: message, code: status));
      }

      final adminEmail =
          (data['email'] as String?) ?? 'walker86391@gmail.com';
      final role = (data['role'] as String?) ?? 'admin';
      final user = UserProfile(
        id: 'admin-${DateTime.now().millisecondsSinceEpoch}',
        email: adminEmail,
        displayName: 'Admin ($role)',
        createdAt: DateTime.now(),
      );

      final next = AuthState(status: AuthStatus.authenticated, user: user);
      _apply(next);
      AppLog.i('Supabase secret admin code verified: $adminEmail');
      return Result.ok(next);
    } catch (e, s) {
      AppLog.e('Supabase signInWithSecretCode failed', e, s);
      return Result.err(_error(e));
    }
  }

  @override
  Future<Result<AuthState>> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.signup,
  }) async {
    try {
      final response = await _auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: type,
      );

      final next = _mapSession(response.session);
      _apply(next);
      AppLog.i('Supabase verifyOtp → ${next.status.name}');
      return Result.ok(next);
    } catch (e) {
      // If signup type failed, try email type as a fallback (for existing users verifying on sign-in)
      if (type == OtpType.signup) {
        try {
          final fallbackResponse = await _auth.verifyOTP(
            email: email.trim(),
            token: token.trim(),
            type: OtpType.email,
          );
          final next = _mapSession(fallbackResponse.session);
          _apply(next);
          AppLog.i('Supabase verifyOtp (fallback) → ${next.status.name}');
          return Result.ok(next);
        } catch (_) {}
      }
      AppLog.w('Supabase verifyOtp failed: $e');
      return Result.err(_error(e));
    }
  }

  @override
  Future<Result<void>> resendOtp({
    required String email,
    OtpType type = OtpType.signup,
  }) async {
    try {
      await _auth.resend(
        email: email.trim(),
        type: type,
      );
      AppLog.i('Supabase resendOtp → ok');
      return const Result.ok(null);
    } catch (e) {
      AppLog.w('Supabase resendOtp failed: $e');
      return Result.err(_error(e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      _apply(const AuthState(status: AuthStatus.unauthenticated));
      return const Result.ok(null);
    } catch (e) {
      return Result.err(_error(e));
    }
  }

  @override
  Future<Result<void>> updateProfile({
    String? displayName,
    DateTime? dateOfBirth,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const Result.err(
          AppError(message: 'Not signed in', code: 'no-session'),
        );
      }

      // Build the update payload explicitly (readable over collection-if).
      final updates = <String, dynamic>{};
      if (displayName != null) {
        updates['display_name'] = displayName;
      }
      if (dateOfBirth != null) {
        // DATE column format: YYYY-MM-DD.
        updates['date_of_birth'] =
            dateOfBirth.toIso8601String().split('T').first;
      }

      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', user.id);

      AppLog.i('Supabase profile updated (${updates.keys.join(', ')})');
      return const Result.ok(null);
    } catch (e, s) {
      // Non-fatal: caller continues to /ok even if this fails (e.g. the
      // profiles SQL has not been run yet).
      AppLog.e('Supabase profile update failed', e, s);
      return Result.err(_error(e));
    }
  }

  void dispose() {
    _supabaseSub?.cancel();
    _controller.close();
  }
}
