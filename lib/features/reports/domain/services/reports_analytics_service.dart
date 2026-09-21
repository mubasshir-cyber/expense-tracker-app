import '../../../transactions/domain/models/transaction_model.dart';
import '../../../transactions/domain/models/transaction_type.dart';
import '../models/account_summary.dart';
import '../models/category_expense_summary.dart';
import '../models/financial_report.dart';
import '../models/report_granularity.dart';
import '../models/trend_point.dart';

/// Pure aggregation service for the Reports module.
///
/// Takes a pre-fetched [List<TransactionModel>] (already filtered by date/user)
/// and computes all analytics in memory — no async, no Supabase, no side-effects.
///
/// Design contract:
/// - Never returns NaN or Infinity.
/// - Safe for empty lists / zero values.
/// - Category and account names are resolved via caller-provided maps.
class ReportsAnalyticsService {
  const ReportsAnalyticsService();

  /// Compute the full [FinancialReport] from [transactions].
  ///
  /// [categoryNames] maps category_id → display name.
  /// [accountNames]  maps account_id  → display name.
  /// [granularity]   controls how trendPoints are bucketed.
  FinancialReport compute({
    required List<TransactionModel> transactions,
    required Map<String, String> categoryNames,
    required Map<String, String> accountNames,
    required ReportGranularity granularity,
    double openingBalance = 0.0,
  }) {
    if (transactions.isEmpty) {
      return FinancialReport(
        openingBalance: openingBalance,
        totalCredits: 0,
        totalExpenses: 0,
        transactionCount: 0,
        creditCount: 0,
        expenseCount: 0,
        averageExpense: 0,
        largestExpense: 0,
        averageCredit: 0,
        largestCredit: 0,
        expenseCategories: const [],
        creditCategories: const [],
        accountSummaries: const [],
        trendPoints: const [],
      );
    }

    // ── Partition ─────────────────────────────────────────────────────────────
    final expenses = transactions
        .where((t) => t.type.toUpperCase() == TransactionType.expense.value)
        .toList();
    final credits = transactions
        .where((t) => t.type.toUpperCase() == TransactionType.credit.value)
        .toList();

    // ── Totals ────────────────────────────────────────────────────────────────
    final totalExpenses = _sum(expenses);
    final totalCredits = _sum(credits);

    // ── Averages ──────────────────────────────────────────────────────────────
    final averageExpense =
        expenses.isEmpty ? 0.0 : totalExpenses / expenses.length;
    final averageCredit =
        credits.isEmpty ? 0.0 : totalCredits / credits.length;

    // ── Largest ───────────────────────────────────────────────────────────────
    final largestExpense = expenses.isEmpty
        ? 0.0
        : expenses.map((t) => t.amount).reduce((a, b) => a > b ? a : b);
    final largestCredit = credits.isEmpty
        ? 0.0
        : credits.map((t) => t.amount).reduce((a, b) => a > b ? a : b);

    // ── Category breakdown ────────────────────────────────────────────────────
    final expenseCategories = _buildCategoryBreakdown(
      expenses,
      totalExpenses,
      categoryNames,
    );
    final creditCategories = _buildCategoryBreakdown(
      credits,
      totalCredits,
      categoryNames,
    );

    // ── Account breakdown ─────────────────────────────────────────────────────
    final accountSummaries = _buildAccountBreakdown(
      transactions,
      accountNames,
    );

    // ── Trend points ──────────────────────────────────────────────────────────
    final trendPoints = _buildTrendPoints(transactions, granularity);

    return FinancialReport(
      openingBalance: openingBalance,
      totalCredits: totalCredits,
      totalExpenses: totalExpenses,
      transactionCount: transactions.length,
      creditCount: credits.length,
      expenseCount: expenses.length,
      averageExpense: averageExpense,
      largestExpense: largestExpense,
      averageCredit: averageCredit,
      largestCredit: largestCredit,
      expenseCategories: expenseCategories,
      creditCategories: creditCategories,
      accountSummaries: accountSummaries,
      trendPoints: trendPoints,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ───────────────────────────────────────────────────────────────────────────

  double _sum(List<TransactionModel> list) =>
      list.fold(0.0, (acc, t) => acc + t.amount);

  List<CategoryExpenseSummary> _buildCategoryBreakdown(
    List<TransactionModel> txns,
    double periodTotal,
    Map<String, String> categoryNames,
  ) {
    if (txns.isEmpty) return [];

    // Group by categoryId
    final Map<String, _CategoryAccum> grouped = {};
    for (final t in txns) {
      final accum = grouped.putIfAbsent(
        t.categoryId,
        () => _CategoryAccum(t.categoryId),
      );
      accum.total += t.amount;
      accum.count++;
    }

    // Convert to summaries
    final summaries = grouped.values.map((accum) {
      final name = categoryNames[accum.categoryId] ?? 'Unknown';
      final pct = periodTotal > 0 ? (accum.total / periodTotal) * 100.0 : 0.0;
      return CategoryExpenseSummary(
        categoryId: accum.categoryId,
        categoryName: name,
        total: accum.total,
        count: accum.count,
        percentage: pct,
      );
    }).toList();

    // Sort descending by total
    summaries.sort((a, b) => b.total.compareTo(a.total));
    return summaries;
  }

  List<AccountSummary> _buildAccountBreakdown(
    List<TransactionModel> txns,
    Map<String, String> accountNames,
  ) {
    if (txns.isEmpty) return [];

    final Map<String, _AccountAccum> grouped = {};
    for (final t in txns) {
      final accum = grouped.putIfAbsent(
        t.accountId,
        () => _AccountAccum(t.accountId),
      );
      if (t.type.toUpperCase() == TransactionType.credit.value) {
        accum.totalCredits += t.amount;
      } else {
        accum.totalExpenses += t.amount;
      }
      accum.count++;
    }

    final summaries = grouped.values.map((accum) {
      final name = accountNames[accum.accountId] ?? 'Unknown';
      return AccountSummary(
        accountId: accum.accountId,
        accountName: name,
        totalCredits: accum.totalCredits,
        totalExpenses: accum.totalExpenses,
        transactionCount: accum.count,
      );
    }).toList();

    // Sort by total activity descending
    summaries.sort(
      (a, b) => (b.totalCredits + b.totalExpenses)
          .compareTo(a.totalCredits + a.totalExpenses),
    );
    return summaries;
  }

  List<TrendPoint> _buildTrendPoints(
    List<TransactionModel> txns,
    ReportGranularity granularity,
  ) {
    if (txns.isEmpty) return [];

    final Map<DateTime, _TrendAccum> buckets = {};

    for (final t in txns) {
      final bucket = _bucketKey(t.transactionDate.toLocal(), granularity);
      final accum = buckets.putIfAbsent(bucket, () => _TrendAccum(bucket));
      if (t.type.toUpperCase() == TransactionType.credit.value) {
        accum.credits += t.amount;
      } else {
        accum.expenses += t.amount;
      }
    }

    final points = buckets.values
        .map((a) => TrendPoint(date: a.date, credits: a.credits, expenses: a.expenses))
        .toList();

    // Sort ascending by date
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  /// Returns the canonical start-of-bucket DateTime for [date] given [granularity].
  DateTime _bucketKey(DateTime date, ReportGranularity granularity) {
    switch (granularity) {
      case ReportGranularity.daily:
        return DateTime(date.year, date.month, date.day);
      case ReportGranularity.weekly:
        // Snap to the most recent Monday
        final weekday = date.weekday; // 1=Mon … 7=Sun
        return DateTime(date.year, date.month, date.day - (weekday - 1));
      case ReportGranularity.monthly:
        return DateTime(date.year, date.month);
    }
  }
}

// ─── Internal accumulator classes ─────────────────────────────────────────────

class _CategoryAccum {
  _CategoryAccum(this.categoryId);
  final String categoryId;
  double total = 0;
  int count = 0;
}

class _AccountAccum {
  _AccountAccum(this.accountId);
  final String accountId;
  double totalCredits = 0;
  double totalExpenses = 0;
  int count = 0;
}

class _TrendAccum {
  _TrendAccum(this.date);
  final DateTime date;
  double credits = 0;
  double expenses = 0;
}
