import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/customer_ledger_models.dart';

class KhataSummaryCard extends StatelessWidget {
  const KhataSummaryCard({
    super.key,
    required this.summary,
    this.currencySymbol = '₹',
  });

  final KhataOverallSummary summary;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.bookOpen,
                  size: 20,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL RECEIVABLE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$currencySymbol ${currencyFormat.format(summary.totalReceivableDue)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricItem(
                label: 'Customers',
                value: '${summary.totalCustomers}',
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              _MetricItem(
                label: 'Due Pending',
                value: '${summary.activeCustomersWithDue}',
                color: AppColors.error,
              ),
              _MetricItem(
                label: 'Settled',
                value: '${summary.settledCustomersCount}',
                color: AppColors.credit,
              ),
              if (summary.advanceCustomersCount > 0)
                _MetricItem(
                  label: 'Advance',
                  value: '$currencySymbol${currencyFormat.format(summary.totalAdvances)}',
                  color: AppColors.primary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
