import 'package:expense_tracker/features/budgets/domain/models/budget_model.dart';
import 'package:expense_tracker/features/budgets/domain/models/budget_period.dart';
import 'package:expense_tracker/features/budgets/domain/models/budget_progress.dart';
import 'package:expense_tracker/features/budgets/presentation/budgets_screen.dart';
import 'package:expense_tracker/features/budgets/presentation/providers/budget_providers.dart';
import 'package:expense_tracker/features/categories/domain/models/category_model.dart';
import 'package:expense_tracker/features/profile/domain/models/user_profile.dart';
import 'package:expense_tracker/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:expense_tracker/features/transactions/presentation/providers/data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testBudget = BudgetModel(
    id: 'budget-1',
    userId: 'user-1',
    categoryId: 'cat-food',
    name: 'Food & Groceries',
    amount: 5000.0,
    period: BudgetPeriod.monthly,
    startDate: DateTime(2026, 9, 1),
    alertThreshold: 0.80,
    isActive: true,
  );

  final testProgress = BudgetProgress(
    budget: testBudget,
    spent: 4000.0, // 80% warning
    effectiveStartDate: DateTime(2026, 9, 1),
    effectiveEndDate: DateTime(2026, 9, 30),
  );

  final testCategory = CategoryModel(
    id: 'cat-food',
    userId: 'user-1',
    name: 'Food & Dining',
    type: 'EXPENSE',
    color: '#10B981',
    isActive: true,
  );

  Widget createTestWidget({List<BudgetModel> budgets = const []}) {
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
        activeBudgetsProvider.overrideWith(
          (ref) async => budgets,
        ),
        allBudgetsProvider.overrideWith(
          (ref) async => budgets,
        ),
        categoriesProvider.overrideWith(
          (ref) async => [testCategory],
        ),
        budgetProgressFamily(testBudget).overrideWith(
          (ref) async => testProgress,
        ),
        activeBudgetsProgressProvider.overrideWith(
          (ref) async => budgets.isNotEmpty ? [testProgress] : [],
        ),
      ],
      child: const MaterialApp(
        home: BudgetsScreen(),
      ),
    );
  }

  group('BudgetsScreen Widget Tests', () {
    testWidgets('renders empty state when no budgets exist', (tester) async {
      await tester.pumpWidget(createTestWidget(budgets: []));
      await tester.pumpAndSettle();

      expect(find.text('Budgets & Spending Limits'), findsOneWidget);
      expect(find.text('No Budgets Set Yet'), findsOneWidget);
      expect(find.text('Create First Budget'), findsOneWidget);
    });

    testWidgets('renders active budgets list and progress cards', (tester) async {
      await tester.pumpWidget(createTestWidget(budgets: [testBudget]));
      await tester.pumpAndSettle();

      expect(find.text('Budgets & Spending Limits'), findsOneWidget);
      expect(find.text('Food & Groceries'), findsOneWidget);
      expect(find.text('Active Budgets'), findsOneWidget);
      expect(find.text('All Budgets'), findsOneWidget);
      expect(find.text('ACTIVE BUDGETS SUMMARY'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('floating action button opens AddEditBudgetSheet modal', (tester) async {
      await tester.pumpWidget(createTestWidget(budgets: [testBudget]));
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('Set New Budget'), findsOneWidget);
      expect(find.text('Overall Budget'), findsOneWidget);
      expect(find.text('Category Budget'), findsOneWidget);
      expect(find.text('Create Budget'), findsOneWidget);
    });
  });
}
