import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../goals/domain/models/savings_goal_model.dart';
import '../../../goals/presentation/providers/goal_providers.dart';

/// Compact savings goals card for the dashboard displaying summary stats
/// and top active goals with mini progress bars.
class DashboardSavingsGoalsCard extends ConsumerWidget {
  const DashboardSavingsGoalsCard({
    super.key,
    this.currencySymbol = '₹',
  });

  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGoalsAsync = ref.watch(activeSavingsGoalsProvider);
    final summaryAsync = ref.watch(savingsGoalsSummaryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,##,##0.##', 'en_IN');

    return activeGoalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          return const SizedBox.shrink();
        }

        final topGoals = goals.take(3).toList();
        final summary = summaryAsync.asData?.value;

        return AppCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.piggyBank,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Savings Goals',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/savings-goals'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'View All',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (summary != null) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem(
                      context,
                      label: 'Total Saved',
                      value: '$currencySymbol${currencyFormat.format(summary.totalSaved)}',
                      color: AppColors.primary,
                    ),
                    _buildSummaryItem(
                      context,
                      label: 'Target',
                      value: '$currencySymbol${currencyFormat.format(summary.totalTarget)}',
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    _buildSummaryItem(
                      context,
                      label: 'Progress',
                      value: '${summary.overallPercentage.toStringAsFixed(0)}%',
                      color: AppColors.credit,
                    ),
                  ],
                ),
              ],
              const Divider(height: 24),
              ...topGoals.map((goal) => _buildMiniGoalItem(context, goal, currencyFormat, isDark)),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniGoalItem(
    BuildContext context,
    SavingsGoalModel goal,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final color = goal.color != null
        ? Color(int.parse(goal.color!.replaceFirst('#', '0xFF')))
        : AppColors.primary;

    return InkWell(
      onTap: () => context.push('/savings-goals/${goal.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$currencySymbol${currencyFormat.format(goal.currentAmount)} / $currencySymbol${currencyFormat.format(goal.targetAmount)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progressRatio,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
