import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_type.dart';

void main() {
  group('TransactionModel', () {
    final testDate = DateTime(2026, 9, 20, 14, 30);

    test('fromMap converts database map to TransactionModel correctly', () {
      final map = {
        'id': 'txn-123',
        'user_id': 'user-456',
        'account_id': 'acc-789',
        'category_id': 'cat-101',
        'type': 'EXPENSE',
        'amount': 450.50,
        'description': 'Grocery shopping',
        'transaction_date': testDate.toIso8601String(),
        'payment_method': 'UPI',
      };

      final txn = TransactionModel.fromMap(map);

      expect(txn.id, equals('txn-123'));
      expect(txn.userId, equals('user-456'));
      expect(txn.accountId, equals('acc-789'));
      expect(txn.categoryId, equals('cat-101'));
      expect(txn.type, equals('EXPENSE'));
      expect(txn.amount, equals(450.50));
      expect(txn.description, equals('Grocery shopping'));
      expect(txn.transactionDate, equals(testDate));
      expect(txn.paymentMethod, equals('UPI'));
    });

    test('toMap produces database-compatible map', () {
      final txn = TransactionModel(
        id: 'txn-123',
        userId: 'user-456',
        accountId: 'acc-789',
        categoryId: 'cat-101',
        type: 'CREDIT',
        amount: 50000.0,
        description: 'Monthly Salary',
        transactionDate: testDate,
        paymentMethod: 'BANK',
      );

      final map = txn.toMap();

      expect(map['id'], equals('txn-123'));
      expect(map['user_id'], equals('user-456'));
      expect(map['account_id'], equals('acc-789'));
      expect(map['category_id'], equals('cat-101'));
      expect(map['type'], equals('CREDIT'));
      expect(map['amount'], equals(50000.0));
      expect(map['description'], equals('Monthly Salary'));
      expect(map['transaction_date'], equals(testDate.toIso8601String()));
      expect(map['payment_method'], equals('BANK'));
    });

    test('amount correctly converts integer to double', () {
      final map = {
        'id': 'txn-int',
        'user_id': 'user-1',
        'account_id': 'acc-1',
        'category_id': 'cat-1',
        'type': 'EXPENSE',
        'amount': 100, // integer from JSON
        'transaction_date': testDate.toIso8601String(),
      };

      final txn = TransactionModel.fromMap(map);

      expect(txn.amount, equals(100.0));
      expect(txn.description, isNull);
      expect(txn.paymentMethod, isNull);
    });

    test('copyWith updates specified fields only', () {
      final txn = TransactionModel(
        id: 'txn-1',
        userId: 'user-1',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: 'EXPENSE',
        amount: 200.0,
        transactionDate: testDate,
      );

      final updated = txn.copyWith(amount: 350.0, description: 'Updated note');

      expect(updated.amount, equals(350.0));
      expect(updated.description, equals('Updated note'));
      expect(updated.id, equals('txn-1'));
      expect(updated.type, equals('EXPENSE'));
    });
  });

  group('TransactionType', () {
    test('value returns correct uppercase strings', () {
      expect(TransactionType.expense.value, equals('EXPENSE'));
      expect(TransactionType.credit.value, equals('CREDIT'));
    });

    test('fromValue parses case-insensitively', () {
      expect(TransactionTypeX.fromValue('EXPENSE'), equals(TransactionType.expense));
      expect(TransactionTypeX.fromValue('expense'), equals(TransactionType.expense));
      expect(TransactionTypeX.fromValue('CREDIT'), equals(TransactionType.credit));
      expect(TransactionTypeX.fromValue('credit'), equals(TransactionType.credit));
    });

    test('fromValue throws on invalid type', () {
      expect(
        () => TransactionTypeX.fromValue('TRANSFER'),
        throwsArgumentError,
      );
      expect(
        () => TransactionTypeX.fromValue(''),
        throwsArgumentError,
      );
    });
  });
}
