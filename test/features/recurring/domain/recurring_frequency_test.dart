import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/recurring/domain/models/recurring_frequency.dart';

void main() {
  group('RecurringFrequency Enum & Next Occurrence Calculations', () {
    test('Daily frequency advances date by 1 day', () {
      final base = DateTime(2026, 1, 15);
      final next = RecurringFrequency.daily.calculateNextOccurrence(base);
      expect(next, DateTime(2026, 1, 16));
    });

    test('Weekly frequency advances date by 7 days', () {
      final base = DateTime(2026, 1, 10);
      final next = RecurringFrequency.weekly.calculateNextOccurrence(base);
      expect(next, DateTime(2026, 1, 17));
    });

    test('Monthly frequency advances to same day in next month', () {
      final base = DateTime(2026, 3, 15);
      final next = RecurringFrequency.monthly.calculateNextOccurrence(base);
      expect(next, DateTime(2026, 4, 15));
    });

    test('Monthly frequency clamps day at month end (Jan 31 to Feb 28 on non-leap year)', () {
      // 2027 is non-leap year
      final base = DateTime(2027, 1, 31);
      final next = RecurringFrequency.monthly.calculateNextOccurrence(base);
      expect(next, DateTime(2027, 2, 28));
    });

    test('Monthly frequency clamps day at Feb 29 on leap year', () {
      // 2028 is leap year
      final base = DateTime(2028, 1, 31);
      final next = RecurringFrequency.monthly.calculateNextOccurrence(base);
      expect(next, DateTime(2028, 2, 29));
    });

    test('Yearly frequency advances by 1 year', () {
      final base = DateTime(2026, 5, 20);
      final next = RecurringFrequency.yearly.calculateNextOccurrence(base);
      expect(next, DateTime(2027, 5, 20));
    });

    test('Yearly frequency handles leap day (Feb 29, 2028 to Feb 28, 2029)', () {
      final base = DateTime(2028, 2, 29);
      final next = RecurringFrequency.yearly.calculateNextOccurrence(base);
      expect(next, DateTime(2029, 2, 28));
    });

    test('fromValue parses correctly and falls back to monthly on unknown value', () {
      expect(RecurringFrequency.fromValue('DAILY'), RecurringFrequency.daily);
      expect(RecurringFrequency.fromValue('weekly'), RecurringFrequency.weekly);
      expect(RecurringFrequency.fromValue('MONTHLY'), RecurringFrequency.monthly);
      expect(RecurringFrequency.fromValue('yearly'), RecurringFrequency.yearly);
      expect(RecurringFrequency.fromValue('UNKNOWN'), RecurringFrequency.monthly);
    });

    test('value and label getters return correct strings', () {
      expect(RecurringFrequency.daily.value, 'DAILY');
      expect(RecurringFrequency.daily.label, 'Daily');
      expect(RecurringFrequency.weekly.value, 'WEEKLY');
      expect(RecurringFrequency.weekly.label, 'Weekly');
      expect(RecurringFrequency.monthly.value, 'MONTHLY');
      expect(RecurringFrequency.monthly.label, 'Monthly');
      expect(RecurringFrequency.yearly.value, 'YEARLY');
      expect(RecurringFrequency.yearly.label, 'Yearly');
    });
  });
}
