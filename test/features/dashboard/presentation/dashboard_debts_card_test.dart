import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/dashboard_debts_card.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_status.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_type.dart';
import 'package:expense_tracker/features/debts/domain/services/debt_calculation_service.dart';
import 'package:expense_tracker/features/debts/presentation/providers/debt_providers.dart';

void main() {
  final sampleDebt = DebtModel(
    id: 'debt-1',
    userId: 'user-1',
    type: DebtType.youAreOwed,
    personName: 'Amaan',
    principalAmount: 50000.0,
    totalRepaymentAmount: 60000.0,
    totalPaid: 25000.0,
    status: DebtStatus.active,
    createdAt: DateTime(2026, 1, 1),
  );

  Widget createWidgetUnderTest({
    List<DebtModel> debts = const [],
  }) {
    const calc = DebtCalculationService();
    final summary = calc.calculateSummary(debts);

    return ProviderScope(
      overrides: [
        allDebtsProvider.overrideWith((ref) async => debts),
        debtSummaryProvider.overrideWith((ref) async => summary),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: DashboardDebtsCard(),
        ),
      ),
    );
  }

  group('DashboardDebtsCard Widget Tests', () {
    testWidgets('renders nothing (SizedBox.shrink) when no debts exist', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(debts: []));
      await tester.pumpAndSettle();

      expect(find.text('Debts & Loans'), findsNothing);
    });

    testWidgets('renders debts card and summary metrics when debts exist', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(debts: [sampleDebt]));
      await tester.pumpAndSettle();

      expect(find.text('Debts & Loans'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
      expect(find.text('You Are Owed'), findsOneWidget);
      expect(find.text('Amaan'), findsOneWidget);
      expect(find.text('Receive'), findsOneWidget);
    });
  });
}
