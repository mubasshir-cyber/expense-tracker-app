import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/notifications/domain/models/notification_model.dart';
import 'package:expense_tracker/features/notifications/domain/models/notification_type.dart';

void main() {
  final baseDate = DateTime(2026, 9, 23, 12, 0);

  final baseMap = {
    'id': 'notif-101',
    'user_id': 'user-123',
    'type': 'BUDGET_WARNING',
    'title': '⚠️ Dining Out Warning',
    'body': "You've reached 80% of your budget.",
    'reference_id': 'b-123',
    'idempotency_key': 'BUDGET_WARNING:b-123:2026-09-01:2026-09-30',
    'scheduled_at': null,
    'read_at': null,
    'metadata': {'budgetId': 'b-123', 'percentage': 80.0},
    'created_at': baseDate.toIso8601String(),
  };

  group('NotificationRepository — NotificationModel DB contract & serialization', () {
    test('fromMap parses all DB fields including idempotency_key', () {
      final model = NotificationModel.fromMap(baseMap);

      expect(model.id, 'notif-101');
      expect(model.userId, 'user-123');
      expect(model.type, NotificationType.budgetWarning);
      expect(model.title, '⚠️ Dining Out Warning');
      expect(model.body, "You've reached 80% of your budget.");
      expect(model.referenceId, 'b-123');
      expect(model.idempotencyKey, 'BUDGET_WARNING:b-123:2026-09-01:2026-09-30');
      expect(model.readAt, isNull);
      expect(model.isUnread, isTrue);
      expect(model.isRead, isFalse);
      expect(model.metadata['budgetId'], 'b-123');
    });

    test('toMap formats payload accurately for Supabase table insertion', () {
      final model = NotificationModel.fromMap(baseMap);
      final map = model.toMap();

      expect(map['id'], 'notif-101');
      expect(map['user_id'], 'user-123');
      expect(map['type'], 'BUDGET_WARNING');
      expect(map['title'], '⚠️ Dining Out Warning');
      expect(map['body'], "You've reached 80% of your budget.");
      expect(map['reference_id'], 'b-123');
      expect(map['idempotency_key'], 'BUDGET_WARNING:b-123:2026-09-01:2026-09-30');
      expect(map['read_at'], isNull);
    });

    test('fromMap → toMap round-trip preserves idempotency and all fields', () {
      final original = NotificationModel.fromMap(baseMap);
      final roundTripped = NotificationModel.fromMap(original.toMap());

      expect(roundTripped, equals(original));
      expect(roundTripped.idempotencyKey, original.idempotencyKey);
    });

    test('markAsRead updates read_at timestamp without altering other properties', () {
      final original = NotificationModel.fromMap(baseMap);
      final readDate = DateTime(2026, 9, 23, 14, 30);
      final read = original.markAsRead(readTimestamp: readDate);

      expect(read.isRead, isTrue);
      expect(read.isUnread, isFalse);
      expect(read.readAt, readDate);
      expect(read.id, original.id);
      expect(read.idempotencyKey, original.idempotencyKey);
    });

    test('markAsUnread clears read_at', () {
      final original = NotificationModel.fromMap(baseMap)
          .markAsRead(readTimestamp: DateTime.now());
      expect(original.isRead, isTrue);

      final unread = original.markAsUnread();
      expect(unread.isRead, isFalse);
      expect(unread.isUnread, isTrue);
      expect(unread.readAt, isNull);
    });
  });
}
