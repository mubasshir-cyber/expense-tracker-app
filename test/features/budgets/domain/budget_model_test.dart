import 'package:expense_tracker/features/budgets/domain/models/budget_model.dart';
import 'package:expense_tracker/features/budgets/domain/models/budget_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetModel', () {
    final now = DateTime(2026, 9, 1);

    test('serialization round-trip toMap and fromMap', () {
      final model = BudgetModel(
        id: 'b-1',
        userId: 'u-1',
        categoryId: 'c-1',
        name: 'Food & Dining',
        amount: 5000.0,
        period: BudgetPeriod.monthly,
        startDate: now,
        endDate: null,
        alertThreshold: 0.85,
        isActive: true,
      );

      final map = model.toMap();
      expect(map['id'], 'b-1');
      expect(map['user_id'], 'u-1');
      expect(map['category_id'], 'c-1');
      expect(map['name'], 'Food & Dining');
      expect(map['amount'], 5000.0);
      expect(map['period'], 'MONTHLY');
      expect(map['alert_threshold'], 0.85);
      expect(map['is_active'], true);

      final restored = BudgetModel.fromMap(map);
      expect(restored.id, model.id);
      expect(restored.name, model.name);
      expect(restored.amount, model.amount);
      expect(restored.period, model.period);
      expect(restored.alertThreshold, model.alertThreshold);
      expect(restored.isOverallBudget, false);
    });

    test('isOverallBudget returns true when categoryId is null or empty', () {
      final overall = BudgetModel(
        id: 'b-2',
        userId: 'u-1',
        categoryId: null,
        name: 'Overall Budget',
        amount: 30000.0,
        period: BudgetPeriod.monthly,
        startDate: now,
      );
      expect(overall.isOverallBudget, true);

      final categoryBudget = overall.copyWith(categoryId: 'c-food');
      expect(categoryBudget.isOverallBudget, false);
    });

    test('copyWith clears categoryId and endDate when requested', () {
      final budget = BudgetModel(
        id: 'b-3',
        userId: 'u-1',
        categoryId: 'c-travel',
        name: 'Travel',
        amount: 10000.0,
        period: BudgetPeriod.custom,
        startDate: now,
        endDate: DateTime(2026, 9, 20),
      );

      final cleared = budget.copyWith(
        clearCategoryId: true,
        clearEndDate: true,
        period: BudgetPeriod.monthly,
      );

      expect(cleared.categoryId, isNull);
      expect(cleared.isOverallBudget, true);
      expect(cleared.endDate, isNull);
      expect(cleared.period, BudgetPeriod.monthly);
    });
  });
}
