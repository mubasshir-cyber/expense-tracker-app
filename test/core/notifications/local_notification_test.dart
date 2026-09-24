import 'package:expense_tracker/core/notifications/notification_channels.dart';
import 'package:expense_tracker/core/notifications/notification_payload.dart';
import 'package:expense_tracker/core/notifications/local_notification_service.dart';
import 'package:expense_tracker/core/notifications/system_notification_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Notification Channels', () {
    test('All channels are defined with correct importance levels', () {
      expect(AppNotificationChannels.all.length, 6);

      expect(AppNotificationChannels.budgetAlerts.id, 'budget_alerts');
      expect(AppNotificationChannels.budgetAlerts.importance, Importance.high);

      expect(AppNotificationChannels.paymentReminders.id, 'payment_reminders');
      expect(AppNotificationChannels.paymentReminders.importance, Importance.high);

      expect(AppNotificationChannels.loanReminders.id, 'loan_reminders');
      expect(AppNotificationChannels.loanReminders.importance, Importance.high);

      expect(AppNotificationChannels.khataReminders.id, 'khata_reminders');
      expect(AppNotificationChannels.khataReminders.importance, Importance.defaultImportance);

      expect(AppNotificationChannels.savingsAlerts.id, 'savings_alerts');
      expect(AppNotificationChannels.savingsAlerts.importance, Importance.defaultImportance);

      expect(AppNotificationChannels.financeAlerts.id, 'finance_alerts');
      expect(AppNotificationChannels.financeAlerts.importance, Importance.defaultImportance);
    });
  });

  group('AppNotificationPayload', () {
    test('Serializes to JSON and deserializes correctly', () {
      const payload = AppNotificationPayload(
        type: 'budget',
        entityId: 'budget-123',
        targetRoute: '/budgets',
        extraData: {'percentage': 85},
      );

      final jsonStr = payload.toJson();
      final parsed = AppNotificationPayload.fromJson(jsonStr);

      expect(parsed.type, 'budget');
      expect(parsed.entityId, 'budget-123');
      expect(parsed.targetRoute, '/budgets');
      expect(parsed.extraData?['percentage'], 85);
    });

    test('Resolved route fallbacks work for all entity types', () {
      const budgetPayload = AppNotificationPayload(type: 'budget');
      expect(budgetPayload.resolvedRoute, '/budgets');

      const recurringPayload = AppNotificationPayload(type: 'recurring');
      expect(recurringPayload.resolvedRoute, '/recurring');

      const debtPayload = AppNotificationPayload(type: 'debt', entityId: 'debt-99');
      expect(debtPayload.resolvedRoute, '/debts/debt-99');

      const goalPayload = AppNotificationPayload(type: 'goal', entityId: 'goal-55');
      expect(goalPayload.resolvedRoute, '/savings-goals/goal-55');

      const khataPayload = AppNotificationPayload(type: 'khata', entityId: 'cust-12');
      expect(khataPayload.resolvedRoute, '/khata/cust-12');

      const genericPayload = AppNotificationPayload(type: 'other');
      expect(genericPayload.resolvedRoute, '/notifications');
    });
  });

  group('LocalNotificationService - Deduplication & ID Generation', () {
    test('generateNotificationId produces deterministic positive IDs', () {
      final service = LocalNotificationService();

      final id1 = service.generateNotificationId('budget', 'b1', '2026-09');
      final id2 = service.generateNotificationId('budget', 'b1', '2026-09');
      final id3 = service.generateNotificationId('budget', 'b2', '2026-09');

      expect(id1, equals(id2)); // Same entity and period -> same ID (prevents duplicates)
      expect(id1, isNot(equals(id3))); // Different entity -> different ID
      expect(id1, isNonNegative);
      expect(id3, isNonNegative);
    });
  });

  group('SystemNotificationPreferences', () {
    test('Defaults to enabled with false for privacy mask', () {
      const prefs = SystemNotificationPreferences();
      expect(prefs.systemNotificationsEnabled, isTrue);
      expect(prefs.budgetAlertsEnabled, isTrue);
      expect(prefs.recurringAlertsEnabled, isTrue);
      expect(prefs.loanAlertsEnabled, isTrue);
      expect(prefs.savingsAlertsEnabled, isTrue);
      expect(prefs.khataAlertsEnabled, isTrue);
      expect(prefs.hideSensitiveAmounts, isFalse);
    });

    test('copyWith updates specific preferences accurately', () {
      const prefs = SystemNotificationPreferences();
      final updated = prefs.copyWith(
        systemNotificationsEnabled: false,
        hideSensitiveAmounts: true,
      );

      expect(updated.systemNotificationsEnabled, isFalse);
      expect(updated.hideSensitiveAmounts, isTrue);
      expect(updated.budgetAlertsEnabled, isTrue); // unchanged
    });
  });
}
