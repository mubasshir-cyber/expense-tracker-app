/// Represents a progress milestone for a savings goal (e.g., 25%, 50%, 75%, 100%).
class GoalMilestone {
  const GoalMilestone({
    required this.percentage,
    required this.targetAmount,
    required this.isAchieved,
  });

  final int percentage; // 25, 50, 75, 100
  final double targetAmount;
  final bool isAchieved;

  bool get isReached => isAchieved;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalMilestone &&
          runtimeType == other.runtimeType &&
          percentage == other.percentage &&
          targetAmount == other.targetAmount &&
          isAchieved == other.isAchieved;

  @override
  int get hashCode =>
      percentage.hashCode ^ targetAmount.hashCode ^ isAchieved.hashCode;
}
