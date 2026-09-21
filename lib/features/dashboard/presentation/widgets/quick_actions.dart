import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onAddExpense;
  final VoidCallback onAddCredit;

  const QuickActions({
    super.key,
    required this.onAddExpense,
    required this.onAddCredit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Add Expense Button
            Expanded(
              child: AppCard(
                onTap: onAddExpense,
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                borderRadius: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.expenseContainerLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.minus,
                        size: 16,
                        color: AppColors.expense,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Add Expense',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.expense,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Add Credit Button
            Expanded(
              child: AppCard(
                onTap: onAddCredit,
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                borderRadius: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.creditContainerLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.plus,
                        size: 16,
                        color: AppColors.credit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Add Credit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.credit,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
