import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/khata_customer_model.dart';
import '../../data/models/khata_entry_model.dart';

/// Current balance state of a customer.
enum CustomerBalanceStatus {
  due('Due', AppColors.error, 'Customer owes you money'),
  settled('Settled', AppColors.credit, 'Account balance is zero'),
  advance('Advance', AppColors.primary, 'Customer has prepaid extra funds');

  const CustomerBalanceStatus(this.displayName, this.badgeColor, this.description);

  final String displayName;
  final Color badgeColor;
  final String description;
}

/// A single entry in a customer's chronological ledger, with its computed running balance.
@immutable
class CustomerLedgerItem {
  const CustomerLedgerItem({
    required this.entry,
    required this.runningBalance,
    required this.cumulativeGiven,
    required this.cumulativeReceived,
  });

  final KhataEntryModel entry;
  final double runningBalance;
  final double cumulativeGiven;
  final double cumulativeReceived;

  CustomerBalanceStatus get balanceStatus {
    if (runningBalance > 0.005) return CustomerBalanceStatus.due;
    if (runningBalance < -0.005) return CustomerBalanceStatus.advance;
    return CustomerBalanceStatus.settled;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerLedgerItem &&
          runtimeType == other.runtimeType &&
          entry == other.entry &&
          runningBalance == other.runningBalance;

  @override
  int get hashCode => entry.hashCode ^ runningBalance.hashCode;

  @override
  String toString() =>
      'CustomerLedgerItem(entry: ${entry.id}, runningBalance: $runningBalance)';
}

/// Aggregated balance summary for a single customer.
@immutable
class CustomerBalanceSummary {
  const CustomerBalanceSummary({
    required this.customer,
    required this.totalGiven,
    required this.totalReceived,
    required this.currentBalance,
    required this.status,
    this.lastEntryDate,
    required this.entriesCount,
  });

  final KhataCustomerModel customer;
  final double totalGiven;
  final double totalReceived;
  final double currentBalance;
  final CustomerBalanceStatus status;
  final DateTime? lastEntryDate;
  final int entriesCount;

  bool get isDue => status == CustomerBalanceStatus.due;
  bool get isSettled => status == CustomerBalanceStatus.settled;
  bool get isAdvance => status == CustomerBalanceStatus.advance;

  /// Absolute amount for display purposes (e.g. ₹900 for due or ₹200 for advance).
  double get absoluteBalance => currentBalance.abs();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerBalanceSummary &&
          runtimeType == other.runtimeType &&
          customer == other.customer &&
          currentBalance == other.currentBalance &&
          status == other.status &&
          entriesCount == other.entriesCount;

  @override
  int get hashCode =>
      customer.hashCode ^
      currentBalance.hashCode ^
      status.hashCode ^
      entriesCount.hashCode;

  @override
  String toString() =>
      'CustomerBalanceSummary(customer: ${customer.name}, balance: $currentBalance, status: ${status.name})';
}

/// Overall aggregated portfolio summary across all customer Khatas.
@immutable
class KhataOverallSummary {
  const KhataOverallSummary({
    required this.totalCustomers,
    required this.activeCustomersWithDue,
    required this.settledCustomersCount,
    required this.advanceCustomersCount,
    required this.totalReceivableDue,
    required this.totalAdvances,
    required this.netCustomerBalance,
    required this.totalGivenAllTime,
    required this.totalReceivedAllTime,
  });

  final int totalCustomers;
  final int activeCustomersWithDue;
  final int settledCustomersCount;
  final int advanceCustomersCount;

  /// Sum of all positive balances (money owed to you by customers).
  final double totalReceivableDue;

  /// Sum of all absolute advance balances (excess money received).
  final double totalAdvances;

  /// Net balance = totalReceivableDue - totalAdvances.
  final double netCustomerBalance;

  final double totalGivenAllTime;
  final double totalReceivedAllTime;

  static const empty = KhataOverallSummary(
    totalCustomers: 0,
    activeCustomersWithDue: 0,
    settledCustomersCount: 0,
    advanceCustomersCount: 0,
    totalReceivableDue: 0.0,
    totalAdvances: 0.0,
    netCustomerBalance: 0.0,
    totalGivenAllTime: 0.0,
    totalReceivedAllTime: 0.0,
  );
}
