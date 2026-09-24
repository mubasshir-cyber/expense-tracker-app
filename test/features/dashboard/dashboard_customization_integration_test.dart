import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/accounts/domain/models/account_model.dart';
import 'package:expense_tracker/features/accounts/presentation/providers/account_providers.dart';
import 'package:expense_tracker/features/categories/domain/models/category_model.dart';
import 'package:expense_tracker/features/dashboard/data/repositories/dashboard_layout_repository.dart';
import 'package:expense_tracker/features/dashboard/domain/models/dashboard_layout.dart';
import 'package:expense_tracker/features/dashboard/domain/models/dashboard_widget_type.dart';
import 'package:expense_tracker/features/dashboard/presentation/dashboard_screen.dart';
import 'package:expense_tracker/features/dashboard/presentation/providers/dashboard_layout_provider.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/balance_card.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/quick_actions.dart';
import 'package:expense_tracker/features/profile/domain/models/user_profile.dart';
import 'package:expense_tracker/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:expense_tracker/features/budgets/presentation/providers/budget_providers.dart';
import 'package:expense_tracker/features/notifications/presentation/providers/notification_providers.dart';
import 'package:expense_tracker/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:expense_tracker/features/goals/domain/services/savings_goal_calculation_service.dart';
import 'package:expense_tracker/features/goals/presentation/providers/goal_providers.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_summary.dart';
import 'package:expense_tracker/features/debts/presentation/providers/debt_providers.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/domain/services/financial_calculation_service.dart';
import 'package:expense_tracker/features/transactions/presentation/providers/data_providers.dart';

class FakeDashboardRepo implements DashboardLayoutRepository {
  FakeDashboardRepo(this.layout);
  DashboardLayout layout;

  @override
  Future<DashboardLayout> loadLayout() async => layout;

  @override
  Future<void> saveLayout(DashboardLayout newLayout) async {
    layout = newLayout;
  }

  @override
  Future<void> resetLayout() async {
    layout = DashboardLayout.defaultLayout();
  }
}

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
  ];

  const testCategories = [
    CategoryModel(
      id: 'cat-1',
      userId: 'user-1',
      name: 'Salary',
      type: 'income',
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
  ];

  const testSummary = FinancialSummary(totalCredit: 50000.0, totalExpense: 0.0);

  Widget createTestApp({
    required DashboardLayout layout,
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
              path: '/customize-dashboard',
              builder: (context, state) =>
                  const Scaffold(body: Text('Customize Dashboard Screen')),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        dashboardLayoutRepositoryProvider
            .overrideWithValue(FakeDashboardRepo(layout)),
        userProfileProvider.overrideWith((ref) => Future.value(testProfile)),
        accountsProvider.overrideWith((ref) => Future.value(testAccounts)),
        categoriesProvider.overrideWith((ref) => Future.value(testCategories)),
        recentTransactionsProvider
            .overrideWith((ref) => Future.value(testTransactions)),
        overallSummaryProvider.overrideWith((ref) => Future.value(testSummary)),
        currentMonthSummaryProvider
            .overrideWith((ref) => Future.value(testSummary)),
        upcomingRecurringProvider.overrideWith((ref) => Future.value([])),
        activeBudgetsProgressProvider.overrideWith((ref) => Future.value([])),
        unreadNotificationCountProvider.overrideWith((ref) => Future.value(0)),
        notificationsListProvider.overrideWith((ref) => Future.value([])),
        activeSavingsGoalsProvider.overrideWith((ref) => Future.value([])),
        allSavingsGoalsProvider.overrideWith((ref) => Future.value([])),
        completedSavingsGoalsProvider.overrideWith((ref) => Future.value([])),
        savingsGoalsSummaryProvider.overrideWith(
          (ref) => Future.value(
            const SavingsGoalsSummary(
              totalTarget: 100000,
              totalSaved: 40000,
              completedCount: 0,
              activeCount: 1,
            ),
          ),
        ),
        allDebtsProvider.overrideWith((ref) => Future.value([])),
        youOweDebtsProvider.overrideWith((ref) => Future.value([])),
        youAreOwedDebtsProvider.overrideWith((ref) => Future.value([])),
        debtSummaryProvider.overrideWith(
          (ref) => Future.value(DebtSummary.empty),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: effectiveRouter,
      ),
    );
  }

  group('Dashboard Customization Integration Tests', () {
    testWidgets('omits hidden widgets and renders visible widgets only',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Hide balance and recentTransactions
      var layout = DashboardLayout.defaultLayout();
      layout = layout.toggleVisibility(DashboardWidgetType.balance, false);
      layout = layout.toggleVisibility(DashboardWidgetType.recentTransactions, false);

      await tester.pumpWidget(createTestApp(layout: layout));
      await tester.pumpAndSettle();

      // BalanceCard and RecentTransactions should not be in the tree
      expect(find.byType(BalanceCard), findsNothing);
      expect(find.text('Current Balance'), findsNothing);
      expect(find.text('Recent Transactions'), findsNothing);

      // Quick Actions and Monthly summary should still be present
      expect(find.byType(QuickActions), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
    });

    testWidgets('renders reordered widgets according to layout order',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Place quickActions as the very first widget
      const layout = DashboardLayout(
        widgets: [
          DashboardWidgetConfig(type: DashboardWidgetType.quickActions, isVisible: true),
          DashboardWidgetConfig(type: DashboardWidgetType.balance, isVisible: true),
        ],
      );

      await tester.pumpWidget(createTestApp(layout: layout));
      await tester.pumpAndSettle();

      final quickActionsFinder = find.byType(QuickActions);
      final balanceCardFinder = find.byType(BalanceCard);

      expect(quickActionsFinder, findsOneWidget);
      expect(balanceCardFinder, findsOneWidget);

      final quickActionsTop = tester.getTopLeft(quickActionsFinder).dy;
      final balanceCardTop = tester.getTopLeft(balanceCardFinder).dy;

      expect(quickActionsTop, lessThan(balanceCardTop));
    });

    testWidgets('renders empty dashboard state when all widgets are hidden',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Hide all widgets
      var layout = DashboardLayout.defaultLayout();
      for (final w in layout.widgets) {
        layout = layout.toggleVisibility(w.type, false);
      }

      await tester.pumpWidget(createTestApp(layout: layout));
      await tester.pumpAndSettle();

      expect(find.text('Your dashboard is empty.'), findsOneWidget);
      expect(find.byKey(const Key('empty_dashboard_customize_button')), findsOneWidget);

      // Tap button in empty dashboard state -> navigates to customize screen
      await tester.tap(find.byKey(const Key('empty_dashboard_customize_button')));
      await tester.pumpAndSettle();

      expect(find.text('Customize Dashboard Screen'), findsOneWidget);
    });

    testWidgets('AppBar drawer menu button is present and opens drawer',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(layout: DashboardLayout.defaultLayout()));
      await tester.pumpAndSettle();

      final menuButton = find.byKey(const Key('dashboard_drawer_button'));
      expect(menuButton, findsOneWidget);
    });
  });
}

