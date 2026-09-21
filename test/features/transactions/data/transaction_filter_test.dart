import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/features/transactions/data/repositories/transaction_repository.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_type.dart';

void main() {
  group('TransactionFilter', () {
    test('default constructor has all null fields', () {
      const filter = TransactionFilter();

      expect(filter.accountId, isNull);
      expect(filter.categoryId, isNull);
      expect(filter.type, isNull);
      expect(filter.from, isNull);
      expect(filter.to, isNull);
      expect(filter.limit, isNull);
      expect(filter.offset, isNull);
    });

    test('accountId filter sets only accountId', () {
      const filter = TransactionFilter(accountId: 'acc-1');

      expect(filter.accountId, 'acc-1');
      expect(filter.categoryId, isNull);
      expect(filter.type, isNull);
    });

    test('categoryId filter sets only categoryId', () {
      const filter = TransactionFilter(categoryId: 'cat-1');

      expect(filter.categoryId, 'cat-1');
      expect(filter.accountId, isNull);
    });

    test('type filter expense sets TransactionType.expense', () {
      const filter = TransactionFilter(type: TransactionType.expense);

      expect(filter.type, TransactionType.expense);
    });

    test('type filter credit sets TransactionType.credit', () {
      const filter = TransactionFilter(type: TransactionType.credit);

      expect(filter.type, TransactionType.credit);
    });

    test('date range filter sets from and to', () {
      final from = DateTime(2026, 1, 1);
      final to = DateTime(2026, 1, 31);
      final filter = TransactionFilter(from: from, to: to);

      expect(filter.from, from);
      expect(filter.to, to);
    });

    test('pagination filter sets limit and offset', () {
      const filter = TransactionFilter(limit: 20, offset: 40);

      expect(filter.limit, 20);
      expect(filter.offset, 40);
    });

    test('multiple filters combine independently', () {
      final from = DateTime(2026, 9, 1);
      final filter = TransactionFilter(
        accountId: 'acc-1',
        categoryId: 'cat-2',
        type: TransactionType.expense,
        from: from,
        limit: 10,
        offset: 0,
      );

      expect(filter.accountId, 'acc-1');
      expect(filter.categoryId, 'cat-2');
      expect(filter.type, TransactionType.expense);
      expect(filter.from, from);
      expect(filter.to, isNull);
      expect(filter.limit, 10);
      expect(filter.offset, 0);
    });

    test('filter is a const value object', () {
      const a = TransactionFilter(accountId: 'acc-1', limit: 10);
      const b = TransactionFilter(accountId: 'acc-1', limit: 10);

      // Both are const — referential equality holds.
      expect(identical(a, b), isTrue);
    });
  });
}
