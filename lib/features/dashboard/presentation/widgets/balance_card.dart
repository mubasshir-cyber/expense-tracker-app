import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/amount_display.dart';
import '../../../../core/widgets/app_card.dart';

class BalanceCard extends StatelessWidget {
  final double netBalance;
  final double totalCredits;
  final double totalExpenses;
  final String currencySymbol;

  const BalanceCard({
    super.key,
    required this.netBalance,
    required this.totalCredits,
    required this.totalExpenses,
    this.currencySymbol = '₹',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      padding: const EdgeInsets.all(20.0),
      borderRadius: 20,
      elevation: isDark ? 0 : 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Balance',
            style: AppTypography.lightTextTheme.titleSmall?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          AmountDisplay(
            amount: netBalance,
            currencySymbol: currencySymbol,
            size: AmountSize.large,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Total Credits
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.creditContainerLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.arrowUpRight,
                          size: 16,
                          color: AppColors.credit,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Credits',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                            AmountDisplay(
                              amount: totalCredits,
                              currencySymbol: currencySymbol,
                              size: AmountSize.small,
                              isCredit: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                const SizedBox(width: 12),
                // Total Expenses
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.expenseContainerLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.arrowDownLeft,
                          size: 16,
                          color: AppColors.expense,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expenses',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                            AmountDisplay(
                              amount: totalExpenses,
                              currencySymbol: currencySymbol,
                              size: AmountSize.small,
                              isExpense: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
