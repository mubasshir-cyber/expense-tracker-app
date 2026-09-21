/// Aggregated financial activity for a single category within a report period.
class CategoryExpenseSummary {
  const CategoryExpenseSummary({
    required this.categoryId,
    required this.categoryName,
    required this.total,
    required this.count,
    required this.percentage,
  });

  final String categoryId;
  final String categoryName;

  /// Sum of transaction amounts for this category.
  final double total;

  /// Number of transactions in this category.
  final int count;

  /// Percentage of the relevant total (e.g., total expenses or total credits).
  /// Range: 0.0 – 100.0. Never NaN.
  final double percentage;

  @override
  String toString() =>
      'CategoryExpenseSummary($categoryName: $total, ${percentage.toStringAsFixed(1)}%)';
}
