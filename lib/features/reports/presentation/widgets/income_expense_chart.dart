import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/models/financial_report.dart';
import '../../domain/models/report_granularity.dart';

/// Credits vs Expenses line chart using fl_chart.
class IncomeExpenseChart extends StatefulWidget {
  const IncomeExpenseChart({
    super.key,
    required this.report,
    required this.granularity,
  });

  final FinancialReport report;
  final ReportGranularity granularity;

  @override
  State<IncomeExpenseChart> createState() => _IncomeExpenseChartState();
}

class _IncomeExpenseChartState extends State<IncomeExpenseChart> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.report.trendPoints.isEmpty) {
      return _emptyState(context);
    }

    final points = widget.report.trendPoints;

    // Build FlSpots for credits and expenses
    final creditSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      creditSpots.add(FlSpot(i.toDouble(), points[i].credits));
      expenseSpots.add(FlSpot(i.toDouble(), points[i].expenses));
    }

    final maxY = points
        .expand((p) => [p.credits, p.expenses])
        .fold(0.0, (a, b) => a > b ? a : b);

    final effectiveMaxY = maxY <= 0 ? 1000.0 : maxY * 1.2;

    final creditColor =
        isDark ? const Color(0xFF34D399) : AppColors.credit;
    final expenseColor =
        isDark ? const Color(0xFFF87171) : AppColors.expense;
    final gridColor = (isDark ? AppColors.borderDark : AppColors.borderLight)
        .withValues(alpha: 0.5);
    final labelColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: effectiveMaxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: gridColor,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 56,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Text(
                      _shortAmount(value),
                      style: TextStyle(
                        fontSize: 10,
                        color: labelColor,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: _bottomInterval(points.length).toDouble(),
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= points.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _dateLabel(points[i].date, widget.granularity),
                        style: TextStyle(
                          fontSize: 10,
                          color: labelColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight,
                getTooltipItems: (spots) {
                  return spots.map((spot) {
                    final isCredit = spot.barIndex == 0;
                    final color = isCredit ? creditColor : expenseColor;
                    final label = isCredit ? 'Credits' : 'Expenses';
                    return LineTooltipItem(
                      '$label\n₹ ${NumberFormat('#,##0', 'en_IN').format(spot.y)}',
                      TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              // Credits line
              LineChartBarData(
                spots: creditSpots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: creditColor,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: points.length <= 10,
                  getDotPainter: (spot, pct, bar, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: creditColor,
                    strokeWidth: 2,
                    strokeColor: theme.colorScheme.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: creditColor.withValues(alpha: 0.08),
                ),
              ),
              // Expenses line
              LineChartBarData(
                spots: expenseSpots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: expenseColor,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: points.length <= 10,
                  getDotPainter: (spot, pct, bar, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: expenseColor,
                    strokeWidth: 2,
                    strokeColor: theme.colorScheme.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: expenseColor.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 40,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 8),
            Text(
              'No data for this period',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _bottomInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 31) return 5;
    if (count <= 52) return 4;
    return (count / 6).ceil();
  }

  String _dateLabel(DateTime date, ReportGranularity granularity) {
    switch (granularity) {
      case ReportGranularity.daily:
        return DateFormat('d/M').format(date);
      case ReportGranularity.weekly:
        return 'W${_weekOfYear(date)}';
      case ReportGranularity.monthly:
        return DateFormat('MMM').format(date);
    }
  }

  int _weekOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    return ((date.difference(startOfYear).inDays) / 7).ceil() + 1;
  }

  String _shortAmount(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }
}
