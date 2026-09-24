import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_installment_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_status.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_type.dart';
import 'package:expense_tracker/features/debts/domain/models/interest_type.dart';
import 'package:expense_tracker/features/debts/domain/services/debt_calculation_service.dart';

void main() {
  const service = DebtCalculationService();

  group('DebtCalculationService - Interest and Total Calculation', () {
    test('calculates interest for InterestType.none', () {
      final interest = service.calculateInterestAmount(50000.0, InterestType.none);
      expect(interest, 0.0);

      final total = service.calculateTotalRepayment(50000.0, interest);
      expect(total, 50000.0);
    });

    test('calculates percentage interest correctly (e.g., 50,000 @ 20% = 10,000 -> 60,000)', () {
      final interest = service.calculateInterestAmount(
        50000.0,
        InterestType.percentage,
        rate: 20.0,
      );
      expect(interest, 10000.0);

      final total = service.calculateTotalRepayment(50000.0, interest);
      expect(total, 60000.0);
    });

    test('calculates fixed interest correctly (e.g., 50,000 + 10,000 fixed = 60,000)', () {
      final interest = service.calculateInterestAmount(
        50000.0,
        InterestType.fixed,
        fixedAmount: 10000.0,
      );
      expect(interest, 10000.0);

      final total = service.calculateTotalRepayment(50000.0, interest);
      expect(total, 60000.0);
    });
  });

  group('DebtCalculationService - Installment Generation', () {
    test('generates monthly installment schedule with correct splits', () {
      final installments = service.generateInstallments(
        debtId: 'debt-1',
        userId: 'user-1',
        principal: 50000.0,
        interestAmount: 10000.0,
        installmentCount: 6,
        startDate: DateTime(2026, 10, 10),
      );

      expect(installments.length, 6);
      expect(installments[0].installmentNumber, 1);
      expect(installments[0].dueDate, DateTime(2026, 10, 10));
      expect(installments[0].totalDue, 10000.0);
      expect(installments[0].status, InstallmentStatus.pending);

      expect(installments[1].installmentNumber, 2);
      expect(installments[1].dueDate, DateTime(2026, 11, 10));

      expect(installments[5].installmentNumber, 6);
      expect(installments[5].dueDate, DateTime(2027, 3, 10));
    });
  });

  group('DebtCalculationService - Sequential Repayment Allocation', () {
    final baseInstallments = [
      DebtInstallmentModel(
        id: 'inst-1',
        debtId: 'debt-1',
        userId: 'user-1',
        installmentNumber: 1,
        dueDate: DateTime(2026, 10, 10),
        principalDue: 8333.33,
        interestDue: 1666.67,
        totalDue: 10000.0,
        paidAmount: 0.0,
        status: InstallmentStatus.pending,
      ),
      DebtInstallmentModel(
        id: 'inst-2',
        debtId: 'debt-1',
        userId: 'user-1',
        installmentNumber: 2,
        dueDate: DateTime(2026, 11, 10),
        principalDue: 8333.33,
        interestDue: 1666.67,
        totalDue: 10000.0,
        paidAmount: 0.0,
        status: InstallmentStatus.pending,
      ),
      DebtInstallmentModel(
        id: 'inst-3',
        debtId: 'debt-1',
        userId: 'user-1',
        installmentNumber: 3,
        dueDate: DateTime(2026, 12, 10),
        principalDue: 8333.33,
        interestDue: 1666.67,
        totalDue: 10000.0,
        paidAmount: 0.0,
        status: InstallmentStatus.pending,
      ),
    ];

    test('allocates exact installment amount (10,000) to mark first installment PAID', () {
      final updated = service.allocateRepaymentToInstallments(
        baseInstallments,
        10000.0,
      );

      expect(updated[0].status, InstallmentStatus.paid);
      expect(updated[0].paidAmount, 10000.0);

      expect(updated[1].status, InstallmentStatus.pending);
      expect(updated[1].paidAmount, 0.0);
    });

    test('allocates partial amount (5,000) to mark first installment PARTIAL', () {
      final updated = service.allocateRepaymentToInstallments(
        baseInstallments,
        5000.0,
      );

      expect(updated[0].status, InstallmentStatus.partial);
      expect(updated[0].paidAmount, 5000.0);
      expect(updated[0].remainingDue, 5000.0);

      expect(updated[1].status, InstallmentStatus.pending);
    });

    test('allocates multi-installment amount (15,000) starting from partial installment', () {
      final partialInstallments = [
        baseInstallments[0].copyWith(
          paidAmount: 5000.0,
          status: InstallmentStatus.partial,
        ),
        baseInstallments[1],
        baseInstallments[2],
      ];

      final updated = service.allocateRepaymentToInstallments(
        partialInstallments,
        15000.0,
      );

      // Inst 1 had 5000 remaining: gets 5000 -> fully paid
      expect(updated[0].status, InstallmentStatus.paid);
      expect(updated[0].paidAmount, 10000.0);

      // Inst 2 had 10000 remaining: gets remaining 10000 -> fully paid
      expect(updated[1].status, InstallmentStatus.paid);
      expect(updated[1].paidAmount, 10000.0);

      // Inst 3 untouched
      expect(updated[2].status, InstallmentStatus.pending);
      expect(updated[2].paidAmount, 0.0);
    });
  });

  group('DebtCalculationService - Summary Calculation', () {
    test('calculates portfolio summary with net position and overdue counts', () {
      final debts = [
        DebtModel(
          id: '1',
          userId: 'u1',
          type: DebtType.youAreOwed,
          personName: 'Amaan',
          principalAmount: 50000.0,
          totalRepaymentAmount: 60000.0,
          totalPaid: 25000.0, // remaining 35000
          status: DebtStatus.active,
          createdAt: DateTime.now(),
        ),
        DebtModel(
          id: '2',
          userId: 'u1',
          type: DebtType.youAreOwed,
          personName: 'Ahmed',
          principalAmount: 20000.0,
          totalRepaymentAmount: 20000.0,
          totalPaid: 0.0, // remaining 20000
          status: DebtStatus.active,
          createdAt: DateTime.now(),
        ),
        DebtModel(
          id: '3',
          userId: 'u1',
          type: DebtType.youOwe,
          personName: 'Bank',
          principalAmount: 40000.0,
          totalRepaymentAmount: 40000.0,
          totalPaid: 10000.0, // remaining 30000
          dueDate: DateTime(2020, 1, 1), // Overdue
          status: DebtStatus.active,
          createdAt: DateTime.now(),
        ),
      ];

      final summary = service.calculateSummary(debts);

      expect(summary.totalYouAreOwed, 55000.0); // 35000 + 20000
      expect(summary.totalYouOwe, 30000.0);
      expect(summary.netPosition, 25000.0); // 55000 - 30000
      expect(summary.activeOwedCount, 2);
      expect(summary.activeOweCount, 1);
      expect(summary.overdueCount, 1);
    });
  });
}
