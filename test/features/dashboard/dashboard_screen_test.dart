import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/accounts/domain/models/account_model.dart';
import 'package:expense_tracker/features/accounts/presentation/providers/account_providers.dart';
import 'package:expense_tracker/features/categories/domain/models/category_model.dart';
import 'package:expense_tracker/features/dashboard/presentation/dashboard_screen.dart';
import 'package:expense_tracker/features/profile/domain/models/user_profile.dart';
import 'package:expense_tracker/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:expense_tracker/features/budgets/presentation/providers/budget_providers.dart';
import 'package:expense_tracker/features/notifications/presentation/providers/notification_providers.dart';
import 'package:expense_tracker/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/domain/services/financial_calculation_service.dart';
import 'package:expense_tracker/features/transactions/presentation/providers/data_providers.dart';

void main() {
  const testProfile = UserProfile(
    id: 'user-1',
    fullName: 'Alex Johnson',
    email: 'alex@example.com',
    currencyCode: 'INR',
    currencySymbol: '₹',
  );

  const testAccounts = [
    AccountModel(
      id: 'acc-1',
      userId: 'user-1',
      name: 'Main Bank',
      type: 'BANK',
      isActive: true,
      openingBalance: 10000.0,
    ),
    AccountModel(
      id: 'acc-2',
      userId: 'user-1',
      name: 'Cash Wallet',
      type: 'CASH',
      isActive: true,
      openingBalance: 2000.0,
    ),
  ];

  const testCategories = [
    CategoryModel(
      id: 'cat-1',
      userId: 'user-1',
      name: 'Salary',
      type: 'income',
      isActive: true,
    ),
    CategoryModel(
      id: 'cat-2',
      userId: 'user-1',
      name: 'Groceries',
      type: 'expense',
      isActive: true,
    ),
  ];

  final testTransactions = [
    TransactionModel(
      id: 'tx-1',
      userId: 'user-1',
      accountId: 'acc-1',
      categoryId: 'cat-1',
      type: 'CREDIT',
      amount: 50000.0,
      description: 'Monthly Salary',
      transactionDate: DateTime(2026, 9, 15, 10, 30),
    ),
    TransactionModel(
      id: 'tx-2',
      userId: 'user-1',
      accountId: 'acc-2',
      categoryId: 'cat-2',
      type: 'EXPENSE',
      amount: 1500.0,
      description: 'Supermarket shopping',
      transactionDate: DateTime(2026, 9, 18, 15, 45),
    ),
  ];

  const testOverallSummary = FinancialSummary(
    totalCredit: 50000.0,
    totalExpense: 1500.0,
  );

  const testMonthlySummary = FinancialSummary(
    totalCredit: 50000.0,
    totalExpense: 1500.0,
  );

  Widget createWidget({
    List<Override> overrides = const [],
    GoRouter? router,
  }) {
    final effectiveRouter = router ??
        GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/add-transaction',
              builder: (context, state) =>
                  const Scaffold(body: Text('Add Transaction Screen')),
            ),
            GoRoute(
              path: '/transactions',
              builder: (context, state) =>
                  const Scaffold(body: Text('All Transactions Screen')),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        userProfileProvider.overrideWith((ref) => Future.value(testProfile)),
        accountsProvider.overrideWith((ref) => Future.value(testAccounts)),
        categoriesProvider.overrideWith((ref) => Future.value(testCategories)),
        recentTransactionsProvider
            .overrideWith((ref) => Future.value(testTransactions)),
        overallSummaryProvider
            .overrideWith((ref) => Future.value(testOverallSummary)),
        currentMonthSummaryProvider
            .overrideWith((ref) => Future.value(testMonthlySummary)),
        upcomingRecurringProvider
            .overrideWith((ref) => Future.value([])),
        activeBudgetsProgressProvider
            .overrideWith((ref) => Future.value([])),
        unreadNotificationCountProvider
            .overrideWith((ref) => Future.value(0)),
        notificationsListProvider
            .overrideWith((ref) => Future.value([])),
        ...overrides,
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: effectiveRouter,
      ),
    );
  }

  group('DashboardScreen Widget Tests', () {
    testWidgets('renders all financial summary metrics and user greeting',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // 1. Verify User Greeting
      expect(find.text('Alex Johnson'), findsOneWidget);

      // 2. Verify Current Balance card (12000 opening + 50000 - 1500 = 60500)
      expect(find.text('Current Balance'), findsOneWidget);
      expect(find.text('₹ 60,500.00'), findsOneWidget);

      // 3. Verify Total Credits and Expenses in balance card
      expect(find.text('Credits'), findsWidgets);
      expect(find.text('Expenses'), findsWidgets);
      expect(find.text('₹ 50,000.00'), findsWidgets);
      expect(find.text('₹ 1,500.00'), findsWidgets);

      // 4. Verify This Month section
      expect(find.text('This Month'), findsOneWidget);

      // 5. Verify Quick Actions
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Add Expense'), findsWidgets);
      expect(find.text('Add Credit'), findsWidgets);

      // 6. Verify Recent Transactions
      expect(find.text('Recent Transactions'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('+ ₹ 50,000.00'), findsOneWidget);
      expect(find.text('- ₹ 1,500.00'), findsOneWidget);
    });

    testWidgets('renders loading state when financial providers are loading',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final completer = Completer<FinancialSummary>();

      await tester.pumpWidget(
        createWidget(
          overrides: [
            overallSummaryProvider.overrideWith((ref) => completer.future),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading financial data...'), findsOneWidget);
    });

    testWidgets('renders error state and retry button when providers fail',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createWidget(
          overrides: [
            overallSummaryProvider.overrideWith(
              (ref) => Future.error(Exception('Network error')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load your financial data.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders empty state when there are no transactions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createWidget(
          overrides: [
            recentTransactionsProvider.overrideWith((ref) => Future.value([])),
            overallSummaryProvider.overrideWith(
              (ref) => Future.value(
                const FinancialSummary(totalCredit: 0, totalExpense: 0),
              ),
            ),
            currentMonthSummaryProvider.overrideWith(
              (ref) => Future.value(
                const FinancialSummary(totalCredit: 0, totalExpense: 0),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No transactions yet'), findsOneWidget);
      expect(
        find.text('Start tracking your finances\nby adding your first transaction.'),
        findsOneWidget,
      );
    });

    testWidgets('quick action Add Expense navigates to /add-transaction',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap first Add Expense button
      await tester.tap(find.text('Add Expense').first);
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction Screen'), findsOneWidget);
    });

    testWidgets('quick action Add Credit navigates to /add-transaction',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap first Add Credit button
      await tester.tap(find.text('Add Credit').first);
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction Screen'), findsOneWidget);
    });

    testWidgets('See all transactions navigates to /transactions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap See all
      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();

      expect(find.text('All Transactions Screen'), findsOneWidget);
    });
  });
}
