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
    });

    test('createAutoRecordedAlert creates confirmation notification', () {
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
    });
  });

  group('SmartAlertEngine — Spending Surge Alerts', () {
    test('triggers alert when current expenses are 20%+ higher than previous month', () {
      const prevMonth = FinancialSummary(totalCredit: 50000, totalExpense: 10000);
      const currMonth = FinancialSummary(totalCredit: 50000, totalExpense: 15000); // 50% increase (₹5000)

      final alert = engine.checkSpendingSurge(
        userId: 'user-1',
        currentMonth: currMonth,
        previousMonth: prevMonth,
        settings: defaultSettings,
      );

      expect(alert, isNotNull);
      expect(alert!.type, NotificationType.spendingAlert);
      expect(alert.title, '📊 Spending Surge Alert');
      expect(alert.body, contains('50%'));
    });

    test('does not trigger when spending increase is minor (< 20%)', () {
      const prevMonth = FinancialSummary(totalCredit: 50000, totalExpense: 10000);
      const currMonth = FinancialSummary(totalCredit: 50000, totalExpense: 10500); // 5% increase

      final alert = engine.checkSpendingSurge(
        userId: 'user-1',
        currentMonth: currMonth,
        previousMonth: prevMonth,
        settings: defaultSettings,
      );

      expect(alert, isNull);
    });
  });
}
