import 'package:intl/intl.dart';

import '../../../budgets/domain/models/budget_progress.dart';
import '../../../recurring/domain/models/recurring_transaction_model.dart';
import '../../../transactions/domain/models/transaction_model.dart';
import '../../../transactions/domain/services/financial_calculation_service.dart';
import '../models/notification_model.dart';
import '../models/notification_settings_model.dart';
import '../models/notification_type.dart';

/// Smart alert evaluation engine.
/// Evaluates alerts based purely on existing domain states without re-calculating financial logic.
class SmartAlertEngine {
  const SmartAlertEngine();

  /// Generates budget threshold and exceeded alerts from active budget progress states.
  List<NotificationModel> checkBudgetAlerts({
    required String userId,
    required List<BudgetProgress> activeProgressList,
    required NotificationSettingsModel settings,
    String currencySymbol = '₹',
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final formatter = NumberFormat('#,##,##0.##', 'en_IN');
    final alerts = <NotificationModel>[];

    for (final progress in activeProgressList) {
      final budget = progress.budget;
      final budgetName = budget.name;
      final formattedAmount = '$currencySymbol${formatter.format(budget.amount)}';
      final formattedSpent = '$currencySymbol${formatter.format(progress.spent)}';
      final formattedRemaining = '$currencySymbol${formatter.format(progress.remaining)}';

      if (progress.isOverBudget && settings.budgetExceededEnabled) {
        final overAmount = '$currencySymbol${formatter.format(progress.overBudgetAmount)}';
        alerts.add(
          NotificationModel(
            id: 'alert_budget_exceeded_${budget.id}',
            userId: userId,
            type: NotificationType.budgetExceeded,
            title: '🚨 $budgetName Exceeded',
            body: 'Your $budgetName spending has exceeded your $formattedAmount budget by $overAmount. ($formattedSpent spent).',
            referenceId: budget.id,
            createdAt: now,
            metadata: {
              'budgetId': budget.id,
              'percentage': progress.percentage,
              'overAmount': progress.overBudgetAmount,
            },
          ),
        );
      } else if (progress.isWarning && settings.budgetWarningEnabled) {
        final pct = progress.percentage.toInt();
        alerts.add(
          NotificationModel(
            id: 'alert_budget_warning_${budget.id}',
            userId: userId,
            type: NotificationType.budgetWarning,
            title: '⚠️ $budgetName Budget Warning',
            body: "You've reached $pct% of your $formattedAmount $budgetName budget ($formattedSpent spent, $formattedRemaining remaining).",
            referenceId: budget.id,
            createdAt: now,
            metadata: {
              'budgetId': budget.id,
              'percentage': progress.percentage,
            },
          ),
        );
      }
    }

    return alerts;
  }

  /// Generates upcoming bill reminders for recurring transactions due soon (1-3 days).
  List<NotificationModel> checkRecurringReminders({
    required String userId,
    required List<RecurringTransactionModel> upcomingRecurringList,
    required NotificationSettingsModel settings,
    String currencySymbol = '₹',
    DateTime? referenceDate,
  }) {
    if (!settings.recurringUpcomingEnabled) return [];

    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final formatter = NumberFormat('#,##,##0.##', 'en_IN');
    final reminders = <NotificationModel>[];

    for (final item in upcomingRecurringList) {
      if (!item.isActive) continue;

      final occ = DateTime(
        item.nextOccurrence.year,
        item.nextOccurrence.month,
        item.nextOccurrence.day,
      );
      final diffDays = occ.difference(today).inDays;
      final formattedAmount = '$currencySymbol${formatter.format(item.amount)}';

      if (diffDays == 0) {
        reminders.add(
          NotificationModel(
            id: 'reminder_due_${item.id}_${occ.toIso8601String()}',
            userId: userId,
            type: NotificationType.recurringDue,
            title: '🔔 ${item.description} Due Today',
            body: '$formattedAmount for ${item.description} is scheduled for today.',
            referenceId: item.id,
            createdAt: now,
            metadata: {'recurringId': item.id, 'amount': item.amount},
          ),
        );
      } else if (diffDays == 1) {
        reminders.add(
          NotificationModel(
            id: 'reminder_upcoming_${item.id}_${occ.toIso8601String()}',
            userId: userId,
            type: NotificationType.recurringUpcoming,
            title: '🔔 Upcoming Payment: ${item.description}',
            body: '$formattedAmount for ${item.description} is due tomorrow.',
            referenceId: item.id,
            createdAt: now,
            metadata: {'recurringId': item.id, 'amount': item.amount},
          ),
        );
      } else if (diffDays > 1 && diffDays <= 3) {
        reminders.add(
          NotificationModel(
            id: 'reminder_upcoming_${item.id}_${occ.toIso8601String()}',
            userId: userId,
            type: NotificationType.recurringUpcoming,
            title: '🔔 Upcoming Bill: ${item.description}',
            body: '$formattedAmount for ${item.description} is due in $diffDays days.',
            referenceId: item.id,
            createdAt: now,
            metadata: {'recurringId': item.id, 'amount': item.amount},
          ),
        );
      }
    }

    return reminders;
  }

  /// Generates a confirmation notification when a recurring transaction is automatically posted.
  NotificationModel? createAutoRecordedAlert({
    required String userId,
    required RecurringTransactionModel item,
    required TransactionModel recordedTransaction,
    required NotificationSettingsModel settings,
    String currencySymbol = '₹',
    DateTime? timestamp,
  }) {
    if (!settings.recurringAutoCreatedEnabled) return null;

    final now = timestamp ?? DateTime.now();
    final formatter = NumberFormat('#,##,##0.##', 'en_IN');
    final formattedAmount = '$currencySymbol${formatter.format(recordedTransaction.amount)}';

    return NotificationModel(
      id: 'auto_recorded_${recordedTransaction.id}',
      userId: userId,
      type: NotificationType.recurringCompleted,
      title: '✓ Recurring Transaction Recorded',
      body: '$formattedAmount ${item.description} was automatically logged into your transaction ledger.',
      referenceId: recordedTransaction.id,
      createdAt: now,
      metadata: {
        'recurringId': item.id,
        'transactionId': recordedTransaction.id,
        'amount': recordedTransaction.amount,
      },
    );
  }

  /// Checks for abnormal spending surges comparing current period to previous.
  NotificationModel? checkSpendingSurge({
    required String userId,
    required FinancialSummary currentMonth,
    required FinancialSummary previousMonth,
    required NotificationSettingsModel settings,
    String currencySymbol = '₹',
    DateTime? timestamp,
  }) {
    if (!settings.spendingAlertsEnabled) return null;
    if (previousMonth.totalExpense <= 0) return null;

    final diff = currentMonth.totalExpense - previousMonth.totalExpense;
    final pctIncrease = (diff / previousMonth.totalExpense) * 100;

    // Trigger alert if spending is 20%+ higher and increased by at least ₹2,000
    if (pctIncrease >= 20 && diff >= 2000) {
      final formatter = NumberFormat('#,##,##0.##', 'en_IN');
      final formattedDiff = '$currencySymbol${formatter.format(diff)}';
      final formattedTotal = '$currencySymbol${formatter.format(currentMonth.totalExpense)}';

      return NotificationModel(
        id: 'spending_surge_${DateTime.now().year}_${DateTime.now().month}',
        userId: userId,
        type: NotificationType.spendingAlert,
        title: '📊 Spending Surge Alert',
        body: "You've spent $formattedTotal this month, which is ${pctIncrease.toInt()}% (+$formattedDiff) more than last month.",
        createdAt: timestamp ?? DateTime.now(),
        metadata: {
          'currentExpense': currentMonth.totalExpense,
          'previousExpense': previousMonth.totalExpense,
          'increasePercent': pctIncrease,
        },
      );
    }

    return null;
  }
}
