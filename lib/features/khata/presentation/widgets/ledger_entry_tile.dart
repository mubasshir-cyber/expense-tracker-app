import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/customer_ledger_models.dart';

class LedgerEntryTile extends StatelessWidget {
  const LedgerEntryTile({
    super.key,
    required this.item,
    this.currencySymbol = '₹',
    this.onEdit,
    this.onDelete,
  });

  final CustomerLedgerItem item;
  final String currencySymbol;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final entry = item.entry;

    final isGiven = entry.isGiven;
    final amountColor = isGiven ? AppColors.error : AppColors.credit;
    final sign = isGiven ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                // Type Icon
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: amountColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isGiven ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                    size: 16,
                    color: amountColor,
                  ),
                ),
                const SizedBox(width: 10),

                // Description & Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.description?.trim().isNotEmpty == true
                                  ? entry.description!
                                  : (isGiven ? 'Given (Credit)' : 'Payment Received'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (entry.isOpeningBalance) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Opening',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('d MMMM yyyy').format(entry.entryDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Entry Amount
                Text(
                  '$sign $currencySymbol${currencyFormat.format(entry.amount)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),

                // Menu button (if editable/deletable)
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    onSelected: (action) {
                      if (action == 'edit') onEdit?.call();
                      if (action == 'delete') onDelete?.call();
                    },
                    itemBuilder: (ctx) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(LucideIcons.pencil, size: 16),
                              SizedBox(width: 8),
                              Text('Edit Entry'),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Delete Entry', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 6),

            // Running Balance Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Running Balance',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
                Text(
                  item.runningBalance == 0
                      ? 'Settled'
                      : '$currencySymbol ${currencyFormat.format(item.runningBalance.abs())} ${item.runningBalance > 0 ? "Due" : "Advance"}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: item.runningBalance > 0.005
                        ? AppColors.error
                        : (item.runningBalance < -0.005 ? AppColors.primary : AppColors.credit),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
