import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../transactions/presentation/providers/data_providers.dart';
import '../../../transactions/presentation/providers/transaction_repository_provider.dart';
import '../../domain/models/recurring_transaction_model.dart';
import '../../domain/services/recurring_schedule_service.dart';
import 'recurring_repository_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Service Provider
// ──────────────────────────────────────────────────────────────────────────────

final recurringScheduleServiceProvider =
    Provider<RecurringScheduleService>((ref) {
  return RecurringScheduleService(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    recurringRepository: ref.watch(recurringRepositoryProvider),
  );
});

// ──────────────────────────────────────────────────────────────────────────────
// Data Providers
// ──────────────────────────────────────────────────────────────────────────────

/// All recurring templates for the current user.
final allRecurringTransactionsProvider =
    FutureProvider<List<RecurringTransactionModel>>((ref) async {
  final repo = ref.watch(recurringRepositoryProvider);
  return repo.getRecurringTransactions(activeOnly: false);
});

/// Active recurring templates only.
final activeRecurringTransactionsProvider =
    FutureProvider<List<RecurringTransactionModel>>((ref) async {
  final repo = ref.watch(recurringRepositoryProvider);
  return repo.getRecurringTransactions(activeOnly: true);
});

/// Upcoming recurring items occurring within the next 30 days.
final upcomingRecurringProvider =
    FutureProvider<List<RecurringTransactionModel>>((ref) async {
  final activeList =
      await ref.watch(activeRecurringTransactionsProvider.future);
  final service = ref.watch(recurringScheduleServiceProvider);
  return service.findUpcoming(activeList, daysAhead: 30);
});

// ──────────────────────────────────────────────────────────────────────────────
// Controller Provider
// ──────────────────────────────────────────────────────────────────────────────

class RecurringController extends StateNotifier<AsyncValue<void>> {
  RecurringController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  void _invalidateAll() {
    _ref.invalidate(allRecurringTransactionsProvider);
    _ref.invalidate(activeRecurringTransactionsProvider);
    _ref.invalidate(upcomingRecurringProvider);
    // Invalidate ledger & analytics
    _ref.invalidate(allTransactionsProvider);
    _ref.invalidate(recentTransactionsProvider);
    _ref.invalidate(overallSummaryProvider);
    _ref.invalidate(currentMonthSummaryProvider);
    _ref.invalidate(accountsProvider);
    _ref.invalidate(activeBudgetsProgressProvider);
  }

  Future<void> createRecurring({
    required String accountId,
    required String categoryId,
    required String type,
    required double amount,
    required String description,
    required String frequency,
    required DateTime startDate,
    required DateTime nextOccurrence,
    DateTime? endDate,
    bool isActive = true,
    bool autoCreate = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(recurringRepositoryProvider);
      await repo.createRecurringTransaction(
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        description: description,
        frequency: frequency,
        startDate: startDate,
        nextOccurrence: nextOccurrence,
        endDate: endDate,
        isActive: isActive,
        autoCreate: autoCreate,
      );
      _invalidateAll();
    });
  }

  Future<void> updateRecurring(RecurringTransactionModel item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(recurringRepositoryProvider);
      await repo.updateRecurringTransaction(item);
      _invalidateAll();
    });
  }

  /// Records a concrete ledger entry and advances the recurring cycle.
  Future<void> recordOccurrence(
    RecurringTransactionModel item, {
    DateTime? executionDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = _ref.read(recurringScheduleServiceProvider);
      await service.processRecurringOccurrence(
        item,
        executionDate: executionDate,
      );
      _invalidateAll();
    });
  }

  Future<void> toggleActive(String id, bool isActive) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(recurringRepositoryProvider);
      await repo.toggleActive(id, isActive);
      _invalidateAll();
    });
  }

  Future<void> deleteRecurring(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(recurringRepositoryProvider);
      await repo.deleteRecurringTransaction(id);
      _invalidateAll();
    });
  }

  /// Automatically creates ledger entries for due items with autoCreate = true.
  Future<int> autoProcessDueItems() async {
    final activeList =
        await _ref.read(activeRecurringTransactionsProvider.future);
    final service = _ref.read(recurringScheduleServiceProvider);
    final count = await service.processAutoCreateDueItems(activeList);
    if (count > 0) {
      _invalidateAll();
    }
    return count;
  }
}

final recurringControllerProvider =
    StateNotifierProvider<RecurringController, AsyncValue<void>>((ref) {
  return RecurringController(ref);
});
