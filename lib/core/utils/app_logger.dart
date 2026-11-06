import 'package:logger/logger.dart';

/// App-wide logger instance.
///
/// Usage: `AppLog.i('message')`, `AppLog.e('oops', error, stack)`.
final class AppLog {
  AppLog._();

  static final Logger _log = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 6,
      lineLength: 100,
      colors: true,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void d(dynamic message) => _log.d(message);
  static void i(dynamic message) => _log.i(message);
  static void w(dynamic message) => _log.w(message);
  static void e(dynamic message, [Object? error, StackTrace? stack]) =>
      _log.e(message, error: error, stackTrace: stack);
}
