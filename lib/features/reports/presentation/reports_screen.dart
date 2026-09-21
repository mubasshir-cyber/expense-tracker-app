import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/models/financial_report.dart';
import 'providers/reports_providers.dart';
import 'widgets/account_breakdown.dart';
import 'widgets/category_breakdown.dart';
import 'widgets/expense_pie_chart.dart';
import 'widgets/financial_overview_card.dart';
import 'widgets/income_expense_chart.dart';
import 'widgets/period_selector.dart';
import 'widgets/statistics_card.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(financialReportProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 0,
            title: const Text('Reports & Analytics'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: () {
                  ref.invalidate(reportTransactionsProvider);
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const PeriodSelector(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
        body: reportAsync.when(
          loading: () => const _LoadingState(),
          error: (error, _) => _ErrorState(
            onRetry: () => ref.invalidate(reportTransactionsProvider),
          ),
          data: (report) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(reportTransactionsProvider);
              // Wait for the new data to load
              await ref.read(financialReportProvider.future);
            },
            child: report.isEmpty
                ? const _EmptyState()
                : _ReportContent(report: report, ref: ref),
          ),
        ),
      ),
    );
  }
}

// ─── Content ─────────────────────────────────────────────────────────────────

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.report, required this.ref});

  final FinancialReport report;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(reportFilterProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Financial Overview ──────────────────────────────────────────────
        _SectionHeader(title: 'Financial Overview'),
        FinancialOverviewCard(report: report, filter: filter),
        const SizedBox(height: 24),

        // ── Credits vs Expenses trend chart ────────────────────────────────
        _SectionHeader(title: 'Credits vs Expenses'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: IncomeExpenseChart(
            report: report,
            granularity: filter.granularity,
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _LegendDot(color: AppColors.credit),
              const SizedBox(width: 4),
              const Text('Credits', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.expense),
              const SizedBox(width: 4),
              const Text('Expenses', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Expense Statistics ──────────────────────────────────────────────
        _SectionHeader(title: 'Expense Statistics'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StatisticsCard(
            title: 'Expense Summary',
            average: report.averageExpense,
            largest: report.largestExpense,
            count: report.expenseCount,
            isExpense: true,
          ),
        ),
        const SizedBox(height: 24),

        // ── Credit Statistics ───────────────────────────────────────────────
        _SectionHeader(title: 'Credit Statistics'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StatisticsCard(
            title: 'Credit Summary',
            average: report.averageCredit,
            largest: report.largestCredit,
            count: report.creditCount,
            isExpense: false,
          ),
        ),
        const SizedBox(height: 24),

        // ── Expense Categories pie chart ────────────────────────────────────
        if (report.expenseCategories.isNotEmpty) ...[
          _SectionHeader(title: 'Expense Categories'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ExpensePieChart(
              categories: report.expenseCategories,
              totalExpenses: report.totalExpenses,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Expense Category Breakdown list ────────────────────────────────
        _SectionHeader(title: 'Expense Breakdown'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CategoryBreakdown(
            categories: report.expenseCategories,
            title: 'Expenses',
            isExpense: true,
          ),
        ),
        const SizedBox(height: 24),

        // ── Credit Category Breakdown list ─────────────────────────────────
        _SectionHeader(title: 'Income Breakdown'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CategoryBreakdown(
            categories: report.creditCategories,
            title: 'Credits',
            isExpense: false,
          ),
        ),
        const SizedBox(height: 24),

        // ── Account Breakdown ───────────────────────────────────────────────
        _SectionHeader(title: 'Account Activity'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AccountBreakdown(accounts: report.accountSummaries),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ─── Loading State ────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shimmer = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ShimmerBlock(height: 120, color: shimmer),
        const SizedBox(height: 16),
        _ShimmerBlock(height: 220, color: shimmer),
        const SizedBox(height: 16),
        _ShimmerBlock(height: 80, color: shimmer),
        const SizedBox(height: 16),
        _ShimmerBlock(height: 160, color: shimmer),
      ],
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({required this.height, required this.color});
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.expense.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load reports',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            Text(
              'No financial activity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different date range\nor add a transaction.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
