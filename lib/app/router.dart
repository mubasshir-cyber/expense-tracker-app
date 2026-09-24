import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_state_provider.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/accounts/presentation/accounts_screen.dart';
import '../features/budgets/presentation/budgets_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/dashboard/presentation/customize_dashboard_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/goals/presentation/goal_detail_screen.dart';
import '../features/goals/presentation/savings_goals_screen.dart';
import '../features/debts/presentation/debts_screen.dart';
import '../features/debts/presentation/debt_detail_screen.dart';
import '../features/notifications/presentation/notification_settings_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/recurring/presentation/recurring_transactions_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/transactions/domain/models/transaction_model.dart';
import '../features/transactions/domain/models/transaction_type.dart';
import '../features/transactions/presentation/add_transaction_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/export_import/presentation/export_screen.dart';
import '../features/export_import/presentation/import_screen.dart';
import '../features/khata/presentation/screens/customer_detail_screen.dart';
import '../features/khata/presentation/screens/customer_statement_screen.dart';
import '../features/khata/presentation/screens/khata_screen.dart';
import 'app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;

      final isPublicRoute = location == '/splash' ||
          location == '/login' ||
          location == '/signup' ||
          location == '/forgot-password';

      if (authState.isLoading) {
        return '/splash';
      }

      final isAuthenticated = authState.value is AuthAuthenticated;

      if (!isAuthenticated) {
        if (!isPublicRoute || location == '/splash') {
          return '/login';
        }
      }

      if (isAuthenticated &&
          (location == '/login' ||
              location == '/signup' ||
              location == '/forgot-password' ||
              location == '/splash')) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Bottom Navigation Stateful Shell Route
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Dashboard / Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'dashboard',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DashboardScreen(),
                ),
              ),
            ],
          ),

          // Branch 2: Transactions
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                name: 'transactions',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: TransactionsScreen(),
                ),
              ),
            ],
          ),

          // Branch 3: Reports & Analytics
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                name: 'reports',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ReportsScreen(),
                ),
              ),
            ],
          ),

          // Branch 4: Profile & Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Top-Level Modal Action Route (No bottom navigation bar)
      GoRoute(
        path: '/add-transaction',
        name: 'add-transaction',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          TransactionModel? transactionToEdit;
          TransactionType? initialType;

          if (state.extra is TransactionModel) {
            transactionToEdit = state.extra as TransactionModel;
          } else if (state.extra is TransactionType) {
            initialType = state.extra as TransactionType;
          }

          final typeParam = state.uri.queryParameters['type']?.toLowerCase();
          if (typeParam == 'expense') {
            initialType = TransactionType.expense;
          } else if (typeParam == 'credit' || typeParam == 'income') {
            initialType = TransactionType.credit;
          }

          return MaterialPage(
            fullscreenDialog: true,
            child: AddTransactionScreen(
              transactionToEdit: transactionToEdit,
              initialType: initialType,
            ),
          );
        },
      ),

      // Accounts Management
      GoRoute(
        path: '/accounts',
        name: 'accounts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccountsScreen(),
      ),

      // Categories Management
      GoRoute(
        path: '/categories',
        name: 'categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoriesScreen(),
      ),

      // Budgets & Spending Limits Management
      GoRoute(
        path: '/budgets',
        name: 'budgets',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BudgetsScreen(),
      ),

      // Recurring Transactions Management
      GoRoute(
        path: '/recurring',
        name: 'recurring',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RecurringTransactionsScreen(),
      ),

      // Smart Financial Notifications Center
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Notification Preferences & Settings
      GoRoute(
        path: '/notification-settings',
        name: 'notification-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),

      // Savings Goals Management
      GoRoute(
        path: '/savings-goals',
        name: 'savings-goals',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SavingsGoalsScreen(),
      ),

      // Savings Goal Detail View
      GoRoute(
        path: '/savings-goals/:id',
        name: 'savings-goal-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final goalId = state.pathParameters['id'] ?? '';
          return GoalDetailScreen(goalId: goalId);
        },
      ),

      // Debts & Loans Management
      GoRoute(
        path: '/debts',
        name: 'debts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DebtsScreen(),
      ),

      // Debt / Loan Detail View
      GoRoute(
        path: '/debts/:id',
        name: 'debt-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final debtId = state.pathParameters['id'] ?? '';
          return DebtDetailScreen(debtId: debtId);
        },
      ),

      // Export Financial Data
      GoRoute(
        path: '/export',
        name: 'export',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExportScreen(),
      ),

      // Import Financial Data (CSV)
      GoRoute(
        path: '/import',
        name: 'import',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ImportScreen(),
      ),

      // Dashboard Customization
      GoRoute(
        path: '/customize-dashboard',
        name: 'customize-dashboard',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CustomizeDashboardScreen(),
      ),

      // Khata / Customer Ledger
      GoRoute(
        path: '/khata',
        name: 'khata',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const KhataScreen(),
      ),

      // Khata Customer Detail View
      GoRoute(
        path: '/khata/customer/:id',
        name: 'khata-customer-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final customerId = state.pathParameters['id'] ?? '';
          return CustomerDetailScreen(customerId: customerId);
        },
      ),

      // Khata Customer Statement View
      GoRoute(
        path: '/khata/customer/:id/statement',
        name: 'khata-customer-statement',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final customerId = state.pathParameters['id'] ?? '';
          return CustomerStatementScreen(customerId: customerId);
        },
      ),
    ],
  );
});
