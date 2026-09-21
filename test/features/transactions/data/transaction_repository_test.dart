import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/features/transactions/domain/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_type.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // TransactionRepository serialization contract tests.
  //
  // These tests verify:
  //  1. TransactionModel.fromMap correctly reads the DB column names
  //  2. toMap produces the correct keys for Supabase inserts/updates
  //  3. TransactionType enum values match what the DB CHECK constraint expects
  //
  // Column names (from 001_initial_schema.sql):
  //   transaction_date DATE
  //   description TEXT
  //   payment_method TEXT
  // ──────────────────────────────────────────────────────────────────────────

  final baseDate = DateTime(2026, 9, 20);

  final baseMap = {
    'id': 'txn-001',
    'user_id': 'user-123',
    'account_id': 'acct-001',
    'category_id': 'cat-001',
    'type': 'EXPENSE',
    'amount': 2500.0,
    'description': 'Groceries',
    'transaction_date': baseDate.toIso8601String(),
    'payment_method': 'UPI',
  };

  group('TransactionRepository — TransactionModel serialization', () {
    test('fromMap parses expense transaction correctly', () {
      final model = TransactionModel.fromMap(baseMap);

      expect(model.id, 'txn-001');
      expect(model.userId, 'user-123');
      expect(model.accountId, 'acct-001');
      expect(model.categoryId, 'cat-001');
      expect(model.type, 'EXPENSE');
      expect(model.amount, 2500.0);
      expect(model.description, 'Groceries');
      expect(model.paymentMethod, 'UPI');
    });

    test('fromMap parses credit transaction correctly', () {
      final map = Map<String, dynamic>.from(baseMap)
        ..['type'] = 'CREDIT'
        ..['amount'] = 50000.0
        ..['description'] = 'Salary';

      final model = TransactionModel.fromMap(map);

      expect(model.type, 'CREDIT');
      expect(model.amount, 50000.0);
      expect(model.description, 'Salary');
    });

    test('fromMap handles integer amount (DB NUMERIC returns int)', () {
      final map = Map<String, dynamic>.from(baseMap)
        ..['amount'] = 5000; // int, not double

      final model = TransactionModel.fromMap(map);

      expect(model.amount, isA<double>());
      expect(model.amount, 5000.0);
    });

    test('fromMap handles null description', () {
      final map = Map<String, dynamic>.from(baseMap)..['description'] = null;

      final model = TransactionModel.fromMap(map);

      expect(model.description, isNull);
    });

    test('fromMap handles null payment_method', () {
      final map = Map<String, dynamic>.from(baseMap)
        ..['payment_method'] = null;

      final model = TransactionModel.fromMap(map);

      expect(model.paymentMethod, isNull);
    });

    test('toMap produces correct keys for DB insert', () {
      final model = TransactionModel.fromMap(baseMap);
      final map = model.toMap();

      expect(map.containsKey('id'), isTrue);
      expect(map.containsKey('user_id'), isTrue);
      expect(map.containsKey('account_id'), isTrue);
      expect(map.containsKey('category_id'), isTrue);
      expect(map.containsKey('type'), isTrue);
      expect(map.containsKey('amount'), isTrue);
      expect(map.containsKey('description'), isTrue);
      expect(map.containsKey('transaction_date'), isTrue);
      expect(map.containsKey('payment_method'), isTrue);
    });

    test('fromMap → toMap round-trip preserves all fields', () {
      final original = TransactionModel.fromMap(baseMap);
      final roundTripped = TransactionModel.fromMap(original.toMap());

      expect(roundTripped.id, original.id);
      expect(roundTripped.userId, original.userId);
      expect(roundTripped.accountId, original.accountId);
      expect(roundTripped.categoryId, original.categoryId);
      expect(roundTripped.type, original.type);
      expect(roundTripped.amount, original.amount);
      expect(roundTripped.description, original.description);
      expect(roundTripped.paymentMethod, original.paymentMethod);
    });

    test('copyWith updates amount only', () {
      final original = TransactionModel.fromMap(baseMap);
      final updated = original.copyWith(amount: 3000.0);

      expect(updated.amount, 3000.0);
      expect(updated.id, original.id);
      expect(updated.type, original.type);
    });

    test('copyWith updates description only', () {
      final original = TransactionModel.fromMap(baseMap);
      final updated = original.copyWith(description: 'Updated note');

      expect(updated.description, 'Updated note');
      expect(updated.amount, original.amount);
    });

    test('soft-delete via copyWith does not appear (no deleted_at on model)',
        () {
      // TransactionModel does not expose deleted_at — soft delete is
      // handled by the repository directly via an UPDATE call, not via the
      // model. This test documents that deliberate design decision.
      final original = TransactionModel.fromMap(baseMap);

      expect(
        () => original.toMap().containsKey('deleted_at'),
        returnsNormally,
      );
      expect(original.toMap().containsKey('deleted_at'), isFalse);
    });
  });

  group('TransactionRepository — TransactionType DB values', () {
    test('expense type value matches DB CHECK constraint', () {
      // DB: CHECK (type IN (\'EXPENSE\', \'CREDIT\'))
      expect(TransactionType.expense.value, 'EXPENSE');
    });

    test('credit type value matches DB CHECK constraint', () {
      expect(TransactionType.credit.value, 'CREDIT');
    });

    test('fromValue parses EXPENSE case-insensitively', () {
      expect(
        TransactionTypeX.fromValue('expense'),
        TransactionType.expense,
      );
      expect(
        TransactionTypeX.fromValue('EXPENSE'),
        TransactionType.expense,
      );
    });

    test('fromValue parses CREDIT case-insensitively', () {
      expect(
        TransactionTypeX.fromValue('credit'),
        TransactionType.credit,
      );
    });

    test('fromValue throws on unknown type', () {
      expect(
        () => TransactionTypeX.fromValue('income'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('TransactionRepository — auth boundary contract', () {
    test('TransactionModel requires user_id field', () {
      expect(
        () => TransactionModel.fromMap({
          'id': 'txn-001',
          // 'user_id' deliberately omitted
          'account_id': 'acct-001',
          'category_id': 'cat-001',
          'type': 'EXPENSE',
          'amount': 100.0,
          'transaction_date': baseDate.toIso8601String(),
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
