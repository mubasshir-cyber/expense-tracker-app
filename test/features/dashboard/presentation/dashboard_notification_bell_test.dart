import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/notifications/presentation/providers/notification_providers.dart';
import 'package:expense_tracker/features/notifications/presentation/widgets/notification_badge_icon.dart';

void main() {
  Widget createTestWidget({int unreadCount = 0}) {
    return ProviderScope(
      overrides: [
        unreadNotificationCountProvider.overrideWith(
          (ref) async => unreadCount,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: const [
              NotificationBadgeIcon(),
            ],
          ),
        ),
      ),
    );
  }

  group('NotificationBadgeIcon Widget Tests', () {
    testWidgets('renders bell icon without badge when unread count is 0', (tester) async {
      await tester.pumpWidget(createTestWidget(unreadCount: 0));
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('renders badge with count when unread count > 0', (tester) async {
      await tester.pumpWidget(createTestWidget(unreadCount: 3));
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('renders 9+ when unread count exceeds 9', (tester) async {
      await tester.pumpWidget(createTestWidget(unreadCount: 15));
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.text('9+'), findsOneWidget);
    });
  });
}
