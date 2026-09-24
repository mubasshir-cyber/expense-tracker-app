import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum DashboardWidgetType {
  balance('balance', 'Balance', 'Total balance, credits & expenses', LucideIcons.wallet),
  monthlySummary('monthlySummary', 'Monthly Summary', 'This month income vs expense breakdown', LucideIcons.pieChart),
  quickActions('quickActions', 'Quick Actions', 'One-tap shortcuts for income and expenses', LucideIcons.zap),
  budgets('budgets', 'Budgets', 'Active budget progress & spending alerts', LucideIcons.target),
  recurring('recurring', 'Recurring Payments', 'Upcoming bills & active subscriptions', LucideIcons.repeat),
  savingsGoals('savingsGoals', 'Savings Goals', 'Target milestones & progress towards savings', LucideIcons.piggyBank),
  debts('debts', 'Debts & Loans', 'Money you owe and money you are owed', LucideIcons.arrowLeftRight),
  recentTransactions('recentTransactions', 'Recent Transactions', 'Latest transaction history entries', LucideIcons.receipt);

  const DashboardWidgetType(
    this.key,
    this.displayName,
    this.description,
    this.icon,
  );

  final String key;
  final String displayName;
  final String description;
  final IconData icon;

  static DashboardWidgetType? fromKey(String? key) {
    if (key == null) return null;
    for (final type in DashboardWidgetType.values) {
      if (type.key == key || type.name == key) {
        return type;
      }
    }
    return null;
  }
}
