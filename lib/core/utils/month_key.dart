import 'package:intl/intl.dart';

class MonthKey {
  static String fromDateTime(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$year-$month';
  }

  static DateTime toDateTime(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return DateTime.now();
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    return DateTime(year, month, 1);
  }

  static String formatMonthLabel(String monthKey) {
    final dt = toDateTime(monthKey);
    return DateFormat('MMM yyyy').format(dt);
  }

  static String previousMonth(String monthKey) {
    final dt = toDateTime(monthKey);
    final prev = DateTime(dt.year, dt.month - 1, 1);
    return fromDateTime(prev);
  }

  static String nextMonth(String monthKey) {
    final dt = toDateTime(monthKey);
    final next = DateTime(dt.year, dt.month + 1, 1);
    return fromDateTime(next);
  }
}
