import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_payload.dart';

/// Helper for scheduling future notifications using timezone-aware calculations.
class NotificationScheduler {
  NotificationScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  static bool _timezoneInitialized = false;

  static void initializeTimezones() {
    if (!_timezoneInitialized) {
      try {
        tz.initializeTimeZones();
        _timezoneInitialized = true;
      } catch (e) {
        developer.log('Failed to initialize timezones: $e',
            name: 'NotificationScheduler');
      }
    }
  }

  /// Schedules a local notification at a specific [scheduledDate].
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required AndroidNotificationChannel channel,
    AppNotificationPayload? payload,
  }) async {
    try {
      initializeTimezones();

      final now = DateTime.now();
      if (scheduledDate.isBefore(now)) {
        developer.log(
            'Scheduled date $scheduledDate is in the past, skipping schedule.',
            name: 'NotificationScheduler');
        return;
      }

      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      final androidDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload?.toJson(),
      );
      developer.log('Scheduled notification $id for $tzDateTime',
          name: 'NotificationScheduler');
    } catch (e, st) {
      developer.log('Error scheduling notification: $e',
          name: 'NotificationScheduler', error: e, stackTrace: st);
    }
  }

  /// Cancels a scheduled or active notification by [id].
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      developer.log('Error canceling notification $id: $e',
          name: 'NotificationScheduler');
    }
  }

  /// Cancels all notifications.
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      developer.log('Error canceling all notifications: $e',
          name: 'NotificationScheduler');
    }
  }
}
