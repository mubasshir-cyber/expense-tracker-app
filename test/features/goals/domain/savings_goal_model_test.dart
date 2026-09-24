import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/goals/domain/models/savings_goal_model.dart';

void main() {
  group('SavingsGoalModel', () {
    final testGoal = SavingsGoalModel(
      id: 'goal-1',
      userId: 'user-123',
      name: 'Emergency Fund',
      targetAmount: 50000.0,
      currentAmount: 25000.0,
      targetDate: DateTime(2026, 12, 31),
      icon: 'shield',
      color: '#4F46E5',
      accountId: 'acc-1',
      categoryId: 'cat-1',
      isActive: true,
      notes: '6 months living expenses',
      createdAt: DateTime(2026, 1, 1, 10, 0),
    );

    test('calculates savedPercentage and progressRatio correctly', () {
      expect(testGoal.savedPercentage, 50.0);
      expect(testGoal.progressRatio, 0.5);

      final completedGoal = testGoal.copyWith(currentAmount: 60000.0);
      expect(completedGoal.savedPercentage, 100.0);
      expect(completedGoal.progressRatio, 1.0);
      expect(completedGoal.isCompleted, isTrue);
      expect(completedGoal.isReached, isTrue);
      expect(completedGoal.remainingAmount, 0.0);

      final emptyGoal = testGoal.copyWith(currentAmount: 0.0);
      expect(emptyGoal.savedPercentage, 0.0);
      expect(emptyGoal.progressRatio, 0.0);
      expect(emptyGoal.remainingAmount, 50000.0);
      expect(emptyGoal.isCompleted, isFalse);
    });

    test('calculates remainingAmount accurately', () {
      expect(testGoal.remainingAmount, 25000.0);

      final overfunded = testGoal.copyWith(currentAmount: 70000.0);
      expect(overfunded.remainingAmount, 0.0);
    });

    test('serializes toMap and deserializes fromMap correctly', () {
      final map = testGoal.toMap();
      expect(map['id'], 'goal-1');
      expect(map['user_id'], 'user-123');
      expect(map['name'], 'Emergency Fund');
      expect(map['target_amount'], 50000.0);
      expect(map['target_date'], '2026-12-31');
      expect(map['icon'], 'shield');
      expect(map['color'], '#4F46E5');
      expect(map['account_id'], 'acc-1');
      expect(map['category_id'], 'cat-1');
      expect(map['is_active'], true);
      expect(map['notes'], '6 months living expenses');

      final deserialized = SavingsGoalModel.fromMap(map, currentAmount: 25000.0);
      expect(deserialized.id, testGoal.id);
      expect(deserialized.userId, testGoal.userId);
      expect(deserialized.name, testGoal.name);
      expect(deserialized.targetAmount, testGoal.targetAmount);
      expect(deserialized.currentAmount, 25000.0);
      expect(deserialized.targetDate, testGoal.targetDate);
      expect(deserialized.icon, testGoal.icon);
      expect(deserialized.color, testGoal.color);
      expect(deserialized.accountId, testGoal.accountId);
      expect(deserialized.categoryId, testGoal.categoryId);
      expect(deserialized.isActive, true);
      expect(deserialized.notes, testGoal.notes);
    });

    test('copyWith properly updates specified fields', () {
      final updated = testGoal.copyWith(
        name: 'Updated Fund',
        currentAmount: 30000.0,
        isActive: false,
      );

      expect(updated.name, 'Updated Fund');
      expect(updated.currentAmount, 30000.0);
      expect(updated.isActive, false);
      expect(updated.targetAmount, testGoal.targetAmount);
      expect(updated.id, testGoal.id);
    });
  });
}
