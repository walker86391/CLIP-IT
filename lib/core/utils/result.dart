/// Lightweight Result type for service/repo calls.
///
/// Services return Result instead of throwing so UI code can branch on
/// success/failure without try/catch noise.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(AppError error) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  AppError? get errorOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final error) => error,
      };

  R fold<R>(R Function(T value) onOk, R Function(AppError error) onErr) =>
      switch (this) {
        Ok<T>(:final value) => onOk(value),
        Err<T>(:final error) => onErr(error),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  const Err(this.error);
  final AppError error;

  @override
  String toString() => 'Err($error)';
}

/// A user-facing, categorized error.
class AppError {
  const AppError({required this.message, this.code, this.cause});

  /// Human-readable message, safe to show in UI.
  final String message;

  /// Machine-readable code for logging/branching (optional).
  final String? code;

  /// Original thrown object, if any (for logging only).
  final Object? cause;

  @override
  String toString() =>
      'AppError(${code ?? 'unknown'}): $message${cause != null ? ' ← $cause' : ''}';
}
