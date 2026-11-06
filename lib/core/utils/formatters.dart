import 'package:intl/intl.dart';

/// Shared display formatters (dates, durations, sizes).
abstract final class Formatters {
  static String date(DateTime dt) => DateFormat.yMMMd().format(dt);

  static String dateTime(DateTime dt) => DateFormat.yMMMd().add_Hm().format(dt);

  static String time(DateTime dt) => DateFormat.Hm().format(dt);

  /// 01:23 or 1:23:45 for durations.
  static String duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
  }

  /// 1.2 KB / 3.4 MB style sizes.
  static String bytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return unit == 0 ? '${value.round()} ${units[unit]}' : '${value.toStringAsFixed(1)} ${units[unit]}';
  }
}
