import 'budget_model.dart';

enum BudgetStatus {
  normal,
  warning,
  overBudget,
}

/// Represents live spending metrics for a budget calculated from transactions.
class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spent,
    required this.effectiveStartDate,
    required this.effectiveEndDate,
  });

  final BudgetModel budget;
  final double spent;
  final DateTime effectiveStartDate;
  final DateTime effectiveEndDate;

  /// Remaining amount until the budget limit is reached (can be negative if over budget).
  double get remaining => budget.amount - spent;

  /// Absolute deficit if over budget, 0.0 otherwise.
  double get overBudgetAmount => isOverBudget ? (spent - budget.amount) : 0.0;

  /// Percentage of the budget consumed (e.g., 80.0 for 80%, 112.5 for 112.5%).
  double get percentage =>
      budget.amount > 0 ? (spent / budget.amount) * 100 : 0.0;

  /// Ratio for progress bars (clamped between 0.0 and 1.0 for rendering standard bars).
  double get progressRatioClamped =>
      budget.amount > 0 ? (spent / budget.amount).clamp(0.0, 1.0) : 0.0;

  /// True if spending has strictly exceeded the allocated budget amount.
  bool get isOverBudget => spent > budget.amount;

  /// True if spending has reached or exceeded the warning threshold but is not yet over budget.
  bool get isWarning =>
      !isOverBudget && spent >= (budget.amount * budget.alertThreshold);

  /// Status classification for UI theming and alerts.
  BudgetStatus get status {
    if (isOverBudget) return BudgetStatus.overBudget;
    if (isWarning) return BudgetStatus.warning;
    return BudgetStatus.normal;
  }
}
