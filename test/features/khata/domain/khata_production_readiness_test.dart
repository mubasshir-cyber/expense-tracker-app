import 'package:expense_tracker/features/khata/data/models/khata_customer_model.dart';
import 'package:expense_tracker/features/khata/data/models/khata_entry_model.dart';
import 'package:expense_tracker/features/khata/domain/models/customer_ledger_models.dart';
import 'package:expense_tracker/features/khata/domain/models/khata_entry_type.dart';
import 'package:expense_tracker/features/khata/domain/services/khata_calculation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = KhataCalculationService();

  group('Khata Specification Test Cases 1 - 8 (Production Audit)', () {
    // CASE 1
    test('CASE 1: Opening = ₹800, GIVEN = ₹150, RECEIVED = ₹50 -> ₹900 Due', () {
      final customer = KhataCustomerModel(
        id: 'cust-1',
        userId: 'user-1',
        name: 'Ahmed',
        phone: '1234567890',
        createdAt: DateTime(2026, 9, 1),
      );

      final entries = [
        KhataEntryModel(
          id: 'e1',
          userId: 'user-1',
          customerId: 'cust-1',
          type: KhataEntryType.given,
          amount: 800.0,
          isOpeningBalance: true,
          entryDate: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1, 8, 0),
        ),
        KhataEntryModel(
          id: 'e2',
          userId: 'user-1',
          customerId: 'cust-1',
          type: KhataEntryType.given,
          amount: 150.0,
          entryDate: DateTime(2026, 9, 2),
          createdAt: DateTime(2026, 9, 2, 10, 0),
        ),
        KhataEntryModel(
          id: 'e3',
          userId: 'user-1',
          customerId: 'cust-1',
          type: KhataEntryType.received,
          amount: 50.0,
          entryDate: DateTime(2026, 9, 3),
          createdAt: DateTime(2026, 9, 3, 14, 0),
        ),
      ];

      final ledger = service.computeLedgerWithRunningBalances(entries);
      expect(ledger.length, 3);
      expect(ledger[0].runningBalance, 800.0);
      expect(ledger[1].runningBalance, 950.0);
      expect(ledger[2].runningBalance, 900.0);
      expect(ledger[2].balanceStatus, CustomerBalanceStatus.due);

      final summary = service.calculateCustomerSummary(customer, entries);
      expect(summary.currentBalance, 900.0);
      expect(summary.status, CustomerBalanceStatus.due);
      expect(summary.isDue, isTrue);
    });

    // CASE 2
    test('CASE 2: Opening = ₹800, GIVEN = ₹150, RECEIVED = ₹950 -> ₹0 Settled', () {
      final customer = KhataCustomerModel(
        id: 'cust-2',
        userId: 'user-1',
        name: 'Rahim',
        phone: '1234567890',
        createdAt: DateTime(2026, 9, 1),
      );

      final entries = [
        KhataEntryModel(
          id: 'e1',
          userId: 'user-1',
          customerId: 'cust-2',
          type: KhataEntryType.given,
          amount: 800.0,
          isOpeningBalance: true,
          entryDate: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1, 8, 0),
        ),
        KhataEntryModel(
          id: 'e2',
          userId: 'user-1',
          customerId: 'cust-2',
          type: KhataEntryType.given,
          amount: 150.0,
          entryDate: DateTime(2026, 9, 2),
          createdAt: DateTime(2026, 9, 2, 10, 0),
        ),
        KhataEntryModel(
          id: 'e3',
          userId: 'user-1',
          customerId: 'cust-2',
          type: KhataEntryType.received,
          amount: 950.0,
          entryDate: DateTime(2026, 9, 3),
          createdAt: DateTime(2026, 9, 3, 14, 0),
        ),
      ];

      final summary = service.calculateCustomerSummary(customer, entries);
      expect(summary.currentBalance, 0.0);
      expect(summary.status, CustomerBalanceStatus.settled);
      expect(summary.isSettled, isTrue);
    });

    // CASE 3
    test('CASE 3: Opening = ₹800, GIVEN = ₹150, RECEIVED = ₹1,000 -> ₹50 Advance', () {
      final customer = KhataCustomerModel(
        id: 'cust-3',
        userId: 'user-1',
        name: 'Salman',
        phone: '1234567890',
        createdAt: DateTime(2026, 9, 1),
      );

      final entries = [
        KhataEntryModel(
          id: 'e1',
          userId: 'user-1',
          customerId: 'cust-3',
          type: KhataEntryType.given,
          amount: 800.0,
          isOpeningBalance: true,
          entryDate: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1, 8, 0),
        ),
        KhataEntryModel(
          id: 'e2',
          userId: 'user-1',
          customerId: 'cust-3',
          type: KhataEntryType.given,
          amount: 150.0,
          entryDate: DateTime(2026, 9, 2),
          createdAt: DateTime(2026, 9, 2, 10, 0),
        ),
        KhataEntryModel(
          id: 'e3',
          userId: 'user-1',
          customerId: 'cust-3',
          type: KhataEntryType.received,
          amount: 1000.0,
          entryDate: DateTime(2026, 9, 3),
          createdAt: DateTime(2026, 9, 3, 14, 0),
        ),
      ];

      final summary = service.calculateCustomerSummary(customer, entries);
      expect(summary.currentBalance, -50.0);
      expect(summary.absoluteBalance, 50.0);
      expect(summary.status, CustomerBalanceStatus.advance);
      expect(summary.isAdvance, isTrue);
    });

    // CASE 4
    test('CASE 4: Multiple entries on same date -> Deterministic ordering (entry_date, created_at, id)', () {
      final sameDay = DateTime(2026, 9, 24);
      final entries = [
        KhataEntryModel(
          id: 'id-c',
          userId: 'user-1',
          customerId: 'cust-4',
          type: KhataEntryType.given,
          amount: 100.0,
          entryDate: sameDay,
          createdAt: DateTime(2026, 9, 24, 15, 0),
        ),
        KhataEntryModel(
          id: 'id-a',
          userId: 'user-1',
          customerId: 'cust-4',
          type: KhataEntryType.given,
          amount: 50.0,
          entryDate: sameDay,
          createdAt: DateTime(2026, 9, 24, 9, 0),
        ),
        KhataEntryModel(
          id: 'id-b',
          userId: 'user-1',
          customerId: 'cust-4',
          type: KhataEntryType.received,
          amount: 25.0,
          entryDate: sameDay,
          createdAt: DateTime(2026, 9, 24, 12, 0),
        ),
      ];

      final ledger = service.computeLedgerWithRunningBalances(entries);
      expect(ledger[0].entry.id, 'id-a');
      expect(ledger[0].runningBalance, 50.0);

      expect(ledger[1].entry.id, 'id-b');
      expect(ledger[1].runningBalance, 25.0);

      expect(ledger[2].entry.id, 'id-c');
      expect(ledger[2].runningBalance, 125.0);
    });

    // CASE 5
    test('CASE 5: Deleted entry -> Excluded from balance and running ledger calculations', () {
      final customer = KhataCustomerModel(
        id: 'cust-5',
        userId: 'user-1',
        name: 'Imran',
        phone: '1234567890',
        createdAt: DateTime(2026, 9, 1),
      );

      final entries = [
        KhataEntryModel(
          id: 'e1',
          userId: 'user-1',
          customerId: 'cust-5',
          type: KhataEntryType.given,
          amount: 500.0,
          entryDate: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1, 8, 0),
        ),
        KhataEntryModel(
          id: 'e2-deleted',
          userId: 'user-1',
          customerId: 'cust-5',
          type: KhataEntryType.given,
          amount: 1000.0,
          deletedAt: DateTime(2026, 9, 2),
          entryDate: DateTime(2026, 9, 2),
          createdAt: DateTime(2026, 9, 2, 10, 0),
        ),
        KhataEntryModel(
          id: 'e3',
          userId: 'user-1',
          customerId: 'cust-5',
          type: KhataEntryType.received,
          amount: 100.0,
          entryDate: DateTime(2026, 9, 3),
          createdAt: DateTime(2026, 9, 3, 14, 0),
        ),
      ];

      final ledger = service.computeLedgerWithRunningBalances(entries);
      expect(ledger.length, 2);
      expect(ledger[0].runningBalance, 500.0);
      expect(ledger[1].runningBalance, 400.0);

      final summary = service.calculateCustomerSummary(customer, entries);
      expect(summary.totalGiven, 500.0);
      expect(summary.totalReceived, 100.0);
      expect(summary.currentBalance, 400.0);
    });

    // CASE 6
    test('CASE 6: Deleted customer -> Excluded from active customer list and portfolio summary', () {
      final activeCustomer = KhataCustomerModel(
        id: 'active-1',
        userId: 'user-1',
        name: 'Active User',
        phone: '111',
        createdAt: DateTime(2026, 9, 1),
      );

      final deletedCustomer = KhataCustomerModel(
        id: 'deleted-1',
        userId: 'user-1',
        name: 'Deleted User',
        phone: '222',
        deletedAt: DateTime(2026, 9, 2),
        createdAt: DateTime(2026, 9, 1),
      );

      final entries = [
        KhataEntryModel(
          id: 'e1',
          userId: 'user-1',
          customerId: 'active-1',
          type: KhataEntryType.given,
          amount: 500.0,
          entryDate: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1),
        ),
        KhataEntryModel(
          id: 'e2',
          userId: 'user-1',
          customerId: 'deleted-1',
          type: KhataEntryType.given,
          amount: 1000.0,
          entryDate: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1),
        ),
      ];

      final overall = service.calculateOverallSummary(
        [activeCustomer, deletedCustomer],
        entries,
      );

      expect(overall.totalCustomers, 1);
      expect(overall.totalReceivableDue, 500.0);
      expect(overall.activeCustomersWithDue, 1);
    });

    // CASE 7 & 8: User A vs User B Isolation
    test('CASE 7 & 8: Multi-user customer ledger isolation', () {
      final userACustomer = KhataCustomerModel(
        id: 'cust-userA',
        userId: 'user-A',
        name: 'User A Client',
        phone: '999',
        createdAt: DateTime(2026, 9, 1),
      );

      final userBCustomer = KhataCustomerModel(
        id: 'cust-userB',
        userId: 'user-B',
        name: 'User B Client',
        phone: '888',
        createdAt: DateTime(2026, 9, 1),
      );

      final allEntries = [
        KhataEntryModel(
          id: 'ea1',
          userId: 'user-A',
          customerId: 'cust-userA',
          type: KhataEntryType.given,
          amount: 300.0,
          entryDate: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1),
        ),
        KhataEntryModel(
          id: 'eb1',
          userId: 'user-B',
          customerId: 'cust-userB',
          type: KhataEntryType.given,
          amount: 700.0,
          entryDate: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1),
        ),
      ];

      // Summary for User A
      final summaryA = service.calculateCustomerSummary(userACustomer, allEntries);
      expect(summaryA.totalGiven, 300.0);
      expect(summaryA.currentBalance, 300.0);

      // Summary for User B
      final summaryB = service.calculateCustomerSummary(userBCustomer, allEntries);
      expect(summaryB.totalGiven, 700.0);
      expect(summaryB.currentBalance, 700.0);
    });
  });
}
