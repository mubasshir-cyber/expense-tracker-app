import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_notification_service.dart';

/// Global provider for LocalNotificationService instance.
final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});
