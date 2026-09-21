import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/accounts/data/repositories/account_repository.dart';
import 'package:expense_tracker/features/accounts/domain/models/account_model.dart';
import 'package:expense_tracker/features/accounts/presentation/accounts_screen.dart';
import 'package:expense_tracker/features/accounts/presentation/providers/account_providers.dart';
import 'package:expense_tracker/features/accounts/presentation/providers/account_repository_provider.dart';

class FakeAccountRepository extends Fake implements AccountRepository {
  bool createCalled = false;
  bool updateCalled = false;
  bool deleteCalled = false;

  String? lastCreatedName;
  String? lastCreatedType;
  double? lastCreatedBalance;
  String? lastDeletedId;

  @override
  Future<List<AccountModel>> getAccounts({bool activeOnly = true}) async {
    return [];
  }

  @override
  Future<AccountModel> createAccount({
    required String name,
    required String type,
    String? icon,
    String? color,
    double openingBalance = 0.00,
  }) async {
    createCalled = true;
    lastCreatedName = name;
    lastCreatedType = type;
    lastCreatedBalance = openingBalance;
    return AccountModel(
      id: 'acc-new',
      userId: 'user-1',
      name: name,
      type: type,
      openingBalance: openingBalance,
      isActive: true,
    );
  }

  @override
  Future<AccountModel> updateAccount({
    required String accountId,
    String? name,
    String? type,
    String? icon,
    String? color,
    bool? isActive,
  }) async {
    updateCalled = true;
    return AccountModel(
      id: accountId,
      userId: 'user-1',
      name: name ?? 'Account',
      type: type ?? 'Bank',
      isActive: isActive ?? true,
    );
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    deleteCalled = true;
    lastDeletedId = accountId;
  }
}

void main() {
  const testAccounts = [
    AccountModel(
      id: 'acc-1',
      userId: 'user-1',
      name: 'Main Bank',
      type: 'Bank',
      isActive: true,
      openingBalance: 10000.0,
    ),
    AccountModel(
      id: 'acc-2',
      userId: 'user-1',
      name: 'Old Cash Box',
      type: 'Cash',
      isActive: false,
      openingBalance: 500.0,
    ),
  ];

  late FakeAccountRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeAccountRepository();
  });

  Widget createWidget({List<AccountModel> accounts = testAccounts}) {
    return ProviderScope(
      overrides: [
        accountRepositoryProvider.overrideWithValue(fakeRepo),
        allAccountsProvider.overrideWith((ref) => Future.value(accounts)),
        accountsProvider.overrideWith((ref) => Future.value(accounts.where((a) => a.isActive).toList())),
        accountBalanceProvider('acc-1').overrideWith((ref) => Future.value(12500.0)),
        accountBalanceProvider('acc-2').overrideWith((ref) => Future.value(500.0)),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const AccountsScreen(),
      ),
    );
  }

  group('AccountsScreen — 5.6 Accounts Management', () {
    testWidgets('renders active accounts list', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Accounts'), findsOneWidget);
      expect(find.text('Main Bank'), findsOneWidget);
      expect(find.text('Old Cash Box'), findsNothing); // Inactive initially hidden
    });

    testWidgets('toggles balance privacy with eye button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Initially balance is visible
      expect(find.text('••••••'), findsNothing);

      // Tap eye button to hide balance
      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await tester.pumpAndSettle();

      // Now balance is masked
      expect(find.text('••••••'), findsOneWidget);

      // Tap eye button again to reveal balance
      await tester.tap(find.byIcon(Icons.visibility_off_rounded));
      await tester.pumpAndSettle();

      expect(find.text('••••••'), findsNothing);
    });

    testWidgets('toggles visibility of inactive accounts via filter menu', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Open filter popup menu in AppBar
      await tester.tap(find.byTooltip('Filter Options'));
      await tester.pumpAndSettle();

      // Tap Show Inactive
      await tester.tap(find.text('Show Inactive'));
      await tester.pumpAndSettle();

      expect(find.text('Main Bank'), findsOneWidget);
      expect(find.text('Old Cash Box'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
    });

    testWidgets('opens Add Account sheet and creates account', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('New Account'), findsOneWidget);

      // Fill name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Account Name *'),
        'Credit Card',
      );

      // Save
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(fakeRepo.createCalled, isTrue);
      expect(fakeRepo.lastCreatedName, 'Credit Card');
    });

    testWidgets('deactivates account after confirmation', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Open menu on account card
      await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
      await tester.pumpAndSettle();

      // Tap Deactivate
      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();

      expect(find.text('Deactivate Account?'), findsOneWidget);

      // Confirm
      await tester.tap(find.widgetWithText(FilledButton, 'Deactivate'));
      await tester.pumpAndSettle();

      expect(fakeRepo.deleteCalled, isTrue);
      expect(fakeRepo.lastDeletedId, 'acc-1');
    });
  });
}
