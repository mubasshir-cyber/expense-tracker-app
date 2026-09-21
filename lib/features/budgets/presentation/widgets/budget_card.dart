import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../categories/domain/models/category_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/budget_progress.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.progress,
    this.category,
    this.currencySymbol = '₹',
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleActive,
  });

  final BudgetProgress progress;
  final CategoryModel? category;
  final String currencySymbol;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleActive;

  Color _getStatusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.overBudget:
        return AppColors.expense;
      case BudgetStatus.warning:
        return const Color(0xFFF59E0B); // Amber warning
      case BudgetStatus.normal:
        return AppColors.credit; // Emerald green
    }
  }

  Color _getCategoryColor() {
    if (category?.color != null) {
      try {
        final hex = category!.color!.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final budget = progress.budget;
    final statusColor = _getStatusColor(progress.status);
    final currencyFormat = NumberFormat('#,##,##0.##', 'en_IN');

    final categoryColor = _getCategoryColor();
    final isOverall = budget.isOverallBudget;

    return AppCard(
      onTap: onTap ?? onEdit,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: Icon + Name + Period Chip + Menu ──────────────────
          Row(
            children: [
              // Icon Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isOverall
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isOverall ? LucideIcons.wallet : LucideIcons.tag,
                  size: 20,
                  color: isOverall ? AppColors.primary : categoryColor,
                ),
              ),
              const SizedBox(width: 12),
              // Name + Scope
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            budget.period.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                        if (!isOverall && category != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              category!.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Options Menu
              if (onEdit != null || onDelete != null || onToggleActive != null)
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreVertical, size: 18),
                  onSelected: (value) {
                    if (value == 'edit' && onEdit != null) onEdit!();
                    if (value == 'toggle' && onToggleActive != null) {
                      onToggleActive!(!budget.isActive);
                    }
                    if (value == 'delete' && onDelete != null) onDelete!();
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(LucideIcons.edit2, size: 16),
                            SizedBox(width: 8),
                            Text('Edit Budget'),
                          ],
                        ),
                      ),
                    if (onToggleActive != null)
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              budget.isActive
                                  ? LucideIcons.pauseCircle
                                  : LucideIcons.playCircle,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(budget.isActive ? 'Deactivate' : 'Activate'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(LucideIcons.trash2,
                                size: 16, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete Budget',
                                style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Spent vs Target Amount Row ────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$currencySymbol${currencyFormat.format(progress.spent)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    ' / $currencySymbol${currencyFormat.format(budget.amount)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              // Percentage Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${progress.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Linear Progress Indicator ─────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.progressRatioClamped,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 10),

          // ── Remaining / Over-Budget Status Row ────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (progress.isOverBudget)
                Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle,
                        size: 14, color: AppColors.expense),
                    const SizedBox(width: 4),
                    Text(
                      'Over budget by $currencySymbol${currencyFormat.format(progress.overBudgetAmount)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.expense,
                      ),
                    ),
                  ],
                )
              else if (progress.isWarning)
                Row(
                  children: [
                    const Icon(LucideIcons.alertCircle,
                        size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      '${(budget.alertThreshold * 100).toInt()}% threshold reached ($currencySymbol${currencyFormat.format(progress.remaining)} left)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  '$currencySymbol${currencyFormat.format(progress.remaining)} remaining',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),

              if (!budget.isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Paused',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
