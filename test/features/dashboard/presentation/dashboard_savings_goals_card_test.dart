import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/dashboard_savings_goals_card.dart';
import 'package:expense_tracker/features/goals/domain/models/savings_goal_model.dart';
import 'package:expense_tracker/features/goals/domain/services/savings_goal_calculation_service.dart';
import 'package:expense_tracker/features/goals/presentation/providers/goal_providers.dart';

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

  Widget createWidgetUnderTest({
    List<SavingsGoalModel> activeGoals = const [],
  }) {
    const calcService = SavingsGoalCalculationService();
    final summary = calcService.calculateSummary(activeGoals);

    return ProviderScope(
      overrides: [
        activeSavingsGoalsProvider.overrideWith((ref) async => activeGoals),
        savingsGoalsSummaryProvider.overrideWith((ref) async => summary),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: DashboardSavingsGoalsCard(currencySymbol: '₹'),
        ),
      ),
    );
  }

  group('DashboardSavingsGoalsCard Widget Tests', () {
    testWidgets('renders nothing when active goals list is empty', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(activeGoals: []));
      await tester.pumpAndSettle();

      expect(find.text('Savings Goals'), findsNothing);
    });

    testWidgets('renders summary and mini goals when goals are active', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(activeGoals: [sampleGoal]));
      await tester.pumpAndSettle();

      expect(find.text('Savings Goals'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
      expect(find.text('Total Saved'), findsOneWidget);
      expect(find.text('Emergency Fund'), findsOneWidget);
    });
  });
}
