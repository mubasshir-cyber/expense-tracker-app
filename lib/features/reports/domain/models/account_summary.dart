/// Aggregated financial activity for a single account within a report period.
class AccountSummary {
  const AccountSummary({
    required this.accountId,
    required this.accountName,
    required this.totalCredits,
    required this.totalExpenses,
    required this.transactionCount,
  });

  final String accountId;
  final String accountName;
  final double totalCredits;
  final double totalExpenses;
  final int transactionCount;

  /// Net activity = credits − expenses.
  double get netActivity => totalCredits - totalExpenses;

  @override
  String toString() =>
      'AccountSummary($accountName: credits=$totalCredits, expenses=$totalExpenses)';
}
