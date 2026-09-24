import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_status.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_type.dart';
import 'package:expense_tracker/features/debts/domain/models/interest_type.dart';

void main() {
  group('DebtModel', () {
    final testDebt = DebtModel(
      id: 'debt-1',
      userId: 'user-123',
      type: DebtType.youAreOwed,
      personName: 'Amaan',
      contactNumber: '+919876543210',
      principalAmount: 50000.0,
      interestType: InterestType.percentage,
      interestRate: 20.0,
      interestAmount: 10000.0,
      totalRepaymentAmount: 60000.0,
      dueDate: DateTime(2026, 10, 30),
      status: DebtStatus.active,
      accountId: 'acc-1',
      notes: 'Personal loan for project',
      totalPaid: 25000.0,
      createdAt: DateTime(2026, 1, 1, 10, 0),
    );

    test('calculates remainingAmount, progressRatio, and progressPercentage correctly', () {
      expect(testDebt.remainingAmount, 35000.0);
      expect(testDebt.progressRatio, closeTo(0.41666, 0.001));
      expect(testDebt.progressPercentage, closeTo(41.666, 0.01));
      expect(testDebt.isSettled, isFalse);
      expect(testDebt.isPartiallyPaid, isTrue);

      final fullyPaid = testDebt.copyWith(totalPaid: 60000.0);
      expect(fullyPaid.remainingAmount, 0.0);
      expect(fullyPaid.progressRatio, 1.0);
      expect(fullyPaid.progressPercentage, 100.0);
      expect(fullyPaid.isSettled, isTrue);
      expect(fullyPaid.isPartiallyPaid, isFalse);

      final overpaid = testDebt.copyWith(totalPaid: 70000.0);
      expect(overpaid.remainingAmount, 0.0);
      expect(overpaid.progressRatio, 1.0);
      expect(overpaid.progressPercentage, 100.0);
      expect(overpaid.isSettled, isTrue);
    });

    test('evaluates overdue status accurately based on asOfDate', () {
      // Due Date is 2026-10-30
      final beforeDue = DateTime(2026, 10, 15);
      final onDue = DateTime(2026, 10, 30);
      final afterDue = DateTime(2026, 11, 1);

      expect(testDebt.isOverdue(asOfDate: beforeDue), isFalse);
      expect(testDebt.isOverdue(asOfDate: onDue), isFalse);
      expect(testDebt.isOverdue(asOfDate: afterDue), isTrue);

      // Settled debt should never be overdue
      final settledDebt = testDebt.copyWith(status: DebtStatus.settled);
      expect(settledDebt.isOverdue(asOfDate: afterDue), isFalse);
    });

    test('serializes toMap and deserializes fromMap correctly', () {
      final map = testDebt.toMap();
      expect(map['id'], 'debt-1');
      expect(map['user_id'], 'user-123');
      expect(map['type'], 'YOU_ARE_OWED');
      expect(map['person_name'], 'Amaan');
      expect(map['contact_number'], '+919876543210');
      expect(map['principal_amount'], 50000.0);
      expect(map['interest_type'], 'PERCENTAGE');
      expect(map['interest_rate'], 20.0);
      expect(map['interest_amount'], 10000.0);
      expect(map['total_repayment_amount'], 60000.0);
      expect(map['due_date'], '2026-10-30');
      expect(map['status'], 'ACTIVE');
      expect(map['account_id'], 'acc-1');
      expect(map['notes'], 'Personal loan for project');

      final deserialized = DebtModel.fromMap(map, totalPaid: 25000.0);
      expect(deserialized.id, testDebt.id);
      expect(deserialized.userId, testDebt.userId);
      expect(deserialized.type, DebtType.youAreOwed);
      expect(deserialized.personName, 'Amaan');
      expect(deserialized.principalAmount, 50000.0);
      expect(deserialized.interestType, InterestType.percentage);
      expect(deserialized.interestRate, 20.0);
      expect(deserialized.interestAmount, 10000.0);
      expect(deserialized.totalRepaymentAmount, 60000.0);
      expect(deserialized.dueDate, testDebt.dueDate);
      expect(deserialized.status, DebtStatus.active);
      expect(deserialized.totalPaid, 25000.0);
    });

    test('copyWith properly updates specified fields', () {
      final updated = testDebt.copyWith(
        personName: 'Amaan Khan',
        status: DebtStatus.settled,
        totalPaid: 60000.0,
      );

      expect(updated.personName, 'Amaan Khan');
      expect(updated.status, DebtStatus.settled);
      expect(updated.totalPaid, 60000.0);
      expect(updated.principalAmount, testDebt.principalAmount);
      expect(updated.id, testDebt.id);
    });
  });
}
