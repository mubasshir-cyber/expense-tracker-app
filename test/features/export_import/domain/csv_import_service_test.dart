import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/accounts/domain/models/account_model.dart';
import 'package:expense_tracker/features/categories/domain/models/category_model.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_type.dart';
import 'package:expense_tracker/features/export_import/domain/services/csv_import_service.dart';

void main() {
  const service = CsvImportService();

  final accounts = [
    const AccountModel(
      id: 'acc-1',
      userId: 'user-1',
      name: 'HDFC Bank',
      type: 'bank',
      isActive: true,
      openingBalance: 50000.0,
    ),
  ];

  final categories = [
    const CategoryModel(
      id: 'cat-1',
      userId: 'user-1',
      name: 'Groceries',
      type: 'expense',
      isActive: true,
    ),
    const CategoryModel(
      id: 'cat-2',
      userId: 'user-1',
      name: 'Salary',
      type: 'income',
      isActive: true,
    ),
  ];

  final existingTransactions = [
    TransactionModel(
      id: 'tx-1',
      userId: 'user-1',
      accountId: 'acc-1',
      categoryId: 'cat-1',
      type: 'EXPENSE',
      amount: 1250.0,
      transactionDate: DateTime(2026, 9, 20),
      description: 'Supermarket shopping',
    ),
  ];

  group('CsvImportService Tests', () {
    test('parses valid CSV and maps columns successfully', () {
      const csv = '''
Date,Type,Amount,Category,Account,Description
2026-09-21,EXPENSE,₹500.00,Groceries,HDFC Bank,Snacks
2026-09-22,INCOME,75000,Salary,HDFC Bank,Monthly Salary
''';

      final rows = service.parseCsv(
        rawCsv: csv,
        existingAccounts: accounts,
        existingCategories: categories,
        existingTransactions: existingTransactions,
      );

      expect(rows.length, 2);

      final row1 = rows[0];
      expect(row1.isValid, isTrue);
      expect(row1.parsedAmount, 500.0);
      expect(row1.parsedType, TransactionType.expense);
      expect(row1.parsedCategoryName, 'Groceries');
      expect(row1.parsedAccountName, 'HDFC Bank');
      expect(row1.parsedDescription, 'Snacks');
      expect(row1.isDuplicate, isFalse);
      expect(row1.isSelected, isTrue);

      final row2 = rows[1];
      expect(row2.isValid, isTrue);
      expect(row2.parsedAmount, 75000.0);
      expect(row2.parsedType, TransactionType.credit);
      expect(row2.parsedDescription, 'Monthly Salary');
    });

    test('detects duplicate transactions against existing database records', () {
      const csv = '''
Date,Type,Amount,Category,Account,Description
2026-09-20,EXPENSE,1250.00,Groceries,HDFC Bank,Supermarket shopping
2026-09-25,EXPENSE,300.00,Groceries,HDFC Bank,Coffee
''';

      final rows = service.parseCsv(
        rawCsv: csv,
        existingAccounts: accounts,
        existingCategories: categories,
        existingTransactions: existingTransactions,
      );

      expect(rows.length, 2);

      final duplicateRow = rows[0];
      expect(duplicateRow.isValid, isTrue);
      expect(duplicateRow.isDuplicate, isTrue);
      expect(duplicateRow.isSelected, isFalse); // duplicates deselected by default

      final normalRow = rows[1];
      expect(normalRow.isDuplicate, isFalse);
      expect(normalRow.isSelected, isTrue);
    });

    test('flags invalid dates and negative/zero amounts with validation errors', () {
      const csv = '''
Date,Type,Amount,Category,Account,Description
invalid-date,EXPENSE,-50.00,Groceries,HDFC Bank,Bad Row
''';

      final rows = service.parseCsv(
        rawCsv: csv,
        existingAccounts: accounts,
        existingCategories: categories,
        existingTransactions: existingTransactions,
      );

      expect(rows.length, 1);
      final row = rows[0];
      expect(row.isValid, isFalse);
      expect(row.isSelected, isFalse);
      expect(row.validationErrors.length, greaterThanOrEqualTo(2));
    });

    test('handles missing required columns gracefully', () {
      const csv = '''
Name,Description
Foo,Bar
''';

      final rows = service.parseCsv(
        rawCsv: csv,
        existingAccounts: accounts,
        existingCategories: categories,
        existingTransactions: existingTransactions,
      );

      expect(rows.length, 1);
      expect(rows.first.isValid, isFalse);
      expect(rows.first.validationErrors.first, contains('Required columns missing'));
    });
  });
}
