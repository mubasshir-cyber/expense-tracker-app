import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/goals/domain/models/goal_contribution_model.dart';

void main() {
  group('GoalContributionModel', () {
    final deposit = GoalContributionModel(
      id: 'contrib-1',
      goalId: 'goal-1',
      userId: 'user-1',
      amount: 5000.0,
      accountId: 'acc-1',
      contributionDate: DateTime(2026, 3, 15),
      notes: 'March monthly savings',
      createdAt: DateTime(2026, 3, 15, 12, 0),
    );

    final withdrawal = GoalContributionModel(
      id: 'contrib-2',
      goalId: 'goal-1',
      userId: 'user-1',
      amount: -2000.0,
      accountId: 'acc-1',
      contributionDate: DateTime(2026, 4, 1),
      notes: 'Partial withdrawal for repair',
      createdAt: DateTime(2026, 4, 1, 9, 30),
    );

    test('identifies deposit vs withdrawal correctly', () {
      expect(deposit.isDeposit, isTrue);
      expect(deposit.isWithdrawal, isFalse);

      expect(withdrawal.isDeposit, isFalse);
      expect(withdrawal.isWithdrawal, isTrue);
    });

    test('serializes toMap and deserializes fromMap accurately', () {
      final map = deposit.toMap();
      expect(map['id'], 'contrib-1');
      expect(map['goal_id'], 'goal-1');
      expect(map['user_id'], 'user-1');
      expect(map['amount'], 5000.0);
      expect(map['account_id'], 'acc-1');
      expect(map['contribution_date'], '2026-03-15');
      expect(map['notes'], 'March monthly savings');

      final deserialized = GoalContributionModel.fromMap(map);
      expect(deserialized.id, deposit.id);
      expect(deserialized.goalId, deposit.goalId);
      expect(deserialized.userId, deposit.userId);
      expect(deserialized.amount, deposit.amount);
      expect(deserialized.accountId, deposit.accountId);
      expect(deserialized.contributionDate, deposit.contributionDate);
      expect(deserialized.notes, deposit.notes);
    });

    test('handles negative amount withdrawal serialization accurately', () {
      final map = withdrawal.toMap();
      expect(map['amount'], -2000.0);

      final deserialized = GoalContributionModel.fromMap(map);
      expect(deserialized.amount, -2000.0);
      expect(deserialized.isWithdrawal, isTrue);
    });
  });
}
