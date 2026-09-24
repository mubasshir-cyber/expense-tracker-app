import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_installment_model.dart';

void main() {
  group('DebtInstallmentModel', () {
    final testInstallment = DebtInstallmentModel(
      id: 'inst-1',
      debtId: 'debt-1',
      userId: 'user-123',
      installmentNumber: 1,
      dueDate: DateTime(2026, 10, 10),
      principalDue: 8333.33,
      interestDue: 1666.67,
      totalDue: 10000.0,
      paidAmount: 5000.0,
      status: InstallmentStatus.partial,
    );

    test('calculates remainingDue and progressRatio correctly', () {
      expect(testInstallment.remainingDue, 5000.0);
      expect(testInstallment.progressRatio, 0.5);
      expect(testInstallment.isPaid, isFalse);

      final paidInst = testInstallment.copyWith(
        paidAmount: 10000.0,
        status: InstallmentStatus.paid,
      );
      expect(paidInst.remainingDue, 0.0);
      expect(paidInst.progressRatio, 1.0);
      expect(paidInst.isPaid, isTrue);
    });

    test('evaluates overdue status correctly based on asOfDate', () {
      final beforeDue = DateTime(2026, 10, 5);
      final onDue = DateTime(2026, 10, 10);
      final afterDue = DateTime(2026, 10, 15);

      expect(testInstallment.isOverdue(asOfDate: beforeDue), isFalse);
      expect(testInstallment.isOverdue(asOfDate: onDue), isFalse);
      expect(testInstallment.isOverdue(asOfDate: afterDue), isTrue);

      final paidInst = testInstallment.copyWith(status: InstallmentStatus.paid);
      expect(paidInst.isOverdue(asOfDate: afterDue), isFalse);
    });

    test('serializes toMap and deserializes fromMap correctly', () {
      final map = testInstallment.toMap();
      expect(map['id'], 'inst-1');
      expect(map['debt_id'], 'debt-1');
      expect(map['user_id'], 'user-123');
      expect(map['installment_number'], 1);
      expect(map['due_date'], '2026-10-10');
      expect(map['principal_due'], 8333.33);
      expect(map['interest_due'], 1666.67);
      expect(map['total_due'], 10000.0);
      expect(map['paid_amount'], 5000.0);
      expect(map['status'], 'PARTIAL');

      final deserialized = DebtInstallmentModel.fromMap(map);
      expect(deserialized.id, testInstallment.id);
      expect(deserialized.debtId, testInstallment.debtId);
      expect(deserialized.installmentNumber, 1);
      expect(deserialized.totalDue, 10000.0);
      expect(deserialized.paidAmount, 5000.0);
      expect(deserialized.status, InstallmentStatus.partial);
    });
  });
}
