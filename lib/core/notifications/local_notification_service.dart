import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import 'notification_channels.dart';
import 'notification_payload.dart';
import 'notification_permission_service.dart';
import 'notification_scheduler.dart';

/// Centralized service for displaying and managing OS-level Android local notifications.
class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin() {
    permissionService = NotificationPermissionService(_plugin);
    scheduler = NotificationScheduler(_plugin);
  }

  final FlutterLocalNotificationsPlugin _plugin;
  late final NotificationPermissionService permissionService;
  late final NotificationScheduler scheduler;

  bool _isInitialized = false;
  void Function(String targetRoute)? _onSelectRoute;

  /// Currency formatter for notification bodies
  final _currencyFormat =
      NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

  /// Initializes the local notification plugin and registers Android notification channels.
  Future<void> initialize({void Function(String targetRoute)? onSelectRoute}) async {
    if (_isInitialized) return;

    _onSelectRoute = onSelectRoute;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      // Register all custom notification channels on Android
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        for (final channel in AppNotificationChannels.all) {
          await androidImpl.createNotificationChannel(channel);
        }
      }

      _isInitialized = true;
      developer.log(
          'LocalNotificationService initialized successfully with all channels.',
          name: 'LocalNotificationService');
    } catch (e, st) {
      developer.log(
          'LocalNotificationService initialization skipped/failed (normal in test runner): $e',
          name: 'LocalNotificationService',
          error: e,
          stackTrace: st);
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payloadStr = response.payload;
    if (payloadStr != null && payloadStr.isNotEmpty) {
      final payload = AppNotificationPayload.fromJson(payloadStr);
      final route = payload.resolvedRoute;
      developer.log('Notification tapped with route: $route',
          name: 'LocalNotificationService');
      _onSelectRoute?.call(route);
    }
  }

  /// Generates a deterministic positive 31-bit integer notification ID to prevent duplicates.
  int generateNotificationId(String type, String entityId,
      [String? dateOrPeriod]) {
    final key = '${type}_${entityId}_${dateOrPeriod ?? ''}';
    return key.hashCode.abs() % 0x7FFFFFFF;
  }

  /// Displays an immediate notification with given details.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required AndroidNotificationChannel channel,
    AppNotificationPayload? payload,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: channel.importance == Importance.high
            ? Priority.high
            : Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

      final details = NotificationDetails(android: androidDetails);

      await _plugin.show(
        id,
        title,
        body,
        details,
        payload: payload?.toJson(),
      );
    } catch (e, st) {
      developer.log('Failed to show notification: $e',
          name: 'LocalNotificationService', error: e, stackTrace: st);
    }
  }

  /// Immediate Test Notification to verify status bar & audio on device.
  Future<void> showTestNotification() async {
    await showNotification(
      id: 999999,
      title: 'Expense Tracker Alerts Active',
      body: 'System notifications are configured and working properly!',
      channel: AppNotificationChannels.financeAlerts,
      payload: const AppNotificationPayload(
        type: 'general',
        targetRoute: '/notification-settings',
      ),
    );
  }

  /// 1. Budget Threshold or Exceeded Alert
  Future<void> showBudgetAlert({
    required String budgetId,
    required String categoryName,
    required double percentage,
    required double remainingAmount,
    required bool isExceeded,
    String? period,
    bool hideSensitiveData = false,
  }) async {
    final periodKey = period ?? DateFormat('yyyy-MM').format(DateTime.now());
    final id = generateNotificationId('budget', budgetId, periodKey);

    String title;
    String body;

    if (hideSensitiveData) {
      title = isExceeded ? 'Budget limit reached' : 'Budget update';
      body = 'You have a new update regarding your spending budget.';
    } else {
      if (isExceeded) {
        title = '$categoryName budget exceeded';
        body =
            'You have exceeded your $categoryName budget by ${_currencyFormat.format(remainingAmount.abs())}.';
      } else {
        title = '$categoryName budget alert';
        body =
            "You've used ${percentage.toStringAsFixed(0)}% of your $categoryName budget. ${_currencyFormat.format(remainingAmount)} remaining.";
      }
    }

    await showNotification(
      id: id,
      title: title,
      body: body,
      channel: AppNotificationChannels.budgetAlerts,
      payload: AppNotificationPayload(
        type: 'budget',
        entityId: budgetId,
        targetRoute: '/budgets',
      ),
    );
  }

  /// 2. Recurring Payment Reminder
  Future<void> showPaymentReminder({
    required String recurringId,
    required String title,
    required double amount,
    required DateTime dueDate,
    bool hideSensitiveData = false,
  }) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(dueDate);
    final id = generateNotificationId('recurring', recurringId, dateKey);

    final isToday = dueDate.day == DateTime.now().day &&
        dueDate.month == DateTime.now().month &&
        dueDate.year == DateTime.now().year;

    final dueText = isToday ? 'due today' : 'due tomorrow';

    String notifTitle;
    String body;

    if (hideSensitiveData) {
      notifTitle = 'Upcoming bill reminder';
      body = 'You have a scheduled recurring payment $dueText.';
    } else {
      notifTitle = '$title $dueText';
      body =
          'Payment of ${_currencyFormat.format(amount)} is scheduled for $dueText.';
    }

    await showNotification(
      id: id,
      title: notifTitle,
      body: body,
      channel: AppNotificationChannels.paymentReminders,
      payload: AppNotificationPayload(
        type: 'recurring',
        entityId: recurringId,
        targetRoute: '/recurring',
      ),
    );
  }

  /// 3. Loan & Debt Reminder
  Future<void> showLoanReminder({
    required String debtId,
    required String personName,
    required double amount,
    required DateTime dueDate,
    required bool isLent,
    bool hideSensitiveData = false,
  }) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(dueDate);
    final id = generateNotificationId('debt', debtId, dateKey);

    String title;
    String body;

    if (hideSensitiveData) {
      title = 'Loan payment reminder';
      body = 'You have a loan payment due soon.';
    } else {
      final formattedAmount = _currencyFormat.format(amount);
      if (isLent) {
        title = 'Payment reminder from $personName';
        body = '$personName has a repayment of $formattedAmount due soon.';
      } else {
        title = 'Loan payment due for $personName';
        body =
            'Repayment of $formattedAmount to $personName is approaching its due date.';
      }
    }

    await showNotification(
      id: id,
      title: title,
      body: body,
      channel: AppNotificationChannels.loanReminders,
      payload: AppNotificationPayload(
        type: 'debt',
        entityId: debtId,
        targetRoute: '/debts/$debtId',
      ),
    );
  }

  /// 4. Khata Customer Pending Balance Reminder
  Future<void> showKhataReminder({
    required String customerId,
    required String customerName,
    required double pendingAmount,
    bool hideSensitiveData = false,
  }) async {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final id = generateNotificationId('khata', customerId, todayKey);

    String title;
    String body;

    if (hideSensitiveData) {
      title = 'Khata balance reminder';
      body = 'A customer has a pending ledger balance.';
    } else {
      title = 'Khata reminder for $customerName';
      body =
          '$customerName has ${_currencyFormat.format(pendingAmount)} pending balance.';
    }

    await showNotification(
      id: id,
      title: title,
      body: body,
      channel: AppNotificationChannels.khataReminders,
      payload: AppNotificationPayload(
        type: 'khata',
        entityId: customerId,
        targetRoute: '/khata/$customerId',
      ),
    );
  }

  /// 5. Savings Goal Milestone Alert
  Future<void> showSavingsAlert({
    required String goalId,
    required String goalName,
    required double percentage,
    bool hideSensitiveData = false,
  }) async {
    final milestoneKey = (percentage ~/ 25) * 25; // 25, 50, 75, 100
    final id =
        generateNotificationId('goal', goalId, 'milestone_$milestoneKey');

    String title;
    String body;

    if (hideSensitiveData) {
      title = 'Savings goal update';
      body = 'You reached a milestone for your savings goal!';
    } else {
      title = 'Savings goal: $goalName';
      if (percentage >= 100) {
        body = 'Congratulations! You reached 100% of your $goalName goal! 🎉';
      } else {
        body =
            "You're ${percentage.toStringAsFixed(0)}% of the way to your $goalName goal.";
      }
    }

    await showNotification(
      id: id,
      title: title,
      body: body,
      channel: AppNotificationChannels.savingsAlerts,
      payload: AppNotificationPayload(
        type: 'goal',
        entityId: goalId,
        targetRoute: '/savings-goals/$goalId',
      ),
    );
  }

  /// Cancels a specific notification
  Future<void> cancel(int id) => scheduler.cancelNotification(id);

  /// Cancels all active notifications
  Future<void> cancelAll() => scheduler.cancelAll();
}
