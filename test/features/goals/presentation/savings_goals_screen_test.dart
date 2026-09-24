import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/goals/domain/models/savings_goal_model.dart';
import 'package:expense_tracker/features/goals/domain/services/savings_goal_calculation_service.dart';
import 'package:expense_tracker/features/goals/presentation/providers/goal_providers.dart';
import 'package:expense_tracker/features/goals/presentation/savings_goals_screen.dart';
import 'package:expense_tracker/features/profile/domain/models/user_profile.dart';
import 'package:expense_tracker/features/profile/presentation/providers/profile_repository_provider.dart';

void main() {
  final sampleGoal = SavingsGoalModel(
    id: 'goal-1',
    userId: 'user-1',
    name: 'Emergency Fund',
    targetAmount: 50000.0,
    currentAmount: 25000.0,
    targetDate: DateTime(2026, 12, 31),
    icon: 'shield',
    color: '#4F46E5',
    createdAt: DateTime(2026, 1, 1),
  );

  final completedGoal = SavingsGoalModel(
    id: 'goal-2',
    userId: 'user-1',
    name: 'MacBook Pro',
    targetAmount: 150000.0,
    currentAmount: 150000.0,
    icon: 'laptop',
    color: '#10B981',
    createdAt: DateTime(2026, 1, 1),
  );

  Widget createWidgetUnderTest({
    List<SavingsGoalModel> activeGoals = const [],
    List<SavingsGoalModel> completedGoals = const [],
    List<SavingsGoalModel> allGoals = const [],
  }) {
    const calcService = SavingsGoalCalculationService();
    final summary = calcService.calculateSummary(allGoals);

    return ProviderScope(
      overrides: [
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(
            id: 'user-1',
            email: 'test@example.com',
            currencyCode: 'INR',
            currencySymbol: '₹',
          ),
        ),
        activeSavingsGoalsProvider.overrideWith((ref) async => activeGoals),
        completedSavingsGoalsProvider.overrideWith((ref) async => completedGoals),
        allSavingsGoalsProvider.overrideWith((ref) async => allGoals),
        savingsGoalsSummaryProvider.overrideWith((ref) async => summary),
      ],
      child: const MaterialApp(
        home: SavingsGoalsScreen(),
      ),
    );
  }

  group('SavingsGoalsScreen Widget Tests', () {
    testWidgets('renders empty state when no goals exist', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Savings Goals'), findsOneWidget);
      expect(find.text('No Savings Goals Yet'), findsOneWidget);
      expect(find.text('Create First Goal'), findsOneWidget);
    });

    testWidgets('renders goals list and summary metrics correctly', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          activeGoals: [sampleGoal],
          completedGoals: [completedGoal],
          allGoals: [sampleGoal, completedGoal],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Savings Goals'), findsOneWidget);
      expect(find.text('Emergency Fund'), findsOneWidget);
      expect(find.text('PORTFOLIO SAVINGS'), findsOneWidget);
      expect(find.text('Active (1)'), findsOneWidget);
      expect(find.text('Reached (1)'), findsOneWidget);

      // Switch to Reached tab
      await tester.tap(find.text('Reached (1)'));
      await tester.pumpAndSettle();

      expect(find.text('MacBook Pro'), findsOneWidget);
    });
  });
}
