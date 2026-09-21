import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/accounts/domain/models/account_model.dart';
import 'package:expense_tracker/features/accounts/presentation/providers/account_providers.dart';
import 'package:expense_tracker/features/categories/domain/models/category_model.dart';
import 'package:expense_tracker/features/profile/domain/models/user_profile.dart';
import 'package:expense_tracker/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/presentation/providers/data_providers.dart';
import 'package:expense_tracker/features/transactions/presentation/transactions_screen.dart';

void main() {
  final now = DateTime.now();

  final testTransactions = [
    TransactionModel(
      id: 'tx-1',
      userId: 'user-1',
      accountId: 'acc-1',
      categoryId: 'cat-1',
      type: 'EXPENSE',
      amount: 450.0,
      description: 'Dinner with friends',
      transactionDate: now,
    ),
    TransactionModel(
      id: 'tx-2',
      userId: 'user-1',
      accountId: 'acc-1',
      categoryId: 'cat-2',
      type: 'CREDIT',
      amount: 50000.0,
      description: 'Monthly Salary',
      transactionDate: now,
    ),
    TransactionModel(
      id: 'tx-3',
      userId: 'user-1',
      accountId: 'acc-2',
      categoryId: 'cat-3',
      type: 'EXPENSE',
      amount: 300.0,
      description: 'Cab fare',
      transactionDate: now.subtract(const Duration(days: 1)),
    ),
  ];

  const testAccounts = [
    AccountModel(
      id: 'acc-1',
      userId: 'user-1',
      name: 'Bank Account',
      type: 'BANK',
      isActive: true,
    ),
    AccountModel(
      id: 'acc-2',
      userId: 'user-1',
      name: 'Cash Wallet',
      type: 'CASH',
      isActive: true,
    ),
  ];

  const testCategories = [
    CategoryModel(
      id: 'cat-1',
      userId: 'user-1',
      name: 'Dining',
      type: 'EXPENSE',
      isActive: true,
    ),
    CategoryModel(
      id: 'cat-2',
      userId: 'user-1',
      name: 'Salary',
      type: 'CREDIT',
      isActive: true,
    ),
    CategoryModel(
      id: 'cat-3',
      userId: 'user-1',
      name: 'Transport',
      type: 'EXPENSE',
      isActive: true,
    ),
  ];

  Widget createWidget({
    List<TransactionModel> transactions = const [],
    bool isLoading = false,
    Object? error,
  }) {
    return ProviderScope(
      overrides: [
        if (isLoading)
          allTransactionsProvider.overrideWith((ref) => Completer<List<TransactionModel>>().future)
        else if (error != null)
          allTransactionsProvider.overrideWith((ref) => Future.error(error))
        else
          allTransactionsProvider.overrideWith((ref) => Future.value(transactions)),
        accountsProvider.overrideWith((ref) => Future.value(testAccounts)),
        categoriesProvider.overrideWith((ref) => Future.value(testCategories)),
        userProfileProvider.overrideWith(
          (ref) => Future.value(
            const UserProfile(
              id: 'user-1',
              fullName: 'User',
              currencyCode: 'INR',
              currencySymbol: '₹',
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const TransactionsScreen(),
      ),
    );
  }

  group('TransactionsScreen — 5.4 Transaction History', () {
    testWidgets('renders transaction list grouped by TODAY and YESTERDAY', (tester) async {
      await tester.pumpWidget(createWidget(transactions: testTransactions));
      await tester.pumpAndSettle();

      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.textContaining('Dinner with friends'), findsOneWidget);
      expect(find.textContaining('Monthly Salary'), findsOneWidget);
      expect(find.textContaining('Cab fare'), findsOneWidget);
    });

    testWidgets('filters transactions by search query', (tester) async {
      await tester.pumpWidget(createWidget(transactions: testTransactions));
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('transaction_search_field'));
      await tester.enterText(searchField, 'Salary');
      await tester.pumpAndSettle();

      expect(find.textContaining('Monthly Salary'), findsOneWidget);
      expect(find.textContaining('Dinner with friends'), findsNothing);
      expect(find.textContaining('Cab fare'), findsNothing);
    });

    testWidgets('filters transactions by type chips (Expenses vs Credits)', (tester) async {
      await tester.pumpWidget(createWidget(transactions: testTransactions));
      await tester.pumpAndSettle();

      // Tap Expense filter
      final expenseFilter = find.byKey(const Key('filter_chip_expense'));
      await tester.tap(expenseFilter);
      await tester.pumpAndSettle();

      expect(find.textContaining('Dinner with friends'), findsOneWidget);
      expect(find.textContaining('Cab fare'), findsOneWidget);
      expect(find.textContaining('Monthly Salary'), findsNothing);

      // Tap Credit filter
      final creditFilter = find.byKey(const Key('filter_chip_credit'));
      await tester.tap(creditFilter);
      await tester.pumpAndSettle();

      expect(find.textContaining('Monthly Salary'), findsOneWidget);
      expect(find.textContaining('Dinner with friends'), findsNothing);
      expect(find.textContaining('Cab fare'), findsNothing);
    });

    testWidgets('renders empty state when no transactions exist', (tester) async {
      await tester.pumpWidget(createWidget(transactions: []));
      await tester.pumpAndSettle();

      expect(find.text('No transactions recorded yet'), findsOneWidget);
    });

    testWidgets('renders error state with retry button', (tester) async {
      await tester.pumpWidget(createWidget(error: 'Network connection error'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load transactions'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
