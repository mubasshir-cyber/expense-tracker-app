import 'package:expense_tracker/features/accounts/domain/models/account_model.dart';
import 'package:expense_tracker/features/accounts/presentation/providers/account_providers.dart';
import 'package:expense_tracker/features/categories/domain/models/category_model.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/dashboard_upcoming_payments_card.dart';
import 'package:expense_tracker/features/profile/domain/models/user_profile.dart';
import 'package:expense_tracker/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:expense_tracker/features/recurring/domain/models/recurring_frequency.dart';
import 'package:expense_tracker/features/recurring/domain/models/recurring_transaction_model.dart';
import 'package:expense_tracker/features/recurring/presentation/providers/recurring_providers.dart';
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
    amount: 1499.0,
    description: 'Broadband Internet',
    frequency: RecurringFrequency.monthly,
    startDate: DateTime(2026, 1, 1),
    nextOccurrence: DateTime(2026, 9, 25),
    isActive: true,
    autoCreate: false,
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
    name: 'Utilities',
    type: 'EXPENSE',
    color: '#0EA5E9',
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
        upcomingRecurringProvider.overrideWith(
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
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardUpcomingPaymentsCard(
              currencySymbol: '₹',
            ),
          ),
        ),
      ),
    );
  }

  group('DashboardUpcomingPaymentsCard Widget Tests', () {
    testWidgets('renders empty state when there are no upcoming bills', (tester) async {
      await tester.pumpWidget(createTestWidget(items: []));
      await tester.pumpAndSettle();

      expect(find.text('Recurring Payments & Bills'), findsOneWidget);
      expect(find.text('Automate Netflix, rent, bills & salary.'), findsOneWidget);
    });

    testWidgets('renders upcoming item tile with title, date, and amount', (tester) async {
      await tester.pumpWidget(createTestWidget(items: [testRecurring]));
      await tester.pumpAndSettle();

      expect(find.text('Upcoming Payments'), findsOneWidget);
      expect(find.text('Broadband Internet'), findsOneWidget);
      expect(find.text('-₹1,499'), findsOneWidget);
      expect(find.text('See All (1)'), findsOneWidget);
    });
  });
}
