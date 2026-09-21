import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/models/category_expense_summary.dart';

/// Pie chart showing expense category distribution.
class ExpensePieChart extends StatefulWidget {
  const ExpensePieChart({
    super.key,
    required this.categories,
    required this.totalExpenses,
  });

  final List<CategoryExpenseSummary> categories;
  final double totalExpenses;

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty || widget.totalExpenses <= 0) {
      return _emptyState(context);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Cap to top-N categories; group remainder as "Others"
    final topCats = _buildDisplayList(widget.categories);

    return Row(
      children: [
        // Pie chart
        SizedBox(
          height: 180,
          width: 180,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.touchedSection == null) {
                    setState(() => _touchedIndex = -1);
                    return;
                  }
                  setState(() {
                    _touchedIndex =
                        response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: topCats.asMap().entries.map((entry) {
                final i = entry.key;
                final cat = entry.value;
                final isSelected = i == _touchedIndex;
                return PieChartSectionData(
                  color: AppColors
                      .categoryPalette[i % AppColors.categoryPalette.length],
                  value: cat.total,
                  title: isSelected
                      ? '${cat.percentage.toStringAsFixed(1)}%'
                      : '',
                  radius: isSelected ? 58 : 48,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Legend
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: topCats.asMap().entries.map((entry) {
              final i = entry.key;
              final cat = entry.value;
              final color = AppColors
                  .categoryPalette[i % AppColors.categoryPalette.length];
              final isSelected = i == _touchedIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cat.categoryName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? theme.colorScheme.onSurface
                              : isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${cat.percentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<CategoryExpenseSummary> _buildDisplayList(
      List<CategoryExpenseSummary> cats) {
    const maxSlices = 6;
    if (cats.length <= maxSlices) return cats;

    final top = cats.take(maxSlices - 1).toList();
    final rest = cats.skip(maxSlices - 1).toList();
    final otherTotal = rest.fold(0.0, (s, c) => s + c.total);
    final otherPct = widget.totalExpenses > 0
        ? (otherTotal / widget.totalExpenses) * 100.0
        : 0.0;

    return [
      ...top,
      CategoryExpenseSummary(
        categoryId: '__others__',
        categoryName: 'Others',
        total: otherTotal,
        count: rest.fold(0, (s, c) => s + c.count),
        percentage: otherPct,
      ),
    ];
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 36,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 8),
            Text(
              'No expense data',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
