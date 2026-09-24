import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/customer_ledger_models.dart';

class CustomerBalanceCard extends StatelessWidget {
  const CustomerBalanceCard({
    super.key,
    required this.summary,
    this.currencySymbol = '₹',
    required this.onAddGiven,
    required this.onAddReceived,
  });

  final CustomerBalanceSummary summary;
  final String currencySymbol;
  final VoidCallback onAddGiven;
  final VoidCallback onAddReceived;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

    final String titleText;
    final Color mainColor;
    final String statusSubtitle;

    if (summary.isSettled) {
      titleText = 'ACCOUNT SETTLED';
      mainColor = AppColors.credit;
      statusSubtitle = 'No pending balance';
    } else if (summary.isDue) {
      titleText = 'CURRENT DUE';
      mainColor = AppColors.error;
      statusSubtitle = 'Customer owes you';
    } else {
      titleText = 'ADVANCE BALANCE';
      mainColor = AppColors.primary;
      statusSubtitle = 'Customer has prepaid';
    }

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titleText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: mainColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusSubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: mainColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Main Balance
          Text(
            '$currencySymbol ${currencyFormat.format(summary.absoluteBalance)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: mainColor,
            ),
          ),
          const SizedBox(height: 16),

          // Sub-totals (Total Given vs Total Received)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Given',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+ $currencySymbol${currencyFormat.format(summary.totalGiven)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 28,
                  width: 1,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Received',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '- $currencySymbol${currencyFormat.format(summary.totalReceived)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.credit,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons: + GIVEN & + RECEIVED
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('add_given_button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onAddGiven,
                  icon: const Icon(LucideIcons.arrowUpRight, size: 18),
                  label: const Text(
                    '+ GIVEN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('add_received_button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.credit,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onAddReceived,
                  icon: const Icon(LucideIcons.arrowDownLeft, size: 18),
                  label: const Text(
                    '+ RECEIVED',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
