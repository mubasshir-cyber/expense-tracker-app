import 'package:expense_tracker/features/auth/domain/models/auth_user.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_controller.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:expense_tracker/features/profile/domain/models/user_profile.dart';
import 'package:expense_tracker/features/profile/presentation/profile_screen.dart';
import 'package:expense_tracker/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthController extends AuthController {
  bool deleteAccountCalled = false;
  bool signOutCalled = false;

  @override
  Future<void> deleteAccount() async {
    deleteAccountCalled = true;
    state = const AsyncData(null);
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    state = const AsyncData(null);
  }
}

void main() {
  final mockUser = AuthUser(
    id: 'test-user-id',
    email: 'user@example.com',
  );

  final mockProfile = const UserProfile(
    id: 'test-user-id',
    fullName: 'Test User',
    email: 'user@example.com',
    currencyCode: 'INR',
    currencySymbol: '₹',
  );

  Widget createSubject(MockAuthController mockController) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(AuthAuthenticated(mockUser)),
        ),
        userProfileProvider.overrideWith(
          (ref) async => mockProfile,
        ),
        authControllerProvider.overrideWith(() => mockController),
      ],
      child: const MaterialApp(
        home: ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen Production Audit Tests', () {
    testWidgets('renders Privacy Policy, Terms, and App Version', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockController = MockAuthController();
      await tester.pumpWidget(createSubject(mockController));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('ABOUT & LEGAL'), 300);
      await tester.pumpAndSettle();

      expect(find.text('ABOUT & LEGAL'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('App Version'), findsOneWidget);
    });

    testWidgets('tapping Privacy Policy opens dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockController = MockAuthController();
      await tester.pumpWidget(createSubject(mockController));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Privacy Policy'), 300);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('tapping Terms & Conditions opens dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockController = MockAuthController();
      await tester.pumpWidget(createSubject(mockController));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Terms & Conditions'), 300);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terms & Conditions'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('tapping Delete Account shows double confirmation and calls deleteAccount', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockController = MockAuthController();
      await tester.pumpWidget(createSubject(mockController));
      await tester.pumpAndSettle();

      // Scroll to find delete account button
      await tester.scrollUntilVisible(
        find.byKey(const Key('delete_account_button')),
        300,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('delete_account_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('delete_account_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete Account?'), findsOneWidget);
      expect(find.text('Delete Everything'), findsOneWidget);

      await tester.tap(find.text('Delete Everything'));
      await tester.pumpAndSettle();

      expect(mockController.deleteAccountCalled, isTrue);
    });
  });
}
