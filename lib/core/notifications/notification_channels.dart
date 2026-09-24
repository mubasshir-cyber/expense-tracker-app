import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Centralized definitions for Android Notification Channels.
class AppNotificationChannels {
  AppNotificationChannels._();

  /// Channel 1: Budget Alerts (High Importance)
  static const AndroidNotificationChannel budgetAlerts =
      AndroidNotificationChannel(
    'budget_alerts',
    'Budget Alerts',
    description: 'Alerts when spending approaches or exceeds budget limits.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// Channel 2: Payment & Bill Reminders (High Importance)
  static const AndroidNotificationChannel paymentReminders =
      AndroidNotificationChannel(
    'payment_reminders',
    'Bill & Payment Reminders',
    description: 'Upcoming recurring bill reminders and subscription schedules.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// Channel 3: Loan & Debt Reminders (High Importance)
  static const AndroidNotificationChannel loanReminders =
      AndroidNotificationChannel(
    'loan_reminders',
    'Loan & Debt Reminders',
    description: 'Due date alerts for borrowed and lent debts.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// Channel 4: Khata Reminders (Default Importance)
  static const AndroidNotificationChannel khataReminders =
      AndroidNotificationChannel(
    'khata_reminders',
    'Khata Reminders',
    description: 'Pending payment reminders for customer credit balances.',
    importance: Importance.defaultImportance,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// Channel 5: Savings Goal Alerts (Default Importance)
  static const AndroidNotificationChannel savingsAlerts =
      AndroidNotificationChannel(
    'savings_alerts',
    'Savings Goals',
    description: 'Milestones and progress updates for savings goals.',
    importance: Importance.defaultImportance,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// Channel 6: General Financial Alerts (Default Importance)
  static const AndroidNotificationChannel financeAlerts =
      AndroidNotificationChannel(
    'finance_alerts',
    'General Financial Alerts',
    description: 'Spending reports and general financial notifications.',
    importance: Importance.defaultImportance,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// List of all channels to register on Android app start.
  static const List<AndroidNotificationChannel> all = [
    budgetAlerts,
    paymentReminders,
    loanReminders,
    khataReminders,
    savingsAlerts,
    financeAlerts,
  ];
}
