import 'package:flutter/material.dart';

/// Supported budget periods.
enum BudgetPeriod {
  weekly('WEEKLY', 'Weekly'),
  monthly('MONTHLY', 'Monthly'),
  custom('CUSTOM', 'Custom');

  const BudgetPeriod(this.value, this.label);

  final String value;
  final String label;

  static BudgetPeriod fromValue(String value) {
    switch (value.toUpperCase()) {
      case 'WEEKLY':
        return BudgetPeriod.weekly;
      case 'MONTHLY':
        return BudgetPeriod.monthly;
      case 'CUSTOM':
        return BudgetPeriod.custom;
      default:
        return BudgetPeriod.monthly;
    }
  }

  /// Computes the effective [DateTimeRange] for this period relative to [referenceDate].
  DateTimeRange calculateDateRange(
    DateTime referenceDate, {
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    switch (this) {
      case BudgetPeriod.weekly:
        // Week starting Monday
        final daysFromMonday = referenceDate.weekday - 1;
        final start = DateTime(
          referenceDate.year,
          referenceDate.month,
          referenceDate.day - daysFromMonday,
        );
        final end = DateTime(
          start.year,
          start.month,
          start.day + 6,
          23,
          59,
          59,
          999,
        );
        return DateTimeRange(start: start, end: end);

      case BudgetPeriod.monthly:
        final start = DateTime(referenceDate.year, referenceDate.month, 1);
        final nextMonthFirst = DateTime(referenceDate.year, referenceDate.month + 1, 1);
        final end = nextMonthFirst.subtract(const Duration(microseconds: 1));
        return DateTimeRange(start: start, end: end);

      case BudgetPeriod.custom:
        final start = customStart ?? DateTime(referenceDate.year, referenceDate.month, 1);
        final end = customEnd ?? DateTime(referenceDate.year, referenceDate.month + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
    }
  }
}
