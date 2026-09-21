import 'package:expense_tracker/features/reports/domain/models/report_granularity.dart';
import 'package:expense_tracker/features/reports/domain/models/report_period.dart';
import 'package:expense_tracker/features/reports/presentation/providers/reports_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Fixed reference: Monday 2024-09-16
  final now = DateTime(2024, 9, 16); // Monday

  group('ReportPeriod.dateRange', () {
    test('thisWeek start is the current Monday', () {
      final (start, _) = ReportPeriod.thisWeek.dateRange(now);
      expect(start, DateTime(2024, 9, 16)); // same day because it's Monday
    });

    test('thisWeek end is today end-of-day', () {
      final (_, end) = ReportPeriod.thisWeek.dateRange(now);
      expect(end.year, 2024);
      expect(end.month, 9);
      expect(end.day, 16);
      expect(end.hour, 23);
    });

    test('thisMonth start is first of current month', () {
      final (start, _) = ReportPeriod.thisMonth.dateRange(now);
      expect(start, DateTime(2024, 9, 1));
    });

    test('lastMonth range covers the previous month', () {
      final (start, end) = ReportPeriod.lastMonth.dateRange(now);
      expect(start.month, 8);
      expect(start.day, 1);
      expect(end.month, 8);
      expect(end.day, 31);
    });

    test('last3Months starts 2 months back', () {
      final (start, _) = ReportPeriod.last3Months.dateRange(now);
      // 2 months before Sep = Jul
      expect(start.month, 7);
    });

    test('thisYear starts January 1', () {
      final (start, end) = ReportPeriod.thisYear.dateRange(now);
      expect(start, DateTime(2024, 1, 1));
      expect(end.year, 2024);
    });

    test('today range covers current day', () {
      final (start, end) = ReportPeriod.today.dateRange(now);
      expect(start, DateTime(2024, 9, 16));
      expect(end, DateTime(2024, 9, 16, 23, 59, 59, 999));
    });

    test('yesterday range covers previous day', () {
      final (start, end) = ReportPeriod.yesterday.dateRange(now);
      expect(start, DateTime(2024, 9, 15));
      expect(end, DateTime(2024, 9, 15, 23, 59, 59, 999));
    });

    test('custom throws StateError', () {
      expect(
        () => ReportPeriod.custom.dateRange(now),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ReportPeriod.defaultGranularity', () {
    test('today → daily', () {
      expect(ReportPeriod.today.defaultGranularity, ReportGranularity.daily);
    });

    test('yesterday → daily', () {
      expect(ReportPeriod.yesterday.defaultGranularity, ReportGranularity.daily);
    });

    test('thisWeek → daily', () {
      expect(ReportPeriod.thisWeek.defaultGranularity, ReportGranularity.daily);
    });

    test('thisMonth → daily', () {
      expect(
          ReportPeriod.thisMonth.defaultGranularity, ReportGranularity.daily);
    });

    test('last3Months → weekly', () {
      expect(ReportPeriod.last3Months.defaultGranularity,
          ReportGranularity.weekly);
    });

    test('thisYear → monthly', () {
      expect(
          ReportPeriod.thisYear.defaultGranularity, ReportGranularity.monthly);
    });
  });

  group('ReportFilter', () {
    test('forPeriod(thisMonth) uses this month dates', () {
      final filter = ReportFilter.forPeriod(ReportPeriod.thisMonth, now);
      expect(filter.startDate, DateTime(2024, 9, 1));
      expect(filter.period, ReportPeriod.thisMonth);
    });

    test('custom factory stores start/end correctly', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31, 23, 59, 59);
      final filter = ReportFilter.custom(startDate: start, endDate: end);
      expect(filter.startDate, start);
      expect(filter.endDate, end);
      expect(filter.period, ReportPeriod.custom);
    });

    test('custom factory throws when start > end', () {
      expect(
        () => ReportFilter.custom(
          startDate: DateTime(2024, 9, 30),
          endDate: DateTime(2024, 9, 1),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('custom factory chooses daily granularity for <= 31 days', () {
      final filter = ReportFilter.custom(
        startDate: DateTime(2024, 9, 1),
        endDate: DateTime(2024, 9, 20),
      );
      expect(filter.granularity, ReportGranularity.daily);
    });

    test('custom factory chooses weekly granularity for 32–90 days', () {
      final filter = ReportFilter.custom(
        startDate: DateTime(2024, 7, 1),
        endDate: DateTime(2024, 9, 1),
      );
      expect(filter.granularity, ReportGranularity.weekly);
    });

    test('custom factory chooses monthly granularity for > 90 days', () {
      final filter = ReportFilter.custom(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 9, 1),
      );
      expect(filter.granularity, ReportGranularity.monthly);
    });
  });

  group('ReportFilterNotifier', () {
    test('initial period is thisMonth', () {
      final notifier = ReportFilterNotifier();
      expect(notifier.state.period, ReportPeriod.thisMonth);
    });

    test('setPeriod updates state', () {
      final notifier = ReportFilterNotifier();
      notifier.setPeriod(ReportPeriod.thisYear);
      expect(notifier.state.period, ReportPeriod.thisYear);
    });

    test('setPeriod(custom) is a no-op', () {
      final notifier = ReportFilterNotifier();
      final before = notifier.state.period;
      notifier.setPeriod(ReportPeriod.custom);
      expect(notifier.state.period, before);
    });

    test('setCustomRange returns true for valid range', () {
      final notifier = ReportFilterNotifier();
      final result = notifier.setCustomRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );
      expect(result, isTrue);
      expect(notifier.state.period, ReportPeriod.custom);
    });

    test('setCustomRange returns false for invalid range (start > end)', () {
      final notifier = ReportFilterNotifier();
      final result = notifier.setCustomRange(
        DateTime(2024, 9, 30),
        DateTime(2024, 9, 1),
      );
      expect(result, isFalse);
      // State must NOT change
      expect(notifier.state.period, ReportPeriod.thisMonth);
    });

    test('setSingleDate configures full day custom filter', () {
      final notifier = ReportFilterNotifier();
      notifier.setSingleDate(DateTime(2024, 5, 20));
      expect(notifier.state.period, ReportPeriod.custom);
      expect(notifier.state.startDate, DateTime(2024, 5, 20));
      expect(notifier.state.endDate, DateTime(2024, 5, 20, 23, 59, 59, 999));
      expect(notifier.state.granularity, ReportGranularity.daily);
    });
  });
}
