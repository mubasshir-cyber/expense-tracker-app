import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_status.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_type.dart';
import 'package:expense_tracker/features/goals/domain/models/savings_goal_model.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_model.dart';
import 'package:expense_tracker/features/export_import/domain/models/pdf_report_config.dart';
import 'package:expense_tracker/features/export_import/domain/services/pdf_export_service.dart';

void main() {
  const service = PdfExportService();

  final sampleTransactions = [
    TransactionModel(
      id: 'tx-1',
      userId: 'user-1',
      accountId: 'acc-1',
      categoryId: 'cat-1',
      type: 'INCOME',
      amount: 50000.0,
      transactionDate: DateTime(2026, 9, 1),
      description: 'Monthly Salary',
    ),
    TransactionModel(
      id: 'tx-2',
      userId: 'user-1',
      accountId: 'acc-1',
      categoryId: 'cat-2',
      type: 'EXPENSE',
      amount: 15000.0,
      transactionDate: DateTime(2026, 9, 15),
      description: 'Rent Payment',
    ),
  ];

  final sampleGoals = [
    SavingsGoalModel(
      id: 'goal-1',
      userId: 'user-1',
      name: 'Vacation',
      targetAmount: 30000.0,
      currentAmount: 15000.0,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  final sampleDebts = [
    DebtModel(
      id: 'debt-1',
      userId: 'user-1',
      type: DebtType.youOwe,
      personName: 'Ahmed',
      principalAmount: 10000.0,
      totalRepaymentAmount: 10000.0,
      totalPaid: 5000.0,
      status: DebtStatus.active,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  group('PdfExportService Tests', () {
    test('generateFinancialReportPdf returns valid PDF binary data', () async {
      const config = PdfReportConfig(
        title: 'Quarterly Financial Statement',
        subtitle: 'Confidential Internal Report',
        name: 'Mubasshir Cyber',
        phone: '+91 9876543210',
        email: 'mubasshir@example.com',
        footerText: 'Generated automatically by Personal Expense Tracker',
      );

      final pdfBytes = await service.generateFinancialReportPdf(
        config: config,
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
        openingBalance: 10000.0,
        transactions: sampleTransactions,
        savingsGoals: sampleGoals,
        debts: sampleDebts,
        accountNames: {'acc-1': 'Main Bank'},
        categoryNames: {'cat-1': 'Salary', 'cat-2': 'Housing'},
        includeTransactions: true,
        includeSavings: true,
        includeDebts: true,
      );

      expect(pdfBytes, isNotEmpty);
      // Valid PDF begins with %PDF header
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, '%PDF-');
    });
  });
}
