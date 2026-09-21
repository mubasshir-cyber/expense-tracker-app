import 'package:expense_tracker/features/budgets/domain/models/budget_model.dart';
import 'package:expense_tracker/features/budgets/domain/models/budget_period.dart';
import 'package:expense_tracker/features/budgets/domain/models/budget_progress.dart';
import 'package:expense_tracker/features/budgets/domain/services/budget_calculation_service.dart';
import 'package:expense_tracker/features/transactions/data/repositories/transaction_repository.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTransactionRepository implements TransactionRepository {
  _FakeTransactionRepository({
    this.overallExpenseTotal = 0.0,
    this.categoryExpenseTotals = const {},
  });

  final double overallExpenseTotal;
  final Map<String, double> categoryExpenseTotals;

  @override
  Future<double> sumByType({
    required TransactionType type,
    String? accountId,
    String? categoryId,
    DateTime? from,
    DateTime? to,
  }) async {
    if (type == TransactionType.expense) {
      if (categoryId != null) {
        return categoryExpenseTotals[categoryId] ?? 0.0;
      }
      return overallExpenseTotal;
    }
    return 0.0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('BudgetCalculationService', () {
    final refDate = DateTime(2026, 9, 15);

    test('calculateProgress for overall monthly budget queries all expenses', () async {
      final fakeRepo = _FakeTransactionRepository(
        overallExpenseTotal: 12500.0,
      );
      final service = BudgetCalculationService(fakeRepo);

      final overallBudget = BudgetModel(
        id: 'b-overall',
        userId: 'u-1',
        name: 'Monthly Cap',
        amount: 20000.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 9, 1),
        alertThreshold: 0.80,
      );

      final progress = await service.calculateProgress(
        overallBudget,
        referenceDate: refDate,
      );

      expect(progress.spent, 12500.0);
      expect(progress.remaining, 7500.0);
      expect(progress.percentage, 62.5);
      expect(progress.status, BudgetStatus.normal);
      expect(progress.effectiveStartDate, DateTime(2026, 9, 1));
      expect(progress.effectiveEndDate.day, 30);
    });

    test('calculateProgress for category-specific budget queries category expenses', () async {
      final fakeRepo = _FakeTransactionRepository(
        overallExpenseTotal: 15000.0,
        categoryExpenseTotals: {
          'cat-food': 4200.0,
          'cat-travel': 3100.0,
        },
      );
      final service = BudgetCalculationService(fakeRepo);

      final foodBudget = BudgetModel(
        id: 'b-food',
        userId: 'u-1',
        categoryId: 'cat-food',
        name: 'Food & Dining',
        amount: 5000.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 9, 1),
        alertThreshold: 0.80,
      );

      final travelBudget = BudgetModel(
        id: 'b-travel',
        userId: 'u-1',
        categoryId: 'cat-travel',
        name: 'Travel',
        amount: 3000.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 9, 1),
      );

      final foodProgress = await service.calculateProgress(
        foodBudget,
        referenceDate: refDate,
      );
      expect(foodProgress.spent, 4200.0);
      expect(foodProgress.isWarning, true); // 4200 >= 4000 (80%)
      expect(foodProgress.status, BudgetStatus.warning);

      final travelProgress = await service.calculateProgress(
        travelBudget,
        referenceDate: refDate,
      );
      expect(travelProgress.spent, 3100.0);
      expect(travelProgress.isOverBudget, true); // 3100 > 3000
      expect(travelProgress.overBudgetAmount, 100.0);
      expect(travelProgress.status, BudgetStatus.overBudget);
    });

    test('calculateAllProgress computes metrics concurrently for list of budgets', () async {
      final fakeRepo = _FakeTransactionRepository(
        overallExpenseTotal: 10000.0,
        categoryExpenseTotals: {'cat-1': 2000.0, 'cat-2': 500.0},
      );
      final service = BudgetCalculationService(fakeRepo);

      final budgets = [
        BudgetModel(
          id: 'b-1',
          userId: 'u-1',
          categoryId: 'cat-1',
          name: 'Cat 1',
          amount: 4000.0,
          period: BudgetPeriod.monthly,
          startDate: DateTime(2026, 9, 1),
        ),
        BudgetModel(
          id: 'b-2',
          userId: 'u-1',
          categoryId: 'cat-2',
          name: 'Cat 2',
          amount: 1000.0,
          period: BudgetPeriod.monthly,
          startDate: DateTime(2026, 9, 1),
        ),
      ];

      final results = await service.calculateAllProgress(
        budgets,
        referenceDate: refDate,
      );

      expect(results.length, 2);
      expect(results[0].spent, 2000.0);
      expect(results[1].spent, 500.0);
    });
  });
}
