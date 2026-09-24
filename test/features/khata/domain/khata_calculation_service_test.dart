import 'package:expense_tracker/features/khata/data/models/khata_customer_model.dart';
import 'package:expense_tracker/features/khata/data/models/khata_entry_model.dart';
import 'package:expense_tracker/features/khata/domain/models/customer_ledger_models.dart';
import 'package:expense_tracker/features/khata/domain/models/khata_entry_type.dart';
import 'package:expense_tracker/features/khata/domain/services/khata_calculation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = KhataCalculationService();

  final dummyCustomer = KhataCustomerModel(
    id: 'cust-ahmed',
    userId: 'user-1',
    name: 'Ahmed',
    phone: '9876543210',
    createdAt: DateTime(2026, 9, 1),
  );

  group('KhataCalculationService - Ahmed End-to-End Test Case', () {
    test('Calculates Opening Pending ₹800 + GIVEN ₹150 - RECEIVED ₹50 = ₹900 Due', () {
      final entries = [
        KhataEntryModel(
          id: 'entry-1',
          userId: 'user-1',
          customerId: 'cust-ahmed',
          type: KhataEntryType.given,
          amount: 800.0,
          isOpeningBalance: true,
          description: 'Previous Pending',
          entryDate: DateTime(2026, 9, 20),
          createdAt: DateTime(2026, 9, 20, 10, 0),
        ),
        KhataEntryModel(
          id: 'entry-2',
          userId: 'user-1',
          customerId: 'cust-ahmed',
          type: KhataEntryType.given,
          amount: 150.0,
          isOpeningBalance: false,
          description: 'Product given on credit',
          entryDate: DateTime(2026, 9, 24),
          createdAt: DateTime(2026, 9, 24, 11, 0),
        ),
        KhataEntryModel(
          id: 'entry-3',
          userId: 'user-1',
          customerId: 'cust-ahmed',
          type: KhataEntryType.received,
          amount: 50.0,
          isOpeningBalance: false,
          description: 'Payment received',
          entryDate: DateTime(2026, 9, 24),
          createdAt: DateTime(2026, 9, 24, 12, 0),
        ),
      ];

      final ledger = service.computeLedgerWithRunningBalances(entries);

      expect(ledger.length, 3);
      // Entry 1: Opening 800 -> 800
      expect(ledger[0].runningBalance, 800.0);
      expect(ledger[0].cumulativeGiven, 800.0);
      expect(ledger[0].cumulativeReceived, 0.0);
      expect(ledger[0].balanceStatus, CustomerBalanceStatus.due);

      // Entry 2: Given 150 -> 950
      expect(ledger[1].runningBalance, 950.0);
      expect(ledger[1].cumulativeGiven, 950.0);
      expect(ledger[1].cumulativeReceived, 0.0);
      expect(ledger[1].balanceStatus, CustomerBalanceStatus.due);

      // Entry 3: Received 50 -> 900
      expect(ledger[2].runningBalance, 900.0);
      expect(ledger[2].cumulativeGiven, 950.0);
      expect(ledger[2].cumulativeReceived, 50.0);
      expect(ledger[2].balanceStatus, CustomerBalanceStatus.due);

      final summary = service.calculateCustomerSummary(dummyCustomer, entries);
      expect(summary.totalGiven, 950.0);
      expect(summary.totalReceived, 50.0);
      expect(summary.currentBalance, 900.0);
      expect(summary.status, CustomerBalanceStatus.due);
      expect(summary.isDue, isTrue);
      expect(summary.isSettled, isFalse);
      expect(summary.isAdvance, isFalse);
    });

    test('Next day: + GIVEN ₹300 (₹1,200), then - RECEIVED ₹500 (₹700)', () {
      final entries = [
        KhataEntryModel(
          id: 'entry-1',
          userId: 'user-1',
          customerId: 'cust-ahmed',
          type: KhataEntryType.given,
          amount: 800.0,
          isOpeningBalance: true,
          entryDate: DateTime(2026, 9, 20),
          createdAt: DateTime(2026, 9, 20, 10, 0),
        ),
        KhataEntryModel(
          id: 'entry-2',
          userId: 'user-1',
          customerId: 'cust-ahmed',
          type: KhataEntryType.given,
          amount: 150.0,
          entryDate: DateTime(2026, 9, 24),
          createdAt: DateTime(2026, 9, 24, 11, 0),
        ),
        KhataEntryModel(
          id: 'entry-3',
          userId: 'user-1',
          customerId: 'cust-ahmed',
          type: KhataEntryType.received,
          amount: 50.0,
          entryDate: DateTime(2026, 9, 24),
          createdAt: DateTime(2026, 9, 24, 12, 0),
        ),
        KhataEntryModel(
          id: 'entry-4',
          userId: 'user-1',
          customerId: 'cust-ahmed',
          type: KhataEntryType.given,
          amount: 300.0,
          entryDate: DateTime(2026, 9, 25),
          createdAt: DateTime(2026, 9, 25, 9, 0),
        ),
        KhataEntryModel(
          id: 'entry-5',
          userId: 'user-1',
          customerId: 'cust-ahmed',
          type: KhataEntryType.received,
          amount: 500.0,
          entryDate: DateTime(2026, 9, 25),
          createdAt: DateTime(2026, 9, 25, 15, 0),
        ),
      ];

      final ledger = service.computeLedgerWithRunningBalances(entries);
      expect(ledger[3].runningBalance, 1200.0);
      expect(ledger[4].runningBalance, 700.0);

      final summary = service.calculateCustomerSummary(dummyCustomer, entries);
      expect(summary.totalGiven, 1250.0);
      expect(summary.totalReceived, 550.0);
      expect(summary.currentBalance, 700.0);
      expect(summary.status, CustomerBalanceStatus.due);
    });
  });

  group('KhataCalculationService - Advance and Settled States', () {
    test('Advance calculation: Due ₹500, Customer pays ₹700 -> Balance -₹200 (Advance)', () {
      final entries = [
        KhataEntryModel(
          id: 'e1',
          userId: 'user-1',
          customerId: 'cust-ahmed',
          type: KhataEntryType.given,
          amount: 500.0,
          entryDate: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1, 10, 0),
        ),
        KhataEntryModel(
          id: 'e2',
          userId: 'user-1',
          customerId: 'cust-ahmed',
          type: KhataEntryType.received,
          amount: 700.0,
          entryDate: DateTime(2026, 9, 2),
          createdAt: DateTime(2026, 9, 2, 10, 0),
        ),
      ];

      final ledger = service.computeLedgerWithRunningBalances(entries);
      expect(ledger[1].runningBalance, -200.0);
      expect(ledger[1].balanceStatus, CustomerBalanceStatus.advance);

      final summary = service.calculateCustomerSummary(dummyCustomer, entries);
      expect(summary.currentBalance, -200.0);
      expect(summary.absoluteBalance, 200.0);
      expect(summary.status, CustomerBalanceStatus.advance);
      expect(summary.isAdvance, isTrue);
    });

    test('Settled calculation: Given ₹500, Received ₹500 -> Balance ₹0 (Settled)', () {
      final entries = [
        KhataEntryModel(
          id: 'e1',
          userId: 'user-1',
          customerId: 'cust-ahmed',
          type: KhataEntryType.given,
          amount: 500.0,
          entryDate: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1, 10, 0),
        ),
        KhataEntryModel(
          id: 'e2',
          userId: 'user-1',
          customerId: 'cust-ahmed',
          type: KhataEntryType.received,
          amount: 500.0,
          entryDate: DateTime(2026, 9, 2),
          createdAt: DateTime(2026, 9, 2, 10, 0),
        ),
      ];

      final summary = service.calculateCustomerSummary(dummyCustomer, entries);
      expect(summary.currentBalance, 0.0);
      expect(summary.status, CustomerBalanceStatus.settled);
      expect(summary.isSettled, isTrue);
    });
  });

  group('KhataCalculationService - Deterministic Chronological Sorting', () {
    test('Sorts by entry_date ASC, created_at ASC, id ASC regardless of input ordering', () {
      final entries = [
        KhataEntryModel(
          id: 'entry-c',
          userId: 'user-1',
          customerId: 'cust-ahmed',
          type: KhataEntryType.given,
          amount: 200.0,
          entryDate: DateTime(2026, 9, 24),
          createdAt: DateTime(2026, 9, 24, 12, 30),
        ),
        KhataEntryModel(
          id: 'entry-a',
          userId: 'user-1',
          customerId: 'cust-ahmed',
          type: KhataEntryType.given,
          amount: 150.0,
          entryDate: DateTime(2026, 9, 24),
          createdAt: DateTime(2026, 9, 24, 10, 0),
        ),
        KhataEntryModel(
          id: 'entry-b',
          userId: 'user-1',
          customerId: 'cust-ahmed',
          type: KhataEntryType.received,
          amount: 50.0,
          entryDate: DateTime(2026, 9, 24),
          createdAt: DateTime(2026, 9, 24, 11, 0),
        ),
      ];

      final ledger = service.computeLedgerWithRunningBalances(entries);

      expect(ledger[0].entry.id, 'entry-a');
      expect(ledger[0].runningBalance, 150.0);

      expect(ledger[1].entry.id, 'entry-b');
      expect(ledger[1].runningBalance, 100.0);

      expect(ledger[2].entry.id, 'entry-c');
      expect(ledger[2].runningBalance, 300.0);
    });
  });

  group('KhataCalculationService - Overall Portfolio Aggregation', () {
    test('Aggregates total receivables only from positive balances (Rule #7)', () {
      final c1 = KhataCustomerModel(id: 'c1', userId: 'u1', name: 'Ahmed', phone: '1', createdAt: DateTime.now());
      final c2 = KhataCustomerModel(id: 'c2', userId: 'u1', name: 'Rahim', phone: '2', createdAt: DateTime.now());
      final c3 = KhataCustomerModel(id: 'c3', userId: 'u1', name: 'Salman', phone: '3', createdAt: DateTime.now());
      final c4 = KhataCustomerModel(id: 'c4', userId: 'u1', name: 'Imran', phone: '4', createdAt: DateTime.now());

      final entries = [
        // Ahmed: +900
        KhataEntryModel(id: 'e1', userId: 'u1', customerId: 'c1', type: KhataEntryType.given, amount: 900.0, entryDate: DateTime.now(), createdAt: DateTime.now()),
        // Rahim: +500
        KhataEntryModel(id: 'e2', userId: 'u1', customerId: 'c2', type: KhataEntryType.given, amount: 500.0, entryDate: DateTime.now(), createdAt: DateTime.now()),
        // Salman: 0 (given 200, received 200)
        KhataEntryModel(id: 'e3', userId: 'u1', customerId: 'c3', type: KhataEntryType.given, amount: 200.0, entryDate: DateTime.now(), createdAt: DateTime.now()),
        KhataEntryModel(id: 'e4', userId: 'u1', customerId: 'c3', type: KhataEntryType.received, amount: 200.0, entryDate: DateTime.now(), createdAt: DateTime.now()),
        // Imran: -200 (received 200 advance)
        KhataEntryModel(id: 'e5', userId: 'u1', customerId: 'c4', type: KhataEntryType.received, amount: 200.0, entryDate: DateTime.now(), createdAt: DateTime.now()),
      ];

      final overall = service.calculateOverallSummary([c1, c2, c3, c4], entries);

      expect(overall.totalReceivableDue, 1400.0); // 900 + 500
      expect(overall.totalAdvances, 200.0);       // 200 advance
      expect(overall.netCustomerBalance, 1200.0); // 1400 - 200
      expect(overall.activeCustomersWithDue, 2);
      expect(overall.settledCustomersCount, 1);
      expect(overall.advanceCustomersCount, 1);
      expect(overall.totalCustomers, 4);
    });
  });

  group('KhataCalculationService - Search and Filters', () {
    test('Filters customer summaries by name, phone and status', () {
      final c1 = KhataCustomerModel(id: 'c1', userId: 'u1', name: 'Ahmed Khan', phone: '9876543210', createdAt: DateTime.now());
      final c2 = KhataCustomerModel(id: 'c2', userId: 'u1', name: 'Rahim Ali', phone: '9123456780', createdAt: DateTime.now());

      final s1 = CustomerBalanceSummary(
        customer: c1,
        totalGiven: 900.0,
        totalReceived: 0.0,
        currentBalance: 900.0,
        status: CustomerBalanceStatus.due,
        entriesCount: 1,
      );

      final s2 = CustomerBalanceSummary(
        customer: c2,
        totalGiven: 500.0,
        totalReceived: 500.0,
        currentBalance: 0.0,
        status: CustomerBalanceStatus.settled,
        entriesCount: 2,
      );

      final filteredByName = service.filterCustomers([s1, s2], query: 'ahmed');
      expect(filteredByName.length, 1);
      expect(filteredByName.first.customer.name, 'Ahmed Khan');

      final filteredByPhone = service.filterCustomers([s1, s2], query: '91234');
      expect(filteredByPhone.length, 1);
      expect(filteredByPhone.first.customer.name, 'Rahim Ali');

      final filteredByStatus = service.filterCustomers([s1, s2], filterStatus: CustomerBalanceStatus.settled);
      expect(filteredByStatus.length, 1);
      expect(filteredByStatus.first.customer.name, 'Rahim Ali');
    });
  });
}
