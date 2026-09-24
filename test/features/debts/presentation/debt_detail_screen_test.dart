import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_installment_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_repayment_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_status.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_type.dart';
import 'package:expense_tracker/features/debts/domain/models/interest_type.dart';
import 'package:expense_tracker/features/debts/presentation/debt_detail_screen.dart';
import 'package:expense_tracker/features/debts/presentation/providers/debt_providers.dart';
import 'package:expense_tracker/features/profile/domain/models/user_profile.dart';
import 'package:expense_tracker/features/profile/presentation/providers/profile_repository_provider.dart';

void main() {
  final sampleDebt = DebtModel(
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
    notes: 'Project funding',
    createdAt: DateTime(2026, 1, 1),
    installments: [
      DebtInstallmentModel(
        id: 'inst-1',
        debtId: 'debt-1',
        userId: 'user-1',
        installmentNumber: 1,
        dueDate: DateTime(2026, 10, 10),
        principalDue: 8333.33,
        interestDue: 1666.67,
        totalDue: 10000.0,
        paidAmount: 10000.0,
        status: InstallmentStatus.paid,
      ),
      DebtInstallmentModel(
        id: 'inst-2',
        debtId: 'debt-1',
        userId: 'user-1',
        installmentNumber: 2,
        dueDate: DateTime(2026, 11, 10),
        principalDue: 8333.33,
        interestDue: 1666.67,
        totalDue: 10000.0,
        paidAmount: 5000.0,
        status: InstallmentStatus.partial,
      ),
    ],
    repayments: [
      DebtRepaymentModel(
        id: 'rep-1',
        debtId: 'debt-1',
        userId: 'user-1',
        amount: 15000.0,
        repaymentDate: DateTime(2026, 10, 15),
        notes: 'First payment received',
        createdAt: DateTime(2026, 10, 15),
      ),
    ],
  );

  Widget createWidgetUnderTest({
    DebtModel? debt,
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
        debtDetailProvider('debt-1').overrideWith((ref) async => debt),
      ],
      child: const MaterialApp(
        home: DebtDetailScreen(debtId: 'debt-1'),
      ),
    );
  }

  group('DebtDetailScreen Widget Tests', () {
    testWidgets('renders debt details, breakdown metrics, and action buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest(debt: sampleDebt));
      await tester.pumpAndSettle();

      expect(find.text('Amaan'), findsWidgets);
      expect(find.text('Receive Payment'), findsOneWidget);
      expect(find.text('REMAINING OUTSTANDING'), findsOneWidget);
      expect(find.text('Principal Amount'), findsWidgets);
      expect(find.text('Interest Calculation'), findsWidgets);
      expect(find.text('Total Expected Repayment'), findsWidgets);
      expect(find.text('REPAYMENT SCHEDULE'), findsOneWidget);
      expect(find.text('PAYMENT HISTORY'), findsOneWidget);
      expect(find.text('First payment received'), findsOneWidget);
    });

    testWidgets('shows error state when debt is not found', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(debt: null));
      await tester.pumpAndSettle();

      expect(find.text('Debt record not found'), findsOneWidget);
    });
  });
}
