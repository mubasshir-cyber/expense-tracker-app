import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:expense_tracker/features/notifications/presentation/providers/notification_providers.dart';
import 'package:expense_tracker/features/notifications/presentation/widgets/notification_badge_icon.dart';

void main() {
  group('NotificationBadgeIcon Widget Tests', () {
    testWidgets('shows bell icon without badge when unread count is 0', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider.overrideWith((ref) async => 0),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationBadgeIcon(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.bell), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows badge with exact count when unread count is between 1 and 9', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider.overrideWith((ref) async => 3),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationBadgeIcon(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.bell), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows "9+" badge when unread count exceeds 9', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider.overrideWith((ref) async => 15),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationBadgeIcon(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.bell), findsOneWidget);
      expect(find.text('9+'), findsOneWidget);
    });
  });
}
