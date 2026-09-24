import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/notification_model.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('User is not authenticated.');
    }
    return user.id;
  }

  /// Returns active notifications for the current user, newest first.
  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    var query = _client
        .from('notifications')
        .select()
        .eq('user_id', _userId)
        .isFilter('deleted_at', null);

    if (unreadOnly) {
      query = query.isFilter('read_at', null);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map(
          (row) => NotificationModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  /// Returns unread notification count.
  Future<int> getUnreadCount() async {
    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', _userId)
        .isFilter('deleted_at', null)
        .isFilter('read_at', null);

    return (response as List).length;
  }

  /// Creates a new notification in the database.
  Future<NotificationModel> createNotification(NotificationModel item) async {
    final payload = {
      'user_id': _userId,
      'type': item.type.value,
      'title': item.title,
      'body': item.body,
      'reference_id': item.referenceId,
      'idempotency_key': item.idempotencyKey,
      'scheduled_at': item.scheduledAt?.toIso8601String(),
      'read_at': item.readAt?.toIso8601String(),
      'metadata': item.metadata,
      'created_at': item.createdAt.toIso8601String(),
    };

    final response = await _client
        .from('notifications')
        .insert(payload)
        .select()
        .single();

    return NotificationModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  /// Creates a notification idempotently.
  /// If an alert with the same [idempotencyKey] exists for this user and is not deleted,
  /// returns the existing notification without creating a duplicate.
  Future<NotificationModel> createNotificationIdempotent(
    NotificationModel item,
  ) async {
    if (item.idempotencyKey != null && item.idempotencyKey!.isNotEmpty) {
      final existing = await _client
          .from('notifications')
          .select()
          .eq('user_id', _userId)
          .eq('idempotency_key', item.idempotencyKey!)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (existing != null) {
        return NotificationModel.fromMap(
          Map<String, dynamic>.from(existing),
        );
      }
    }

    return createNotification(item);
  }

  /// Batch syncs alerts idempotently, preventing duplicate creation.
  Future<void> syncAlertNotifications(List<NotificationModel> alerts) async {
    if (alerts.isEmpty) return;

    for (final alert in alerts) {
      await createNotificationIdempotent(alert);
    }
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', notificationId)
        .eq('user_id', _userId);
  }

  /// Marks all unread notifications for the user as read.
  Future<void> markAllAsRead() async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', _userId)
        .isFilter('read_at', null)
        .isFilter('deleted_at', null);
  }

  /// Soft deletes a single notification.
  Future<void> deleteNotification(String notificationId) async {
    await _client
        .from('notifications')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', notificationId)
        .eq('user_id', _userId);
  }

  /// Soft deletes all notifications for the user.
  Future<void> clearAllNotifications() async {
    await _client
        .from('notifications')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', _userId)
        .isFilter('deleted_at', null);
  }
}
