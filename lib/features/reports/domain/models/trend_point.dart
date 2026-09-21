/// A single time-bucket data point for the trend line chart.
class TrendPoint {
  const TrendPoint({
    required this.date,
    required this.credits,
    required this.expenses,
  });

  /// The representative date for this bucket (start of the day/week/month).
  final DateTime date;

  /// Total credits in this bucket.
  final double credits;

  /// Total expenses in this bucket.
  final double expenses;

  @override
  String toString() =>
      'TrendPoint(${date.toIso8601String()}: credits=$credits, expenses=$expenses)';
}
