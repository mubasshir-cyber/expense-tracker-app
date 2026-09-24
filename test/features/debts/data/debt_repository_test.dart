import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_installment_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_repayment_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_status.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_type.dart';
import 'package:expense_tracker/features/debts/domain/models/interest_type.dart';

void main() {
  group('DebtRepository — Data Contracts & Schema Guarding', () {
    const baseDebtMap = {
      'id': 'debt-001',
      'user_id': 'user-456',
      'type': 'YOU_ARE_OWED',
      'person_name': 'Amaan',
      'contact_number': '+919876543210',
      'principal_amount': 50000.0,
      'interest_type': 'PERCENTAGE',
      'interest_rate': 20.0,
      'interest_amount': 10000.0,
      'total_repayment_amount': 60000.0,
      'due_date': '2026-10-30',
      'status': 'ACTIVE',
      'account_id': 'acc-1',
      'notes': 'Loan for project',
      'created_at': '2026-01-01T00:00:00.000Z',
    };

    const baseInstallmentMap = {
      'id': 'inst-001',
      'debt_id': 'debt-001',
      'user_id': 'user-456',
      'installment_number': 1,
      'due_date': '2026-10-10',
      'principal_due': 8333.33,
      'interest_due': 1666.67,
      'total_due': 10000.0,
      'paid_amount': 10000.0,
      'status': 'PAID',
      'paid_at': '2026-10-05T10:00:00.000Z',
    };

    const baseRepaymentMap = {
      'id': 'rep-001',
      'debt_id': 'debt-001',
      'user_id': 'user-456',
      'amount': 10000.0,
      'repayment_date': '2026-10-05',
      'account_id': 'acc-1',
      'installment_id': 'inst-001',
      'notes': 'First EMI',
      'created_at': '2026-10-05T10:00:00.000Z',
    };

    test('DebtModel fromMap maps all fields accurately', () {
      final model = DebtModel.fromMap(baseDebtMap, totalPaid: 10000.0);

      expect(model.id, 'debt-001');
      expect(model.userId, 'user-456');
      expect(model.type, DebtType.youAreOwed);
      expect(model.personName, 'Amaan');
      expect(model.contactNumber, '+919876543210');
      expect(model.principalAmount, 50000.0);
      expect(model.interestType, InterestType.percentage);
      expect(model.interestRate, 20.0);
      expect(model.interestAmount, 10000.0);
      expect(model.totalRepaymentAmount, 60000.0);
      expect(model.totalPaid, 10000.0);
      expect(model.remainingAmount, 50000.0);
      expect(model.status, DebtStatus.active);
    });

    test('DebtModel toMap produces compliant Supabase dictionary', () {
      final model = DebtModel.fromMap(baseDebtMap);
      final map = model.toMap();

      expect(map['id'], 'debt-001');
      expect(map['user_id'], 'user-456');
      expect(map['type'], 'YOU_ARE_OWED');
      expect(map['person_name'], 'Amaan');
      expect(map['principal_amount'], 50000.0);
      expect(map['interest_type'], 'PERCENTAGE');
      expect(map['interest_rate'], 20.0);
      expect(map['interest_amount'], 10000.0);
      expect(map['total_repayment_amount'], 60000.0);
    });

    test('DebtInstallmentModel fromMap and toMap adhere to schema', () {
      final model = DebtInstallmentModel.fromMap(baseInstallmentMap);

      expect(model.id, 'inst-001');
      expect(model.debtId, 'debt-001');
      expect(model.installmentNumber, 1);
      expect(model.totalDue, 10000.0);
      expect(model.paidAmount, 10000.0);
      expect(model.status, InstallmentStatus.paid);

      final map = model.toMap();
      expect(map['id'], 'inst-001');
      expect(map['installment_number'], 1);
      expect(map['status'], 'PAID');
    });

    test('DebtRepaymentModel fromMap and toMap adhere to schema', () {
      final model = DebtRepaymentModel.fromMap(baseRepaymentMap);

      expect(model.id, 'rep-001');
      expect(model.debtId, 'debt-001');
      expect(model.amount, 10000.0);
      expect(model.repaymentDate, DateTime(2026, 10, 5));
      expect(model.installmentId, 'inst-001');

      final map = model.toMap();
      expect(map['id'], 'rep-001');
      expect(map['debt_id'], 'debt-001');
      expect(map['amount'], 10000.0);
    });
  });
}
