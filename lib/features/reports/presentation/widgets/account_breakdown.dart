import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/models/account_summary.dart';

/// Per-account financial activity breakdown.
class AccountBreakdown extends StatelessWidget {
  const AccountBreakdown({
    super.key,
    required this.accounts,
  });

  final List<AccountSummary> accounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (accounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'No data for this period',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }

    return Column(
      children: accounts.map((acc) => _AccountRow(account: acc)).toList(),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});
  final AccountSummary account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    final net = account.netActivity;
    final netColor = net >= 0 ? AppColors.credit : AppColors.expense;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account name row
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  account.accountName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${account.transactionCount} txn${account.transactionCount == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AccountMetric(
                  label: 'Credits',
                  value: currency.format(account.totalCredits),
                  color: AppColors.credit,
                ),
              ),
              Expanded(
                child: _AccountMetric(
                  label: 'Expenses',
                  value: currency.format(account.totalExpenses),
                  color: AppColors.expense,
                ),
              ),
              Expanded(
                child: _AccountMetric(
                  label: 'Net',
                  value: '${net >= 0 ? '+' : '-'}${currency.format(net.abs())}',
                  color: netColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountMetric extends StatelessWidget {
  const _AccountMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
