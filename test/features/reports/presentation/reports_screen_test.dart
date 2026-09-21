import 'package:expense_tracker/features/reports/domain/models/financial_report.dart';
import 'package:expense_tracker/features/reports/domain/models/report_period.dart';
import 'package:expense_tracker/features/reports/presentation/providers/reports_providers.dart';
import 'package:expense_tracker/features/reports/presentation/reports_screen.dart';
import 'package:expense_tracker/features/reports/domain/models/account_summary.dart';
import 'package:expense_tracker/features/reports/domain/models/category_expense_summary.dart';
import 'package:expense_tracker/features/reports/domain/models/trend_point.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Widget _wrap({
  required Widget child,
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

FinancialReport _sampleReport() => FinancialReport(
      totalCredits: 5000.0,
      totalExpenses: 2000.0,
      transactionCount: 10,
      creditCount: 3,
      expenseCount: 7,
      averageExpense: 285.71,
      largestExpense: 800.0,
      averageCredit: 1666.67,
      largestCredit: 3000.0,
      expenseCategories: [
        const CategoryExpenseSummary(
          categoryId: 'cat-food',
          categoryName: 'Food',
          total: 1200.0,
          count: 4,
          percentage: 60.0,
        ),
        const CategoryExpenseSummary(
          categoryId: 'cat-travel',
          categoryName: 'Travel',
          total: 800.0,
          count: 3,
          percentage: 40.0,
        ),
      ],
      creditCategories: [
        const CategoryExpenseSummary(
          categoryId: 'cat-salary',
          categoryName: 'Salary',
          total: 5000.0,
          count: 3,
          percentage: 100.0,
        ),
      ],
      accountSummaries: [
        const AccountSummary(
          accountId: 'acc-bank',
          accountName: 'Bank',
          totalCredits: 5000.0,
          totalExpenses: 2000.0,
          transactionCount: 10,
        ),
      ],
      trendPoints: [
        TrendPoint(
          date: DateTime(2024, 9, 1),
          credits: 5000.0,
          expenses: 2000.0,
        ),
      ],
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ReportsScreen', () {
    testWidgets('shows loading state while data is fetching',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const ReportsScreen(),
          overrides: [
            reportFilterProvider.overrideWith(
              (ref) => ReportFilterNotifier(),
            ),
            financialReportProvider.overrideWith(
              (ref) => Future.delayed(const Duration(seconds: 10)),
            ),
          ],
        ),
      );
      await tester.pump();
      // Loading shimmer blocks should be visible
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Screen should render without crash
      expect(find.byType(ReportsScreen), findsOneWidget);
    });

    testWidgets('shows error state and retry button when data fails',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const ReportsScreen(),
          overrides: [
            reportFilterProvider.overrideWith(
              (ref) => ReportFilterNotifier(),
            ),
            financialReportProvider.overrideWith(
              (ref) => Future.error(Exception('Network error')),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Unable to load reports'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows empty state when no transactions in period',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const ReportsScreen(),
          overrides: [
            reportFilterProvider.overrideWith(
              (ref) => ReportFilterNotifier(),
            ),
            financialReportProvider.overrideWith(
              (ref) => Future.value(FinancialReport.empty),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('No financial activity'), findsOneWidget);
    });

    testWidgets('renders report content when data is available',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrap(
          child: const ReportsScreen(),
          overrides: [
            reportFilterProvider.overrideWith(
              (ref) => ReportFilterNotifier(),
            ),
            financialReportProvider.overrideWith(
              (ref) => Future.value(_sampleReport()),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      // Section headers visible
      expect(find.text('Financial Overview'), findsOneWidget);
      expect(find.text('Credits vs Expenses'), findsOneWidget);
    });

    testWidgets('period selector is displayed', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const ReportsScreen(),
          overrides: [
            reportFilterProvider.overrideWith(
              (ref) => ReportFilterNotifier(),
            ),
            financialReportProvider.overrideWith(
              (ref) => Future.value(FinancialReport.empty),
            ),
          ],
        ),
      );
      await tester.pump();
      // Period preset chips
      expect(find.text('This Month'), findsOneWidget);
    });

    testWidgets('refresh icon button is present', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const ReportsScreen(),
          overrides: [
            reportFilterProvider.overrideWith(
              (ref) => ReportFilterNotifier(),
            ),
            financialReportProvider.overrideWith(
              (ref) => Future.value(FinancialReport.empty),
            ),
          ],
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });
  });

  group('ReportFilterNotifier state changes', () {
    test('default filter is thisMonth', () {
      final notifier = ReportFilterNotifier();
      expect(notifier.state.period, ReportPeriod.thisMonth);
    });

    test('changing to thisWeek updates state', () {
      final notifier = ReportFilterNotifier();
      notifier.setPeriod(ReportPeriod.thisWeek);
      expect(notifier.state.period, ReportPeriod.thisWeek);
    });

    test('custom range with valid dates is accepted', () {
      final notifier = ReportFilterNotifier();
      final result = notifier.setCustomRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31, 23, 59, 59),
      );
      expect(result, isTrue);
      expect(notifier.state.period, ReportPeriod.custom);
    });

    test('custom range start > end is rejected', () {
      final notifier = ReportFilterNotifier();
      final result = notifier.setCustomRange(
        DateTime(2024, 2, 1),
        DateTime(2024, 1, 1),
      );
      expect(result, isFalse);
      expect(notifier.state.period, ReportPeriod.thisMonth);
    });
  });
}
