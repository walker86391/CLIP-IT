import 'dart:async';

/// Severity levels for user-facing notifications.
enum NotificationLevel { info, success, warning, error }

/// A user-facing toast payload.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.level,
    required this.title,
    this.message,
    this.duration = const Duration(seconds: 4),
  });

  final String id;
  final NotificationLevel level;
  final String title;
  final String? message;
  final Duration duration;
}

/// Bridge between services and the toast UI.
///
/// Services push notifications here; the toast overlay (app_toast.dart)
/// listens and displays them with queueing. UI code may also push directly.
abstract class NotificationsService {
  Stream<AppNotification> get stream;

  void show(AppNotification notification);

  /// Convenience constructors for common levels.
  static AppNotification info(String title, {String? message}) =>
      AppNotification(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        level: NotificationLevel.info,
        title: title,
        message: message,
      );

  static AppNotification success(String title, {String? message}) =>
      AppNotification(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        level: NotificationLevel.success,
        title: title,
        message: message,
      );

  static AppNotification warning(String title, {String? message}) =>
      AppNotification(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        level: NotificationLevel.warning,
        title: title,
        message: message,
      );

  static AppNotification error(String title, {String? message}) =>
      AppNotification(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        level: NotificationLevel.error,
        title: title,
        message: message,
      );
}

/// In-memory implementation for Step 0.
final class NotificationsServiceImpl implements NotificationsService {
  final StreamController<AppNotification> _controller =
      StreamController.broadcast();

  // Simple queue: track active notifications so the UI overlay can manage
  // dismissal order.
  final List<AppNotification> _queue = [];

  @override
  Stream<AppNotification> get stream => _controller.stream;

  @override
  void show(AppNotification notification) {
    _queue.add(notification);
    if (_queue.length > 5) _queue.removeAt(0); // Cap displayed toasts.
    _controller.add(notification);
  }

  void dispose() => _controller.close();
}
