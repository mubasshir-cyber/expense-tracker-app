import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../recurring/presentation/providers/recurring_providers.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/notification_settings_repository.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/models/notification_settings_model.dart';
import '../../domain/services/smart_alert_engine.dart';

/// Repository provider for notifications.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

/// Repository provider for notification settings.
final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>((ref) {
  return NotificationSettingsRepository(Supabase.instance.client);
});

/// Domain provider for SmartAlertEngine.
final smartAlertEngineProvider = Provider<SmartAlertEngine>((ref) {
  return const SmartAlertEngine();
});

/// Provider for user's notification preferences.
final notificationSettingsProvider =
    FutureProvider<NotificationSettingsModel>((ref) async {
  final repo = ref.watch(notificationSettingsRepositoryProvider);
  return repo.getSettings();
});

/// Provider for all active notifications.
final notificationsListProvider =
    FutureProvider<List<NotificationModel>>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getNotifications();
});

/// Provider for unread notification count.
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final notifications = await ref.watch(notificationsListProvider.future);
  return notifications.where((n) => n.isUnread).length;
});

/// Controller for performing notification interactions and updating preferences.
final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, AsyncValue<void>>((ref) {
  return NotificationsController(ref);
});

class NotificationsController extends StateNotifier<AsyncValue<void>> {
  NotificationsController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  NotificationRepository get _repo => _ref.read(notificationRepositoryProvider);
  NotificationSettingsRepository get _settingsRepo =>
      _ref.read(notificationSettingsRepositoryProvider);

  /// Synchronizes financial domain alerts (budgets & upcoming recurring payments)
  Future<void> syncDomainAlerts() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final settings = await _ref.read(notificationSettingsProvider.future);
      final engine = _ref.read(smartAlertEngineProvider);

      final budgetProgressList =
          await _ref.read(activeBudgetsProgressProvider.future);
      final upcomingRecurring =
          await _ref.read(upcomingRecurringProvider.future);

      final budgetAlerts = engine.checkBudgetAlerts(
        userId: user.id,
        activeProgressList: budgetProgressList,
        settings: settings,
      );

      final recurringAlerts = engine.checkRecurringReminders(
        userId: user.id,
        upcomingRecurringList: upcomingRecurring,
        settings: settings,
      );

      final allAlerts = [...budgetAlerts, ...recurringAlerts];
      if (allAlerts.isNotEmpty) {
        await _repo.syncAlertNotifications(allAlerts);
        _ref.invalidate(notificationsListProvider);
      }
    } catch (_) {
      // Ignore background sync failure
    }
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String notificationId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.markAsRead(notificationId);
      _ref.invalidate(notificationsListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    try {
      await _repo.markAllAsRead();
      _ref.invalidate(notificationsListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Deletes a single notification.
  Future<void> deleteNotification(String notificationId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteNotification(notificationId);
      _ref.invalidate(notificationsListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Clears all notifications.
  Future<void> clearAll() async {
    state = const AsyncValue.loading();
    try {
      await _repo.clearAllNotifications();
      _ref.invalidate(notificationsListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Updates notification preferences.
  Future<void> updateSettings(NotificationSettingsModel newSettings) async {
    state = const AsyncValue.loading();
    try {
      await _settingsRepo.saveSettings(newSettings);
      _ref.invalidate(notificationSettingsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
