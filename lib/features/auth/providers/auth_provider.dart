import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OtpType;

import '../../../core/config/app_env.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/result.dart';

/// Whether the real Supabase backend is live. Drives the "Supabase not
/// configured" banner on the auth screen and keeps submit buttons disabled
/// when false.
final supabaseConfiguredProvider = Provider<bool>(
  (ref) => AppEnv.supabaseInitialized,
);

/// Service selection: real Supabase auth when initialized at startup,
/// in-memory stub otherwise (local-only mode).
final authServiceProvider = Provider<AuthService>((ref) {
  final AuthService service = AppEnv.supabaseInitialized
      ? SupabaseAuthService()
      : AuthServiceStub();
  if (service is AuthServiceStub) {
    ref.onDispose(service.dispose);
  } else if (service is SupabaseAuthService) {
    ref.onDispose(service.dispose);
  }
  return service;
});

/// Auth state + actions. Notifies router (via refreshListenable) when the
/// status flips, driving the auth guard.
final class AuthController extends Notifier<AuthState> {
  Completer<AuthState>? _ready;
  StreamSubscription<AuthState>? _sub;
  bool _initStarted = false;

  @override
  AuthState build() {
    final service = ref.watch(authServiceProvider);

    _ready = Completer<AuthState>();
    _initStarted = false;

    _sub?.cancel();
    _sub = service.onAuthStateChanged().listen((state) {
      this.state = state;
      if (!(_ready?.isCompleted ?? true) &&
          state.status != AuthStatus.unknown) {
        _ready!.complete(state);
      }
    });
    ref.onDispose(() => _sub?.cancel());

    return service.currentState;
  }

  /// Resolves when init has finished (status != unknown).
  Future<AuthState> get ready {
    if (!_initStarted) {
      _initStarted = true;
      unawaited(_init());
    }
    return _ready!.future;
  }

  Future<void> _init() async {
    final result = await ref.read(authServiceProvider).init();
    result.fold(
      (state) {
        this.state = state;
        if (!(_ready?.isCompleted ?? true)) _ready!.complete(state);
      },
      (error) {
        AppLog.e('Auth init failed: ${error.message}');
        if (!(_ready?.isCompleted ?? true)) {
          _ready!.complete(
            const AuthState(status: AuthStatus.unauthenticated),
          );
        }
      },
    );
  }

  Future<Result<AuthState>> signIn({
    required String email,
    required String password,
  }) async {
    final result = await ref.read(authServiceProvider).signIn(
          email: email,
          password: password,
        );
    AppLog.i('signIn → ${result.isOk ? result.valueOrNull?.status.name : result.errorOrNull}');
    return result;
  }

  Future<Result<AuthState>> signUp({
    required String email,
    required String password,
    String? displayName,
    DateTime? dateOfBirth,
  }) async {
    final result = await ref.read(authServiceProvider).signUp(
          email: email,
          password: password,
          displayName: displayName,
          dateOfBirth: dateOfBirth,
        );
    AppLog.i(
      'signUp → ${result.isOk ? result.valueOrNull?.status.name : result.errorOrNull}',
    );
    return result;
  }

  /// Best-effort profile update (public.profiles). Non-blocking for the
  /// caller: failures are logged and returned, never thrown.
  Future<Result<void>> updateProfile({
    String? displayName,
    DateTime? dateOfBirth,
  }) {
    return ref.read(authServiceProvider).updateProfile(
          displayName: displayName,
          dateOfBirth: dateOfBirth,
        );
  }

  Future<Result<AuthState>> signInWithSecretCode(String code) async {
    final result =
        await ref.read(authServiceProvider).signInWithSecretCode(code);
    AppLog.i(
      'signInWithSecretCode → '
      '${result.isOk ? result.valueOrNull?.status.name : result.errorOrNull}',
    );
    return result;
  }

  Future<Result<AuthState>> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.signup,
  }) async {
    final result = await ref.read(authServiceProvider).verifyOtp(
          email: email,
          token: token,
          type: type,
        );
    AppLog.i(
      'verifyOtp → ${result.isOk ? result.valueOrNull?.status.name : result.errorOrNull}',
    );
    return result;
  }

  Future<Result<void>> resendOtp({
    required String email,
    OtpType type = OtpType.signup,
  }) async {
    final result = await ref.read(authServiceProvider).resendOtp(
          email: email,
          type: type,
        );
    AppLog.i(
      'resendOtp → ${result.isOk ? "ok" : result.errorOrNull}',
    );
    return result;
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    AppLog.i('signOut → ok');
  }
}

/// Auth state provider for widgets/guards.
final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Completes once auth init has finished; the loading route waits on this
/// before transitioning.
final authReadyProvider = FutureProvider<AuthState>((ref) async {
  final controller = ref.watch(authProvider.notifier);
  return controller.ready;
});

/// Listenable adapter for GoRouter refresh on auth changes.
final class AuthChangeNotifier implements Listenable {
  AuthChangeNotifier(this._ref) {
    _sub = _ref.listen(authProvider, (_, _) => _notify());
  }

  final Ref _ref;
  final List<VoidCallback> _listeners = [];
  ProviderSubscription<AuthState>? _sub;

  void _notify() {
    for (final l in List.of(_listeners)) {
      l();
    }
  }

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void dispose() => _sub?.close();
}
