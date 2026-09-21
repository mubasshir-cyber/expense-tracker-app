import 'package:expense_tracker/features/reports/domain/models/financial_report.dart';
import 'package:expense_tracker/features/reports/domain/models/report_granularity.dart';
import 'package:expense_tracker/features/reports/domain/services/reports_analytics_service.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ReportsAnalyticsService();
  const catNames = <String, String>{'cat-food': 'Food', 'cat-travel': 'Travel', 'cat-salary': 'Salary'};
  const accNames = <String, String>{'acc-bank': 'Bank', 'acc-cash': 'Cash'};

  // ─── Helper ───────────────────────────────────────────────────────────────

  TransactionModel expense({
    String id = 'e1',
    double amount = 100.0,
    String categoryId = 'cat-food',
    String accountId = 'acc-bank',
    DateTime? date,
  }) =>
      TransactionModel(
        id: id,
        userId: 'user1',
        accountId: accountId,
        categoryId: categoryId,
        type: 'EXPENSE',
        amount: amount,
        transactionDate: date ?? DateTime(2024, 9, 15),
      );

  TransactionModel credit({
    String id = 'c1',
    double amount = 500.0,
    String categoryId = 'cat-salary',
    String accountId = 'acc-bank',
    DateTime? date,
  }) =>
      TransactionModel(
        id: id,
        userId: 'user1',
        accountId: accountId,
        categoryId: categoryId,
        type: 'CREDIT',
        amount: amount,
        transactionDate: date ?? DateTime(2024, 9, 15),
      );

  // ─── Empty input ──────────────────────────────────────────────────────────

  group('empty input', () {
    test('returns FinancialReport.empty for empty list', () {
      final report = service.compute(
        transactions: [],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.totalCredits, 0.0);
      expect(report.totalExpenses, 0.0);
      expect(report.netCashFlow, 0.0);
      expect(report.transactionCount, 0);
      expect(report.expenseCategories, isEmpty);
      expect(report.creditCategories, isEmpty);
      expect(report.accountSummaries, isEmpty);
      expect(report.trendPoints, isEmpty);
      expect(report.isEmpty, isTrue);
    });

    test('FinancialReport.empty has zero values', () {
      expect(FinancialReport.empty.openingBalance, 0.0);
      expect(FinancialReport.empty.closingBalance, 0.0);
      expect(FinancialReport.empty.averageExpense, 0.0);
      expect(FinancialReport.empty.largestExpense, 0.0);
      expect(FinancialReport.empty.averageCredit, 0.0);
      expect(FinancialReport.empty.largestCredit, 0.0);
    });
  });

  // ─── Opening & Closing Balance ─────────────────────────────────────────────

  group('opening and closing balance', () {
    test('opening balance defaults to 0 and closing balance matches netCashFlow', () {
      final report = service.compute(
        transactions: [credit(amount: 500.0), expense(amount: 200.0)],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.openingBalance, 0.0);
      expect(report.netCashFlow, 300.0);
      expect(report.closingBalance, 300.0);
    });

    test('positive opening balance with negative net flow (e.g. yesterday 500, today -200 -> closing 300)', () {
      final report = service.compute(
        transactions: [expense(amount: 200.0)],
        openingBalance: 500.0,
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.openingBalance, 500.0);
      expect(report.totalExpenses, 200.0);
      expect(report.netCashFlow, -200.0);
      expect(report.closingBalance, 300.0);
    });

    test('empty transactions retains provided opening balance', () {
      final report = service.compute(
        transactions: [],
        openingBalance: 500.0,
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.openingBalance, 500.0);
      expect(report.netCashFlow, 0.0);
      expect(report.closingBalance, 500.0);
      expect(report.isEmpty, isTrue);
    });
  });

  // ─── Single transaction ───────────────────────────────────────────────────

  group('single transaction', () {
    test('single expense transaction', () {
      final report = service.compute(
        transactions: [expense(amount: 250.0)],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.totalExpenses, 250.0);
      expect(report.totalCredits, 0.0);
      expect(report.netCashFlow, -250.0);
      expect(report.transactionCount, 1);
      expect(report.expenseCount, 1);
      expect(report.creditCount, 0);
      expect(report.averageExpense, 250.0);
      expect(report.largestExpense, 250.0);
      expect(report.isEmpty, isFalse);
    });

    test('single credit transaction', () {
      final report = service.compute(
        transactions: [credit(amount: 10000.0)],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.totalCredits, 10000.0);
      expect(report.totalExpenses, 0.0);
      expect(report.netCashFlow, 10000.0);
      expect(report.averageCredit, 10000.0);
      expect(report.largestCredit, 10000.0);
    });
  });

  // ─── Totals ───────────────────────────────────────────────────────────────

  group('totals and net cash flow', () {
    test('net cash flow = credits - expenses', () {
      final report = service.compute(
        transactions: [
          credit(id: 'c1', amount: 5000.0),
          expense(id: 'e1', amount: 1500.0),
          expense(id: 'e2', amount: 800.0),
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.totalCredits, 5000.0);
      expect(report.totalExpenses, 2300.0);
      expect(report.netCashFlow, closeTo(2700.0, 0.001));
    });

    test('negative net cash flow when expenses > credits', () {
      final report = service.compute(
        transactions: [
          credit(id: 'c1', amount: 100.0),
          expense(id: 'e1', amount: 1000.0),
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.netCashFlow, closeTo(-900.0, 0.001));
    });

    test('transaction count includes all types', () {
      final report = service.compute(
        transactions: [
          credit(id: 'c1'),
          expense(id: 'e1'),
          expense(id: 'e2'),
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.transactionCount, 3);
      expect(report.creditCount, 1);
      expect(report.expenseCount, 2);
    });
  });

  // ─── Averages ─────────────────────────────────────────────────────────────

  group('averages', () {
    test('average expense = total / count', () {
      final report = service.compute(
        transactions: [
          expense(id: 'e1', amount: 300.0),
          expense(id: 'e2', amount: 700.0),
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.averageExpense, closeTo(500.0, 0.001));
    });

    test('average credit = total / count', () {
      final report = service.compute(
        transactions: [
          credit(id: 'c1', amount: 1000.0),
          credit(id: 'c2', amount: 3000.0),
          credit(id: 'c3', amount: 2000.0),
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.averageCredit, closeTo(2000.0, 0.001));
    });

    test('no division-by-zero when there are no expenses', () {
      final report = service.compute(
        transactions: [credit(id: 'c1', amount: 500.0)],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.averageExpense, 0.0);
      expect(report.averageExpense.isNaN, isFalse);
      expect(report.averageExpense.isInfinite, isFalse);
    });

    test('no division-by-zero when there are no credits', () {
      final report = service.compute(
        transactions: [expense(id: 'e1', amount: 200.0)],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.averageCredit, 0.0);
      expect(report.averageCredit.isNaN, isFalse);
    });
  });

  // ─── Largest ─────────────────────────────────────────────────────────────

  group('largest transaction', () {
    test('largest expense', () {
      final report = service.compute(
        transactions: [
          expense(id: 'e1', amount: 100.0),
          expense(id: 'e2', amount: 999.0),
          expense(id: 'e3', amount: 50.0),
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.largestExpense, 999.0);
    });

    test('largest credit', () {
      final report = service.compute(
        transactions: [
          credit(id: 'c1', amount: 500.0),
          credit(id: 'c2', amount: 50000.0),
          credit(id: 'c3', amount: 1000.0),
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.largestCredit, 50000.0);
    });

    test('largest expense is 0 when no expenses', () {
      final report = service.compute(
        transactions: [credit(id: 'c1', amount: 500.0)],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.largestExpense, 0.0);
    });
  });

  // ─── Category aggregation ─────────────────────────────────────────────────

  group('category aggregation', () {
    test('same-category expenses are grouped', () {
      final report = service.compute(
        transactions: [
          expense(id: 'e1', amount: 200.0, categoryId: 'cat-food'),
          expense(id: 'e2', amount: 300.0, categoryId: 'cat-food'),
          expense(id: 'e3', amount: 150.0, categoryId: 'cat-travel'),
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.expenseCategories.length, 2);
      final food = report.expenseCategories
          .firstWhere((c) => c.categoryId == 'cat-food');
      expect(food.total, 500.0);
      expect(food.count, 2);
      expect(food.categoryName, 'Food');
    });

    test('category percentage is correct', () {
      final report = service.compute(
        transactions: [
          expense(id: 'e1', amount: 600.0, categoryId: 'cat-food'),
          expense(id: 'e2', amount: 400.0, categoryId: 'cat-travel'),
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      final food = report.expenseCategories
          .firstWhere((c) => c.categoryId == 'cat-food');
      final travel = report.expenseCategories
          .firstWhere((c) => c.categoryId == 'cat-travel');
      expect(food.percentage, closeTo(60.0, 0.001));
      expect(travel.percentage, closeTo(40.0, 0.001));
    });

    test('no NaN category percentage when total is zero', () {
      // Zero-amount expense edge case
      final report = service.compute(
        transactions: [expense(id: 'e1', amount: 0.0)],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      for (final cat in report.expenseCategories) {
        expect(cat.percentage.isNaN, isFalse);
        expect(cat.percentage.isInfinite, isFalse);
      }
    });

    test('categories sorted descending by total', () {
      final report = service.compute(
        transactions: [
          expense(id: 'e1', amount: 100.0, categoryId: 'cat-travel'),
          expense(id: 'e2', amount: 500.0, categoryId: 'cat-food'),
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.expenseCategories.first.categoryId, 'cat-food');
      expect(report.expenseCategories.last.categoryId, 'cat-travel');
    });

    test('unknown category id falls back to "Unknown"', () {
      final report = service.compute(
        transactions: [expense(id: 'e1', categoryId: 'cat-unknown')],
        categoryNames: {},
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.expenseCategories.first.categoryName, 'Unknown');
    });
  });

  // ─── Account aggregation ──────────────────────────────────────────────────

  group('account aggregation', () {
    test('same-account transactions are grouped', () {
      final report = service.compute(
        transactions: [
          expense(id: 'e1', amount: 300.0, accountId: 'acc-bank'),
          credit(id: 'c1', amount: 5000.0, accountId: 'acc-bank'),
          expense(id: 'e2', amount: 200.0, accountId: 'acc-cash'),
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.accountSummaries.length, 2);
      final bank = report.accountSummaries
          .firstWhere((a) => a.accountId == 'acc-bank');
      expect(bank.totalCredits, 5000.0);
      expect(bank.totalExpenses, 300.0);
      expect(bank.netActivity, closeTo(4700.0, 0.001));
      expect(bank.transactionCount, 2);
      expect(bank.accountName, 'Bank');
    });

    test('net activity is credits - expenses per account', () {
      final report = service.compute(
        transactions: [
          expense(id: 'e1', amount: 1000.0, accountId: 'acc-cash'),
          credit(id: 'c1', amount: 400.0, accountId: 'acc-cash'),
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      final cash = report.accountSummaries.first;
      expect(cash.netActivity, closeTo(-600.0, 0.001));
    });

    test('unknown account id falls back to "Unknown"', () {
      final report = service.compute(
        transactions: [expense(id: 'e1', accountId: 'acc-unknown')],
        categoryNames: catNames,
        accountNames: {},
        granularity: ReportGranularity.daily,
      );
      expect(report.accountSummaries.first.accountName, 'Unknown');
    });
  });

  // ─── Trend / time-series ──────────────────────────────────────────────────

  group('trend aggregation', () {
    test('daily granularity groups by calendar day', () {
      final report = service.compute(
        transactions: [
          expense(id: 'e1', amount: 100.0, date: DateTime(2024, 9, 1)),
          expense(id: 'e2', amount: 200.0, date: DateTime(2024, 9, 1)),
          credit(id: 'c1', amount: 500.0, date: DateTime(2024, 9, 2)),
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.trendPoints.length, 2);
      final day1 = report.trendPoints
          .firstWhere((p) => p.date.day == 1);
      expect(day1.expenses, 300.0);
      expect(day1.credits, 0.0);

      final day2 = report.trendPoints
          .firstWhere((p) => p.date.day == 2);
      expect(day2.credits, 500.0);
      expect(day2.expenses, 0.0);
    });

    test('weekly granularity groups to Monday buckets', () {
      // 2024-09-02 is a Monday, 2024-09-08 is a Sunday (same week)
      final report = service.compute(
        transactions: [
          expense(id: 'e1', date: DateTime(2024, 9, 2)),   // Mon
          expense(id: 'e2', date: DateTime(2024, 9, 8)),   // Sun — same week
          expense(id: 'e3', date: DateTime(2024, 9, 9)),   // Mon — next week
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.weekly,
      );
      expect(report.trendPoints.length, 2);
    });

    test('monthly granularity groups by year-month', () {
      final report = service.compute(
        transactions: [
          expense(id: 'e1', date: DateTime(2024, 7, 15)),
          expense(id: 'e2', date: DateTime(2024, 8, 1)),
          credit(id: 'c1', date: DateTime(2024, 8, 31)),
          expense(id: 'e3', date: DateTime(2024, 9, 1)),
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.monthly,
      );
      expect(report.trendPoints.length, 3);
    });

    test('trend points are sorted ascending by date', () {
      final report = service.compute(
        transactions: [
          expense(id: 'e1', date: DateTime(2024, 9, 5)),
          expense(id: 'e2', date: DateTime(2024, 9, 1)),
          expense(id: 'e3', date: DateTime(2024, 9, 3)),
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      final dates = report.trendPoints.map((p) => p.date).toList();
      for (var i = 1; i < dates.length; i++) {
        expect(dates[i].isAfter(dates[i - 1]), isTrue);
      }
    });
  });

  // ─── Decimal amounts ─────────────────────────────────────────────────────

  group('decimal amounts', () {
    test('decimal amounts are handled correctly', () {
      final report = service.compute(
        transactions: [
          expense(id: 'e1', amount: 99.99),
          expense(id: 'e2', amount: 0.01),
        ],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.totalExpenses, closeTo(100.0, 0.001));
      expect(report.averageExpense, closeTo(50.0, 0.001));
    });
  });

  // ─── Zero amount ─────────────────────────────────────────────────────────

  group('zero amount', () {
    test('zero amount transactions do not crash', () {
      expect(
        () => service.compute(
          transactions: [expense(id: 'e1', amount: 0.0)],
          categoryNames: catNames,
          accountNames: accNames,
          granularity: ReportGranularity.daily,
        ),
        returnsNormally,
      );
    });

    test('zero amount produces 0 average', () {
      final report = service.compute(
        transactions: [expense(id: 'e1', amount: 0.0)],
        categoryNames: catNames,
        accountNames: accNames,
        granularity: ReportGranularity.daily,
      );
      expect(report.averageExpense, 0.0);
    });
  });
}
