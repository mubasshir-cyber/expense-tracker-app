import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service responsible for querying and requesting Android OS notification permissions.
class NotificationPermissionService {
  NotificationPermissionService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// Returns true if system notifications are enabled for this app.
  Future<bool> isPermissionGranted() async {
    try {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final areEnabled =
            await androidImplementation.areNotificationsEnabled();
        return areEnabled ?? false;
      }
      return true;
    } catch (e, st) {
      developer.log('Error checking notification permission: $e',
          name: 'NotificationPermissionService', error: e, stackTrace: st);
      return false;
    }
  }

  /// Requests the POST_NOTIFICATIONS runtime permission on Android 13+ (API 33+).
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    try {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted =
            await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e, st) {
      developer.log('Error requesting notification permission: $e',
          name: 'NotificationPermissionService', error: e, stackTrace: st);
      return false;
    }
  }
}
