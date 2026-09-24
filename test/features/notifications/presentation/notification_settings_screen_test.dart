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
      tester.view.physicalSize = const Size(500 * 3, 2400 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Smart Notification Engine'), findsOneWidget);

      // Category Headers
      expect(find.text('SYSTEM & OS NOTIFICATIONS'), findsOneWidget);
      expect(find.text('BUDGET ALERTS'), findsOneWidget);
      expect(find.text('RECURRING & UPCOMING BILLS'), findsOneWidget);
      expect(find.text('LOANS, DEBTS & KHATA'), findsOneWidget);
      expect(find.text('SAVINGS GOALS & INSIGHTS'), findsOneWidget);

      // Preference items
      expect(find.text('Device Status Bar Alerts'), findsOneWidget);
      expect(find.text('Hide Sensitive Balances'), findsOneWidget);
      expect(find.text('Budget Warning (80% Threshold)'), findsOneWidget);
      expect(find.text('Budget Exceeded Alert'), findsOneWidget);
      expect(find.text('Upcoming Bill Reminders'), findsOneWidget);
      expect(find.text('Auto-Created Transactions'), findsOneWidget);
      expect(find.text('Loan & Debt Reminders'), findsOneWidget);
      expect(find.text('Khata Customer Due Alerts'), findsOneWidget);
      expect(find.text('Savings Goal Milestones'), findsOneWidget);
      expect(find.text('Spending Surge Alerts'), findsOneWidget);
      expect(find.text('Monthly Financial Summary'), findsOneWidget);
      expect(find.text('Send Test Notification'), findsOneWidget);

      // Verify all switch list tiles are present (11 switches)
      expect(find.byType(Switch), findsNWidgets(11));
    });
  });
}
