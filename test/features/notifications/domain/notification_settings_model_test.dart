import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/notifications/domain/models/notification_settings_model.dart';

void main() {
  group('NotificationSettingsModel', () {
    test('defaultSettings initializes all toggles to true', () {
      final settings = NotificationSettingsModel.defaultSettings('user-1');
      expect(settings.userId, 'user-1');
      expect(settings.budgetWarningEnabled, isTrue);
      expect(settings.budgetExceededEnabled, isTrue);
      expect(settings.recurringUpcomingEnabled, isTrue);
      expect(settings.recurringAutoCreatedEnabled, isTrue);
      expect(settings.spendingAlertsEnabled, isTrue);
      expect(settings.monthlySummaryEnabled, isTrue);
    });

    test('toMap and fromMap work accurately', () {
      final custom = const NotificationSettingsModel(
        userId: 'user-2',
        budgetWarningEnabled: true,
        budgetExceededEnabled: false,
        recurringUpcomingEnabled: true,
        recurringAutoCreatedEnabled: false,
        spendingAlertsEnabled: true,
        monthlySummaryEnabled: false,
      );

      final map = custom.toMap();
      expect(map['user_id'], 'user-2');
      expect(map['budget_warning_enabled'], isTrue);
      expect(map['budget_exceeded_enabled'], isFalse);
      expect(map['recurring_auto_created_enabled'], isFalse);

      final fromMap = NotificationSettingsModel.fromMap(map);
      expect(fromMap.userId, custom.userId);
      expect(fromMap.budgetWarningEnabled, custom.budgetWarningEnabled);
      expect(fromMap.budgetExceededEnabled, custom.budgetExceededEnabled);
      expect(fromMap.recurringAutoCreatedEnabled, custom.recurringAutoCreatedEnabled);
    });

    test('copyWith properly updates specific channels', () {
      final initial = NotificationSettingsModel.defaultSettings('user-1');
      final updated = initial.copyWith(
        budgetWarningEnabled: false,
        spendingAlertsEnabled: false,
      );

      expect(updated.budgetWarningEnabled, isFalse);
      expect(updated.spendingAlertsEnabled, isFalse);
      expect(updated.budgetExceededEnabled, isTrue);
      expect(updated.recurringUpcomingEnabled, isTrue);
    });
  });
}
