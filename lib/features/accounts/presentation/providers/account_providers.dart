import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transactions/domain/services/financial_calculation_service.dart';
import '../../../transactions/presentation/providers/transaction_repository_provider.dart';
import '../../domain/models/account_model.dart';
import 'account_repository_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Service provider
// ──────────────────────────────────────────────────────────────────────────────

final financialCalculationServiceProvider =
    Provider<FinancialCalculationService>((ref) {
  return FinancialCalculationService(
    ref.watch(transactionRepositoryProvider),
  );
});

// ──────────────────────────────────────────────────────────────────────────────
// Account data providers
// ──────────────────────────────────────────────────────────────────────────────

/// All active accounts for the current user.
final accountsProvider = FutureProvider<List<AccountModel>>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.getAccounts();
});

/// All accounts (including inactive) for the current user.
final allAccountsProvider = FutureProvider<List<AccountModel>>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.getAccounts(activeOnly: false);
});

/// A single account by [id].
final accountProvider =
    FutureProvider.family<AccountModel, String>((ref, id) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.getAccount(id);
});

/// Computed balance (income − expense) for a single account [id].
final accountBalanceProvider =
    FutureProvider.family<double, String>((ref, accountId) {
  final service = ref.watch(financialCalculationServiceProvider);
  return service.getAccountBalance(accountId);
});
