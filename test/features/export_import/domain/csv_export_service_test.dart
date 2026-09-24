import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/accounts/domain/models/account_model.dart';
import 'package:expense_tracker/features/categories/domain/models/category_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_repayment_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_status.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_type.dart';
import 'package:expense_tracker/features/debts/domain/models/interest_type.dart';
import 'package:expense_tracker/features/goals/domain/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/domain/models/savings_goal_model.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_model.dart';
import 'package:expense_tracker/features/export_import/domain/services/csv_export_service.dart';

void main() {
  const service = CsvExportService();

  final sampleAccounts = [
    const AccountModel(
      id: 'acc-1',
      userId: 'user-1',
      name: 'HDFC Bank',
      type: 'bank',
      isActive: true,
      openingBalance: 10000.0,
    ),
  ];

  final sampleCategories = [
    const CategoryModel(
      id: 'cat-1',
      userId: 'user-1',
      name: 'Groceries',
      type: 'expense',
      isActive: true,
    ),
  ];

  final sampleTransactions = [
    TransactionModel(
      id: 'tx-1',
      userId: 'user-1',
      accountId: 'acc-1',
      categoryId: 'cat-1',
      type: 'EXPENSE',
      amount: 1500.0,
      transactionDate: DateTime(2026, 9, 20),
      description: 'Supermarket shopping',
      paymentMethod: 'UPI',
    ),
  ];

  final sampleGoals = [
    SavingsGoalModel(
      id: 'goal-1',
      userId: 'user-1',
      name: 'Emergency Fund',
      targetAmount: 50000.0,
      currentAmount: 20000.0,
      targetDate: DateTime(2026, 12, 31),
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  final sampleContributions = [
    GoalContributionModel(
      id: 'contrib-1',
      goalId: 'goal-1',
      userId: 'user-1',
      accountId: 'acc-1',
      amount: 20000.0,
      contributionDate: DateTime(2026, 9, 15),
      notes: 'Initial allocation',
      createdAt: DateTime(2026, 9, 15),
    ),
  ];

  final sampleDebts = [
    DebtModel(
      id: 'debt-1',
      userId: 'user-1',
      type: DebtType.youAreOwed,
      personName: 'Amaan',
      principalAmount: 50000.0,
      interestType: InterestType.percentage,
      interestRate: 20.0,
      interestAmount: 10000.0,
      totalRepaymentAmount: 60000.0,
      totalPaid: 20000.0,
      dueDate: DateTime(2026, 10, 30),
      status: DebtStatus.active,
      repayments: [
        DebtRepaymentModel(
          id: 'rep-1',
          debtId: 'debt-1',
          userId: 'user-1',
          accountId: 'acc-1',
          amount: 20000.0,
          repaymentDate: DateTime(2026, 9, 10),
          notes: 'Part payment',
          createdAt: DateTime(2026, 9, 10),
        ),
      ],
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  group('CsvExportService Tests', () {
    test('generateSampleCsv generates valid CSV template', () {
      final csv = service.generateSampleCsv();
      expect(csv, contains('Date,Type,Amount,Category,Account,Description,Payment Method'));
      expect(csv, contains('Groceries'));
      expect(csv, contains('Salary'));
    });

    test('exportTransactionsCsv creates correctly mapped CSV output', () {
      final csv = service.exportTransactionsCsv(
        sampleTransactions,
        accountNames: {'acc-1': 'HDFC Bank'},
        categoryNames: {'cat-1': 'Groceries'},
      );

      expect(csv, contains('ID,Date,Type,Category,Account,Amount,Description,Payment Method'));
      expect(csv, contains('tx-1'));
      expect(csv, contains('2026-09-20'));
      expect(csv, contains('EXPENSE'));
      expect(csv, contains('Groceries'));
      expect(csv, contains('HDFC Bank'));
      expect(csv, contains('1500.00'));
    });

    test('exportSavingsGoalsCsv includes goal info and contribution history', () {
      final csv = service.exportSavingsGoalsCsv(
        sampleGoals,
        contributions: {'goal-1': sampleContributions},
        accountNames: {'acc-1': 'HDFC Bank'},
      );

      expect(csv, contains('Goal ID,Goal Name,Target Amount,Current Saved'));
      expect(csv, contains('Emergency Fund'));
      expect(csv, contains('50000.00'));
      expect(csv, contains('20000.00'));
      expect(csv, contains('DEPOSIT'));
      expect(csv, contains('Initial allocation'));
    });

    test('exportDebtsCsv includes debt and repayment schedules', () {
      final csv = service.exportDebtsCsv(
        sampleDebts,
        accountNames: {'acc-1': 'HDFC Bank'},
      );

      expect(csv, contains('Debt ID,Person Name,Direction / Type,Principal Amount'));
      expect(csv, contains('Amaan'));
      expect(csv, contains('50000.00'));
      expect(csv, contains('60000.00'));
      expect(csv, contains('20000.00'));
      expect(csv, contains('Part payment'));
    });

    test('generateFullBackupZip creates valid ZIP with separate CSV files', () {
      final zipBytes = service.generateFullBackupZip(
        transactions: sampleTransactions,
        accounts: sampleAccounts,
        categories: sampleCategories,
        savingsGoals: sampleGoals,
        goalContributions: sampleContributions,
        debts: sampleDebts,
        accountNames: {'acc-1': 'HDFC Bank'},
        categoryNames: {'cat-1': 'Groceries'},
      );

      expect(zipBytes, isNotEmpty);
      final decodedArchive = ZipDecoder().decodeBytes(zipBytes);
      final filenames = decodedArchive.files.map((f) => f.name).toList();

      expect(filenames, contains('transactions.csv'));
      expect(filenames, contains('accounts.csv'));
      expect(filenames, contains('categories.csv'));
      expect(filenames, contains('savings_goals.csv'));
      expect(filenames, contains('goal_contributions.csv'));
      expect(filenames, contains('debts.csv'));
      expect(filenames, contains('debt_repayments.csv'));
    });
  });
}
