import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/notifications/local_notification_provider.dart';
import '../../../../core/notifications/system_notification_preferences.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../recurring/presentation/providers/recurring_providers.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/notification_settings_repository.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/models/notification_settings_model.dart';
import '../../domain/models/notification_type.dart';
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

        // Deliver OS-level local notifications if enabled by preferences & permission
        await _deliverOsNotifications(allAlerts);
      }
    } catch (_) {
      // Ignore background sync failure
    }
  }

  /// Delivers OS status bar notifications for eligible alerts according to preferences
  Future<void> _deliverOsNotifications(List<NotificationModel> alerts) async {
    try {
      final systemPrefs =
          await _ref.read(systemNotificationPreferencesProvider.future);
      if (!systemPrefs.systemNotificationsEnabled) return;

      final localNotif = _ref.read(localNotificationServiceProvider);
      final isGranted =
          await localNotif.permissionService.isPermissionGranted();
      if (!isGranted) return;

      final hideSensitive = systemPrefs.hideSensitiveAmounts;

      for (final alert in alerts) {
        switch (alert.type) {
          case NotificationType.budgetWarning:
          case NotificationType.budgetExceeded:
            if (systemPrefs.budgetAlertsEnabled) {
              final budgetId = alert.metadata['budgetId'] as String? ?? alert.referenceId ?? alert.id;
              final percentage = (alert.metadata['percentage'] as num?)?.toDouble() ?? 100.0;
              final overAmount = (alert.metadata['overAmount'] as num?)?.toDouble() ?? 0.0;
              final isExceeded = alert.type == NotificationType.budgetExceeded;
              final categoryName = alert.title.replaceAll(RegExp(r'[🚨⚠️]'), '').replaceAll('Exceeded', '').replaceAll('Budget Warning', '').trim();

              await localNotif.showBudgetAlert(
                budgetId: budgetId,
                categoryName: categoryName.isNotEmpty ? categoryName : 'Budget',
                percentage: percentage,
                remainingAmount: isExceeded ? overAmount : 0,
                isExceeded: isExceeded,
                hideSensitiveData: hideSensitive,
              );
            }
            break;

          case NotificationType.recurringUpcoming:
          case NotificationType.recurringDue:
            if (systemPrefs.recurringAlertsEnabled) {
              final recurringId = alert.metadata['recurringId'] as String? ?? alert.referenceId ?? alert.id;
              final amount = (alert.metadata['amount'] as num?)?.toDouble() ?? 0.0;
              final isToday = alert.type == NotificationType.recurringDue;
              final dueDate = isToday ? DateTime.now() : DateTime.now().add(const Duration(days: 1));
              final title = alert.title.replaceAll(RegExp(r'[🔔]'), '').trim();

              await localNotif.showPaymentReminder(
                recurringId: recurringId,
                title: title.isNotEmpty ? title : 'Bill payment',
                amount: amount,
                dueDate: dueDate,
                hideSensitiveData: hideSensitive,
              );
            }
            break;

          case NotificationType.debtDue:
            if (systemPrefs.loanAlertsEnabled) {
              final debtId = alert.referenceId ?? alert.id;
              final amount = (alert.metadata['amount'] as num?)?.toDouble() ?? 0.0;
              final personName = alert.metadata['personName'] as String? ?? 'Contact';
              final isLent = alert.metadata['isLent'] as bool? ?? false;

              await localNotif.showLoanReminder(
                debtId: debtId,
                personName: personName,
                amount: amount,
                dueDate: DateTime.now(),
                isLent: isLent,
                hideSensitiveData: hideSensitive,
              );
            }
            break;

          case NotificationType.goalMilestone:
            if (systemPrefs.savingsAlertsEnabled) {
              final goalId = alert.referenceId ?? alert.id;
              final goalName = alert.metadata['goalName'] as String? ?? 'Savings Goal';
              final percentage = (alert.metadata['percentage'] as num?)?.toDouble() ?? 100.0;

              await localNotif.showSavingsAlert(
                goalId: goalId,
                goalName: goalName,
                percentage: percentage,
                hideSensitiveData: hideSensitive,
              );
            }
            break;

          case NotificationType.khataDue:
            if (systemPrefs.khataAlertsEnabled) {
              final customerId = alert.referenceId ?? alert.id;
              final customerName = alert.metadata['customerName'] as String? ?? 'Customer';
              final pendingAmount = (alert.metadata['pendingAmount'] as num?)?.toDouble() ?? 0.0;

              await localNotif.showKhataReminder(
                customerId: customerId,
                customerName: customerName,
                pendingAmount: pendingAmount,
                hideSensitiveData: hideSensitive,
              );
            }
            break;

          default:
            break;
        }
      }
    } catch (_) {
      // Local notification delivery failure must never crash or block app
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
