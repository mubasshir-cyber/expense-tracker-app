/// Time-series bucketing granularity for trend charts.
enum ReportGranularity {
  daily,
  weekly,
  monthly;

  String get label {
    switch (this) {
      case ReportGranularity.daily:
        return 'Daily';
      case ReportGranularity.weekly:
        return 'Weekly';
      case ReportGranularity.monthly:
        return 'Monthly';
    }
  }
}
