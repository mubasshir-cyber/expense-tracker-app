import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/goals/domain/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/domain/models/savings_goal_model.dart';
import 'package:expense_tracker/features/goals/domain/services/savings_goal_calculation_service.dart';

void main() {
  group('SavingsGoalCalculationService', () {
    const service = SavingsGoalCalculationService();

    test('computeGoalBalance correctly calculates net total', () {
      final contributions = [
        GoalContributionModel(
          id: 'c1',
          goalId: 'g1',
          userId: 'u1',
          amount: 10000.0,
          contributionDate: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
        ),
        GoalContributionModel(
          id: 'c2',
          goalId: 'g1',
          userId: 'u1',
          amount: 5000.0,
          contributionDate: DateTime(2026, 2, 1),
          createdAt: DateTime(2026, 2, 1),
        ),
        GoalContributionModel(
          id: 'c3',
          goalId: 'g1',
          userId: 'u1',
          amount: -3000.0,
          contributionDate: DateTime(2026, 2, 15),
          createdAt: DateTime(2026, 2, 15),
        ),
      ];

      final balance = service.computeGoalBalance(contributions);
      expect(balance, 12000.0);
    });

    test('calculateProjection handles completed goal', () {
      final goal = SavingsGoalModel(
        id: 'g1',
        userId: 'u1',
        name: 'New Car',
        targetAmount: 50000.0,
        currentAmount: 50000.0,
        targetDate: DateTime(2026, 12, 31),
        createdAt: DateTime(2026, 1, 1),
      );

      final projection = service.calculateProjection(goal);
      expect(projection.isTargetReached, isTrue);
      expect(projection.requiredMonthlyRate, 0.0);
      expect(projection.requiredWeeklyRate, 0.0);
    });

    test('calculateProjection handles goal with no target date', () {
      final goal = SavingsGoalModel(
        id: 'g1',
        userId: 'u1',
        name: 'Open Ended',
        targetAmount: 50000.0,
        currentAmount: 10000.0,
        targetDate: null,
        createdAt: DateTime(2026, 1, 1),
      );

      final projection = service.calculateProjection(goal);
      expect(projection.isTargetReached, isFalse);
      expect(projection.requiredMonthlyRate, isNull);
      expect(projection.requiredWeeklyRate, isNull);
      expect(projection.daysRemaining, isNull);
    });

    test('calculateProjection handles passed deadline with remaining balance', () {
      final goal = SavingsGoalModel(
        id: 'g1',
        userId: 'u1',
        name: 'Past Goal',
        targetAmount: 50000.0,
        currentAmount: 20000.0,
        targetDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2025, 1, 1),
      );

      final projection = service.calculateProjection(
        goal,
        asOfDate: DateTime(2026, 2, 1),
      );
      expect(projection.isDeadlinePassed, isTrue);
      expect(projection.requiredMonthlyRate, isNull);
      expect(projection.requiredWeeklyRate, isNull);
      expect(projection.daysRemaining, lessThan(0));
    });

    test('calculateProjection calculates monthly and weekly required rates for active goal', () {
      final asOf = DateTime(2026, 1, 1);
      final targetDate = DateTime(2026, 3, 2); // 60 days
      final goal = SavingsGoalModel(
        id: 'g1',
        userId: 'u1',
        name: 'Trip to Tokyo',
        targetAmount: 100000.0,
        currentAmount: 40000.0, // 60,000 remaining
        targetDate: targetDate,
        createdAt: DateTime(2026, 1, 1),
      );

      final projection = service.calculateProjection(goal, asOfDate: asOf);
      expect(projection.isTargetReached, isFalse);
      expect(projection.isDeadlinePassed, isFalse);
      expect(projection.daysRemaining, 60);
      expect(projection.requiredMonthlyRate, isNotNull);
      // 60,000 / 60 days = 1,000/day * 30.4375 ≈ 30,437.5
      expect(projection.requiredMonthlyRate!, closeTo(30437.5, 1.0));
      // 60,000 / 60 days = 1,000/day * 7 = 7,000
      expect(projection.requiredWeeklyRate!, closeTo(7000.0, 1.0));
    });

    test('calculateMilestones provides 25, 50, 75, 100% milestone progress correctly', () {
      final goal = SavingsGoalModel(
        id: 'g1',
        userId: 'u1',
        name: 'Laptop Fund',
        targetAmount: 100000.0,
        currentAmount: 60000.0,
        createdAt: DateTime(2026, 1, 1),
      );

      final milestones = service.calculateMilestones(goal);
      expect(milestones.length, 4);

      // 25% ($25,000) -> reached
      expect(milestones[0].percentage, 25);
      expect(milestones[0].targetAmount, 25000.0);
      expect(milestones[0].isReached, isTrue);

      // 50% ($50,000) -> reached
      expect(milestones[1].percentage, 50);
      expect(milestones[1].targetAmount, 50000.0);
      expect(milestones[1].isReached, isTrue);

      // 75% ($75,000) -> not reached
      expect(milestones[2].percentage, 75);
      expect(milestones[2].targetAmount, 75000.0);
      expect(milestones[2].isReached, isFalse);

      // 100% ($100,000) -> not reached
      expect(milestones[3].percentage, 100);
      expect(milestones[3].targetAmount, 100000.0);
      expect(milestones[3].isReached, isFalse);
    });

    test('calculateSummary aggregates multiple goals correctly', () {
      final goals = [
        SavingsGoalModel(
          id: 'g1',
          userId: 'u1',
          name: 'Goal 1',
          targetAmount: 10000.0,
          currentAmount: 10000.0, // completed
          createdAt: DateTime(2026, 1, 1),
        ),
        SavingsGoalModel(
          id: 'g2',
          userId: 'u1',
          name: 'Goal 2',
          targetAmount: 30000.0,
          currentAmount: 10000.0, // active
          createdAt: DateTime(2026, 1, 1),
        ),
      ];

      final summary = service.calculateSummary(goals);
      expect(summary.totalTarget, 40000.0);
      expect(summary.totalSaved, 20000.0);
      expect(summary.completedCount, 1);
      expect(summary.activeCount, 1);
      expect(summary.overallPercentage, 50.0);
      expect(summary.overallProgressRatio, 0.5);
    });
  });
}
