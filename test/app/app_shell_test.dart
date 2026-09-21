import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
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

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(const AuthAuthenticated(testUser)),
        ),
        userProfileProvider.overrideWith((ref) => Future.value(testProfile)),
        accountsProvider.overrideWith((ref) => Future.value([])),
        categoriesProvider.overrideWith((ref) => Future.value([])),
        expenseCategoriesProvider.overrideWith((ref) => Future.value([])),
        incomeCategoriesProvider.overrideWith((ref) => Future.value([])),
        allTransactionsProvider.overrideWith((ref) => Future.value([])),
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
        allRecurringTransactionsProvider.overrideWith((ref) => Future.value([])),
        unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
        notificationsListProvider.overrideWith((ref) => Future.value([])),
      ],
      child: const ExpenseTrackerApp(),
    );
  }

  group('AppShell Widget Tests', () {
    testWidgets('renders all 4 navigation destinations and Add Transaction FAB',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify Home destination
      expect(find.text('Home'), findsOneWidget);
      expect(find.byIcon(LucideIcons.home), findsWidgets);

      // 2. Verify Transactions destination
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.byIcon(LucideIcons.receipt), findsWidgets);

      // 3. Verify Reports destination
      expect(find.text('Reports'), findsOneWidget);
      expect(find.byIcon(LucideIcons.pieChart), findsWidgets);

      // 4. Verify Profile destination
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byIcon(LucideIcons.user), findsWidgets);

      // 5. Verify Add Transaction action exists
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byTooltip('Add Transaction'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FloatingActionButton),
          matching: find.byIcon(LucideIcons.plus),
        ),
        findsOneWidget,
      );
    });

    testWidgets('navigates to different branches when destinations are tapped',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initial tab is Dashboard (Home)
      expect(find.text('Home'), findsWidgets);

      // Tap Transactions destination
      await tester.tap(find.byIcon(LucideIcons.receipt).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('transaction_search_field')), findsOneWidget);

      // Tap Reports destination
      await tester.tap(find.byIcon(LucideIcons.pieChart).first);
      await tester.pumpAndSettle();
      expect(find.text('Reports & Analytics'), findsOneWidget);

      // Tap Profile destination
      await tester.tap(find.byIcon(LucideIcons.user).first);
      await tester.pumpAndSettle();
      expect(find.text('Profile & Settings'), findsOneWidget);
      expect(find.text('DATA MANAGEMENT'), findsOneWidget);

      // Tap back to Home destination
      await tester.tap(find.byIcon(LucideIcons.home).first);
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('tapping Add Transaction FAB navigates to add transaction screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify Add Transaction modal / screen is shown
      expect(find.text('Add Transaction'), findsWidgets);
    });
  });
}
