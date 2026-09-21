import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/features/transactions/data/repositories/transaction_repository.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_type.dart';
import 'package:expense_tracker/features/transactions/domain/services/financial_calculation_service.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Fake TransactionRepository — no Supabase, no network.
// Stores per-type totals keyed by (type, accountId?) so the service can sum.
// ──────────────────────────────────────────────────────────────────────────────
class _FakeTransactionRepository implements TransactionRepository {
  _FakeTransactionRepository({
    required this.creditTotal,
    required this.expenseTotal,
    this.accountCreditTotals = const {},
    this.accountExpenseTotals = const {},
  });

  final double creditTotal;
  final double expenseTotal;

  /// Per-account overrides: accountId → total.
  final Map<String, double> accountCreditTotals;
  final Map<String, double> accountExpenseTotals;

  @override
  Future<double> sumByType({
    required TransactionType type,
    String? accountId,
    String? categoryId,
    DateTime? from,
    DateTime? to,
  }) async {
    if (type == TransactionType.credit) {
      if (accountId != null) {
        return accountCreditTotals[accountId] ?? 0.0;
      }
      return creditTotal;
    } else {
      if (accountId != null) {
        return accountExpenseTotals[accountId] ?? 0.0;
      }
      return expenseTotal;
    }
  }

  // ── Remaining interface members not used by FinancialCalculationService ────
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

// ──────────────────────────────────────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────────────────────────────────────
void main() {
  group('FinancialSummary', () {
    test('netBalance = totalCredit - totalExpense', () {
      const summary = FinancialSummary(
        totalCredit: 60000,
        totalExpense: 7000,
      );

      expect(summary.totalCredit, 60000);
      expect(summary.totalExpense, 7000);
      expect(summary.netBalance, 53000);
    });

    test('zero transactions give zero net balance', () {
      const summary = FinancialSummary(
        totalCredit: 0,
        totalExpense: 0,
      );

      expect(summary.netBalance, 0);
    });

    test('only credits — net balance equals total credit', () {
      const summary = FinancialSummary(
        totalCredit: 50000,
        totalExpense: 0,
      );

      expect(summary.netBalance, 50000);
    });

    test('only expenses — net balance is negative', () {
      const summary = FinancialSummary(
        totalCredit: 0,
        totalExpense: 2000,
      );

      expect(summary.netBalance, -2000);
    });

    test('decimal amounts are handled precisely', () {
      const summary = FinancialSummary(
        totalCredit: 1234.56,
        totalExpense: 789.01,
      );

      expect(summary.netBalance, closeTo(445.55, 0.001));
    });

    test('toString contains credit, expense, net', () {
      const summary = FinancialSummary(
        totalCredit: 100,
        totalExpense: 40,
      );

      final str = summary.toString();
      expect(str, contains('credit'));
      expect(str, contains('expense'));
      expect(str, contains('net'));
    });
  });

  group('FinancialCalculationService.getOverallSummary', () {
    test(
      'calculates net balance correctly — '
      'opening ₹10,000 + credit ₹5,000 − expense ₹2,000 = ₹13,000',
      () async {
        final repo = _FakeTransactionRepository(
          creditTotal: 15000, // ₹10,000 opening + ₹5,000
          expenseTotal: 2000,
        );
        final service = FinancialCalculationService(repo);

        final summary = await service.getOverallSummary();

        expect(summary.totalCredit, 15000);
        expect(summary.totalExpense, 2000);
        expect(summary.netBalance, 13000);
      },
    );

    test(
      'explicit example: credit ₹50,000 + ₹10,000 — expense ₹2,000 + ₹5,000',
      () async {
        final repo = _FakeTransactionRepository(
          creditTotal: 60000,
          expenseTotal: 7000,
        );
        final service = FinancialCalculationService(repo);

        final summary = await service.getOverallSummary();

        expect(summary.totalCredit, 60000);
        expect(summary.totalExpense, 7000);
        expect(summary.netBalance, 53000);
      },
    );

    test('zero transactions give zero summary', () async {
      final repo = _FakeTransactionRepository(
        creditTotal: 0,
        expenseTotal: 0,
      );
      final service = FinancialCalculationService(repo);

      final summary = await service.getOverallSummary();

      expect(summary.totalCredit, 0);
      expect(summary.totalExpense, 0);
      expect(summary.netBalance, 0);
    });

    test('only credits scenario', () async {
      final repo = _FakeTransactionRepository(
        creditTotal: 75000,
        expenseTotal: 0,
      );
      final service = FinancialCalculationService(repo);

      final summary = await service.getOverallSummary();

      expect(summary.netBalance, 75000);
    });

    test('only expenses scenario — negative balance', () async {
      final repo = _FakeTransactionRepository(
        creditTotal: 0,
        expenseTotal: 5000,
      );
      final service = FinancialCalculationService(repo);

      final summary = await service.getOverallSummary();

      expect(summary.netBalance, -5000);
    });

    test('decimal amounts are handled correctly', () async {
      final repo = _FakeTransactionRepository(
        creditTotal: 999.99,
        expenseTotal: 0.01,
      );
      final service = FinancialCalculationService(repo);

      final summary = await service.getOverallSummary();

      expect(summary.netBalance, closeTo(999.98, 0.001));
    });

    test('large amounts do not overflow', () async {
      final repo = _FakeTransactionRepository(
        creditTotal: 9999999.99,
        expenseTotal: 1234567.89,
      );
      final service = FinancialCalculationService(repo);

      final summary = await service.getOverallSummary();

      expect(summary.netBalance, closeTo(8765432.10, 0.01));
    });
  });

  group('FinancialCalculationService.getAccountBalance', () {
    test('returns credit − expense for a specific account', () async {
      final repo = _FakeTransactionRepository(
        creditTotal: 0,
        expenseTotal: 0,
        accountCreditTotals: {'acc-1': 20000, 'acc-2': 5000},
        accountExpenseTotals: {'acc-1': 3000, 'acc-2': 1000},
      );
      final service = FinancialCalculationService(repo);

      final balance = await service.getAccountBalance('acc-1');

      expect(balance, 17000);
    });

    test('different accounts return independent balances', () async {
      final repo = _FakeTransactionRepository(
        creditTotal: 0,
        expenseTotal: 0,
        accountCreditTotals: {'acc-1': 20000, 'acc-2': 5000},
        accountExpenseTotals: {'acc-1': 3000, 'acc-2': 1000},
      );
      final service = FinancialCalculationService(repo);

      final bal1 = await service.getAccountBalance('acc-1');
      final bal2 = await service.getAccountBalance('acc-2');

      expect(bal1, 17000);
      expect(bal2, 4000);
    });

    test('account with no transactions returns 0', () async {
      final repo = _FakeTransactionRepository(
        creditTotal: 0,
        expenseTotal: 0,
      );
      final service = FinancialCalculationService(repo);

      final balance = await service.getAccountBalance('acc-unknown');

      expect(balance, 0);
    });
  });

  group('FinancialCalculationService.getCurrentMonthSummary', () {
    test('delegates to getOverallSummary with a date range', () async {
      // The fake ignores date range; we just verify the summary is returned.
      final repo = _FakeTransactionRepository(
        creditTotal: 12000,
        expenseTotal: 4000,
      );
      final service = FinancialCalculationService(repo);

      final summary = await service.getCurrentMonthSummary();

      expect(summary.totalCredit, 12000);
      expect(summary.totalExpense, 4000);
      expect(summary.netBalance, 8000);
    });
  });
}
