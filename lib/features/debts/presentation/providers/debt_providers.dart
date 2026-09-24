import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../data/repositories/debt_repository.dart';
import '../../domain/models/debt_installment_model.dart';
import '../../domain/models/debt_model.dart';
import '../../domain/models/debt_repayment_model.dart';
import '../../domain/models/debt_summary.dart';
import '../../domain/models/debt_type.dart';
import '../../domain/services/debt_calculation_service.dart';

/// Pure domain calculation service provider.
final debtCalculationServiceProvider = Provider<DebtCalculationService>((ref) {
  return const DebtCalculationService();
});

/// Data repository provider.
final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  final calculationService = ref.watch(debtCalculationServiceProvider);
  return DebtRepository(
    SupabaseConfig.client,
    calculationService: calculationService,
  );
});

/// Stream/Future provider for all debts and loans.
final allDebtsProvider = FutureProvider<List<DebtModel>>((ref) async {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.getDebts();
});

/// Debts where the user owes money (Liabilities).
final youOweDebtsProvider = FutureProvider<List<DebtModel>>((ref) async {
  final all = await ref.watch(allDebtsProvider.future);
  return all.where((d) => d.type == DebtType.youOwe && !d.isSettled).toList();
});

/// Loans where the user is owed money (Assets).
final youAreOwedDebtsProvider = FutureProvider<List<DebtModel>>((ref) async {
  final all = await ref.watch(allDebtsProvider.future);
  return all.where((d) => d.type == DebtType.youAreOwed && !d.isSettled).toList();
});

/// Settled debts and loans.
final settledDebtsProvider = FutureProvider<List<DebtModel>>((ref) async {
  final all = await ref.watch(allDebtsProvider.future);
  return all.where((d) => d.isSettled).toList();
});

/// Summary provider aggregating portfolio net position and counts.
final debtSummaryProvider = FutureProvider<DebtSummary>((ref) async {
  final debts = await ref.watch(allDebtsProvider.future);
  final calc = ref.watch(debtCalculationServiceProvider);
  return calc.computeSummary(debts);
});

/// Single debt detail provider.
final debtDetailProvider = FutureProvider.family<DebtModel?, String>((ref, id) async {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.getDebt(id);
});

/// Installments list for a specific debt.
final debtInstallmentsProvider = FutureProvider.family<List<DebtInstallmentModel>, String>((ref, debtId) async {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.getInstallments(debtId);
});

/// Repayments ledger for a specific debt.
final debtRepaymentsProvider = FutureProvider.family<List<DebtRepaymentModel>, String>((ref, debtId) async {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.getRepayments(debtId);
});

/// Asynchronous state controller for mutating debts and repayments.
class DebtController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<DebtModel?> createDebt({
    required DebtModel debt,
    List<DebtInstallmentModel> installments = const [],
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(debtRepositoryProvider);
      final created = await repo.createDebt(debt: debt, installments: installments);
      _invalidateAll();
      state = const AsyncValue.data(null);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateDebt(DebtModel debt) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(debtRepositoryProvider);
      await repo.updateDebt(debt);
      _invalidateAll(debtId: debt.id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteDebt(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(debtRepositoryProvider);
      await repo.deleteDebt(id);
      _invalidateAll(debtId: id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<DebtRepaymentModel> recordRepayment({
    required String debtId,
    required double amount,
    required DateTime repaymentDate,
    String? accountId,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(debtRepositoryProvider);
      final created = await repo.addRepayment(
        debtId: debtId,
        amount: amount,
        repaymentDate: repaymentDate,
        accountId: accountId,
        notes: notes,
      );
      _invalidateAll(debtId: debtId);
      state = const AsyncValue.data(null);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteRepayment(String repaymentId, String debtId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(debtRepositoryProvider);
      await repo.deleteRepayment(repaymentId, debtId);
      _invalidateAll(debtId: debtId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void _invalidateAll({String? debtId}) {
    ref.invalidate(allDebtsProvider);
    ref.invalidate(youOweDebtsProvider);
    ref.invalidate(youAreOwedDebtsProvider);
    ref.invalidate(settledDebtsProvider);
    ref.invalidate(debtSummaryProvider);
    if (debtId != null) {
      ref.invalidate(debtDetailProvider(debtId));
      ref.invalidate(debtInstallmentsProvider(debtId));
      ref.invalidate(debtRepaymentsProvider(debtId));
    }
  }
}

final debtControllerProvider = AsyncNotifierProvider<DebtController, void>(() {
  return DebtController();
});
