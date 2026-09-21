import 'report_granularity.dart';

/// Named date-range presets for the Reports module.
enum ReportPeriod {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  lastMonth,
  last3Months,
  thisYear,
  custom,
}

extension ReportPeriodX on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.today:
        return 'Today';
      case ReportPeriod.yesterday:
        return 'Yesterday';
      case ReportPeriod.thisWeek:
        return 'This Week';
      case ReportPeriod.thisMonth:
        return 'This Month';
      case ReportPeriod.lastMonth:
        return 'Last Month';
      case ReportPeriod.last3Months:
        return 'Last 3 Months';
      case ReportPeriod.thisYear:
        return 'This Year';
      case ReportPeriod.custom:
        return 'Custom';
    }
  }

  /// Returns [startDate, endDate] for the preset relative to [now].
  /// For [ReportPeriod.custom] this throws; use [ReportFilter] directly.
  (DateTime start, DateTime end) dateRange([DateTime? now]) {
    final today = now ?? DateTime.now();
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);

    switch (this) {
      case ReportPeriod.today:
        final start = DateTime(today.year, today.month, today.day);
        return (start, todayEnd);

      case ReportPeriod.yesterday:
        final start = DateTime(today.year, today.month, today.day - 1);
        final end = DateTime(today.year, today.month, today.day - 1, 23, 59, 59, 999);
        return (start, end);

      case ReportPeriod.thisWeek:
        // Start = most recent Monday (or today if Monday)
        final weekday = today.weekday; // 1=Mon … 7=Sun
        final start = DateTime(today.year, today.month, today.day - (weekday - 1));
        return (start, todayEnd);

      case ReportPeriod.thisMonth:
        final start = DateTime(today.year, today.month);
        return (start, todayEnd);

      case ReportPeriod.lastMonth:
        final start = DateTime(today.year, today.month - 1);
        final end = DateTime(today.year, today.month, 0, 23, 59, 59, 999);
        return (start, end);

      case ReportPeriod.last3Months:
        final start = DateTime(today.year, today.month - 2);
        return (start, todayEnd);

      case ReportPeriod.thisYear:
        final start = DateTime(today.year);
        return (start, todayEnd);

      case ReportPeriod.custom:
        throw StateError(
          'Custom period does not have a built-in date range. '
          'Use ReportFilter.startDate and ReportFilter.endDate directly.',
        );
    }
  }

  /// Recommended chart granularity for this preset.
  ReportGranularity get defaultGranularity {
    switch (this) {
      case ReportPeriod.today:
      case ReportPeriod.yesterday:
      case ReportPeriod.thisWeek:
      case ReportPeriod.thisMonth:
      case ReportPeriod.lastMonth:
        return ReportGranularity.daily;
      case ReportPeriod.last3Months:
        return ReportGranularity.weekly;
      case ReportPeriod.thisYear:
        return ReportGranularity.monthly;
      case ReportPeriod.custom:
        return ReportGranularity.daily; // overridden by range length
    }
  }
}
