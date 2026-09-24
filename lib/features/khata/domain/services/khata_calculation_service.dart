import '../../data/models/khata_customer_model.dart';
import '../../data/models/khata_entry_model.dart';
import '../models/customer_ledger_models.dart';

/// Pure domain calculation service for Khata customer balances and ledger running calculations.
class KhataCalculationService {
  const KhataCalculationService();

  /// Computes deterministic chronological ledger items with running balances for a list of entries.
  /// Sorting order:
  /// 1. entryDate ASC
  /// 2. createdAt ASC
  /// 3. id ASC
  List<CustomerLedgerItem> computeLedgerWithRunningBalances(List<KhataEntryModel> entries) {
    final activeEntries = entries.where((e) => !e.isDeleted).toList();

    // Deterministic chronological sort
    activeEntries.sort((a, b) {
      final dateComp = a.entryDate.compareTo(b.entryDate);
      if (dateComp != 0) return dateComp;
      final createdComp = a.createdAt.compareTo(b.createdAt);
      if (createdComp != 0) return createdComp;
      return a.id.compareTo(b.id);
    });

    double runningBalance = 0.0;
    double cumulativeGiven = 0.0;
    double cumulativeReceived = 0.0;
    final ledger = <CustomerLedgerItem>[];

    for (final entry in activeEntries) {
      if (entry.isGiven) {
        runningBalance += entry.amount;
        cumulativeGiven += entry.amount;
      } else {
        runningBalance -= entry.amount;
        cumulativeReceived += entry.amount;
      }

      ledger.add(
        CustomerLedgerItem(
          entry: entry,
          runningBalance: runningBalance,
          cumulativeGiven: cumulativeGiven,
          cumulativeReceived: cumulativeReceived,
        ),
      );
    }

    return ledger;
  }

  /// Calculates the balance summary and current state for a single customer.
  CustomerBalanceSummary calculateCustomerSummary(
    KhataCustomerModel customer,
    List<KhataEntryModel> entries,
  ) {
    final customerEntries = entries
        .where((e) => e.customerId == customer.id && !e.isDeleted)
        .toList();

    double totalGiven = 0.0;
    double totalReceived = 0.0;
    DateTime? lastEntryDate;

    for (final entry in customerEntries) {
      if (entry.isGiven) {
        totalGiven += entry.amount;
      } else {
        totalReceived += entry.amount;
      }

      if (lastEntryDate == null || entry.entryDate.isAfter(lastEntryDate)) {
        lastEntryDate = entry.entryDate;
      }
    }

    final currentBalance = totalGiven - totalReceived;

    final CustomerBalanceStatus status;
    if (currentBalance > 0.005) {
      status = CustomerBalanceStatus.due;
    } else if (currentBalance < -0.005) {
      status = CustomerBalanceStatus.advance;
    } else {
      status = CustomerBalanceStatus.settled;
    }

    return CustomerBalanceSummary(
      customer: customer,
      totalGiven: totalGiven,
      totalReceived: totalReceived,
      currentBalance: currentBalance,
      status: status,
      lastEntryDate: lastEntryDate,
      entriesCount: customerEntries.length,
    );
  }

  /// Computes the overall portfolio summary across all active customers.
  KhataOverallSummary calculateOverallSummary(
    List<KhataCustomerModel> activeCustomers,
    List<KhataEntryModel> allEntries,
  ) {
    final validCustomers = activeCustomers.where((c) => !c.isDeleted).toList();

    int activeWithDue = 0;
    int settledCount = 0;
    int advanceCount = 0;
    double totalReceivableDue = 0.0;
    double totalAdvances = 0.0;
    double totalGivenAllTime = 0.0;
    double totalReceivedAllTime = 0.0;

    for (final entry in allEntries.where((e) => !e.isDeleted)) {
      if (entry.isGiven) {
        totalGivenAllTime += entry.amount;
      } else {
        totalReceivedAllTime += entry.amount;
      }
    }

    for (final customer in validCustomers) {
      final summary = calculateCustomerSummary(customer, allEntries);

      if (summary.status == CustomerBalanceStatus.due) {
        activeWithDue++;
        totalReceivableDue += summary.currentBalance;
      } else if (summary.status == CustomerBalanceStatus.advance) {
        advanceCount++;
        totalAdvances += summary.currentBalance.abs();
      } else {
        settledCount++;
      }
    }

    final netCustomerBalance = totalReceivableDue - totalAdvances;

    return KhataOverallSummary(
      totalCustomers: validCustomers.length,
      activeCustomersWithDue: activeWithDue,
      settledCustomersCount: settledCount,
      advanceCustomersCount: advanceCount,
      totalReceivableDue: totalReceivableDue,
      totalAdvances: totalAdvances,
      netCustomerBalance: netCustomerBalance,
      totalGivenAllTime: totalGivenAllTime,
      totalReceivedAllTime: totalReceivedAllTime,
    );
  }

  /// Filters a list of customer summaries by search query (name/phone) and balance status.
  List<CustomerBalanceSummary> filterCustomers(
    List<CustomerBalanceSummary> summaries, {
    String? query,
    CustomerBalanceStatus? filterStatus,
  }) {
    var filtered = summaries;

    if (query != null && query.trim().isNotEmpty) {
      final cleanQuery = query.trim().toLowerCase();
      filtered = filtered.where((s) {
        final nameMatch = s.customer.name.toLowerCase().contains(cleanQuery);
        final phoneMatch = s.customer.phone.toLowerCase().contains(cleanQuery);
        return nameMatch || phoneMatch;
      }).toList();
    }

    if (filterStatus != null) {
      filtered = filtered.where((s) => s.status == filterStatus).toList();
    }

    return filtered;
  }
}
