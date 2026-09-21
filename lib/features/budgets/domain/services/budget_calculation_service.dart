import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../../transactions/domain/models/transaction_type.dart';
import '../models/budget_model.dart';
import '../models/budget_progress.dart';

/// Calculates live budget progress strictly from actual transactions in [TransactionRepository].
class BudgetCalculationService {
  BudgetCalculationService(this._transactionRepository);

  final TransactionRepository _transactionRepository;

  /// Calculates dynamic spending progress for a single [budget].
  Future<BudgetProgress> calculateProgress(
    BudgetModel budget, {
    DateTime? referenceDate,
  }) async {
    final now = referenceDate ?? DateTime.now();
    final dateRange = budget.period.calculateDateRange(
      now,
      customStart: budget.startDate,
      customEnd: budget.endDate,
    );

    final double spent;
    if (budget.isOverallBudget) {
      // Sum all expenses across all categories within the period
      spent = await _transactionRepository.sumByType(
        type: TransactionType.expense,
        from: dateRange.start,
        to: dateRange.end,
      );
    } else {
      // Sum expenses exclusively for the target category
      spent = await _transactionRepository.sumByType(
        type: TransactionType.expense,
        categoryId: budget.categoryId,
        from: dateRange.start,
        to: dateRange.end,
      );
    }

    return BudgetProgress(
      budget: budget,
      spent: spent,
      effectiveStartDate: dateRange.start,
      effectiveEndDate: dateRange.end,
    );
  }

  /// Calculates dynamic spending progress for a list of [budgets].
  Future<List<BudgetProgress>> calculateAllProgress(
    List<BudgetModel> budgets, {
    DateTime? referenceDate,
  }) async {
    final futures = budgets.map(
      (budget) => calculateProgress(budget, referenceDate: referenceDate),
    );
    return Future.wait(futures);
  }
}
