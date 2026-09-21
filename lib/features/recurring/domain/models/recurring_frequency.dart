/// Supported recurring frequencies.
enum RecurringFrequency {
  daily('DAILY', 'Daily'),
  weekly('WEEKLY', 'Weekly'),
  monthly('MONTHLY', 'Monthly'),
  yearly('YEARLY', 'Yearly'),
  custom('CUSTOM', 'Custom');

  const RecurringFrequency(this.value, this.label);

  final String value;
  final String label;

  static RecurringFrequency fromValue(String value) {
    switch (value.toUpperCase()) {
      case 'DAILY':
        return RecurringFrequency.daily;
      case 'WEEKLY':
        return RecurringFrequency.weekly;
      case 'MONTHLY':
        return RecurringFrequency.monthly;
      case 'YEARLY':
        return RecurringFrequency.yearly;
      case 'CUSTOM':
        return RecurringFrequency.custom;
      default:
        return RecurringFrequency.monthly;
    }
  }

  /// Calculates the next occurrence date after [fromDate], avoiding month-end drift.
  DateTime calculateNextOccurrence(DateTime fromDate) {
    switch (this) {
      case RecurringFrequency.daily:
        return DateTime(fromDate.year, fromDate.month, fromDate.day + 1);

      case RecurringFrequency.weekly:
        return DateTime(fromDate.year, fromDate.month, fromDate.day + 7);

      case RecurringFrequency.monthly:
        var nextYear = fromDate.year;
        var nextMonth = fromDate.month + 1;
        if (nextMonth > 12) {
          nextYear++;
          nextMonth = 1;
        }

        // Determine days in target month
        final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        final targetDay = fromDate.day > daysInNextMonth ? daysInNextMonth : fromDate.day;
        return DateTime(nextYear, nextMonth, targetDay);

      case RecurringFrequency.yearly:
        final nextYear = fromDate.year + 1;
        final daysInTargetMonth = DateTime(nextYear, fromDate.month + 1, 0).day;
        final targetDay = fromDate.day > daysInTargetMonth ? daysInTargetMonth : fromDate.day;
        return DateTime(nextYear, fromDate.month, targetDay);

      case RecurringFrequency.custom:
        // Default custom progression to next month
        return DateTime(fromDate.year, fromDate.month + 1, fromDate.day);
    }
  }
}
