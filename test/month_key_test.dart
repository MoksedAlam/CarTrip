import 'package:fleetboard/core/utils/month_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthKey Tests', () {
    test('fromDateTime converts correctly to YYYY-MM', () {
      expect(MonthKey.fromDateTime(DateTime(2026, 9, 20)), '2026-09');
      expect(MonthKey.fromDateTime(DateTime(2026, 1, 5)), '2026-01');
      expect(MonthKey.fromDateTime(DateTime(2026, 12, 31)), '2026-12');
    });

    test('toDateTime parses correctly', () {
      final dt = MonthKey.toDateTime('2026-09');
      expect(dt.year, 2026);
      expect(dt.month, 9);
      expect(dt.day, 1);
    });

    test('formatMonthLabel formats nicely', () {
      expect(MonthKey.formatMonthLabel('2026-09'), 'Sep 2026');
      expect(MonthKey.formatMonthLabel('2026-01'), 'Jan 2026');
    });

    test('previousMonth and nextMonth navigation', () {
      expect(MonthKey.previousMonth('2026-09'), '2026-08');
      expect(MonthKey.nextMonth('2026-09'), '2026-10');
      // Year boundaries
      expect(MonthKey.previousMonth('2026-01'), '2025-12');
      expect(MonthKey.nextMonth('2026-12'), '2027-01');
    });
  });
}
