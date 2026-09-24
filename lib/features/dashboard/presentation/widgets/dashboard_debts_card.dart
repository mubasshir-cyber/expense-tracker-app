import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../debts/domain/models/debt_model.dart';
import '../../../debts/domain/models/debt_type.dart';
import '../../../debts/presentation/providers/debt_providers.dart';

/// Compact debts & loans card for the dashboard displaying summary stats
/// (You Are Owed, You Owe, Net Position) and top active debts.
class DashboardDebtsCard extends ConsumerWidget {
  const DashboardDebtsCard({
    super.key,
    this.currencySymbol = '₹',
  });

  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDebtsAsync = ref.watch(allDebtsProvider);
    final summaryAsync = ref.watch(debtSummaryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,##,##0.##', 'en_IN');

    return allDebtsAsync.when(
      data: (debts) {
        if (debts.isEmpty) {
          return const SizedBox.shrink();
        }

        final activeDebts = debts.where((d) => !d.status.isClosed).toList();
        final displayDebts = (activeDebts.isNotEmpty ? activeDebts : debts).take(3).toList();
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
                          LucideIcons.arrowLeftRight,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Debts & Loans',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/debts'),
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
                      label: 'You Are Owed',
                      value: '$currencySymbol${currencyFormat.format(summary.totalYouAreOwedRemaining)}',
                      color: AppColors.credit,
                    ),
                    _buildSummaryItem(
                      context,
                      label: 'You Owe',
                      value: '$currencySymbol${currencyFormat.format(summary.totalYouOweRemaining)}',
                      color: AppColors.expense,
                    ),
                    _buildSummaryItem(
                      context,
                      label: 'Net Position',
                      value: '${summary.netPosition >= 0 ? '+' : ''}$currencySymbol${currencyFormat.format(summary.netPosition)}',
                      color: summary.netPosition >= 0 ? AppColors.credit : AppColors.expense,
                    ),
                  ],
                ),
              ],
              const Divider(height: 24),
              ...displayDebts.map((debt) => _buildMiniDebtItem(context, debt, currencyFormat, isDark)),
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

  Widget _buildMiniDebtItem(
    BuildContext context,
    DebtModel debt,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final isOwed = debt.type == DebtType.youAreOwed;
    final badgeColor = isOwed ? AppColors.credit : AppColors.expense;

    return InkWell(
      onTap: () => context.push('/debts/${debt.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          debt.personName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isOwed ? 'Receive' : 'Pay',
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$currencySymbol${currencyFormat.format(debt.remainingAmount)} left',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: debt.isOverdue() ? AppColors.expense : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: debt.progressRatio,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
