import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_status.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_type.dart';
import 'package:expense_tracker/features/debts/domain/models/interest_type.dart';
import 'package:expense_tracker/features/debts/domain/services/debt_calculation_service.dart';
import 'package:expense_tracker/features/debts/presentation/debts_screen.dart';
import 'package:expense_tracker/features/debts/presentation/providers/debt_providers.dart';
import 'package:expense_tracker/features/profile/domain/models/user_profile.dart';
import 'package:expense_tracker/features/profile/presentation/providers/profile_repository_provider.dart';

void main() {
  final sampleLoan = DebtModel(
    id: 'debt-1',
    userId: 'user-1',
    type: DebtType.youAreOwed,
    personName: 'Amaan',
    principalAmount: 50000.0,
    interestType: InterestType.percentage,
    interestRate: 20.0,
    interestAmount: 10000.0,
    totalRepaymentAmount: 60000.0,
    totalPaid: 25000.0,
    dueDate: DateTime(2026, 10, 30),
    status: DebtStatus.active,
    createdAt: DateTime(2026, 1, 1),
  );

  final sampleDebt = DebtModel(
    id: 'debt-2',
    userId: 'user-1',
    type: DebtType.youOwe,
    personName: 'Bank of India',
    principalAmount: 40000.0,
    totalRepaymentAmount: 40000.0,
    totalPaid: 10000.0,
    dueDate: DateTime(2026, 11, 15),
    status: DebtStatus.active,
    createdAt: DateTime(2026, 1, 1),
  );

  Widget createWidgetUnderTest({
    List<DebtModel> debts = const [],
  }) {
    const calcService = DebtCalculationService();
    final summary = calcService.calculateSummary(debts);

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
        allDebtsProvider.overrideWith((ref) async => debts),
        debtSummaryProvider.overrideWith((ref) async => summary),
      ],
      child: const MaterialApp(
        home: DebtsScreen(),
      ),
    );
  }

  group('DebtsScreen Widget Tests', () {
    testWidgets('renders empty state when no debts exist', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Debts & Loans'), findsOneWidget);
      expect(find.text('No Debts or Loans Yet'), findsOneWidget);
      expect(find.text('Add First Debt / Loan'), findsOneWidget);
    });

    testWidgets('renders debts list and summary portfolio banner correctly', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          debts: [sampleLoan, sampleDebt],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Debts & Loans'), findsOneWidget);
      expect(find.text('Amaan'), findsOneWidget);
      expect(find.text('Bank of India'), findsOneWidget);
      expect(find.text('PORTFOLIO POSITION'), findsOneWidget);
      expect(find.text('You Are Owed (Asset)'), findsOneWidget);
      expect(find.text('You Owe (Liability)'), findsOneWidget);

      // Verify filter tabs
      expect(find.text('Active (2)'), findsOneWidget);
      expect(find.text('You Owe (1)'), findsOneWidget);
      expect(find.text('You Are Owed (1)'), findsOneWidget);

      // Tap You Owe tab
      await tester.tap(find.text('You Owe (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Bank of India'), findsOneWidget);
      expect(find.text('Amaan'), findsNothing);
    });
  });
}
