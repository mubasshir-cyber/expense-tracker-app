import 'package:expense_tracker/core/widgets/app_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('AppStateView Widget Tests', () {
    testWidgets('renders Loading state correctly', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const AppStateView.loading(
            title: 'Fetching financial data...',
            message: 'Please hold on',
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Fetching financial data...'), findsOneWidget);
      expect(find.text('Please hold on'), findsOneWidget);
    });

    testWidgets('renders Empty state with action', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        wrapWidget(
          AppStateView.empty(
            title: 'No Customers Found',
            message: 'Start by adding your first customer.',
            actionLabel: 'Add Customer',
            onAction: () => actionTriggered = true,
          ),
        ),
      );

      expect(find.text('No Customers Found'), findsOneWidget);
      expect(find.text('Start by adding your first customer.'), findsOneWidget);
      expect(find.text('Add Customer'), findsOneWidget);

      await tester.tap(find.text('Add Customer'));
      await tester.pump();
      expect(actionTriggered, isTrue);
    });

    testWidgets('renders Offline / No Internet state with retry action', (tester) async {
      bool retryTriggered = false;

      await tester.pumpWidget(
        wrapWidget(
          AppStateView.offline(
            onAction: () => retryTriggered = true,
          ),
        ),
      );

      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retryTriggered, isTrue);
    });

    testWidgets('renders Timeout state correctly', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const AppStateView.timeout(),
        ),
      );

      expect(find.text('Request Timed Out'), findsOneWidget);
      expect(find.text('The server took too long to respond. Please try again.'), findsOneWidget);
    });

    testWidgets('renders 401 Unauthorized / Session Expired state', (tester) async {
      bool signInTriggered = false;

      await tester.pumpWidget(
        wrapWidget(
          AppStateView.unauthorized(
            onAction: () => signInTriggered = true,
          ),
        ),
      );

      expect(find.text('Session Expired'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(signInTriggered, isTrue);
    });

    testWidgets('renders 403 Forbidden state', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const AppStateView.forbidden(),
        ),
      );

      expect(find.text('Access Denied'), findsOneWidget);
    });

    testWidgets('renders 404 Not Found state', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const AppStateView.notFound(),
        ),
      );

      expect(find.text('Page Not Found'), findsOneWidget);
    });

    testWidgets('renders 500 Server Error state', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const AppStateView.serverError(),
        ),
      );

      expect(find.text('Server Error'), findsOneWidget);
    });

    testWidgets('renders Maintenance mode state', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const AppStateView.maintenance(),
        ),
      );

      expect(find.text('Under Maintenance'), findsOneWidget);
    });

    testWidgets('renders App Update Required state', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const AppStateView.updateRequired(),
        ),
      );

      expect(find.text('Update Required'), findsOneWidget);
    });

    testWidgets('renders Generic Error state with secondary action', (tester) async {
      bool primaryTriggered = false;
      bool secondaryTriggered = false;

      await tester.pumpWidget(
        wrapWidget(
          AppStateView.error(
            title: 'Calculation Error',
            message: 'An unexpected mathematical error occurred.',
            actionLabel: 'Try Again',
            onAction: () => primaryTriggered = true,
            secondaryActionLabel: 'Dismiss',
            onSecondaryAction: () => secondaryTriggered = true,
          ),
        ),
      );

      expect(find.text('Calculation Error'), findsOneWidget);
      expect(find.text('An unexpected mathematical error occurred.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(primaryTriggered, isTrue);

      await tester.tap(find.text('Dismiss'));
      await tester.pump();
      expect(secondaryTriggered, isTrue);
    });

    testWidgets('renders Success state', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const AppStateView.success(
            title: 'Payment Recorded',
            message: '₹500 has been credited to customer ledger.',
          ),
        ),
      );

      expect(find.text('Payment Recorded'), findsOneWidget);
      expect(find.text('₹500 has been credited to customer ledger.'), findsOneWidget);
    });
  });
}
