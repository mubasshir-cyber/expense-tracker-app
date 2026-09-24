/// Pre-configured calendar and rolling date presets for exporting reports.
enum ExportDatePreset {
  oneWeek,
  oneMonth,
  threeMonths,
  oneYear,
  custom;

  String get label {
    switch (this) {
      case ExportDatePreset.oneWeek:
        return '1 Week';
      case ExportDatePreset.oneMonth:
        return '1 Month';
      case ExportDatePreset.threeMonths:
        return '3 Months';
      case ExportDatePreset.oneYear:
        return '1 Year';
      case ExportDatePreset.custom:
        return 'Custom';
    }
  }

  /// Computes start and end dates relative to [asOfDate] (defaults to current date).
  ///
  /// - 1 Week: 7 days up to [asOfDate] (e.g., 17 Sep → 23 Sep)
  /// - 1 Month: 1st of current calendar month up to [asOfDate] (e.g., 01 Sep → 23 Sep)
  /// - 3 Months: 1st of month 2 months prior up to [asOfDate] (e.g., 01 Jul → 23 Sep)
  /// - 1 Year: 1st of month 11 months prior up to [asOfDate] (e.g., 01 Oct 2025 → 23 Sep 2026)
  /// - Custom: Returns [asOfDate] to [asOfDate] as baseline fallback
  ({DateTime startDate, DateTime endDate}) calculateDateRange([DateTime? asOfDate]) {
    final now = asOfDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case ExportDatePreset.oneWeek:
        return (
          startDate: today.subtract(const Duration(days: 6)),
          endDate: today,
        );
      case ExportDatePreset.oneMonth:
        return (
          startDate: DateTime(today.year, today.month, 1),
          endDate: today,
        );
      case ExportDatePreset.threeMonths:
        var startMonth = today.month - 2;
        var startYear = today.year;
        while (startMonth <= 0) {
          startMonth += 12;
          startYear -= 1;
        }
        return (
          startDate: DateTime(startYear, startMonth, 1),
          endDate: today,
        );
      case ExportDatePreset.oneYear:
        var startMonth = today.month - 11;
        var startYear = today.year;
        while (startMonth <= 0) {
          startMonth += 12;
          startYear -= 1;
        }
        return (
          startDate: DateTime(startYear, startMonth, 1),
          endDate: today,
        );
      case ExportDatePreset.custom:
        return (
          startDate: today,
          endDate: today,
        );
    }
  }
}
