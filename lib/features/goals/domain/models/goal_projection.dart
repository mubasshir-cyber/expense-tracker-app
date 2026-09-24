/// Dynamic savings rate projection details based on target date and remaining balance.
class GoalProjection {
  const GoalProjection({
    this.requiredMonthlyRate,
    this.requiredWeeklyRate,
    this.daysRemaining,
    this.isDeadlinePassed = false,
    this.isTargetReached = false,
  });

  /// Monthly savings required to meet the goal on time (null if no deadline or deadline passed).
  final double? requiredMonthlyRate;

  /// Weekly savings required to meet the goal on time (null if no deadline or deadline passed).
  final double? requiredWeeklyRate;

  /// Calendar days remaining until target date (negative if passed).
  final int? daysRemaining;

  /// True if target date is before today and target has not been reached.
  final bool isDeadlinePassed;

  /// True if goal balance has reached or exceeded the target amount.
  final bool isTargetReached;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalProjection &&
          runtimeType == other.runtimeType &&
          requiredMonthlyRate == other.requiredMonthlyRate &&
          requiredWeeklyRate == other.requiredWeeklyRate &&
          daysRemaining == other.daysRemaining &&
          isDeadlinePassed == other.isDeadlinePassed &&
          isTargetReached == other.isTargetReached;

  @override
  int get hashCode =>
      requiredMonthlyRate.hashCode ^
      requiredWeeklyRate.hashCode ^
      daysRemaining.hashCode ^
      isDeadlinePassed.hashCode ^
      isTargetReached.hashCode;
}
