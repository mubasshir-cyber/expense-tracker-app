import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/notifications/domain/models/notification_settings_model.dart';
import 'package:expense_tracker/features/notifications/presentation/notification_settings_screen.dart';
import 'package:expense_tracker/features/notifications/presentation/providers/notification_providers.dart';

void main() {
  const sampleSettings = NotificationSettingsModel(
    userId: 'user-1',
    budgetWarningEnabled: true,
    budgetExceededEnabled: true,
    recurringUpcomingEnabled: true,
    recurringAutoCreatedEnabled: true,
    spendingAlertsEnabled: true,
    monthlySummaryEnabled: true,
  );

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        notificationSettingsProvider.overrideWith(
          (ref) async => sampleSettings,
        ),
      ],
      child: const MaterialApp(
        home: NotificationSettingsScreen(),
      ),
    );
  }

  group('NotificationSettingsScreen Widget Tests', () {
    testWidgets('renders all preference categories and switch list tiles', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Smart Notification Engine'), findsOneWidget);

      // Category Headers
      expect(find.text('BUDGET ALERTS'), findsOneWidget);
      expect(find.text('RECURRING & UPCOMING BILLS'), findsOneWidget);
      expect(find.text('SPENDING INSIGHTS & REPORTS'), findsOneWidget);

      // Preference items
      expect(find.text('Budget Warning (80% Threshold)'), findsOneWidget);
      expect(find.text('Budget Exceeded Alert'), findsOneWidget);
      expect(find.text('Upcoming Bill Reminders'), findsOneWidget);
      expect(find.text('Auto-Created Transactions'), findsOneWidget);
      expect(find.text('Spending Surge Alerts'), findsOneWidget);
      expect(find.text('Monthly Financial Summary'), findsOneWidget);

      // Verify all 6 switches are present
      expect(find.byType(Switch), findsNWidgets(6));
    });
  });
}
