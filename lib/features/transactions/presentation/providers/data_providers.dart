import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/domain/models/category_model.dart';
import '../../../categories/presentation/providers/category_repository_provider.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/services/financial_calculation_service.dart';
import 'transaction_repository_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Category data providers
// ──────────────────────────────────────────────────────────────────────────────

/// All categories visible to the current user (system + own custom).
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getCategories();
});

/// Expense categories only.
final expenseCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getCategories(type: 'expense');
});

/// Income / credit categories only.
final incomeCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getCategories(type: 'income');
});

// ──────────────────────────────────────────────────────────────────────────────
// Transaction data providers
// ──────────────────────────────────────────────────────────────────────────────

/// Transactions for the current user with an optional [TransactionFilter].
final transactionsProvider =
    FutureProvider.family<List<TransactionModel>, TransactionFilter>(
        (ref, filter) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactions(filter: filter);
});

/// All transactions for the current user (no filter applied).
final allTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactions();
});

/// Recent transactions for Dashboard (limit 5).
final recentTransactionsProvider =
    FutureProvider<List<TransactionModel>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactions(filter: const TransactionFilter(limit: 5));
});

// ──────────────────────────────────────────────────────────────────────────────
// Financial summary providers
// ──────────────────────────────────────────────────────────────────────────────

/// Overall financial summary (all time) for the current user.
final overallSummaryProvider = FutureProvider<FinancialSummary>((ref) {
  final service = ref.watch(financialCalculationServiceProvider);
  return service.getOverallSummary();
});

/// Financial summary for the current calendar month.
final currentMonthSummaryProvider = FutureProvider<FinancialSummary>((ref) {
  final service = ref.watch(financialCalculationServiceProvider);
  return service.getCurrentMonthSummary();
});
