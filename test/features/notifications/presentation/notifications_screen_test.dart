import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/notifications/domain/models/notification_model.dart';
import 'package:expense_tracker/features/notifications/domain/models/notification_settings_model.dart';
import 'package:expense_tracker/features/notifications/domain/models/notification_type.dart';
import 'package:expense_tracker/features/notifications/presentation/notifications_screen.dart';
import 'package:expense_tracker/features/notifications/presentation/providers/notification_providers.dart';

void main() {
  final now = DateTime.now();
  final sampleNotification1 = NotificationModel(
    id: 'n-1',
    userId: 'user-1',
    type: NotificationType.budgetWarning,
    title: '⚠️ Groceries Budget Warning',
    body: "You've reached 84% of your ₹5,000 budget.",
    createdAt: now,
  );

  final sampleNotification2 = NotificationModel(
    id: 'n-2',
    userId: 'user-1',
    type: NotificationType.recurringUpcoming,
    title: '🔔 Upcoming Bill: Netflix',
    body: '₹649 is due tomorrow.',
    createdAt: now.subtract(const Duration(days: 1)), // Yesterday
  );

  final sampleNotification3 = NotificationModel(
    id: 'n-3',
    userId: 'user-1',
    type: NotificationType.spendingAlert,
    title: '📊 Spending Surge Alert',
    body: 'Expenses increased by 50%.',
    readAt: now,
    createdAt: now,
  );

  Widget createTestWidget({
    List<NotificationModel>? notifications,
    bool shouldThrow = false,
  }) {
    return ProviderScope(
      overrides: [
        notificationsListProvider.overrideWith((ref) async {
          if (shouldThrow) throw Exception('Network error');
          return notifications ?? [sampleNotification1, sampleNotification2, sampleNotification3];
        }),
        unreadNotificationCountProvider.overrideWith((ref) async {
          if (shouldThrow) return 0;
          return (notifications ?? [sampleNotification1, sampleNotification2, sampleNotification3])
              .where((n) => n.isUnread)
              .length;
        }),
        notificationSettingsProvider.overrideWith(
          (ref) async => const NotificationSettingsModel(userId: 'user-1'),
        ),
      ],
      child: const MaterialApp(
        home: NotificationsScreen(),
      ),
    );
  }

  group('NotificationsScreen Widget Tests', () {
    testWidgets('renders empty state when there are no notifications', (tester) async {
      await tester.pumpWidget(createTestWidget(notifications: []));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('No Notifications Yet'), findsOneWidget);
      expect(find.textContaining('all caught up'), findsOneWidget);
    });

    testWidgets('renders error state and retry button when loading fails', (tester) async {
      await tester.pumpWidget(createTestWidget(shouldThrow: true));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load notifications'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders notification items grouped by date with filter chips', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Unread (2)'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Reminders'), findsOneWidget);

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('⚠️ Groceries Budget Warning'), findsOneWidget);
      expect(find.text('🔔 Upcoming Bill: Netflix'), findsOneWidget);
    });

    testWidgets('filters list by Unread, Alerts, and Reminders chips', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Filter by Unread
      await tester.tap(find.text('Unread (2)'));
      await tester.pumpAndSettle();
      expect(find.text('⚠️ Groceries Budget Warning'), findsOneWidget);
      expect(find.text('🔔 Upcoming Bill: Netflix'), findsOneWidget);
      expect(find.text('📊 Spending Surge Alert'), findsNothing);

      // Filter by Alerts
      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();
      expect(find.text('⚠️ Groceries Budget Warning'), findsOneWidget);
      expect(find.text('📊 Spending Surge Alert'), findsOneWidget);
      expect(find.text('🔔 Upcoming Bill: Netflix'), findsNothing);

      // Filter by Reminders
      await tester.tap(find.text('Reminders'));
      await tester.pumpAndSettle();
      expect(find.text('🔔 Upcoming Bill: Netflix'), findsOneWidget);
      expect(find.text('⚠️ Groceries Budget Warning'), findsNothing);
    });
  });
}
