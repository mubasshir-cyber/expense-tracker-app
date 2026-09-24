import 'dart:convert';

/// Structured payload attached to local notifications for deep-linking and handling.
class AppNotificationPayload {
  const AppNotificationPayload({
    required this.type,
    this.entityId,
    this.targetRoute,
    this.extraData,
  });

  final String type; // e.g., 'budget', 'recurring', 'debt', 'goal', 'khata', 'general'
  final String? entityId;
  final String? targetRoute;
  final Map<String, dynamic>? extraData;

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      if (entityId != null) 'entityId': entityId,
      if (targetRoute != null) 'targetRoute': targetRoute,
      if (extraData != null) 'extraData': extraData,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory AppNotificationPayload.fromMap(Map<String, dynamic> map) {
    return AppNotificationPayload(
      type: map['type'] as String? ?? 'general',
      entityId: map['entityId'] as String?,
      targetRoute: map['targetRoute'] as String?,
      extraData: map['extraData'] as Map<String, dynamic>?,
    );
  }

  factory AppNotificationPayload.fromJson(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return AppNotificationPayload.fromMap(map);
    } catch (_) {
      return const AppNotificationPayload(type: 'general');
    }
  }

  /// Default route fallback based on notification category
  String get resolvedRoute {
    if (targetRoute != null && targetRoute!.isNotEmpty) {
      return targetRoute!;
    }
    switch (type) {
      case 'budget':
        return '/budgets';
      case 'recurring':
        return '/recurring';
      case 'debt':
      case 'loan':
        return entityId != null ? '/debts/$entityId' : '/debts';
      case 'goal':
      case 'savings':
        return entityId != null ? '/savings-goals/$entityId' : '/savings-goals';
      case 'khata':
        return entityId != null ? '/khata/$entityId' : '/khata';
      default:
        return '/notifications';
    }
  }
}
