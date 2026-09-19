import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_shell.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/transactions/presentation/add_transaction_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// The central declarative GoRouter configuration for the application.
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
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
      pageBuilder: (context, state) => const MaterialPage(
        fullscreenDialog: true,
        child: AddTransactionScreen(),
      ),
    ),
  ],
);
