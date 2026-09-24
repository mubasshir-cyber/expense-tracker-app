import 'package:flutter/material.dart';
import '../../../accounts/domain/models/account_model.dart';
import '../../../categories/domain/models/category_model.dart';
import '../../../transactions/domain/models/transaction_model.dart';
import '../../../transactions/domain/services/financial_calculation_service.dart';
import '../../domain/models/dashboard_widget_type.dart';
import 'balance_card.dart';
import 'dashboard_budget_card.dart';
import 'dashboard_debts_card.dart';
import 'dashboard_savings_goals_card.dart';
import 'dashboard_upcoming_payments_card.dart';
import 'monthly_summary_card.dart';
import 'quick_actions.dart';
import 'recent_transactions.dart';

/// Resolves a [DashboardWidgetType] into its corresponding dashboard widget card.
Widget buildDashboardWidget({
  required DashboardWidgetType type,
  required BuildContext context,
  required double netBalance,
  required double totalCredits,
  required double totalExpenses,
  required String currencySymbol,
  required FinancialSummary? currentMonthSummary,
  required List<TransactionModel> recentTransactions,
  required List<CategoryModel> categories,
  required List<AccountModel> accounts,
  required VoidCallback onAddExpense,
  required VoidCallback onAddCredit,
  required VoidCallback onSeeAllTransactions,
}) {
  switch (type) {
    case DashboardWidgetType.balance:
      return BalanceCard(
        netBalance: netBalance,
        totalCredits: totalCredits,
        totalExpenses: totalExpenses,
        currencySymbol: currencySymbol,
      );

    case DashboardWidgetType.monthlySummary:
      if (currentMonthSummary == null) {
        return const SizedBox.shrink();
      }
      return MonthlySummaryCard(
        summary: currentMonthSummary,
        currencySymbol: currencySymbol,
      );

    case DashboardWidgetType.quickActions:
      return QuickActions(
        onAddExpense: onAddExpense,
        onAddCredit: onAddCredit,
      );

    case DashboardWidgetType.budgets:
      return DashboardBudgetCard(
        currencySymbol: currencySymbol,
      );

    case DashboardWidgetType.recurring:
      return DashboardUpcomingPaymentsCard(
        currencySymbol: currencySymbol,
      );

    case DashboardWidgetType.savingsGoals:
      return DashboardSavingsGoalsCard(
        currencySymbol: currencySymbol,
      );

    case DashboardWidgetType.debts:
      return DashboardDebtsCard(
        currencySymbol: currencySymbol,
      );

    case DashboardWidgetType.recentTransactions:
      return RecentTransactions(
        transactions: recentTransactions,
        categories: categories,
        accounts: accounts,
        currencySymbol: currencySymbol,
        onSeeAll: onSeeAllTransactions,
        onAddExpense: onAddExpense,
        onAddCredit: onAddCredit,
      );
  }
}
