import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

/// Semantic types of smart financial notifications.
enum NotificationType {
  budgetWarning('BUDGET_WARNING', 'Budget Warning'),
  budgetExceeded('BUDGET_EXCEEDED', 'Budget Exceeded'),
  recurringUpcoming('RECURRING_UPCOMING', 'Upcoming Bill'),
  recurringDue('RECURRING_DUE', 'Payment Due'),
  recurringCompleted('RECURRING_COMPLETED', 'Recurring Transaction'),
  spendingAlert('SPENDING_ALERT', 'Spending Alert'),
  monthlySummary('MONTHLY_SUMMARY', 'Monthly Summary'),
  debtDue('DEBT_DUE', 'Loan Due'),
  goalMilestone('GOAL_MILESTONE', 'Savings Milestone'),
  khataDue('KHATA_DUE', 'Khata Reminder'),
  system('SYSTEM', 'System');

  const NotificationType(this.value, this.label);

  final String value;
  final String label;

  static NotificationType fromValue(String value) {
    switch (value.toUpperCase()) {
      case 'BUDGET_WARNING':
        return NotificationType.budgetWarning;
      case 'BUDGET_EXCEEDED':
        return NotificationType.budgetExceeded;
      case 'RECURRING_UPCOMING':
        return NotificationType.recurringUpcoming;
      case 'RECURRING_DUE':
        return NotificationType.recurringDue;
      case 'RECURRING_COMPLETED':
        return NotificationType.recurringCompleted;
      case 'SPENDING_ALERT':
        return NotificationType.spendingAlert;
      case 'MONTHLY_SUMMARY':
        return NotificationType.monthlySummary;
      case 'DEBT_DUE':
        return NotificationType.debtDue;
      case 'GOAL_MILESTONE':
        return NotificationType.goalMilestone;
      case 'KHATA_DUE':
        return NotificationType.khataDue;
      case 'SYSTEM':
      default:
        return NotificationType.system;
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.budgetWarning:
        return LucideIcons.alertTriangle;
      case NotificationType.budgetExceeded:
        return LucideIcons.alertOctagon;
      case NotificationType.recurringUpcoming:
        return LucideIcons.bell;
      case NotificationType.recurringDue:
        return LucideIcons.calendarClock;
      case NotificationType.recurringCompleted:
        return LucideIcons.checkCircle2;
      case NotificationType.spendingAlert:
        return LucideIcons.trendingUp;
      case NotificationType.monthlySummary:
        return LucideIcons.barChart3;
      case NotificationType.debtDue:
        return LucideIcons.landmark;
      case NotificationType.goalMilestone:
        return LucideIcons.target;
      case NotificationType.khataDue:
        return LucideIcons.bookOpen;
      case NotificationType.system:
        return LucideIcons.info;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.budgetWarning:
        return const Color(0xFFF59E0B); // Amber
      case NotificationType.budgetExceeded:
        return AppColors.error; // Red
      case NotificationType.recurringUpcoming:
        return const Color(0xFF8B5CF6); // Purple
      case NotificationType.recurringDue:
        return const Color(0xFFF97316); // Orange
      case NotificationType.recurringCompleted:
        return AppColors.credit; // Green
      case NotificationType.spendingAlert:
        return const Color(0xFFEC4899); // Pink
      case NotificationType.monthlySummary:
        return AppColors.primary; // Blue
      case NotificationType.debtDue:
        return const Color(0xFFD97706); // Amber-700
      case NotificationType.goalMilestone:
        return const Color(0xFF10B981); // Emerald
      case NotificationType.khataDue:
        return const Color(0xFF6366F1); // Indigo
      case NotificationType.system:
        return const Color(0xFF6B7280); // Gray
    }
  }
}
