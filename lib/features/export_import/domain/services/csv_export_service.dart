import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../../../accounts/domain/models/account_model.dart';
import '../../../categories/domain/models/category_model.dart';
import '../../../debts/domain/models/debt_model.dart';
import '../../../goals/domain/models/goal_contribution_model.dart';
import '../../../goals/domain/models/savings_goal_model.dart';
import '../../../transactions/domain/models/transaction_model.dart';

/// Pure domain service generating RFC 4180 CSV strings and ZIP backup archives.
class CsvExportService {
  const CsvExportService();

  static const _converter = ListToCsvConverter();
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  /// Generates a standard sample CSV format template for transactions.
  String generateSampleCsv() {
    final sampleRows = <List<dynamic>>[
      ['Date', 'Type', 'Amount', 'Category', 'Account', 'Description', 'Payment Method'],
      ['2026-09-23', 'EXPENSE', '1250.00', 'Groceries', 'HDFC Bank', 'Weekly supermart shopping', 'UPI'],
      ['2026-09-22', 'INCOME', '85000.00', 'Salary', 'HDFC Bank', 'Monthly client payout', 'Net Banking'],
      ['2026-09-20', 'EXPENSE', '450.00', 'Dining Out', 'Cash Wallet', 'Dinner with colleagues', 'Cash'],
    ];
    return _converter.convert(sampleRows);
  }

  /// Exports standard transactions ledger to RFC 4180 CSV string.
  String exportTransactionsCsv(
    List<TransactionModel> transactions, {
    required Map<String, String> accountNames,
    required Map<String, String> categoryNames,
  }) {
    final rows = <List<dynamic>>[
      // Header row
      [
        'ID',
        'Date',
        'Type',
        'Category',
        'Account',
        'Amount',
        'Description',
        'Payment Method',
      ],
    ];

    for (final tx in transactions) {
      final categoryName = categoryNames[tx.categoryId] ?? tx.categoryId;
      final accountName = accountNames[tx.accountId] ?? tx.accountId;
      rows.add([
        tx.id,
        _dateFormat.format(tx.transactionDate),
        tx.type,
        categoryName,
        accountName,
        tx.amount.toStringAsFixed(2),
        tx.description ?? '',
        tx.paymentMethod ?? '',
      ]);
    }

    return _converter.convert(rows);
  }

  /// Exports savings goals and allocation history to RFC 4180 CSV string.
  String exportSavingsGoalsCsv(
    List<SavingsGoalModel> goals, {
    required Map<String, List<GoalContributionModel>> contributions,
    required Map<String, String> accountNames,
  }) {
    final rows = <List<dynamic>>[
      [
        'Goal ID',
        'Goal Name',
        'Target Amount',
        'Current Saved',
        'Progress %',
        'Remaining Amount',
        'Target Date',
        'Status',
        'Default Account',
        'Notes',
        'Contribution Date',
        'Contribution Type',
        'Contribution Amount',
        'Contribution Notes',
      ],
    ];

    for (final goal in goals) {
      final goalContribs = contributions[goal.id] ?? [];
      final accountName = goal.accountId != null ? (accountNames[goal.accountId!] ?? goal.accountId!) : '';

      if (goalContribs.isEmpty) {
        rows.add([
          goal.id,
          goal.name,
          goal.targetAmount.toStringAsFixed(2),
          goal.currentAmount.toStringAsFixed(2),
          '${goal.savedPercentage.toStringAsFixed(1)}%',
          goal.remainingAmount.toStringAsFixed(2),
          goal.targetDate != null ? _dateFormat.format(goal.targetDate!) : '',
          goal.isCompleted ? 'COMPLETED' : 'ACTIVE',
          accountName,
          goal.notes ?? '',
          '',
          '',
          '',
          '',
        ]);
      } else {
        for (final contrib in goalContribs) {
          rows.add([
            goal.id,
            goal.name,
            goal.targetAmount.toStringAsFixed(2),
            goal.currentAmount.toStringAsFixed(2),
            '${goal.savedPercentage.toStringAsFixed(1)}%',
            goal.remainingAmount.toStringAsFixed(2),
            goal.targetDate != null ? _dateFormat.format(goal.targetDate!) : '',
            goal.isCompleted ? 'COMPLETED' : 'ACTIVE',
            accountName,
            goal.notes ?? '',
            _dateFormat.format(contrib.contributionDate),
            contrib.isDeposit ? 'DEPOSIT' : 'WITHDRAWAL',
            contrib.amount.toStringAsFixed(2),
            contrib.notes ?? '',
          ]);
        }
      }
    }

    return _converter.convert(rows);
  }

  /// Exports debts, loans, interest breakdowns, installments, and repayment history to CSV.
  String exportDebtsCsv(
    List<DebtModel> debts, {
    required Map<String, String> accountNames,
  }) {
    final rows = <List<dynamic>>[
      [
        'Debt ID',
        'Person Name',
        'Direction / Type',
        'Principal Amount',
        'Interest Type',
        'Interest Rate',
        'Interest Amount',
        'Total Expected',
        'Total Paid',
        'Remaining Balance',
        'Due Date',
        'Status',
        'Notes',
        'Repayment Date',
        'Repayment Amount',
        'Repayment Account',
        'Repayment Notes',
      ],
    ];

    for (final debt in debts) {
      if (debt.repayments.isEmpty) {
        rows.add([
          debt.id,
          debt.personName,
          debt.type.dbValue,
          debt.principalAmount.toStringAsFixed(2),
          debt.interestType.dbValue,
          debt.interestRate.toStringAsFixed(2),
          debt.interestAmount.toStringAsFixed(2),
          debt.totalRepaymentAmount.toStringAsFixed(2),
          debt.totalPaid.toStringAsFixed(2),
          debt.remainingAmount.toStringAsFixed(2),
          debt.dueDate != null ? _dateFormat.format(debt.dueDate!) : '',
          debt.status.dbValue,
          debt.notes ?? '',
          '',
          '',
          '',
          '',
        ]);
      } else {
        for (final rep in debt.repayments) {
          final accName = rep.accountId != null ? (accountNames[rep.accountId!] ?? rep.accountId!) : '';
          rows.add([
            debt.id,
            debt.personName,
            debt.type.dbValue,
            debt.principalAmount.toStringAsFixed(2),
            debt.interestType.dbValue,
            debt.interestRate.toStringAsFixed(2),
            debt.interestAmount.toStringAsFixed(2),
            debt.totalRepaymentAmount.toStringAsFixed(2),
            debt.totalPaid.toStringAsFixed(2),
            debt.remainingAmount.toStringAsFixed(2),
            debt.dueDate != null ? _dateFormat.format(debt.dueDate!) : '',
            debt.status.dbValue,
            debt.notes ?? '',
            _dateFormat.format(rep.repaymentDate),
            rep.amount.toStringAsFixed(2),
            accName,
            rep.notes ?? '',
          ]);
        }
      }
    }

    return _converter.convert(rows);
  }

  /// Packages a full multi-ledger backup into a clean ZIP archive with separate CSV files.
  List<int> generateFullBackupZip({
    required List<TransactionModel> transactions,
    required List<AccountModel> accounts,
    required List<CategoryModel> categories,
    required List<SavingsGoalModel> savingsGoals,
    required List<GoalContributionModel> goalContributions,
    required List<DebtModel> debts,
    required Map<String, String> accountNames,
    required Map<String, String> categoryNames,
  }) {
    final archive = Archive();

    // 1. transactions.csv
    final txCsv = exportTransactionsCsv(
      transactions,
      accountNames: accountNames,
      categoryNames: categoryNames,
    );
    archive.addFile(ArchiveFile('transactions.csv', txCsv.length, utf8.encode(txCsv)));

    // 2. accounts.csv
    final accRows = <List<dynamic>>[
      ['ID', 'Name', 'Type', 'Opening Balance', 'Is Active'],
      ...accounts.map((a) => [a.id, a.name, a.type, a.openingBalance.toStringAsFixed(2), a.isActive]),
    ];
    final accCsv = _converter.convert(accRows);
    archive.addFile(ArchiveFile('accounts.csv', accCsv.length, utf8.encode(accCsv)));

    // 3. categories.csv
    final catRows = <List<dynamic>>[
      ['ID', 'Name', 'Type', 'Icon', 'Color', 'Is Active'],
      ...categories.map((c) => [c.id, c.name, c.type, c.icon ?? '', c.color ?? '', c.isActive]),
    ];
    final catCsv = _converter.convert(catRows);
    archive.addFile(ArchiveFile('categories.csv', catCsv.length, utf8.encode(catCsv)));

    // 4. savings_goals.csv
    final sgRows = <List<dynamic>>[
      ['ID', 'Name', 'Target Amount', 'Current Saved', 'Target Date', 'Is Active', 'Notes'],
      ...savingsGoals.map((g) => [
        g.id,
        g.name,
        g.targetAmount.toStringAsFixed(2),
        g.currentAmount.toStringAsFixed(2),
        g.targetDate != null ? _dateFormat.format(g.targetDate!) : '',
        g.isActive,
        g.notes ?? '',
      ]),
    ];
    final sgCsv = _converter.convert(sgRows);
    archive.addFile(ArchiveFile('savings_goals.csv', sgCsv.length, utf8.encode(sgCsv)));

    // 5. goal_contributions.csv
    final gcRows = <List<dynamic>>[
      ['ID', 'Goal ID', 'Date', 'Type', 'Amount', 'Account ID', 'Notes'],
      ...goalContributions.map((c) => [
        c.id,
        c.goalId,
        _dateFormat.format(c.contributionDate),
        c.isDeposit ? 'DEPOSIT' : 'WITHDRAWAL',
        c.amount.toStringAsFixed(2),
        c.accountId ?? '',
        c.notes ?? '',
      ]),
    ];
    final gcCsv = _converter.convert(gcRows);
    archive.addFile(ArchiveFile('goal_contributions.csv', gcCsv.length, utf8.encode(gcCsv)));

    // 6. debts.csv
    final debtRows = <List<dynamic>>[
      ['ID', 'Person Name', 'Type', 'Principal', 'Interest Type', 'Interest Rate', 'Interest Amount', 'Total Expected', 'Status', 'Due Date'],
      ...debts.map((d) => [
        d.id,
        d.personName,
        d.type.dbValue,
        d.principalAmount.toStringAsFixed(2),
        d.interestType.dbValue,
        d.interestRate.toStringAsFixed(2),
        d.interestAmount.toStringAsFixed(2),
        d.totalRepaymentAmount.toStringAsFixed(2),
        d.status.dbValue,
        d.dueDate != null ? _dateFormat.format(d.dueDate!) : '',
      ]),
    ];
    final debtsCsv = _converter.convert(debtRows);
    archive.addFile(ArchiveFile('debts.csv', debtsCsv.length, utf8.encode(debtsCsv)));

    // 7. debt_repayments.csv
    final allReps = debts.expand((d) => d.repayments).toList();
    final repRows = <List<dynamic>>[
      ['ID', 'Debt ID', 'Date', 'Amount', 'Account ID', 'Notes'],
      ...allReps.map((r) => [
        r.id,
        r.debtId,
        _dateFormat.format(r.repaymentDate),
        r.amount.toStringAsFixed(2),
        r.accountId ?? '',
        r.notes ?? '',
      ]),
    ];
    final repCsv = _converter.convert(repRows);
    archive.addFile(ArchiveFile('debt_repayments.csv', repCsv.length, utf8.encode(repCsv)));

    return ZipEncoder().encode(archive) ?? [];
  }
}
