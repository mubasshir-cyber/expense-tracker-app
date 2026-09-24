import '../models/debt_installment_model.dart';
import '../models/debt_model.dart';
import '../models/debt_summary.dart';
import '../models/debt_type.dart';
import '../models/interest_type.dart';

/// Pure domain calculation service for debt/loan metrics, interest computation,
/// installment generation, repayment allocation, and portfolio summary.
class DebtCalculationService {
  const DebtCalculationService();

  /// Calculates the interest amount based on interest type, rate, and flat amount.
  double calculateInterestAmount(
    double principal,
    InterestType interestType, {
    double rate = 0.0,
    double fixedAmount = 0.0,
  }) {
    if (principal <= 0) return 0.0;
    switch (interestType) {
      case InterestType.none:
        return 0.0;
      case InterestType.percentage:
        return (principal * (rate / 100.0));
      case InterestType.fixed:
        return fixedAmount > 0 ? fixedAmount : 0.0;
    }
  }

  /// Calculates total expected repayment = principal + interest.
  double calculateTotalRepayment(double principal, double interestAmount) {
    final p = principal > 0 ? principal : 0.0;
    final i = interestAmount > 0 ? interestAmount : 0.0;
    return p + i;
  }

  /// Generates a monthly installment schedule for a debt/loan.
  List<DebtInstallmentModel> generateInstallments({
    required String debtId,
    required String userId,
    required double principal,
    required double interestAmount,
    required int installmentCount,
    required DateTime startDate,
  }) {
    if (installmentCount <= 0) return [];

    final totalRepayment = principal + interestAmount;
    final baseTotalDue = (totalRepayment / installmentCount);
    final basePrincipalDue = (principal / installmentCount);
    final baseInterestDue = (interestAmount / installmentCount);

    final list = <DebtInstallmentModel>[];

    for (var i = 1; i <= installmentCount; i++) {
      // Advance month-by-month
      final yearOffset = (startDate.month + (i - 1) - 1) ~/ 12;
      final targetMonth = ((startDate.month + (i - 1) - 1) % 12) + 1;
      final targetYear = startDate.year + yearOffset;
      final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
      final targetDay = startDate.day > daysInTargetMonth ? daysInTargetMonth : startDate.day;
      final dueDate = DateTime(targetYear, targetMonth, targetDay);

      list.add(
        DebtInstallmentModel(
          id: '${debtId}_inst_$i',
          debtId: debtId,
          userId: userId,
          installmentNumber: i,
          dueDate: dueDate,
          principalDue: double.parse(basePrincipalDue.toStringAsFixed(2)),
          interestDue: double.parse(baseInterestDue.toStringAsFixed(2)),
          totalDue: double.parse(baseTotalDue.toStringAsFixed(2)),
          paidAmount: 0.0,
          status: InstallmentStatus.pending,
        ),
      );
    }

    return list;
  }

  /// Allocates a repayment amount sequentially across pending or partial installments.
  List<DebtInstallmentModel> allocateRepaymentToInstallments(
    List<DebtInstallmentModel> currentInstallments,
    double repaymentAmount,
  ) {
    if (currentInstallments.isEmpty || repaymentAmount <= 0) {
      return currentInstallments;
    }

    // Sort by installment number
    final sorted = List<DebtInstallmentModel>.from(currentInstallments)
      ..sort((a, b) => a.installmentNumber.compareTo(b.installmentNumber));

    var remainingToAllocate = repaymentAmount;
    final updatedList = <DebtInstallmentModel>[];

    for (final inst in sorted) {
      if (inst.isPaid || remainingToAllocate <= 0) {
        updatedList.add(inst);
        continue;
      }

      final neededForThis = inst.totalDue - inst.paidAmount;
      if (remainingToAllocate >= neededForThis) {
        // Fully pay this installment
        updatedList.add(
          inst.copyWith(
            paidAmount: inst.totalDue,
            status: InstallmentStatus.paid,
          ),
        );
        remainingToAllocate -= neededForThis;
      } else {
        // Partially pay this installment
        final newPaid = inst.paidAmount + remainingToAllocate;
        updatedList.add(
          inst.copyWith(
            paidAmount: newPaid,
            status: InstallmentStatus.partial,
          ),
        );
        remainingToAllocate = 0.0;
      }
    }

    return updatedList;
  }

  /// Computes total portfolio summary metrics across all debts and loans.
  DebtSummary computeSummary(List<DebtModel> debts, {DateTime? asOfDate}) {
    var totalYouAreOwed = 0.0;
    var totalYouOwe = 0.0;
    var activeOweCount = 0;
    var activeOwedCount = 0;
    var settledCount = 0;
    var overdueCount = 0;

    for (final debt in debts) {
      if (debt.isSettled) {
        settledCount++;
        continue;
      }

      final isOverdue = debt.isOverdue(asOfDate: asOfDate);
      if (isOverdue) {
        overdueCount++;
      }

      if (debt.type == DebtType.youAreOwed) {
        totalYouAreOwed += debt.remainingAmount;
        activeOwedCount++;
      } else {
        totalYouOwe += debt.remainingAmount;
        activeOweCount++;
      }
    }

    return DebtSummary(
      totalYouAreOwed: totalYouAreOwed,
      totalYouOwe: totalYouOwe,
      activeOweCount: activeOweCount,
      activeOwedCount: activeOwedCount,
      settledCount: settledCount,
      overdueCount: overdueCount,
    );
  }

  /// Alias for computeSummary
  DebtSummary calculateSummary(List<DebtModel> debts, {DateTime? asOfDate}) =>
      computeSummary(debts, asOfDate: asOfDate);
}
