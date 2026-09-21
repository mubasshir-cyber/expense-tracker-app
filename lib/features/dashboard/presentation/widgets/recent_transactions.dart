import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/amount_display.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../accounts/domain/models/account_model.dart';
import '../../../categories/domain/models/category_model.dart';
import '../../../transactions/domain/models/transaction_model.dart';

class RecentTransactions extends StatelessWidget {
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
  final String currencySymbol;
  final VoidCallback onSeeAll;
  final VoidCallback onAddExpense;
  final VoidCallback onAddCredit;

  const RecentTransactions({
    super.key,
    required this.transactions,
    this.categories = const [],
    this.accounts = const [],
    this.currencySymbol = '₹',
    required this.onSeeAll,
    required this.onAddExpense,
    required this.onAddCredit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categoryMap = {for (final c in categories) c.id: c};
    final accountMap = {for (final a in accounts) a.id: a};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
            if (transactions.isNotEmpty)
              InkWell(
                onTap: onSeeAll,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          _buildEmptyState(context, isDark)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final category = categoryMap[tx.categoryId];
              final account = accountMap[tx.accountId];
              final isCredit = tx.type.toUpperCase() == 'CREDIT';
              final formattedDate = DateFormat('d MMM yyyy').format(tx.transactionDate);

              return AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                borderRadius: 14,
                child: Row(
                  children: [
                    // Category Icon Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCredit
                            ? AppColors.creditContainerLight
                            : AppColors.expenseContainerLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                        size: 20,
                        color: isCredit ? AppColors.credit : AppColors.expense,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title, description & date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category?.name ?? 'General',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (tx.description != null && tx.description!.trim().isNotEmpty)
                                tx.description!.trim(),
                              if (account != null) account.name,
                              formattedDate,
                            ].join(' • '),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Amount
                    AmountDisplay(
                      amount: tx.amount,
                      currencySymbol: currencySymbol,
                      isCredit: isCredit,
                      isExpense: !isCredit,
                      showSign: true,
                      size: AmountSize.medium,
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      borderRadius: 16,
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.receiptText,
                size: 32,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start tracking your finances\nby adding your first transaction.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Add Expense',
                    onPressed: onAddExpense,
                    type: AppButtonType.outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Add Credit',
                    onPressed: onAddCredit,
                    type: AppButtonType.primary,
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
