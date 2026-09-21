import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transactions/presentation/providers/transaction_repository_provider.dart';
import '../../domain/models/budget_model.dart';
import '../../domain/models/budget_progress.dart';
import '../../domain/services/budget_calculation_service.dart';
import 'budget_repository_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Calculation Service Provider
// ──────────────────────────────────────────────────────────────────────────────

final budgetCalculationServiceProvider =
    Provider<BudgetCalculationService>((ref) {
  return BudgetCalculationService(
    ref.watch(transactionRepositoryProvider),
  );
});

// ──────────────────────────────────────────────────────────────────────────────
// Budget Data Providers
// ──────────────────────────────────────────────────────────────────────────────

/// All user budgets (active and inactive), excluding soft-deleted rows.
final allBudgetsProvider = FutureProvider<List<BudgetModel>>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getBudgets(activeOnly: false);
});

/// Active user budgets only.
final activeBudgetsProvider = FutureProvider<List<BudgetModel>>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getBudgets(activeOnly: true);
});

/// Live spending progress calculated from transactions for all active budgets.
final activeBudgetsProgressProvider =
    FutureProvider<List<BudgetProgress>>((ref) async {
  final activeBudgets = await ref.watch(activeBudgetsProvider.future);
  final calculationService = ref.watch(budgetCalculationServiceProvider);
  return calculationService.calculateAllProgress(activeBudgets);
});

/// Live spending progress for the overall monthly budget (if created and active).
final overallMonthlyBudgetProgressProvider =
    FutureProvider<BudgetProgress?>((ref) async {
  final activeBudgets = await ref.watch(activeBudgetsProvider.future);
  final calculationService = ref.watch(budgetCalculationServiceProvider);
  
  final overall = activeBudgets
      .where((b) => b.isOverallBudget)
      .firstOrNull;

  if (overall == null) return null;
  return calculationService.calculateProgress(overall);
});

/// Live spending progress for a specific budget instance.
final budgetProgressFamily =
    FutureProvider.family<BudgetProgress, BudgetModel>((ref, budget) async {
  final calculationService = ref.watch(budgetCalculationServiceProvider);
  return calculationService.calculateProgress(budget);
});

// ──────────────────────────────────────────────────────────────────────────────
// Budget Controller Provider
// ──────────────────────────────────────────────────────────────────────────────

class BudgetController extends StateNotifier<AsyncValue<void>> {
  BudgetController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  void _invalidateProviders() {
    _ref.invalidate(allBudgetsProvider);
    _ref.invalidate(activeBudgetsProvider);
    _ref.invalidate(activeBudgetsProgressProvider);
    _ref.invalidate(overallMonthlyBudgetProgressProvider);
  }

  Future<void> createBudget({
    String? categoryId,
    required String name,
    required double amount,
    required String period,
    required DateTime startDate,
    DateTime? endDate,
    double alertThreshold = 0.80,
    bool isActive = true,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(budgetRepositoryProvider);
      await repo.createBudget(
        categoryId: categoryId,
        name: name,
        amount: amount,
        period: period,
        startDate: startDate,
        endDate: endDate,
        alertThreshold: alertThreshold,
        isActive: isActive,
      );
      _invalidateProviders();
    });
  }

  Future<void> updateBudget(BudgetModel budget) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(budgetRepositoryProvider);
      await repo.updateBudget(budget);
      _invalidateProviders();
    });
  }

  Future<void> toggleBudgetActive(String id, bool isActive) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(budgetRepositoryProvider);
      await repo.toggleBudgetActive(id, isActive);
      _invalidateProviders();
    });
  }

  Future<void> deleteBudget(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(budgetRepositoryProvider);
      await repo.deleteBudget(id);
      _invalidateProviders();
    });
  }
}

final budgetControllerProvider =
    StateNotifierProvider<BudgetController, AsyncValue<void>>((ref) {
  return BudgetController(ref);
});
