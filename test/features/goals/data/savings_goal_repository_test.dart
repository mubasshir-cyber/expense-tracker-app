import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/goals/domain/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/domain/models/savings_goal_model.dart';

void main() {
  group('SavingsGoalRepository — Data Contracts & Schema Guarding', () {
    const baseGoalMap = {
      'id': 'goal-123',
      'user_id': 'user-456',
      'name': 'House Downpayment',
      'target_amount': 500000.0,
      'target_date': '2027-12-31',
      'icon': 'home',
      'color': '#10B981',
      'account_id': 'acc-1',
      'category_id': 'cat-1',
      'is_active': true,
      'notes': 'Save 20% downpayment',
      'created_at': '2026-01-01T00:00:00.000Z',
    };

    const baseContribMap = {
      'id': 'contrib-001',
      'goal_id': 'goal-123',
      'user_id': 'user-456',
      'amount': 25000.0,
      'account_id': 'acc-1',
      'contribution_date': '2026-02-01',
      'notes': 'February bonus deposit',
      'created_at': '2026-02-01T12:00:00.000Z',
    };

    test('SavingsGoalModel fromMap maps all fields accurately', () {
      final model = SavingsGoalModel.fromMap(baseGoalMap, currentAmount: 75000.0);

      expect(model.id, 'goal-123');
      expect(model.userId, 'user-456');
      expect(model.name, 'House Downpayment');
      expect(model.targetAmount, 500000.0);
      expect(model.currentAmount, 75000.0);
      expect(model.targetDate, DateTime(2027, 12, 31));
      expect(model.icon, 'home');
      expect(model.color, '#10B981');
      expect(model.accountId, 'acc-1');
      expect(model.categoryId, 'cat-1');
      expect(model.isActive, isTrue);
      expect(model.notes, 'Save 20% downpayment');
    });

    test('SavingsGoalModel toMap produces compliant Supabase dictionary', () {
      final model = SavingsGoalModel.fromMap(baseGoalMap);
      final map = model.toMap();

      expect(map['id'], 'goal-123');
      expect(map['user_id'], 'user-456');
      expect(map['name'], 'House Downpayment');
      expect(map['target_amount'], 500000.0);
      expect(map['target_date'], '2027-12-31');
      expect(map['icon'], 'home');
      expect(map['color'], '#10B981');
      expect(map['account_id'], 'acc-1');
      expect(map['category_id'], 'cat-1');
      expect(map['is_active'], true);
      expect(map['notes'], 'Save 20% downpayment');
    });

    test('GoalContributionModel fromMap and toMap adhere to schema', () {
      final model = GoalContributionModel.fromMap(baseContribMap);

      expect(model.id, 'contrib-001');
      expect(model.goalId, 'goal-123');
      expect(model.userId, 'user-456');
      expect(model.amount, 25000.0);
      expect(model.accountId, 'acc-1');
      expect(model.contributionDate, DateTime(2026, 2, 1));
      expect(model.notes, 'February bonus deposit');

      final map = model.toMap();
      expect(map['id'], 'contrib-001');
      expect(map['goal_id'], 'goal-123');
      expect(map['amount'], 25000.0);
      expect(map['account_id'], 'acc-1');
      expect(map['contribution_date'], '2026-02-01');
      expect(map['notes'], 'February bonus deposit');
    });
  });
}
