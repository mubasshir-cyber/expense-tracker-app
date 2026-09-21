import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../data/repositories/recurring_repository.dart';
import '../models/recurring_transaction_model.dart';

/// Handles scheduling calculations, upcoming payment discovery, and ledger transaction generation.
class RecurringScheduleService {
  RecurringScheduleService({
    required this.transactionRepository,
    required this.recurringRepository,
  });

  final TransactionRepository transactionRepository;
  final RecurringRepository recurringRepository;

  /// Filters active recurring templates due on or before [referenceDate].
  List<RecurringTransactionModel> findDue(
    List<RecurringTransactionModel> list, {
    DateTime? referenceDate,
  }) {
    return list.where((item) => item.isDue(referenceDate)).toList();
  }

  /// Filters active recurring templates occurring within [daysAhead] days from [referenceDate].
  List<RecurringTransactionModel> findUpcoming(
    List<RecurringTransactionModel> list, {
    int daysAhead = 30,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = today.add(Duration(days: daysAhead));

    final upcoming = list.where((item) {
      if (!item.isActive) return false;
      final occ = DateTime(
        item.nextOccurrence.year,
        item.nextOccurrence.month,
        item.nextOccurrence.day,
      );
      return !occ.isBefore(today) && !occ.isAfter(cutoff);
    }).toList();

    upcoming.sort((a, b) => a.nextOccurrence.compareTo(b.nextOccurrence));
    return upcoming;
  }

  /// Records a concrete ledger entry from the recurring template and advances the template's schedule.
  Future<void> processRecurringOccurrence(
    RecurringTransactionModel item, {
    DateTime? executionDate,
  }) async {
    final recordDate = executionDate ?? item.nextOccurrence;

    // 1. Create concrete ledger transaction entry
    await transactionRepository.createTransaction(
      accountId: item.accountId,
      categoryId: item.categoryId,
      type: item.type,
      amount: item.amount,
      date: recordDate,
      note: item.description,
    );

    // 2. Compute next cycle occurrence
    final nextDate = item.computeNextCycleDate();
    final shouldRemainActive =
        item.endDate == null || !nextDate.isAfter(item.endDate!);

    // 3. Advance next_occurrence on the recurring template
    await recurringRepository.advanceNextOccurrence(
      item.id,
      nextDate,
      isActive: shouldRemainActive,
    );
  }

  /// Automatically processes all due items marked with autoCreate = true.
  Future<int> processAutoCreateDueItems(
    List<RecurringTransactionModel> list, {
    DateTime? referenceDate,
  }) async {
    final dueItems =
        findDue(list, referenceDate: referenceDate).where((item) => item.autoCreate);
    int processedCount = 0;

    for (final item in dueItems) {
      await processRecurringOccurrence(item, executionDate: item.nextOccurrence);
      processedCount++;
    }

    return processedCount;
  }
}
