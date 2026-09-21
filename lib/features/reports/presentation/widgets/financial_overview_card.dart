import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/amount_display.dart';
import '../../domain/models/financial_report.dart';
import '../../domain/models/report_period.dart';
import '../providers/reports_providers.dart';

/// Comprehensive financial overview displaying Opening Balance, Inflow, Outflow, and Closing Balance.
class FinancialOverviewCard extends StatelessWidget {
  const FinancialOverviewCard({
    super.key,
    required this.report,
    required this.filter,
  });

  final FinancialReport report;
  final ReportFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String periodLabel;
    if (filter.period == ReportPeriod.custom) {
      final isSingle = filter.startDate.year == filter.endDate.year &&
          filter.startDate.month == filter.endDate.month &&
          filter.startDate.day == filter.endDate.day;
      periodLabel = isSingle
          ? _fmt(filter.startDate)
          : '${_fmt(filter.startDate)} – ${_fmt(filter.endDate)}';
    } else {
      periodLabel = filter.period.label;
    }

    final String openingLabel;
    final String closingLabel;
    if (filter.period == ReportPeriod.today) {
      openingLabel = 'Yesterday Close';
      closingLabel = 'Today Close';
    } else if (filter.period == ReportPeriod.yesterday) {
      openingLabel = 'Opening';
      closingLabel = 'Yesterday Close';
    } else if (filter.period == ReportPeriod.thisMonth) {
      openingLabel = 'Month Opening';
      closingLabel = 'Closing Balance';
    } else {
      openingLabel = 'Opening Balance';
      closingLabel = 'Closing Balance';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                periodLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: report.netCashFlow >= 0
                      ? AppColors.credit.withValues(alpha: 0.12)
                      : AppColors.expense.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  report.netCashFlow >= 0 ? 'Net Positive' : 'Net Negative',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: report.netCashFlow >= 0
                        ? AppColors.credit
                        : AppColors.expense,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Opening → Closing Balance Flow Card ─────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.surfaceDark,
                        AppColors.surfaceVariantDark,
                      ]
                    : [
                        theme.colorScheme.surface,
                        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Opening Balance
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            openingLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AmountDisplay(
                            amount: report.openingBalance,
                            size: AmountSize.medium,
                          ),
                        ],
                      ),
                    ),
                    // Arrow / Flow Indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            report.netCashFlow >= 0
                                ? '+₹${report.netCashFlow.toStringAsFixed(0)}'
                                : '-₹${report.netCashFlow.abs().toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: report.netCashFlow >= 0
                                  ? AppColors.credit
                                  : AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Closing Balance
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            closingLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AmountDisplay(
                            amount: report.closingBalance,
                            size: AmountSize.medium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── Inflow / Outflow Grid ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Credits (Inflow)',
                      color: AppColors.credit,
                      containerColor: isDark
                          ? AppColors.creditContainerDark
                          : AppColors.creditContainerLight,
                      child: AmountDisplay(
                        amount: report.totalCredits,
                        isCredit: true,
                        size: AmountSize.medium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Expenses (Outflow)',
                      color: AppColors.expense,
                      containerColor: isDark
                          ? AppColors.expenseContainerDark
                          : AppColors.expenseContainerLight,
                      child: AmountDisplay(
                        amount: report.totalExpenses,
                        isExpense: true,
                        size: AmountSize.medium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Net Period Flow',
                      color: report.netCashFlow >= 0
                          ? AppColors.credit
                          : AppColors.expense,
                      containerColor: report.netCashFlow >= 0
                          ? (isDark
                              ? AppColors.creditContainerDark
                              : AppColors.creditContainerLight)
                          : (isDark
                              ? AppColors.expenseContainerDark
                              : AppColors.expenseContainerLight),
                      child: AmountDisplay(
                        amount: report.netCashFlow,
                        showSign: true,
                        size: AmountSize.medium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Transactions',
                      color: theme.colorScheme.primary,
                      containerColor: isDark
                          ? AppColors.primaryContainerDark
                          : AppColors.primaryContainerLight,
                      child: Text(
                        '${report.transactionCount}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) => DateFormat('d MMM yy').format(d);
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.color,
    required this.containerColor,
    required this.child,
  });

  final String label;
  final Color color;
  final Color containerColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
