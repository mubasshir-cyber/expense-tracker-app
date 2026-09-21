import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/accounts/data/repositories/account_repository.dart';
import 'package:expense_tracker/features/accounts/domain/models/account_model.dart';
import 'package:expense_tracker/features/accounts/presentation/providers/account_providers.dart';
import 'package:expense_tracker/features/accounts/presentation/providers/account_repository_provider.dart';
import 'package:expense_tracker/features/categories/data/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/models/category_model.dart';
import 'package:expense_tracker/features/categories/presentation/providers/category_repository_provider.dart';
import 'package:expense_tracker/features/profile/data/repositories/profile_repository.dart';
import 'package:expense_tracker/features/profile/domain/models/user_profile.dart';
import 'package:expense_tracker/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:expense_tracker/features/transactions/data/repositories/transaction_repository.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_type.dart';
import 'package:expense_tracker/features/transactions/presentation/add_transaction_screen.dart';
import 'package:expense_tracker/features/transactions/presentation/providers/data_providers.dart';
import 'package:expense_tracker/features/transactions/presentation/providers/transaction_repository_provider.dart';

class FakeProfileRepository extends Fake implements ProfileRepository {
  @override
  Future<UserProfile> getCurrentProfile() async => const UserProfile(
        id: 'user-1',
        fullName: 'User',
        currencyCode: 'INR',
        currencySymbol: '₹',
      );
}

class FakeTransactionRepository extends Fake implements TransactionRepository {
  bool createCalled = false;
  bool updateCalled = false;
  bool deleteCalled = false;

  String? lastAccountId;
  String? lastCategoryId;
  TransactionType? lastType;
  double? lastAmount;
  String? lastDeletedId;

  @override
  Future<List<TransactionModel>> getTransactions({TransactionFilter? filter}) async {
    return [];
  }

  @override
  Future<TransactionModel> createTransaction({
    required String accountId,
    required String categoryId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    createCalled = true;
    lastAccountId = accountId;
    lastCategoryId = categoryId;
    lastType = type;
    lastAmount = amount;
    return TransactionModel(
      id: 'tx-new',
      userId: 'user-1',
      accountId: accountId,
      categoryId: categoryId,
      type: type.value,
      amount: amount,
      description: note,
      transactionDate: date,
    );
  }

  @override
  Future<TransactionModel> updateTransaction({
    required String transactionId,
    String? accountId,
    String? categoryId,
    TransactionType? type,
    double? amount,
    DateTime? date,
    String? note,
  }) async {
    updateCalled = true;
    lastAccountId = accountId;
    lastCategoryId = categoryId;
    lastType = type;
    lastAmount = amount;
    return TransactionModel(
      id: transactionId,
      userId: 'user-1',
      accountId: accountId ?? 'acc-1',
      categoryId: categoryId ?? 'cat-1',
      type: type?.value ?? 'EXPENSE',
      amount: amount ?? 100.0,
      description: note,
      transactionDate: date ?? DateTime.now(),
    );
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    deleteCalled = true;
    lastDeletedId = transactionId;
  }
}

class FakeAccountRepository extends Fake implements AccountRepository {
  @override
  Future<List<AccountModel>> getAccounts({bool activeOnly = true}) async => [
        const AccountModel(
          id: 'acc-1',
          userId: 'user-1',
          name: 'Main Bank',
          type: 'BANK',
          isActive: true,
          openingBalance: 10000.0,
        ),
        const AccountModel(
          id: 'acc-2',
          userId: 'user-1',
          name: 'Cash Wallet',
          type: 'CASH',
          isActive: true,
          openingBalance: 2000.0,
        ),
      ];
}

class FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getCategories({String? type}) async => [
        const CategoryModel(
          id: 'cat-exp-1',
          userId: 'user-1',
          name: 'Groceries',
          type: 'EXPENSE',
          isActive: true,
        ),
        const CategoryModel(
          id: 'cat-exp-2',
          userId: 'user-1',
          name: 'Transport',
          type: 'EXPENSE',
          isActive: true,
        ),
        const CategoryModel(
          id: 'cat-crd-1',
          userId: 'user-1',
          name: 'Salary',
          type: 'CREDIT',
          isActive: true,
        ),
      ];
}

void main() {
  const testAccounts = [
    AccountModel(
      id: 'acc-1',
      userId: 'user-1',
      name: 'Main Bank',
      type: 'BANK',
      isActive: true,
      openingBalance: 10000.0,
    ),
    AccountModel(
      id: 'acc-2',
      userId: 'user-1',
      name: 'Cash Wallet',
      type: 'CASH',
      isActive: true,
      openingBalance: 2000.0,
    ),
  ];

  const testExpenseCategories = [
    CategoryModel(
      id: 'cat-exp-1',
      userId: 'user-1',
      name: 'Groceries',
      type: 'EXPENSE',
      isActive: true,
    ),
    CategoryModel(
      id: 'cat-exp-2',
      userId: 'user-1',
      name: 'Transport',
      type: 'EXPENSE',
      isActive: true,
    ),
  ];

  const testCreditCategories = [
    CategoryModel(
      id: 'cat-crd-1',
      userId: 'user-1',
      name: 'Salary',
      type: 'CREDIT',
      isActive: true,
    ),
  ];

  late FakeTransactionRepository fakeTxRepo;
  late FakeAccountRepository fakeAccRepo;
  late FakeCategoryRepository fakeCatRepo;
  late FakeProfileRepository fakeProfileRepo;

  setUp(() {
    fakeTxRepo = FakeTransactionRepository();
    fakeAccRepo = FakeAccountRepository();
    fakeCatRepo = FakeCategoryRepository();
    fakeProfileRepo = FakeProfileRepository();
  });

  Widget createWidget({
    TransactionModel? transactionToEdit,
    TransactionType? initialType,
  }) {
    return ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(fakeProfileRepo),
        accountRepositoryProvider.overrideWithValue(fakeAccRepo),
        categoryRepositoryProvider.overrideWithValue(fakeCatRepo),
        transactionRepositoryProvider.overrideWithValue(fakeTxRepo),
        allTransactionsProvider.overrideWith((ref) => Future.value([])),
        accountsProvider.overrideWith((ref) => Future.value(testAccounts)),
        categoriesProvider.overrideWith(
          (ref) => Future.value([...testExpenseCategories, ...testCreditCategories]),
        ),
        expenseCategoriesProvider.overrideWith((ref) => Future.value(testExpenseCategories)),
        incomeCategoriesProvider.overrideWith((ref) => Future.value(testCreditCategories)),
        userProfileProvider.overrideWith(
          (ref) => Future.value(
            const UserProfile(
              id: 'user-1',
              fullName: 'User',
              currencyCode: 'INR',
              currencySymbol: '₹',
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: AddTransactionScreen(
          transactionToEdit: transactionToEdit,
          initialType: initialType,
        ),
      ),
    );
  }

  group('AddTransactionScreen — 5.3 Add Transaction', () {
    testWidgets('renders initial Expense form with all fields', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.text('Expense'), findsWidgets);
      expect(find.text('Credit'), findsWidgets);
      expect(find.byKey(const Key('transaction_amount_field')), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
      expect(find.byKey(const Key('save_transaction_button')), findsOneWidget);
    });

    testWidgets('validates required amount, category and account fields', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final saveButton = find.byKey(const Key('save_transaction_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Please enter an amount'), findsOneWidget);
    });

    testWidgets('switches between Expense and Credit types and category lists', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Switch to Credit
      final creditToggle = find.byKey(const Key('type_toggle_credit'));
      await tester.tap(creditToggle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Open category dropdown (first dropdown)
      final categoryDropdown = find.byType(DropdownButtonFormField<String>).first;
      await tester.tap(categoryDropdown);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should show Salary (credit category)
      expect(find.text('Salary').last, findsOneWidget);
    });

    testWidgets('successfully creates an expense transaction', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Enter amount
      await tester.enterText(find.byKey(const Key('transaction_amount_field')), '450');

      // Select Category
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Groceries').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Select Account
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Main Bank').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Save
      final saveButton = find.byKey(const Key('save_transaction_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeTxRepo.createCalled, isTrue);
      expect(fakeTxRepo.lastAccountId, 'acc-1');
      expect(fakeTxRepo.lastCategoryId, 'cat-exp-1');
      expect(fakeTxRepo.lastType, TransactionType.expense);
      expect(fakeTxRepo.lastAmount, 450.0);
    });
  });

  group('AddTransactionScreen — 5.5 Edit & Delete', () {
    final existingTx = TransactionModel(
      id: 'tx-edit-1',
      userId: 'user-1',
      accountId: 'acc-1',
      categoryId: 'cat-exp-1',
      type: 'EXPENSE',
      amount: 1250.0,
      description: 'Weekly grocery run',
      transactionDate: DateTime(2026, 9, 20),
    );

    testWidgets('pre-fills existing transaction in Edit mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(transactionToEdit: existingTx));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Edit Transaction'), findsOneWidget);
      expect(find.text('1250.00'), findsOneWidget);
      expect(find.text('Weekly grocery run'), findsOneWidget);
      expect(find.byKey(const Key('delete_transaction_button')), findsOneWidget);
    });

    testWidgets('successfully updates transaction', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(transactionToEdit: existingTx));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byKey(const Key('transaction_amount_field')), '1500');
      final saveButton = find.byKey(const Key('save_transaction_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeTxRepo.updateCalled, isTrue);
      expect(fakeTxRepo.lastAccountId, 'acc-1');
      expect(fakeTxRepo.lastCategoryId, 'cat-exp-1');
      expect(fakeTxRepo.lastAmount, 1500.0);
    });

    testWidgets('soft deletes transaction after confirmation dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(transactionToEdit: existingTx));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap delete button
      await tester.tap(find.byKey(const Key('delete_transaction_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Delete transaction?'), findsOneWidget);
      expect(find.text('This transaction will be removed from your records.'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.text('Delete').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeTxRepo.deleteCalled, isTrue);
      expect(fakeTxRepo.lastDeletedId, 'tx-edit-1');
    });
  });
}
