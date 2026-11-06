import 'package:flutter/material.dart';

/// Reduce-motion scope.
///
/// Wrap the app above the navigator with this widget; components check it
/// via [AppMotion] so custom transitions honor the accessibility setting.
class ReduceMotion extends InheritedWidget {
  const ReduceMotion({
    required this.enabled,
    required super.child,
    super.key,
  });

  final bool enabled;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReduceMotion>()?.enabled ??
      false;

  @override
  bool updateShouldNotify(ReduceMotion oldWidget) =>
      oldWidget.enabled != enabled;
}

/// Motion tokens + reduce-motion support.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 80);
  static const Duration medium = Duration(milliseconds: 160);
  static const Curve curve = Curves.fastOutSlowIn;

  static bool disabled(BuildContext context) => ReduceMotion.of(context);

  static Duration fastOf(BuildContext context) =>
      disabled(context) ? Duration.zero : fast;

  static Duration mediumOf(BuildContext context) =>
      disabled(context) ? Duration.zero : medium;
}
