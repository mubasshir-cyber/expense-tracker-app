import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/recurring/domain/models/recurring_frequency.dart';
import 'package:expense_tracker/features/recurring/domain/models/recurring_transaction_model.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_type.dart';

void main() {
  group('RecurringTransactionModel', () {
    final sampleModel = RecurringTransactionModel(
      id: 'rec-1',
      userId: 'user-1',
      accountId: 'acc-1',
      categoryId: 'cat-1',
      type: TransactionType.expense,
      amount: 649.0,
      description: 'Netflix Subscription',
      frequency: RecurringFrequency.monthly,
      startDate: DateTime(2026, 1, 1),
      nextOccurrence: DateTime(2026, 2, 1),
      endDate: DateTime(2026, 12, 31),
      isActive: true,
      autoCreate: true,
      createdAt: DateTime(2026, 1, 1, 10, 0),
    );

    test('toMap and fromMap serialize and deserialize accurately', () {
      final map = sampleModel.toMap();
      expect(map['id'], 'rec-1');
      expect(map['user_id'], 'user-1');
      expect(map['account_id'], 'acc-1');
      expect(map['category_id'], 'cat-1');
      expect(map['type'], 'EXPENSE');
      expect(map['amount'], 649.0);
      expect(map['description'], 'Netflix Subscription');
      expect(map['frequency'], 'MONTHLY');
      expect(map['start_date'], '2026-01-01');
      expect(map['next_occurrence'], '2026-02-01');
      expect(map['end_date'], '2026-12-31');
      expect(map['is_active'], true);
      expect(map['auto_create'], true);

      final deserialized = RecurringTransactionModel.fromMap(map);
      expect(deserialized.id, sampleModel.id);
      expect(deserialized.userId, sampleModel.userId);
      expect(deserialized.type, sampleModel.type);
      expect(deserialized.amount, sampleModel.amount);
      expect(deserialized.description, sampleModel.description);
      expect(deserialized.frequency, sampleModel.frequency);
      expect(deserialized.startDate, sampleModel.startDate);
      expect(deserialized.nextOccurrence, sampleModel.nextOccurrence);
      expect(deserialized.endDate, sampleModel.endDate);
      expect(deserialized.isActive, sampleModel.isActive);
      expect(deserialized.autoCreate, sampleModel.autoCreate);
    });

    test('copyWith updates fields correctly without mutating unmodified properties', () {
      final updated = sampleModel.copyWith(
        amount: 799.0,
        isActive: false,
        endDate: null,
      );

      expect(updated.id, 'rec-1');
      expect(updated.amount, 799.0);
      expect(updated.isActive, false);
      expect(updated.endDate, sampleModel.endDate); // when null passed without clear flag
    });

    test('isDue correctly determines if occurrence is on or before asOfDate', () {
      // nextOccurrence is 2026-02-01
      expect(sampleModel.isDue(DateTime(2026, 1, 31)), false);
      expect(sampleModel.isDue(DateTime(2026, 2, 1, 8, 30)), true);
      expect(sampleModel.isDue(DateTime(2026, 2, 10)), true);

      // Inactive item should never be due
      final inactive = sampleModel.copyWith(isActive: false);
      expect(inactive.isDue(DateTime(2026, 2, 10)), false);

      // Item where next occurrence is after end date should not be due
      final expired = sampleModel.copyWith(
        nextOccurrence: DateTime(2027, 1, 1),
        endDate: DateTime(2026, 12, 31),
      );
      expect(expired.isDue(DateTime(2027, 1, 5)), false);
    });

    test('computeNextCycleDate calculates next occurrence date correctly', () {
      final nextDate = sampleModel.computeNextCycleDate();
      expect(nextDate, DateTime(2026, 3, 1));
    });
  });
}
