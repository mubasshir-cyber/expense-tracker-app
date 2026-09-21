import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/notifications/domain/models/notification_model.dart';
import 'package:expense_tracker/features/notifications/domain/models/notification_type.dart';

void main() {
  group('NotificationModel', () {
    final sampleNotification = NotificationModel(
      id: 'notif-1',
      userId: 'user-1',
      type: NotificationType.budgetWarning,
      title: '⚠️ Food Budget Warning',
      body: "You've reached 80% of your ₹5,000 Food budget.",
      referenceId: 'budget-food-1',
      createdAt: DateTime(2026, 9, 22, 10, 30),
      metadata: {'budgetId': 'budget-food-1', 'spent': 4000.0},
    );

    test('toMap and fromMap serialize and deserialize accurately', () {
      final map = sampleNotification.toMap();
      expect(map['id'], 'notif-1');
      expect(map['user_id'], 'user-1');
      expect(map['type'], 'BUDGET_WARNING');
      expect(map['title'], '⚠️ Food Budget Warning');
      expect(map['body'], "You've reached 80% of your ₹5,000 Food budget.");
      expect(map['reference_id'], 'budget-food-1');
      expect(map['read_at'], isNull);
      expect(map['metadata'], {'budgetId': 'budget-food-1', 'spent': 4000.0});

      final deserialized = NotificationModel.fromMap(map);
      expect(deserialized.id, sampleNotification.id);
      expect(deserialized.userId, sampleNotification.userId);
      expect(deserialized.type, NotificationType.budgetWarning);
      expect(deserialized.title, sampleNotification.title);
      expect(deserialized.isUnread, isTrue);
      expect(deserialized.isRead, isFalse);
    });

    test('markAsRead and markAsUnread work accurately', () {
      final read = sampleNotification.markAsRead(
        readTimestamp: DateTime(2026, 9, 22, 11, 0),
      );
      expect(read.isRead, isTrue);
      expect(read.isUnread, isFalse);
      expect(read.readAt, DateTime(2026, 9, 22, 11, 0));

      final unread = read.markAsUnread();
      expect(unread.isRead, isFalse);
      expect(unread.isUnread, isTrue);
      expect(unread.readAt, isNull);
    });

    test('copyWith modifies selected properties without mutating unchanged fields', () {
      final updated = sampleNotification.copyWith(
        title: 'Updated Alert',
        type: NotificationType.budgetExceeded,
      );

      expect(updated.id, 'notif-1');
      expect(updated.title, 'Updated Alert');
      expect(updated.type, NotificationType.budgetExceeded);
      expect(updated.body, sampleNotification.body);
    });
  });
}
