import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/notifications/domain/models/notification_settings_model.dart';

void main() {
  final baseMap = {
    'id': 'settings-101',
    'user_id': 'user-123',
    'budget_warning_enabled': true,
    'budget_exceeded_enabled': false,
    'recurring_upcoming_enabled': true,
    'recurring_auto_created_enabled': true,
    'spending_alerts_enabled': false,
    'monthly_summary_enabled': true,
  };

  group('NotificationSettingsRepository — DB Contract & Serialization', () {
    test('fromMap parses all settings correctly', () {
      final model = NotificationSettingsModel.fromMap(baseMap);

      expect(model.userId, 'user-123');
      expect(model.budgetWarningEnabled, isTrue);
      expect(model.budgetExceededEnabled, isFalse);
      expect(model.recurringUpcomingEnabled, isTrue);
      expect(model.recurringAutoCreatedEnabled, isTrue);
      expect(model.spendingAlertsEnabled, isFalse);
      expect(model.monthlySummaryEnabled, isTrue);
    });

    test('toMap formats payload accurately for Supabase table upsert', () {
      final model = NotificationSettingsModel.fromMap(baseMap);
      final map = model.toMap();

      expect(map['user_id'], 'user-123');
      expect(map['budget_warning_enabled'], isTrue);
      expect(map['budget_exceeded_enabled'], isFalse);
      expect(map['recurring_upcoming_enabled'], isTrue);
      expect(map['recurring_auto_created_enabled'], isTrue);
      expect(map['spending_alerts_enabled'], isFalse);
      expect(map['monthly_summary_enabled'], isTrue);
    });

    test('fromMap → toMap round-trip preserves equality', () {
      final original = NotificationSettingsModel.fromMap(baseMap);
      final roundTripped = NotificationSettingsModel.fromMap(original.toMap());

      expect(roundTripped, equals(original));
    });
  });
}
