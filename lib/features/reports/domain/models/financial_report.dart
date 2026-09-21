import 'account_summary.dart';
import 'category_expense_summary.dart';
import 'trend_point.dart';

/// The single aggregated analytics result for the Reports screen.
///
/// Computed by [ReportsAnalyticsService] from a filtered list of transactions.
/// Every widget on the Reports screen reads from this model — there is no
/// separate data source per chart.
class FinancialReport {
  const FinancialReport({
    this.openingBalance = 0.0,
    required this.totalCredits,
    required this.totalExpenses,
    required this.transactionCount,
    required this.creditCount,
    required this.expenseCount,
    required this.averageExpense,
    required this.largestExpense,
    required this.averageCredit,
    required this.largestCredit,
    required this.expenseCategories,
    required this.creditCategories,
    required this.accountSummaries,
    required this.trendPoints,
  });

  /// Balance prior to the selected period start date.
  final double openingBalance;

  final double totalCredits;
  final double totalExpenses;
  final int transactionCount;
  final int creditCount;
  final int expenseCount;

  final double averageExpense;
  final double largestExpense;
  final double averageCredit;
  final double largestCredit;

  /// Top expense categories sorted by total descending.
  final List<CategoryExpenseSummary> expenseCategories;

  /// Top credit categories sorted by total descending.
  final List<CategoryExpenseSummary> creditCategories;

  /// Per-account breakdown.
  final List<AccountSummary> accountSummaries;

  /// Time-series data for trend charts.
  final List<TrendPoint> trendPoints;

  /// Net cash flow = total credits − total expenses.
  double get netCashFlow => totalCredits - totalExpenses;

  /// Closing balance = openingBalance + netCashFlow.
  double get closingBalance => openingBalance + netCashFlow;

  /// True when there are no transactions in the selected period.
  bool get isEmpty => transactionCount == 0;

  /// An empty report (zero period / no transactions).
  static const FinancialReport empty = FinancialReport(
    openingBalance: 0,
    totalCredits: 0,
    totalExpenses: 0,
    transactionCount: 0,
    creditCount: 0,
    expenseCount: 0,
    averageExpense: 0,
    largestExpense: 0,
    averageCredit: 0,
    largestCredit: 0,
    expenseCategories: [],
    creditCategories: [],
    accountSummaries: [],
    trendPoints: [],
  );
}
