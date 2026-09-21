import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/amount_display.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../transactions/domain/services/financial_calculation_service.dart';

class MonthlySummaryCard extends StatelessWidget {
  final FinancialSummary summary;
  final String currencySymbol;

  const MonthlySummaryCard({
    super.key,
    required this.summary,
    this.currencySymbol = '₹',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.calendar, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'This Month',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Monthly Credits Card
            Expanded(
              child: AppCard(
                color: isDark
                    ? AppColors.credit.withValues(alpha: 0.12)
                    : AppColors.creditContainerLight,
                borderColor: AppColors.credit.withValues(alpha: isDark ? 0.3 : 0.2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                borderRadius: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.arrowUpRight,
                          size: 14,
                          color: AppColors.credit,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Credits',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.credit : const Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AmountDisplay(
                      amount: summary.totalCredit,
                      currencySymbol: currencySymbol,
                      size: AmountSize.medium,
                      isCredit: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Monthly Expenses Card
            Expanded(
              child: AppCard(
                color: isDark
                    ? AppColors.expense.withValues(alpha: 0.12)
                    : AppColors.expenseContainerLight,
                borderColor: AppColors.expense.withValues(alpha: isDark ? 0.3 : 0.2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                borderRadius: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.arrowDownLeft,
                          size: 14,
                          color: AppColors.expense,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Expenses',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.expense : const Color(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AmountDisplay(
                      amount: summary.totalExpense,
                      currencySymbol: currencySymbol,
                      size: AmountSize.medium,
                      isExpense: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
