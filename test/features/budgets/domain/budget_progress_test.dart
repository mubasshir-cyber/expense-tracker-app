import 'package:expense_tracker/features/budgets/domain/models/budget_model.dart';
import 'package:expense_tracker/features/budgets/domain/models/budget_period.dart';
import 'package:expense_tracker/features/budgets/domain/models/budget_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetProgress', () {
    final budget = BudgetModel(
      id: 'b-1',
      userId: 'u-1',
      name: 'Food',
      amount: 5000.0,
      period: BudgetPeriod.monthly,
      startDate: DateTime(2026, 9, 1),
      alertThreshold: 0.80, // 80% threshold = 4000
    );

    test('normal status when spent is below alert threshold', () {
      final progress = BudgetProgress(
        budget: budget,
        spent: 2500.0,
        effectiveStartDate: DateTime(2026, 9, 1),
        effectiveEndDate: DateTime(2026, 9, 30),
      );

      expect(progress.remaining, 2500.0);
      expect(progress.percentage, 50.0);
      expect(progress.progressRatioClamped, 0.5);
      expect(progress.isWarning, false);
      expect(progress.isOverBudget, false);
      expect(progress.status, BudgetStatus.normal);
      expect(progress.overBudgetAmount, 0.0);
    });

    test('warning status when spent reaches or exceeds threshold (80%)', () {
      final progress = BudgetProgress(
        budget: budget,
        spent: 4000.0,
        effectiveStartDate: DateTime(2026, 9, 1),
        effectiveEndDate: DateTime(2026, 9, 30),
      );

      expect(progress.remaining, 1000.0);
      expect(progress.percentage, 80.0);
      expect(progress.isWarning, true);
      expect(progress.isOverBudget, false);
      expect(progress.status, BudgetStatus.warning);
    });

    test('overBudget status when spent exceeds budget amount (>100%)', () {
      final progress = BudgetProgress(
        budget: budget,
        spent: 5600.0,
        effectiveStartDate: DateTime(2026, 9, 1),
        effectiveEndDate: DateTime(2026, 9, 30),
      );

      expect(progress.remaining, -600.0);
      expect(progress.overBudgetAmount, 600.0);
      expect(progress.percentage, closeTo(112.0, 0.001));
      expect(progress.progressRatioClamped, 1.0); // Clamped for bar rendering
      expect(progress.isWarning, false);
      expect(progress.isOverBudget, true);
      expect(progress.status, BudgetStatus.overBudget);
    });
  });
}
