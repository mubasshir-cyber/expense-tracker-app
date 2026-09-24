import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/goals/domain/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/domain/models/savings_goal_model.dart';
import 'package:expense_tracker/features/goals/presentation/goal_detail_screen.dart';
import 'package:expense_tracker/features/goals/presentation/providers/goal_providers.dart';
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

  final sampleContributions = [
    GoalContributionModel(
      id: 'c1',
      goalId: 'goal-1',
      userId: 'user-1',
      amount: 25000.0,
      contributionDate: DateTime(2026, 1, 15),
      notes: 'Initial allocation',
      createdAt: DateTime(2026, 1, 15),
    ),
  ];

  Widget createWidgetUnderTest({
    SavingsGoalModel? goal,
    List<GoalContributionModel> contributions = const [],
  }) {
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
        goalDetailProvider('goal-1').overrideWith((ref) async => goal),
        goalContributionsProvider('goal-1').overrideWith((ref) async => contributions),
      ],
      child: const MaterialApp(
        home: GoalDetailScreen(goalId: 'goal-1'),
      ),
    );
  }

  group('GoalDetailScreen Widget Tests', () {
    testWidgets('renders goal details, action buttons and history', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          goal: sampleGoal,
          contributions: sampleContributions,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Emergency Fund'), findsWidgets);
      expect(find.text('Add Money'), findsOneWidget);
      expect(find.text('Withdraw'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Initial allocation'), findsOneWidget);
    });

    testWidgets('shows empty history indicator when no contributions exist', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          goal: sampleGoal,
          contributions: [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No deposits or withdrawals logged yet'), findsOneWidget);
    });
  });
}
