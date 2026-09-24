import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/widgets/app_drawer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../accounts/presentation/providers/account_providers.dart';
import '../../profile/presentation/providers/profile_repository_provider.dart';
import '../../transactions/presentation/providers/data_providers.dart';
import '../../budgets/presentation/providers/budget_providers.dart';
import '../../notifications/presentation/providers/notification_providers.dart';
import '../../notifications/presentation/widgets/notification_badge_icon.dart';
import '../../recurring/presentation/providers/recurring_providers.dart';
import '../../goals/presentation/providers/goal_providers.dart';
import '../../debts/presentation/providers/debt_providers.dart';
import 'providers/dashboard_layout_provider.dart';
import 'widgets/dashboard_widget_resolver.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  void _refreshAll(WidgetRef ref) {
    ref.invalidate(overallSummaryProvider);
    ref.invalidate(currentMonthSummaryProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(userProfileProvider);
    ref.invalidate(activeBudgetsProvider);
    ref.invalidate(activeBudgetsProgressProvider);
    ref.invalidate(upcomingRecurringProvider);
    ref.invalidate(allRecurringTransactionsProvider);
    ref.invalidate(notificationsListProvider);
    ref.invalidate(activeSavingsGoalsProvider);
    ref.invalidate(allSavingsGoalsProvider);
    ref.invalidate(completedSavingsGoalsProvider);
    ref.invalidate(savingsGoalsSummaryProvider);
    ref.invalidate(allDebtsProvider);
    ref.invalidate(youOweDebtsProvider);
    ref.invalidate(youAreOwedDebtsProvider);
    ref.invalidate(debtSummaryProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final overallSummaryAsync = ref.watch(overallSummaryProvider);
    final currentMonthSummaryAsync = ref.watch(currentMonthSummaryProvider);
    final recentTransactionsAsync = ref.watch(recentTransactionsProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final dashboardLayout = ref.watch(dashboardLayoutProvider);

    // Check loading state
    final isLoading = overallSummaryAsync.isLoading ||
        currentMonthSummaryAsync.isLoading ||
        recentTransactionsAsync.isLoading ||
        accountsAsync.isLoading ||
        categoriesAsync.isLoading;

    // Check error state
    final hasError = overallSummaryAsync.hasError ||
        currentMonthSummaryAsync.hasError ||
        recentTransactionsAsync.hasError ||
        accountsAsync.hasError ||
        categoriesAsync.hasError;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            key: const Key('dashboard_drawer_button'),
            icon: const Icon(LucideIcons.menu, size: 22),
            tooltip: 'Open Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              profileAsync.value?.fullName?.isNotEmpty == true
                  ? profileAsync.value!.fullName!
                  : 'Your Finances',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        actions: [
          const NotificationBadgeIcon(),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            tooltip: 'Refresh',
            onPressed: () => _refreshAll(ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (isLoading && !overallSummaryAsync.hasValue) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading financial data...',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          if (hasError && !overallSummaryAsync.hasValue) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.alertCircle,
                        size: 44,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Unable to load your financial data.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Please check your network connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: 'Retry',
                        onPressed: () => _refreshAll(ref),
                        type: AppButtonType.primary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final overallSummary = overallSummaryAsync.value;
          final currentMonthSummary = currentMonthSummaryAsync.value;
          final recentTransactions = recentTransactionsAsync.value ?? [];
          final accounts = accountsAsync.value ?? [];
          final categories = categoriesAsync.value ?? [];
          final currencySymbol = profileAsync.value?.currencySymbol ?? '₹';

          // Calculate opening balance sum
          final totalOpeningBalance = accounts.fold<double>(
            0.0,
            (sum, acc) => sum + acc.openingBalance,
          );

          final totalCredits = overallSummary?.totalCredit ?? 0.0;
          final totalExpenses = overallSummary?.totalExpense ?? 0.0;
          final netBalance = totalOpeningBalance + (overallSummary?.netBalance ?? 0.0);

          final visibleWidgets = dashboardLayout.visibleWidgets;

          return RefreshIndicator(
            onRefresh: () async => _refreshAll(ref),
            child: visibleWidgets.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.black.withValues(alpha: 0.04),
                                    ),
                                    child: Icon(
                                      LucideIcons.layoutDashboard,
                                      size: 48,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Your dashboard is empty.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'You have hidden all dashboard cards. Choose which widgets to show to get a full view of your finances.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  FilledButton.icon(
                                    key: const Key('empty_dashboard_customize_button'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => context.push('/customize-dashboard'),
                                    icon: const Icon(LucideIcons.slidersHorizontal, size: 18),
                                    label: const Text(
                                      'Customize your dashboard',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < visibleWidgets.length; i++) ...[
                          buildDashboardWidget(
                            type: visibleWidgets[i].type,
                            context: context,
                            netBalance: netBalance,
                            totalCredits: totalCredits,
                            totalExpenses: totalExpenses,
                            currencySymbol: currencySymbol,
                            currentMonthSummary: currentMonthSummary,
                            recentTransactions: recentTransactions,
                            categories: categories,
                            accounts: accounts,
                            onAddExpense: () => context.push('/add-transaction'),
                            onAddCredit: () => context.push('/add-transaction'),
                            onSeeAllTransactions: () => context.go('/transactions'),
                          ),
                          if (i < visibleWidgets.length - 1)
                            const SizedBox(height: 16)
                          else
                            const SizedBox(height: 32),
                        ],
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
