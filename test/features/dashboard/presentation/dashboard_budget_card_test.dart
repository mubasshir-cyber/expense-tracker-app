import 'package:expense_tracker/features/budgets/domain/models/budget_model.dart';
import 'package:expense_tracker/features/budgets/domain/models/budget_period.dart';
import 'package:expense_tracker/features/budgets/domain/models/budget_progress.dart';
import 'package:expense_tracker/features/budgets/presentation/providers/budget_providers.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/dashboard_budget_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testBudget = BudgetModel(
    id: 'b-overall',
    userId: 'user-1',
    name: 'Overall Monthly Budget',
    amount: 25000.0,
    period: BudgetPeriod.monthly,
    startDate: DateTime(2026, 9, 1),
  );

  final testProgress = BudgetProgress(
    budget: testBudget,
    spent: 18500.0,
    effectiveStartDate: DateTime(2026, 9, 1),
    effectiveEndDate: DateTime(2026, 9, 30),
  );

  group('DashboardBudgetCard', () {
    testWidgets('renders prompt when no active budgets exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBudgetsProgressProvider.overrideWith(
              (ref) async => [],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardBudgetCard(currencySymbol: '₹'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set Spending Budgets'), findsOneWidget);
      expect(find.text('Track limits and avoid overspending.'), findsOneWidget);
    });

    testWidgets('renders active budgets meters when budgets exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBudgetsProgressProvider.overrideWith(
              (ref) async => [testProgress],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardBudgetCard(currencySymbol: '₹'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budgets & Spending Limits'), findsOneWidget);
      expect(find.text('See All (1)'), findsOneWidget);
      expect(find.text('Overall Monthly Budget'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
