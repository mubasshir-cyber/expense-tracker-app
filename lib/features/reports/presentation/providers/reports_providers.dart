import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/accounts/presentation/providers/account_providers.dart';
import '../../../../features/transactions/data/repositories/transaction_repository.dart';
import '../../../../features/transactions/domain/models/transaction_model.dart';
import '../../../../features/transactions/domain/models/transaction_type.dart';
import '../../../../features/transactions/presentation/providers/data_providers.dart';
import '../../../../features/transactions/presentation/providers/transaction_repository_provider.dart';
import '../../domain/models/financial_report.dart';
import '../../domain/models/report_granularity.dart';
import '../../domain/models/report_period.dart';
import '../../domain/services/reports_analytics_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Filter State
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable state for the active report filter.
class ReportFilter {
  const ReportFilter({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.granularity,
  });

  final ReportPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final ReportGranularity granularity;

  /// Factory for a preset period.
  factory ReportFilter.forPeriod(ReportPeriod period, [DateTime? now]) {
    final (start, end) = period.dateRange(now);
    return ReportFilter(
      period: period,
      startDate: start,
      endDate: end,
      granularity: period.defaultGranularity,
    );
  }

  /// Factory for a custom date range.
  ///
  /// Throws [ArgumentError] if [startDate] is after [endDate].
  factory ReportFilter.custom({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (startDate.isAfter(endDate)) {
      throw ArgumentError('startDate must not be after endDate.');
    }
    // Choose granularity based on range length
    final days = endDate.difference(startDate).inDays;
    final ReportGranularity granularity;
    if (days <= 31) {
      granularity = ReportGranularity.daily;
    } else if (days <= 90) {
      granularity = ReportGranularity.weekly;
    } else {
      granularity = ReportGranularity.monthly;
    }
    return ReportFilter(
      period: ReportPeriod.custom,
      startDate: startDate,
      endDate: endDate,
      granularity: granularity,
    );
  }

  ReportFilter copyWith({
    ReportPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    ReportGranularity? granularity,
  }) {
    return ReportFilter(
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      granularity: granularity ?? this.granularity,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Notifier
// ─────────────────────────────────────────────────────────────────────────────

class ReportFilterNotifier extends StateNotifier<ReportFilter> {
  ReportFilterNotifier()
      : super(ReportFilter.forPeriod(ReportPeriod.thisMonth));

  void setPeriod(ReportPeriod period) {
    if (period == ReportPeriod.custom) return; // use setCustomRange for custom
    state = ReportFilter.forPeriod(period);
  }

  /// Sets a single day filter (start of day to end of day).
  void setSingleDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    state = ReportFilter(
      period: ReportPeriod.custom,
      startDate: start,
      endDate: end,
      granularity: ReportGranularity.daily,
    );
  }

  /// Sets a custom date range. Returns false if [start] > [end].
  bool setCustomRange(DateTime start, DateTime end) {
    if (start.isAfter(end)) return false;
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    state = ReportFilter.custom(startDate: normalizedStart, endDate: normalizedEnd);
    return true;
  }
}

/// The single report filter — all providers below depend on this.
final reportFilterProvider =
    StateNotifierProvider<ReportFilterNotifier, ReportFilter>(
  (ref) => ReportFilterNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// ONE filtered transaction fetch for the entire Reports screen.
/// All analytics derive from this dataset.
final reportTransactionsProvider =
    FutureProvider<List<TransactionModel>>((ref) async {
  final filter = ref.watch(reportFilterProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactions(
    filter: TransactionFilter(
      from: filter.startDate,
      to: filter.endDate,
    ),
  );
});

/// Computes the net opening balance prior to the active filter's start date.
final openingBalanceProvider = FutureProvider<double>((ref) async {
  final filter = ref.watch(reportFilterProvider);
  final repo = ref.watch(transactionRepositoryProvider);

  final beforeStart = filter.startDate.subtract(const Duration(microseconds: 1));
  final priorCredits = await repo.sumByType(
    type: TransactionType.credit,
    to: beforeStart,
  );
  final priorExpenses = await repo.sumByType(
    type: TransactionType.expense,
    to: beforeStart,
  );
  return priorCredits - priorExpenses;
});

/// Map of categoryId → category name (resolved once, reused by analytics).
final _categoryNameMapProvider =
    FutureProvider<Map<String, String>>((ref) async {
  final categories = await ref.watch(categoriesProvider.future);
  return {for (final c in categories) c.id: c.name};
});

/// Map of accountId → account name (resolved once, reused by analytics).
final _accountNameMapProvider =
    FutureProvider<Map<String, String>>((ref) async {
  final accounts = await ref.watch(allAccountsProvider.future);
  return {for (final a in accounts) a.id: a.name};
});

// ─────────────────────────────────────────────────────────────────────────────
// Analytics Provider — the single computed FinancialReport
// ─────────────────────────────────────────────────────────────────────────────

const _analyticsService = ReportsAnalyticsService();

/// Computes the full [FinancialReport] from the filtered transaction dataset and opening balance.
///
/// This is the ONLY provider the UI widgets should consume for financial data.
/// All charts, cards, and breakdowns read from this report.
final financialReportProvider = FutureProvider<FinancialReport>((ref) async {
  final filter = ref.watch(reportFilterProvider);
  final transactions = await ref.watch(reportTransactionsProvider.future);
  final openingBalance = await ref.watch(openingBalanceProvider.future);
  final categoryNames = await ref.watch(_categoryNameMapProvider.future);
  final accountNames = await ref.watch(_accountNameMapProvider.future);

  return _analyticsService.compute(
    transactions: transactions,
    openingBalance: openingBalance,
    categoryNames: categoryNames,
    accountNames: accountNames,
    granularity: filter.granularity,
  );
});
