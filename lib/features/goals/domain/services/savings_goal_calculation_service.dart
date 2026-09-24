import '../models/goal_contribution_model.dart';
import '../models/goal_milestone.dart';
import '../models/goal_projection.dart';
import '../models/savings_goal_model.dart';

/// Summary overview of all savings goals.
class SavingsGoalsSummary {
  const SavingsGoalsSummary({
    required this.totalTarget,
    required this.totalSaved,
    required this.completedCount,
    required this.activeCount,
  });

  final double totalTarget;
  final double totalSaved;
  final int completedCount;
  final int activeCount;

  double get overallPercentage {
    if (totalTarget <= 0) return 0.0;
    return ((totalSaved / totalTarget) * 100).clamp(0.0, 100.0);
  }

  double get overallProgressRatio => (overallPercentage / 100).clamp(0.0, 1.0);
}

/// Pure domain calculation service for savings goals metrics, milestones, and trajectories.
class SavingsGoalCalculationService {
  const SavingsGoalCalculationService();

  /// Computes the net saved balance from a list of goal contributions.
  double computeGoalBalance(List<GoalContributionModel> contributions) {
    return contributions.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );
  }

  /// Calculates dynamic savings rate projections to meet goal deadline on time.
  GoalProjection calculateProjection(
    SavingsGoalModel goal, {
    DateTime? asOfDate,
  }) {
    if (goal.isCompleted || goal.remainingAmount <= 0) {
      return const GoalProjection(
        isTargetReached: true,
        requiredMonthlyRate: 0.0,
        requiredWeeklyRate: 0.0,
      );
    }

    if (goal.targetDate == null) {
      return const GoalProjection(
        requiredMonthlyRate: null,
        requiredWeeklyRate: null,
        daysRemaining: null,
      );
    }

    final now = asOfDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      goal.targetDate!.year,
      goal.targetDate!.month,
      goal.targetDate!.day,
    );
    final daysRemaining = target.difference(today).inDays;

    if (daysRemaining < 0) {
      return GoalProjection(
        isDeadlinePassed: true,
        daysRemaining: daysRemaining,
        requiredMonthlyRate: null,
        requiredWeeklyRate: null,
      );
    }

    if (daysRemaining == 0) {
      return GoalProjection(
        daysRemaining: 0,
        requiredMonthlyRate: goal.remainingAmount,
        requiredWeeklyRate: goal.remainingAmount,
      );
    }

    // Average days in calendar month = 365.25 / 12 = 30.4375
    final monthlyRate = (goal.remainingAmount / daysRemaining) * 30.4375;
    final weeklyRate = (goal.remainingAmount / daysRemaining) * 7.0;

    return GoalProjection(
      daysRemaining: daysRemaining,
      requiredMonthlyRate: monthlyRate,
      requiredWeeklyRate: weeklyRate,
    );
  }

  /// Calculates milestone achievement status (25%, 50%, 75%, 100%).
  List<GoalMilestone> calculateMilestones(SavingsGoalModel goal) {
    const percentages = [25, 50, 75, 100];
    return percentages.map((p) {
      final targetForMilestone = goal.targetAmount * (p / 100.0);
      final isAchieved = goal.savedPercentage >= p;
      return GoalMilestone(
        percentage: p,
        targetAmount: targetForMilestone,
        isAchieved: isAchieved,
      );
    }).toList();
  }

  /// Calculates overall portfolio summary across multiple savings goals.
  SavingsGoalsSummary calculateOverallSummary(List<SavingsGoalModel> goals) {
    var totalTarget = 0.0;
    var totalSaved = 0.0;
    var completedCount = 0;
    var activeCount = 0;

    for (final goal in goals) {
      if (!goal.isActive) continue;
      totalTarget += goal.targetAmount;
      totalSaved += goal.currentAmount;
      if (goal.isCompleted) {
        completedCount++;
      } else {
        activeCount++;
      }
    }

    return SavingsGoalsSummary(
      totalTarget: totalTarget,
      totalSaved: totalSaved,
      completedCount: completedCount,
      activeCount: activeCount,
    );
  }

  /// Alias for calculateOverallSummary.
  SavingsGoalsSummary calculateSummary(List<SavingsGoalModel> goals) =>
      calculateOverallSummary(goals);
}
