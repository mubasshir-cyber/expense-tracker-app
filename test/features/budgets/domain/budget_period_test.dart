import 'package:expense_tracker/features/budgets/domain/models/budget_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetPeriod', () {
    test('fromValue parses values case-insensitively', () {
      expect(BudgetPeriod.fromValue('WEEKLY'), BudgetPeriod.weekly);
      expect(BudgetPeriod.fromValue('weekly'), BudgetPeriod.weekly);
      expect(BudgetPeriod.fromValue('MONTHLY'), BudgetPeriod.monthly);
      expect(BudgetPeriod.fromValue('monthly'), BudgetPeriod.monthly);
      expect(BudgetPeriod.fromValue('CUSTOM'), BudgetPeriod.custom);
      expect(BudgetPeriod.fromValue('custom'), BudgetPeriod.custom);
      expect(BudgetPeriod.fromValue('unknown'), BudgetPeriod.monthly);
    });

    test('calculateDateRange for monthly period spans entire month', () {
      final ref = DateTime(2026, 9, 15);
      final range = BudgetPeriod.monthly.calculateDateRange(ref);

      expect(range.start, DateTime(2026, 9, 1));
      expect(range.end.year, 2026);
      expect(range.end.month, 9);
      expect(range.end.day, 30);
    });

    test('calculateDateRange for weekly period spans Monday to Sunday', () {
      // 2026-09-21 is Monday (weekday = 1)
      final monday = DateTime(2026, 9, 21);
      final rangeMonday = BudgetPeriod.weekly.calculateDateRange(monday);
      expect(rangeMonday.start, DateTime(2026, 9, 21));
      expect(rangeMonday.end.day, 27);

      // 2026-09-24 is Thursday (weekday = 4)
      final thursday = DateTime(2026, 9, 24);
      final rangeThursday = BudgetPeriod.weekly.calculateDateRange(thursday);
      expect(rangeThursday.start, DateTime(2026, 9, 21));
      expect(rangeThursday.end.day, 27);
    });

    test('calculateDateRange for custom period respects custom dates', () {
      final start = DateTime(2026, 9, 5);
      final end = DateTime(2026, 9, 25);
      final range = BudgetPeriod.custom.calculateDateRange(
        DateTime(2026, 9, 10),
        customStart: start,
        customEnd: end,
      );

      expect(range.start, start);
      expect(range.end, end);
    });
  });
}
