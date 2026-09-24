import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/budgets/domain/models/budget_model.dart';
import 'package:expense_tracker/features/budgets/domain/models/budget_period.dart';
import 'package:expense_tracker/features/budgets/domain/models/budget_progress.dart';
import 'package:expense_tracker/features/notifications/domain/models/notification_settings_model.dart';
import 'package:expense_tracker/features/notifications/domain/models/notification_type.dart';
import 'package:expense_tracker/features/notifications/domain/services/smart_alert_engine.dart';
import 'package:expense_tracker/features/recurring/domain/models/recurring_frequency.dart';
import 'package:expense_tracker/features/recurring/domain/models/recurring_transaction_model.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_type.dart';
import 'package:expense_tracker/features/transactions/domain/services/financial_calculation_service.dart';

void main() {
  const engine = SmartAlertEngine();
  const defaultSettings = NotificationSettingsModel(userId: 'user-1');

  final sampleBudget = BudgetModel(
    id: 'b-1',
    userId: 'user-1',
    name: 'Groceries',
    amount: 5000.0,
    period: BudgetPeriod.monthly,
    startDate: DateTime(2026, 9, 1),
    endDate: DateTime(2026, 9, 30),
    alertThreshold: 0.80,
    isActive: true,
  );

  group('SmartAlertEngine — Budget Alerts', () {
    test('generates warning alert when spending reaches threshold (80%)', () {
      final warningProgress = BudgetProgress(
        budget: sampleBudget,
        spent: 4200.0, // 84%
        effectiveStartDate: DateTime(2026, 9, 1),
        effectiveEndDate: DateTime(2026, 9, 30),
      );

      final alerts = engine.checkBudgetAlerts(
        userId: 'user-1',
        activeProgressList: [warningProgress],
        settings: defaultSettings,
      );

      expect(alerts.length, 1);
      expect(alerts.first.type, NotificationType.budgetWarning);
      expect(alerts.first.title, '⚠️ Groceries Budget Warning');
      expect(alerts.first.body, contains("84%"));
      expect(alerts.first.idempotencyKey, 'BUDGET_WARNING:b-1:2026-09-01:2026-09-30');
    });

    test('generates budget exceeded alert when spending is over 100%', () {
      final overBudgetProgress = BudgetProgress(
        budget: sampleBudget,
        spent: 5650.0, // 113%
        effectiveStartDate: DateTime(2026, 9, 1),
        effectiveEndDate: DateTime(2026, 9, 30),
      );

      final alerts = engine.checkBudgetAlerts(
        userId: 'user-1',
        activeProgressList: [overBudgetProgress],
        settings: defaultSettings,
      );

      expect(alerts.length, 1);
      expect(alerts.first.type, NotificationType.budgetExceeded);
      expect(alerts.first.title, '🚨 Groceries Exceeded');
      expect(alerts.first.body, contains('exceeded your ₹5,000 budget by ₹650'));
      expect(alerts.first.idempotencyKey, 'BUDGET_EXCEEDED:b-1:2026-09-01:2026-09-30');
    });

    test('suppresses alerts when corresponding settings toggles are disabled', () {
      final overBudgetProgress = BudgetProgress(
        budget: sampleBudget,
        spent: 6000.0,
        effectiveStartDate: DateTime(2026, 9, 1),
        effectiveEndDate: DateTime(2026, 9, 30),
      );

      final disabledSettings = defaultSettings.copyWith(
        budgetExceededEnabled: false,
        budgetWarningEnabled: false,
      );

      final alerts = engine.checkBudgetAlerts(
        userId: 'user-1',
        activeProgressList: [overBudgetProgress],
        settings: disabledSettings,
      );

      expect(alerts, isEmpty);
    });

    test('returns empty when activeProgressList is empty', () {
      final alerts = engine.checkBudgetAlerts(
        userId: 'user-1',
        activeProgressList: [],
        settings: defaultSettings,
      );
      expect(alerts, isEmpty);
    });
  });

  group('SmartAlertEngine — Recurring & Upcoming Reminders', () {
    final recurringItem = RecurringTransactionModel(
      id: 'rec-1',
      userId: 'user-1',
      accountId: 'acc-1',
      categoryId: 'cat-1',
      type: TransactionType.expense,
      amount: 649.0,
      description: 'Netflix',
      frequency: RecurringFrequency.monthly,
      startDate: DateTime(2026, 9, 1),
      nextOccurrence: DateTime(2026, 9, 23),
      isActive: true,
    );

    test('generates upcoming reminder for bill due tomorrow', () {
      final reminders = engine.checkRecurringReminders(
        userId: 'user-1',
        upcomingRecurringList: [recurringItem],
        settings: defaultSettings,
        referenceDate: DateTime(2026, 9, 22), // 1 day before Sept 23
      );

      expect(reminders.length, 1);
      expect(reminders.first.type, NotificationType.recurringUpcoming);
      expect(reminders.first.title, '🔔 Upcoming Payment: Netflix');
      expect(reminders.first.body, contains('due tomorrow'));
      expect(reminders.first.idempotencyKey, 'RECURRING_UPCOMING:rec-1:2026-09-23');
    });

    test('generates upcoming reminder for bill due in 2-3 days', () {
      final reminders = engine.checkRecurringReminders(
        userId: 'user-1',
        upcomingRecurringList: [recurringItem],
        settings: defaultSettings,
        referenceDate: DateTime(2026, 9, 21), // 2 days before Sept 23
      );

      expect(reminders.length, 1);
      expect(reminders.first.type, NotificationType.recurringUpcoming);
      expect(reminders.first.title, '🔔 Upcoming Bill: Netflix');
      expect(reminders.first.body, contains('due in 2 days'));
      expect(reminders.first.idempotencyKey, 'RECURRING_UPCOMING:rec-1:2026-09-23');
    });

    test('generates due reminder for bill due today', () {
      final reminders = engine.checkRecurringReminders(
        userId: 'user-1',
        upcomingRecurringList: [recurringItem],
        settings: defaultSettings,
        referenceDate: DateTime(2026, 9, 23), // Same day
      );

      expect(reminders.length, 1);
      expect(reminders.first.type, NotificationType.recurringDue);
      expect(reminders.first.title, '🔔 Netflix Due Today');
      expect(reminders.first.idempotencyKey, 'RECURRING_DUE:rec-1:2026-09-23');
    });

    test('createAutoRecordedAlert creates confirmation notification with transactionId key', () {
      final txn = TransactionModel(
        id: 'tx-101',
        userId: 'user-1',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'EXPENSE',
        amount: 649.0,
        description: 'Netflix (Recurring)',
        transactionDate: DateTime(2026, 9, 23),
      );

      final alert = engine.createAutoRecordedAlert(
        userId: 'user-1',
        item: recurringItem,
        recordedTransaction: txn,
        settings: defaultSettings,
      );

      expect(alert, isNotNull);
      expect(alert!.type, NotificationType.recurringCompleted);
      expect(alert.title, '✓ Recurring Transaction Recorded');
      expect(alert.body, contains('Netflix was automatically logged'));
      expect(alert.idempotencyKey, 'RECURRING_COMPLETED:rec-1:tx-101');
    });

    test('suppresses reminders when recurringUpcomingEnabled is false', () {
      final disabledSettings = defaultSettings.copyWith(recurringUpcomingEnabled: false);
      final reminders = engine.checkRecurringReminders(
        userId: 'user-1',
        upcomingRecurringList: [recurringItem],
        settings: disabledSettings,
        referenceDate: DateTime(2026, 9, 22),
      );
      expect(reminders, isEmpty);
    });
  });

  group('SmartAlertEngine — Spending & Monthly Summary Alerts', () {
    test('triggers alert when current expenses are 20%+ higher than previous month', () {
      const prevMonth = FinancialSummary(totalCredit: 50000, totalExpense: 10000);
      const currMonth = FinancialSummary(totalCredit: 50000, totalExpense: 15000); // 50% increase (₹5000)

      final alert = engine.checkSpendingAlerts(
        userId: 'user-1',
        currentMonth: currMonth,
        previousMonth: prevMonth,
        settings: defaultSettings,
        periodStart: DateTime(2026, 9, 1),
        periodEnd: DateTime(2026, 9, 30),
      );

      expect(alert, isNotNull);
      expect(alert!.type, NotificationType.spendingAlert);
      expect(alert.title, '📊 Spending Surge Alert');
      expect(alert.body, contains('50%'));
      expect(alert.idempotencyKey, 'SPENDING_ALERT:2026-09-01:2026-09-30:SURGE');
    });

    test('does not trigger spending alert when increase is under threshold', () {
      const prevMonth = FinancialSummary(totalCredit: 50000, totalExpense: 10000);
      const currMonth = FinancialSummary(totalCredit: 50000, totalExpense: 10500); // 5% increase

      final alert = engine.checkSpendingAlerts(
        userId: 'user-1',
        currentMonth: currMonth,
        previousMonth: prevMonth,
        settings: defaultSettings,
      );

      expect(alert, isNull);
    });

    test('generates monthly summary notification when enabled', () {
      const monthlySummary = FinancialSummary(
        totalCredit: 45000,
        totalExpense: 18500,
      );

      final summaryAlert = engine.createMonthlySummaryAlert(
        userId: 'user-1',
        monthlySummary: monthlySummary,
        year: 2026,
        month: 9,
        settings: defaultSettings,
      );

      expect(summaryAlert, isNotNull);
      expect(summaryAlert!.type, NotificationType.monthlySummary);
      expect(summaryAlert.title, '📊 September Summary');
      expect(summaryAlert.body, contains('Credits: ₹45,000'));
      expect(summaryAlert.body, contains('Expenses: ₹18,500'));
      expect(summaryAlert.body, contains('Net: +₹26,500'));
      expect(summaryAlert.idempotencyKey, 'MONTHLY_SUMMARY:2026:9');
    });

    test('suppresses monthly summary when monthlySummaryEnabled is false', () {
      final disabled = defaultSettings.copyWith(monthlySummaryEnabled: false);
      const monthlySummary = FinancialSummary(totalCredit: 45000, totalExpense: 18500);

      final summaryAlert = engine.createMonthlySummaryAlert(
        userId: 'user-1',
        monthlySummary: monthlySummary,
        year: 2026,
        month: 9,
        settings: disabled,
      );

      expect(summaryAlert, isNull);
    });
  });

  group('SmartAlertEngine — Idempotency & Repeated Evaluation Tests', () {
    test('same budget warning evaluated twice produces identical alert key', () {
      final warningProgress = BudgetProgress(
        budget: sampleBudget,
        spent: 4200.0,
        effectiveStartDate: DateTime(2026, 9, 1),
        effectiveEndDate: DateTime(2026, 9, 30),
      );

      final eval1 = engine.checkBudgetAlerts(
        userId: 'user-1',
        activeProgressList: [warningProgress],
        settings: defaultSettings,
      );

      final eval2 = engine.checkBudgetAlerts(
        userId: 'user-1',
        activeProgressList: [warningProgress],
        settings: defaultSettings,
      );

      expect(eval1.length, 1);
      expect(eval2.length, 1);
      expect(eval1.first.idempotencyKey, eval2.first.idempotencyKey);
      expect(eval1.first.idempotencyKey, 'BUDGET_WARNING:b-1:2026-09-01:2026-09-30');
    });

    test('same budget exceeded evaluated twice produces identical alert key', () {
      final overProgress = BudgetProgress(
        budget: sampleBudget,
        spent: 6000.0,
        effectiveStartDate: DateTime(2026, 9, 1),
        effectiveEndDate: DateTime(2026, 9, 30),
      );

      final eval1 = engine.checkBudgetAlerts(
        userId: 'user-1',
        activeProgressList: [overProgress],
        settings: defaultSettings,
      );

      final eval2 = engine.checkBudgetAlerts(
        userId: 'user-1',
        activeProgressList: [overProgress],
        settings: defaultSettings,
      );

      expect(eval1.first.idempotencyKey, eval2.first.idempotencyKey);
      expect(eval1.first.idempotencyKey, 'BUDGET_EXCEEDED:b-1:2026-09-01:2026-09-30');
    });

    test('same recurring occurrence evaluated twice produces identical alert key', () {
      final recurringItem = RecurringTransactionModel(
        id: 'rec-1',
        userId: 'user-1',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 649.0,
        description: 'Netflix',
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(2026, 9, 1),
        nextOccurrence: DateTime(2026, 9, 23),
        isActive: true,
      );

      final eval1 = engine.checkRecurringReminders(
        userId: 'user-1',
        upcomingRecurringList: [recurringItem],
        settings: defaultSettings,
        referenceDate: DateTime(2026, 9, 22),
      );

      final eval2 = engine.checkRecurringReminders(
        userId: 'user-1',
        upcomingRecurringList: [recurringItem],
        settings: defaultSettings,
        referenceDate: DateTime(2026, 9, 22),
      );

      expect(eval1.first.idempotencyKey, eval2.first.idempotencyKey);
      expect(eval1.first.idempotencyKey, 'RECURRING_UPCOMING:rec-1:2026-09-23');
    });

    test('same completed transaction evaluated twice produces identical alert key', () {
      final recurringItem = RecurringTransactionModel(
        id: 'rec-1',
        userId: 'user-1',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 649.0,
        description: 'Netflix',
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(2026, 9, 1),
        nextOccurrence: DateTime(2026, 9, 23),
        isActive: true,
      );

      final txn = TransactionModel(
        id: 'tx-101',
        userId: 'user-1',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'EXPENSE',
        amount: 649.0,
        description: 'Netflix (Recurring)',
        transactionDate: DateTime(2026, 9, 23),
      );

      final eval1 = engine.createAutoRecordedAlert(
        userId: 'user-1',
        item: recurringItem,
        recordedTransaction: txn,
        settings: defaultSettings,
      );

      final eval2 = engine.createAutoRecordedAlert(
        userId: 'user-1',
        item: recurringItem,
        recordedTransaction: txn,
        settings: defaultSettings,
      );

      expect(eval1!.idempotencyKey, eval2!.idempotencyKey);
      expect(eval1.idempotencyKey, 'RECURRING_COMPLETED:rec-1:tx-101');
    });

    test('same monthly summary evaluated twice produces identical alert key', () {
      const summary = FinancialSummary(totalCredit: 45000, totalExpense: 18500);

      final eval1 = engine.createMonthlySummaryAlert(
        userId: 'user-1',
        monthlySummary: summary,
        year: 2026,
        month: 9,
        settings: defaultSettings,
      );

      final eval2 = engine.createMonthlySummaryAlert(
        userId: 'user-1',
        monthlySummary: summary,
        year: 2026,
        month: 9,
        settings: defaultSettings,
      );

      expect(eval1!.idempotencyKey, eval2!.idempotencyKey);
      expect(eval1.idempotencyKey, 'MONTHLY_SUMMARY:2026:9');
    });
  });
}
