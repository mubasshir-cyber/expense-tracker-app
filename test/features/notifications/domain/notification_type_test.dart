import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/notifications/domain/models/notification_type.dart';

void main() {
  group('NotificationType Enum', () {
    test('fromValue maps all valid DB strings and falls back to system', () {
      expect(
        NotificationType.fromValue('BUDGET_WARNING'),
        NotificationType.budgetWarning,
      );
      expect(
        NotificationType.fromValue('budget_exceeded'),
        NotificationType.budgetExceeded,
      );
      expect(
        NotificationType.fromValue('RECURRING_UPCOMING'),
        NotificationType.recurringUpcoming,
      );
      expect(
        NotificationType.fromValue('recurring_due'),
        NotificationType.recurringDue,
      );
      expect(
        NotificationType.fromValue('RECURRING_COMPLETED'),
        NotificationType.recurringCompleted,
      );
      expect(
        NotificationType.fromValue('SPENDING_ALERT'),
        NotificationType.spendingAlert,
      );
      expect(
        NotificationType.fromValue('MONTHLY_SUMMARY'),
        NotificationType.monthlySummary,
      );
      expect(
        NotificationType.fromValue('UNKNOWN_TYPE'),
        NotificationType.system,
      );
    });

    test('value and label getters return correct strings', () {
      expect(NotificationType.budgetWarning.value, 'BUDGET_WARNING');
      expect(NotificationType.budgetWarning.label, 'Budget Warning');
      expect(NotificationType.budgetExceeded.value, 'BUDGET_EXCEEDED');
      expect(NotificationType.recurringUpcoming.value, 'RECURRING_UPCOMING');
    });

    test('icon and color getters return non-null properties', () {
      for (final type in NotificationType.values) {
        expect(type.icon, isNotNull);
        expect(type.color, isNotNull);
      }
    });
  });
}
