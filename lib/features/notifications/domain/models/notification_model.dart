import 'notification_type.dart';

/// Immutable representation of a financial notification.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.referenceId,
    this.idempotencyKey,
    this.scheduledAt,
    this.readAt,
    this.metadata = const {},
    required this.createdAt,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? referenceId;
  final String? idempotencyKey;
  final DateTime? scheduledAt;
  final DateTime? readAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  bool get isRead => readAt != null;
  bool get isUnread => readAt == null;

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: NotificationType.fromValue(map['type'] as String),
      title: map['title'] as String,
      body: map['body'] as String,
      referenceId: map['reference_id'] as String?,
      idempotencyKey: map['idempotency_key'] as String?,
      scheduledAt: map['scheduled_at'] != null
          ? DateTime.parse(map['scheduled_at'] as String)
          : null,
      readAt: map['read_at'] != null
          ? DateTime.parse(map['read_at'] as String)
          : null,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'title': title,
      'body': body,
      'reference_id': referenceId,
      'idempotency_key': idempotencyKey,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    String? referenceId,
    String? idempotencyKey,
    DateTime? scheduledAt,
    DateTime? readAt,
    bool clearReadAt = false,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      referenceId: referenceId ?? this.referenceId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      readAt: clearReadAt ? null : (readAt ?? this.readAt),
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  NotificationModel markAsRead({DateTime? readTimestamp}) {
    return copyWith(readAt: readTimestamp ?? DateTime.now());
  }

  NotificationModel markAsUnread() {
    return copyWith(clearReadAt: true);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          type == other.type &&
          title == other.title &&
          body == other.body &&
          referenceId == other.referenceId &&
          idempotencyKey == other.idempotencyKey &&
          readAt == other.readAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      type.hashCode ^
      title.hashCode ^
      body.hashCode ^
      (referenceId?.hashCode ?? 0) ^
      (idempotencyKey?.hashCode ?? 0) ^
      (readAt?.hashCode ?? 0);
}
