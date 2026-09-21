import 'package:expense_tracker/features/accounts/domain/models/account_model.dart';
import 'package:expense_tracker/features/accounts/presentation/providers/account_providers.dart';
import 'package:expense_tracker/features/categories/domain/models/category_model.dart';
import 'package:expense_tracker/features/profile/domain/models/user_profile.dart';
import 'package:expense_tracker/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:expense_tracker/features/recurring/domain/models/recurring_frequency.dart';
import 'package:expense_tracker/features/recurring/domain/models/recurring_transaction_model.dart';
import 'package:expense_tracker/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:expense_tracker/features/recurring/presentation/recurring_transactions_screen.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_type.dart';
import 'package:expense_tracker/features/transactions/presentation/providers/data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testRecurring = RecurringTransactionModel(
    id: 'rec-1',
    userId: 'user-1',
    accountId: 'acc-1',
    categoryId: 'cat-1',
    type: TransactionType.expense,
    amount: 649.0,
    description: 'Netflix Subscription',
    frequency: RecurringFrequency.monthly,
    startDate: DateTime(2026, 1, 1),
    nextOccurrence: DateTime(2026, 10, 1),
    isActive: true,
    autoCreate: true,
  );

  const testAccount = AccountModel(
    id: 'acc-1',
    userId: 'user-1',
    name: 'HDFC Bank',
    type: 'BANK',
    openingBalance: 50000.0,
    isActive: true,
  );

  final testCategory = CategoryModel(
    id: 'cat-1',
    userId: 'user-1',
    name: 'Entertainment',
    type: 'EXPENSE',
    color: '#E50914',
    isActive: true,
  );

  Widget createTestWidget({List<RecurringTransactionModel> items = const []}) {
    return ProviderScope(
      overrides: [
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(
            id: 'user-1',
            email: 'test@example.com',
            currencyCode: 'INR',
            currencySymbol: '₹',
          ),
        ),
        activeRecurringTransactionsProvider.overrideWith(
          (ref) async => items.where((i) => i.isActive).toList(),
        ),
        allRecurringTransactionsProvider.overrideWith(
          (ref) async => items,
        ),
        categoriesProvider.overrideWith(
          (ref) async => [testCategory],
        ),
        accountsProvider.overrideWith(
          (ref) async => [testAccount],
        ),
      ],
      child: const MaterialApp(
        home: RecurringTransactionsScreen(),
      ),
    );
  }

  group('RecurringTransactionsScreen Widget Tests', () {
    testWidgets('renders empty state when no recurring schedules exist', (tester) async {
      await tester.pumpWidget(createTestWidget(items: []));
      await tester.pumpAndSettle();

      expect(find.text('Recurring Transactions'), findsOneWidget);
      expect(find.text('No Recurring Transactions'), findsOneWidget);
      expect(find.text('Add First Recurring Item'), findsOneWidget);
    });

    testWidgets('renders active recurring items and commitments summary banner', (tester) async {
      await tester.pumpWidget(createTestWidget(items: [testRecurring]));
      await tester.pumpAndSettle();

      expect(find.text('Recurring Transactions'), findsOneWidget);
      expect(find.text('Netflix Subscription'), findsOneWidget);
      expect(find.text('Active (1)'), findsOneWidget);
      expect(find.text('Paused (0)'), findsOneWidget);
      expect(find.text('All (1)'), findsOneWidget);
      expect(find.text('ACTIVE MONTHLY SCHEDULE'), findsOneWidget);
      expect(find.text('₹649'), findsOneWidget); // In summary banner
      expect(find.text('-₹649'), findsOneWidget); // In transaction card
      expect(find.text('Auto'), findsOneWidget);
    });

    testWidgets('floating action button opens AddEditRecurringSheet modal', (tester) async {
      await tester.pumpWidget(createTestWidget(items: [testRecurring]));
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('New Recurring Transaction'), findsOneWidget);
      expect(find.text('Frequency'), findsOneWidget);
      expect(find.text('Auto-Create Transaction'), findsOneWidget);
      expect(find.text('Create Recurring Schedule'), findsOneWidget);
    });
  });
}
