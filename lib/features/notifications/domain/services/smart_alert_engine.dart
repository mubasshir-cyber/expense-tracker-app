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
/// All generated notifications contain deterministic idempotency keys.
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
      final startStr = progress.effectiveStartDate.toIso8601String().split('T').first;
      final endStr = progress.effectiveEndDate.toIso8601String().split('T').first;

      if (progress.isOverBudget && settings.budgetExceededEnabled) {
        final overAmount = '$currencySymbol${formatter.format(progress.overBudgetAmount)}';
        final alertKey = 'BUDGET_EXCEEDED:${budget.id}:$startStr:$endStr';
        alerts.add(
          NotificationModel(
            id: 'alert_budget_exceeded_${budget.id}',
            userId: userId,
            type: NotificationType.budgetExceeded,
            title: '🚨 $budgetName Exceeded',
            body: 'Your $budgetName spending has exceeded your $formattedAmount budget by $overAmount. ($formattedSpent spent).',
            referenceId: budget.id,
            idempotencyKey: alertKey,
            createdAt: now,
            metadata: {
              'budgetId': budget.id,
              'percentage': progress.percentage,
              'overAmount': progress.overBudgetAmount,
              'periodStart': startStr,
              'periodEnd': endStr,
            },
          ),
        );
      } else if (progress.isWarning && settings.budgetWarningEnabled) {
        final pct = progress.percentage.toInt();
        final alertKey = 'BUDGET_WARNING:${budget.id}:$startStr:$endStr';
        alerts.add(
          NotificationModel(
            id: 'alert_budget_warning_${budget.id}',
            userId: userId,
            type: NotificationType.budgetWarning,
            title: '⚠️ $budgetName Budget Warning',
            body: "You've reached $pct% of your $formattedAmount $budgetName budget ($formattedSpent spent, $formattedRemaining remaining).",
            referenceId: budget.id,
            idempotencyKey: alertKey,
            createdAt: now,
            metadata: {
              'budgetId': budget.id,
              'percentage': progress.percentage,
              'periodStart': startStr,
              'periodEnd': endStr,
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
      final occDateStr = occ.toIso8601String().split('T').first;
      final diffDays = occ.difference(today).inDays;
      final formattedAmount = '$currencySymbol${formatter.format(item.amount)}';

      if (diffDays == 0) {
        final alertKey = 'RECURRING_DUE:${item.id}:$occDateStr';
        reminders.add(
          NotificationModel(
            id: 'reminder_due_${item.id}_$occDateStr',
            userId: userId,
            type: NotificationType.recurringDue,
            title: '🔔 ${item.description} Due Today',
            body: '$formattedAmount for ${item.description} is scheduled for today.',
            referenceId: item.id,
            idempotencyKey: alertKey,
            createdAt: now,
            metadata: {
              'recurringId': item.id,
              'amount': item.amount,
              'occurrenceDate': occDateStr,
            },
          ),
        );
      } else if (diffDays == 1) {
        final alertKey = 'RECURRING_UPCOMING:${item.id}:$occDateStr';
        reminders.add(
          NotificationModel(
            id: 'reminder_upcoming_${item.id}_$occDateStr',
            userId: userId,
            type: NotificationType.recurringUpcoming,
            title: '🔔 Upcoming Payment: ${item.description}',
            body: '$formattedAmount for ${item.description} is due tomorrow.',
            referenceId: item.id,
            idempotencyKey: alertKey,
            createdAt: now,
            metadata: {
              'recurringId': item.id,
              'amount': item.amount,
              'occurrenceDate': occDateStr,
            },
          ),
        );
      } else if (diffDays > 1 && diffDays <= 3) {
        final alertKey = 'RECURRING_UPCOMING:${item.id}:$occDateStr';
        reminders.add(
          NotificationModel(
            id: 'reminder_upcoming_${item.id}_$occDateStr',
            userId: userId,
            type: NotificationType.recurringUpcoming,
            title: '🔔 Upcoming Bill: ${item.description}',
            body: '$formattedAmount for ${item.description} is due in $diffDays days.',
            referenceId: item.id,
            idempotencyKey: alertKey,
            createdAt: now,
            metadata: {
              'recurringId': item.id,
              'amount': item.amount,
              'occurrenceDate': occDateStr,
            },
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
    final alertKey = 'RECURRING_COMPLETED:${item.id}:${recordedTransaction.id}';

    return NotificationModel(
      id: 'auto_recorded_${recordedTransaction.id}',
      userId: userId,
      type: NotificationType.recurringCompleted,
      title: '✓ Recurring Transaction Recorded',
      body: '$formattedAmount ${item.description} was automatically logged into your transaction ledger.',
      referenceId: recordedTransaction.id,
      idempotencyKey: alertKey,
      createdAt: now,
      metadata: {
        'recurringId': item.id,
        'transactionId': recordedTransaction.id,
        'amount': recordedTransaction.amount,
      },
    );
  }

  /// Checks for abnormal spending surges comparing current period to previous.
  NotificationModel? checkSpendingAlerts({
    required String userId,
    required FinancialSummary currentMonth,
    required FinancialSummary previousMonth,
    required NotificationSettingsModel settings,
    String currencySymbol = '₹',
    DateTime? timestamp,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    if (!settings.spendingAlertsEnabled) return null;
    if (previousMonth.totalExpense <= 0) return null;

    final diff = currentMonth.totalExpense - previousMonth.totalExpense;
    final pctIncrease = (diff / previousMonth.totalExpense) * 100;

    // Trigger alert if spending is 20%+ higher and increased by at least ₹2,000
    if (pctIncrease >= 20 && diff >= 2000) {
      final now = timestamp ?? DateTime.now();
      final formatter = NumberFormat('#,##,##0.##', 'en_IN');
      final formattedDiff = '$currencySymbol${formatter.format(diff)}';
      final formattedTotal = '$currencySymbol${formatter.format(currentMonth.totalExpense)}';
      
      final startStr = periodStart != null 
          ? periodStart.toIso8601String().split('T').first 
          : '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final endStr = periodEnd != null 
          ? periodEnd.toIso8601String().split('T').first 
          : now.toIso8601String().split('T').first;
      final alertKey = 'SPENDING_ALERT:$startStr:$endStr:SURGE';

      return NotificationModel(
        id: 'spending_surge_${now.year}_${now.month}',
        userId: userId,
        type: NotificationType.spendingAlert,
        title: '📊 Spending Surge Alert',
        body: "You've spent $formattedTotal this month, which is ${pctIncrease.toInt()}% (+$formattedDiff) more than last month.",
        idempotencyKey: alertKey,
        createdAt: now,
        metadata: {
          'currentExpense': currentMonth.totalExpense,
          'previousExpense': previousMonth.totalExpense,
          'increasePercent': pctIncrease,
          'periodStart': startStr,
          'periodEnd': endStr,
        },
      );
    }

    return null;
  }

  /// Backward-compatible alias for checkSpendingAlerts.
  NotificationModel? checkSpendingSurge({
    required String userId,
    required FinancialSummary currentMonth,
    required FinancialSummary previousMonth,
    required NotificationSettingsModel settings,
    String currencySymbol = '₹',
    DateTime? timestamp,
  }) {
    return checkSpendingAlerts(
      userId: userId,
      currentMonth: currentMonth,
      previousMonth: previousMonth,
      settings: settings,
      currencySymbol: currencySymbol,
      timestamp: timestamp,
    );
  }

  /// Generates a monthly summary notification for a completed or evaluated month.
  NotificationModel? createMonthlySummaryAlert({
    required String userId,
    required FinancialSummary monthlySummary,
    required int year,
    required int month,
    required NotificationSettingsModel settings,
    String currencySymbol = '₹',
    DateTime? timestamp,
  }) {
    if (!settings.monthlySummaryEnabled) return null;

    final now = timestamp ?? DateTime.now();
    final formatter = NumberFormat('#,##,##0.##', 'en_IN');
    final monthName = DateFormat('MMMM').format(DateTime(year, month, 1));
    final formattedCredits = '$currencySymbol${formatter.format(monthlySummary.totalCredit)}';
    final formattedExpenses = '$currencySymbol${formatter.format(monthlySummary.totalExpense)}';
    final net = monthlySummary.netBalance;
    final sign = net >= 0 ? '+' : '-';
    final formattedNet = '$sign$currencySymbol${formatter.format(net.abs())}';
    final alertKey = 'MONTHLY_SUMMARY:$year:$month';

    return NotificationModel(
      id: 'monthly_summary_${year}_$month',
      userId: userId,
      type: NotificationType.monthlySummary,
      title: '📊 $monthName Summary',
      body: 'Credits: $formattedCredits • Expenses: $formattedExpenses • Net: $formattedNet',
      idempotencyKey: alertKey,
      createdAt: now,
      metadata: {
        'year': year,
        'month': month,
        'credits': monthlySummary.totalCredit,
        'expenses': monthlySummary.totalExpense,
        'net': monthlySummary.netBalance,
      },
    );
  }
}
