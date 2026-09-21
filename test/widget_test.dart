import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/app/app.dart';
import 'package:expense_tracker/features/accounts/presentation/providers/account_providers.dart';
import 'package:expense_tracker/features/auth/domain/models/auth_user.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:expense_tracker/features/profile/domain/models/user_profile.dart';
import 'package:expense_tracker/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:expense_tracker/features/budgets/presentation/providers/budget_providers.dart';
import 'package:expense_tracker/features/notifications/presentation/providers/notification_providers.dart';
import 'package:expense_tracker/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:expense_tracker/features/transactions/domain/services/financial_calculation_service.dart';
import 'package:expense_tracker/features/transactions/presentation/providers/data_providers.dart';

void main() {
  testWidgets('App smoke test - unauthenticated user lands on Login screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthUnauthenticated()),
          ),
        ],
        child: const ExpenseTrackerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Login screen elements are present
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets(
      'App smoke test - authenticated user loads navigation shell with Dashboard',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const testUser = AuthUser(
      id: 'test-user-id',
      email: 'test@example.com',
    );

    const testProfile = UserProfile(
      id: 'test-user-id',
      fullName: 'Test User',
      currencyCode: 'INR',
      currencySymbol: '₹',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthAuthenticated(testUser)),
          ),
          userProfileProvider.overrideWith((ref) => Future.value(testProfile)),
          accountsProvider.overrideWith((ref) => Future.value([])),
          categoriesProvider.overrideWith((ref) => Future.value([])),
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
          activeBudgetsProgressProvider.overrideWith((ref) => Future.value([])),
          upcomingRecurringProvider.overrideWith((ref) => Future.value([])),
          unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
          notificationsListProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const ExpenseTrackerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Dashboard navigation shell is present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
