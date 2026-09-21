import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/notifications/domain/models/notification_model.dart';
import 'package:expense_tracker/features/notifications/domain/models/notification_settings_model.dart';
import 'package:expense_tracker/features/notifications/domain/models/notification_type.dart';
import 'package:expense_tracker/features/notifications/presentation/notifications_screen.dart';
import 'package:expense_tracker/features/notifications/presentation/providers/notification_providers.dart';

void main() {
  final sampleNotification1 = NotificationModel(
    id: 'n-1',
    userId: 'user-1',
    type: NotificationType.budgetWarning,
    title: '⚠️ Groceries Budget Warning',
    body: "You've reached 84% of your ₹5,000 budget.",
    createdAt: DateTime.now(),
  );

  final sampleNotification2 = NotificationModel(
    id: 'n-2',
    userId: 'user-1',
    type: NotificationType.recurringUpcoming,
    title: '🔔 Upcoming Bill: Netflix',
    body: '₹649 is due tomorrow.',
    createdAt: DateTime.now().subtract(const Duration(days: 1)), // Yesterday
  );

  Widget createTestWidget({List<NotificationModel> notifications = const []}) {
    return ProviderScope(
      overrides: [
        notificationsListProvider.overrideWith(
          (ref) async => notifications,
        ),
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

    testWidgets('renders notification items grouped by date with filter chips', (tester) async {
      await tester.pumpWidget(
        createTestWidget(notifications: [sampleNotification1, sampleNotification2]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('Unread (2)'), findsOneWidget);
      expect(find.text('Budgets'), findsOneWidget);
      expect(find.text('Recurring Bills'), findsOneWidget);

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('⚠️ Groceries Budget Warning'), findsOneWidget);
      expect(find.text('🔔 Upcoming Bill: Netflix'), findsOneWidget);
    });
  });
}
