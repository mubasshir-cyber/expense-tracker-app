import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/recurring/data/repositories/recurring_repository.dart';
import 'package:expense_tracker/features/recurring/domain/models/recurring_frequency.dart';
import 'package:expense_tracker/features/recurring/domain/models/recurring_transaction_model.dart';
import 'package:expense_tracker/features/recurring/domain/services/recurring_schedule_service.dart';
import 'package:expense_tracker/features/transactions/data/repositories/transaction_repository.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_type.dart';

class FakeTransactionRepository implements TransactionRepository {
  final List<Map<String, dynamic>> createdCalls = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<TransactionModel> createTransaction({
    required String accountId,
    required String categoryId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    createdCalls.add({
      'accountId': accountId,
      'categoryId': categoryId,
      'type': type,
      'amount': amount,
      'date': date,
      'note': note,
    });
    return TransactionModel(
      id: 'tx-new',
      userId: 'user-1',
      accountId: accountId,
      categoryId: categoryId,
      type: type == TransactionType.expense ? 'EXPENSE' : 'CREDIT',
      amount: amount,
      description: note,
      transactionDate: date,
    );
  }
}

class FakeRecurringRepository implements RecurringRepository {
  final List<Map<String, dynamic>> advanceCalls = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> advanceNextOccurrence(
    String id,
    DateTime nextDate, {
    bool isActive = true,
  }) async {
    advanceCalls.add({
      'id': id,
      'nextDate': nextDate,
      'isActive': isActive,
    });
  }
}

void main() {
  late FakeTransactionRepository fakeTxnRepo;
  late FakeRecurringRepository fakeRecurringRepo;
  late RecurringScheduleService service;

  final item1 = RecurringTransactionModel(
    id: 'rec-1',
    userId: 'user-1',
    accountId: 'acc-1',
    categoryId: 'cat-1',
    type: TransactionType.expense,
    amount: 500.0,
    description: 'Gym',
    frequency: RecurringFrequency.monthly,
    startDate: DateTime(2026, 1, 1),
    nextOccurrence: DateTime(2026, 3, 1),
    isActive: true,
    autoCreate: true,
  );

  final item2 = RecurringTransactionModel(
    id: 'rec-2',
    userId: 'user-1',
    accountId: 'acc-2',
    categoryId: 'cat-2',
    type: TransactionType.credit,
    amount: 50000.0,
    description: 'Salary',
    frequency: RecurringFrequency.monthly,
    startDate: DateTime(2026, 1, 1),
    nextOccurrence: DateTime(2026, 3, 25),
    isActive: true,
    autoCreate: false,
  );

  final inactiveItem = RecurringTransactionModel(
    id: 'rec-3',
    userId: 'user-1',
    accountId: 'acc-1',
    categoryId: 'cat-1',
    type: TransactionType.expense,
    amount: 200.0,
    description: 'Old Subscription',
    frequency: RecurringFrequency.monthly,
    startDate: DateTime(2026, 1, 1),
    nextOccurrence: DateTime(2026, 2, 1),
    isActive: false,
    autoCreate: true,
  );

  setUp(() {
    fakeTxnRepo = FakeTransactionRepository();
    fakeRecurringRepo = FakeRecurringRepository();
    service = RecurringScheduleService(
      transactionRepository: fakeTxnRepo,
      recurringRepository: fakeRecurringRepo,
    );
  });

  group('RecurringScheduleService', () {
    test('findDue filters active recurring items that are due as of the given date', () {
      final list = [item1, item2, inactiveItem];
      final dueItems = service.findDue(list, referenceDate: DateTime(2026, 3, 5));

      expect(dueItems.length, 1);
      expect(dueItems.first.id, 'rec-1');
    });

    test('findUpcoming filters and sorts items occurring within the horizon window', () {
      final list = [item1, item2, inactiveItem];
      // Horizon from 2026-03-01 to 2026-03-31 (30 days)
      final upcoming = service.findUpcoming(
        list,
        referenceDate: DateTime(2026, 3, 1),
        daysAhead: 30,
      );

      expect(upcoming.length, 2);
      expect(upcoming[0].id, 'rec-1');
      expect(upcoming[1].id, 'rec-2');
    });

    test('processRecurringOccurrence creates actual transaction and advances next occurrence', () async {
      await service.processRecurringOccurrence(
        item1,
        executionDate: DateTime(2026, 3, 1),
      );

      // Verify generated transaction call
      expect(fakeTxnRepo.createdCalls.length, 1);
      final txn = fakeTxnRepo.createdCalls.first;
      expect(txn['accountId'], item1.accountId);
      expect(txn['categoryId'], item1.categoryId);
      expect(txn['type'], TransactionType.expense);
      expect(txn['amount'], 500.0);
      expect(txn['note'], 'Gym');
      expect(txn['date'], DateTime(2026, 3, 1));

      // Verify updated recurring template call
      expect(fakeRecurringRepo.advanceCalls.length, 1);
      final adv = fakeRecurringRepo.advanceCalls.first;
      expect(adv['id'], item1.id);
      expect(adv['nextDate'], DateTime(2026, 4, 1));
      expect(adv['isActive'], true);
    });

    test('processRecurringOccurrence deactivates template if next occurrence exceeds endDate', () async {
      final terminatingItem = item1.copyWith(
        nextOccurrence: DateTime(2026, 12, 1),
        endDate: DateTime(2026, 12, 15),
      );

      await service.processRecurringOccurrence(
        terminatingItem,
        executionDate: DateTime(2026, 12, 1),
      );

      expect(fakeRecurringRepo.advanceCalls.length, 1);
      final adv = fakeRecurringRepo.advanceCalls.first;
      expect(adv['nextDate'], DateTime(2027, 1, 1));
      expect(adv['isActive'], false); // exceeded endDate (2026-12-15)
    });

    test('processAutoCreateDueItems processes only due items with autoCreate = true', () async {
      final dueManual = item2.copyWith(nextOccurrence: DateTime(2026, 3, 1)); // autoCreate = false
      final list = [item1, dueManual, inactiveItem];

      final processedCount = await service.processAutoCreateDueItems(
        list,
        referenceDate: DateTime(2026, 3, 5),
      );

      expect(processedCount, 1);
      expect(fakeTxnRepo.createdCalls.length, 1);
      expect(fakeTxnRepo.createdCalls.first['amount'], 500.0);
      expect(fakeRecurringRepo.advanceCalls.length, 1);
    });
  });
}
