/// Aggregated portfolio summary of debts and loans.
class DebtSummary {
  const DebtSummary({
    required this.totalYouAreOwed,
    required this.totalYouOwe,
    required this.activeOweCount,
    required this.activeOwedCount,
    required this.settledCount,
    required this.overdueCount,
  });

  /// Total money lent to others currently outstanding (Asset).
  final double totalYouAreOwed;
  double get totalYouAreOwedRemaining => totalYouAreOwed;

  /// Total money borrowed from others currently outstanding (Liability).
  final double totalYouOwe;
  double get totalYouOweRemaining => totalYouOwe;

  /// Net balance = You Are Owed (Assets) - You Owe (Liabilities).
  double get netPosition => totalYouAreOwed - totalYouOwe;

  final int activeOweCount;
  final int activeOwedCount;
  final int settledCount;
  final int overdueCount;

  int get totalActiveCount => activeOweCount + activeOwedCount;

  static const empty = DebtSummary(
    totalYouAreOwed: 0.0,
    totalYouOwe: 0.0,
    activeOweCount: 0,
    activeOwedCount: 0,
    settledCount: 0,
    overdueCount: 0,
  );
}
