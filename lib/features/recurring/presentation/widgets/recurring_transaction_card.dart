import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../accounts/domain/models/account_model.dart';
import '../../../categories/domain/models/category_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/recurring_transaction_model.dart';

class RecurringTransactionCard extends StatelessWidget {
  const RecurringTransactionCard({
    super.key,
    required this.item,
    this.category,
    this.account,
    this.currencySymbol = '₹',
    this.onRecord,
    this.onEdit,
    this.onDelete,
    this.onToggleActive,
  });

  final RecurringTransactionModel item;
  final CategoryModel? category;
  final AccountModel? account;
  final String currencySymbol;
  final VoidCallback? onRecord;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleActive;

  Color _getCategoryColor() {
    if (category?.color != null) {
      try {
        final hex = category!.color!.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return item.isCredit ? AppColors.credit : AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,##,##0.##', 'en_IN');
    final dateFormat = DateFormat('dd MMM yyyy');
    final isDue = item.isDue();
    final categoryColor = _getCategoryColor();

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Category Icon + Description + Amount + Menu ─────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                  size: 20,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 12),

              // Description & Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (category != null)
                          Text(
                            category!.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        if (category != null && account != null)
                          Text(
                            '•',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        if (account != null)
                          Text(
                            account!.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount & Options Menu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.isCredit ? '+' : '-'}$currencySymbol${currencyFormat.format(item.amount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: item.isCredit ? AppColors.credit : AppColors.expense,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.frequency.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),

              if (onEdit != null || onDelete != null || onToggleActive != null)
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreVertical, size: 18),
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    if (val == 'edit' && onEdit != null) onEdit!();
                    if (val == 'toggle' && onToggleActive != null) {
                      onToggleActive!(!item.isActive);
                    }
                    if (val == 'delete' && onDelete != null) onDelete!();
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(LucideIcons.edit2, size: 16),
                            SizedBox(width: 8),
                            Text('Edit Template'),
                          ],
                        ),
                      ),
                    if (onToggleActive != null)
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              item.isActive
                                  ? LucideIcons.pauseCircle
                                  : LucideIcons.playCircle,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(item.isActive ? 'Pause Schedule' : 'Resume Schedule'),
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
                            Text('Delete',
                                style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // ── Bottom Schedule Info & Action Row ────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Schedule Date & Due indicator
              Row(
                children: [
                  Icon(
                    isDue ? LucideIcons.alertCircle : LucideIcons.calendar,
                    size: 14,
                    color: isDue
                        ? const Color(0xFFF59E0B)
                        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Next: ${dateFormat.format(item.nextOccurrence)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isDue ? FontWeight.bold : FontWeight.w500,
                      color: isDue
                          ? const Color(0xFFF59E0B)
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                  ),
                  if (item.autoCreate) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Auto',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Record Now CTA Button
              if (item.isActive && onRecord != null)
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(LucideIcons.checkCircle2, size: 14),
                  label: const Text('Record Now', style: TextStyle(fontSize: 11)),
                  onPressed: onRecord,
                ),

              if (!item.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Paused',
                    style: TextStyle(
                      fontSize: 11,
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
