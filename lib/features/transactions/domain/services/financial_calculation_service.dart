import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../../transactions/domain/models/transaction_type.dart';

/// Results from a financial summary calculation.
class FinancialSummary {
  const FinancialSummary({
    required this.totalCredit,
    required this.totalExpense,
  });

  final double totalCredit;
  final double totalExpense;

  double get netBalance => totalCredit - totalExpense;

  @override
  String toString() {
    return 'FinancialSummary('
        'credit: $totalCredit, '
        'expense: $totalExpense, '
        'net: $netBalance'
        ')';
  }
}

/// Derives financial summaries from [TransactionRepository].
///
/// Balances are computed from transactions — not stored on accounts —
/// which is the source of truth per the schema design.
class FinancialCalculationService {
  FinancialCalculationService(this._transactionRepository);

  final TransactionRepository _transactionRepository;

  /// Returns the net balance for a specific account.
  Future<double> getAccountBalance(String accountId) async {
    final credit = await _transactionRepository.sumByType(
      type: TransactionType.credit,
      accountId: accountId,
    );

    final expense = await _transactionRepository.sumByType(
      type: TransactionType.expense,
      accountId: accountId,
    );

    return credit - expense;
  }

  /// Returns total income, total expense, and net balance
  /// across all accounts for the current user.
  Future<FinancialSummary> getOverallSummary({
    DateTime? from,
    DateTime? to,
  }) async {
    final credit = await _transactionRepository.sumByType(
      type: TransactionType.credit,
      from: from,
      to: to,
    );

    final expense = await _transactionRepository.sumByType(
      type: TransactionType.expense,
      from: from,
      to: to,
    );

    return FinancialSummary(
      totalCredit: credit,
      totalExpense: expense,
    );
  }

  /// Returns the current month's income, expense, and net balance.
  Future<FinancialSummary> getCurrentMonthSummary() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month);
    final to = DateTime(now.year, now.month + 1).subtract(
      const Duration(microseconds: 1),
    );

    return getOverallSummary(from: from, to: to);
  }
}
