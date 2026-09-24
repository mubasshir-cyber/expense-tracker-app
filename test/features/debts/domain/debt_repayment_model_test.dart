import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_repayment_model.dart';

void main() {
  group('DebtRepaymentModel', () {
    final testRepayment = DebtRepaymentModel(
      id: 'rep-1',
      debtId: 'debt-1',
      userId: 'user-123',
      amount: 15000.0,
      repaymentDate: DateTime(2026, 10, 12),
      accountId: 'acc-1',
      installmentId: 'inst-1',
      notes: 'First installment payment',
      createdAt: DateTime(2026, 10, 12, 14, 30),
    );

    test('serializes toMap and deserializes fromMap correctly', () {
      final map = testRepayment.toMap();
      expect(map['id'], 'rep-1');
      expect(map['debt_id'], 'debt-1');
      expect(map['user_id'], 'user-123');
      expect(map['amount'], 15000.0);
      expect(map['repayment_date'], '2026-10-12');
      expect(map['account_id'], 'acc-1');
      expect(map['installment_id'], 'inst-1');
      expect(map['notes'], 'First installment payment');

      final deserialized = DebtRepaymentModel.fromMap(map);
      expect(deserialized.id, testRepayment.id);
      expect(deserialized.debtId, testRepayment.debtId);
      expect(deserialized.amount, 15000.0);
      expect(deserialized.repaymentDate, testRepayment.repaymentDate);
      expect(deserialized.accountId, 'acc-1');
      expect(deserialized.installmentId, 'inst-1');
      expect(deserialized.notes, 'First installment payment');
    });

    test('copyWith updates fields properly', () {
      final updated = testRepayment.copyWith(amount: 20000.0, notes: 'Updated notes');
      expect(updated.amount, 20000.0);
      expect(updated.notes, 'Updated notes');
      expect(updated.id, testRepayment.id);
      expect(updated.debtId, testRepayment.debtId);
    });
  });
}
