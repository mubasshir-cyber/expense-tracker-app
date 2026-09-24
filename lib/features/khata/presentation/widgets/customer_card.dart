import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/customer_ledger_models.dart';

class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.summary,
    this.currencySymbol = '₹',
    required this.onTap,
  });

  final CustomerBalanceSummary summary;
  final String currencySymbol;
  final VoidCallback onTap;

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'C';
    final parts = clean.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final customer = summary.customer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            // Initials Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                _getInitials(customer.name),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Customer Name & Phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.phone,
                        size: 13,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        customer.phone,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Balance & Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (summary.isSettled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.credit.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Settled',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.credit,
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$currencySymbol ${currencyFormat.format(summary.absoluteBalance)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: summary.isDue ? AppColors.error : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        summary.isDue ? 'Due' : 'Advance',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: summary.isDue ? AppColors.error : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                if (summary.lastEntryDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMM').format(summary.lastEntryDate!),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ],
        ),
      ),
    );
  }
}
