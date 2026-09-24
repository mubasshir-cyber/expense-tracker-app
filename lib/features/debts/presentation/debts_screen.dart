import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../profile/presentation/providers/profile_repository_provider.dart';
import '../domain/models/debt_model.dart';
import '../domain/models/debt_type.dart';
import 'providers/debt_providers.dart';
import 'widgets/add_edit_debt_sheet.dart';
import 'widgets/debt_card.dart';
import 'widgets/record_repayment_sheet.dart';

/// Main debts & loans dashboard screen with summary banner and filter tabs.
class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  int _selectedFilterIndex = 0; // 0: All Active, 1: You Owe, 2: You Are Owed, 3: Settled

  void _showAddDebtSheet(BuildContext context, {DebtType? initialType}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditDebtSheet(initialType: initialType),
    );
  }

  void _showRecordPaymentSheet(BuildContext context, DebtModel debt, String currencySymbol) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecordRepaymentSheet(
        debt: debt,
        currencySymbol: currencySymbol,
      ),
    );
  }

  List<DebtModel> _filterDebts(List<DebtModel> debts) {
    switch (_selectedFilterIndex) {
      case 0: // All Active (not settled)
        return debts.where((d) => !d.isSettled).toList();
      case 1: // You Owe (Active liabilities)
        return debts.where((d) => d.type == DebtType.youOwe && !d.isSettled).toList();
      case 2: // You Are Owed (Active assets)
        return debts.where((d) => d.type == DebtType.youAreOwed && !d.isSettled).toList();
      case 3: // Settled
        return debts.where((d) => d.isSettled).toList();
      default:
        return debts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatter = NumberFormat('#,##,##0.##', 'en_IN');

    final debtsAsync = ref.watch(allDebtsProvider);
    final summaryAsync = ref.watch(debtSummaryProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final currencySymbol = profileAsync.value?.currencySymbol ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debts & Loans'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, size: 22),
            tooltip: 'Add Debt / Loan',
            onPressed: () => _showAddDebtSheet(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allDebtsProvider);
          ref.invalidate(debtSummaryProvider);
        },
        child: debtsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load debts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Retry',
                    type: AppButtonType.secondary,
                    onPressed: () => ref.invalidate(allDebtsProvider),
                  ),
                ],
              ),
            ),
          ),
          data: (allDebts) {
            if (allDebts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(32.0),
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.handCoins,
                        size: 44,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Debts or Loans Yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track money you owe to others and money lent to friends, family, or institutions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: AppButton(
                      label: 'Add First Debt / Loan',
                      type: AppButtonType.primary,
                      icon: LucideIcons.plus,
                      isFullWidth: false,
                      onPressed: () => _showAddDebtSheet(context),
                    ),
                  ),
                ],
              );
            }

            final summary = summaryAsync.asData?.value;
            final filteredDebts = _filterDebts(allDebts);

            final totalYouAreOwed = summary?.totalYouAreOwed ?? 0.0;
            final totalYouOwe = summary?.totalYouOwe ?? 0.0;
            final netPosition = summary?.netPosition ?? 0.0;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // ── Summary Header Banner ───────────────────────────────────
                AppCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PORTFOLIO POSITION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Net Balance',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${netPosition >= 0 ? '+' : ''}$currencySymbol${formatter.format(netPosition)}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: netPosition >= 0
                                      ? AppColors.credit
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          if (summary != null && summary.overdueCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.alertCircle,
                                      size: 14, color: AppColors.error),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${summary.overdueCount} Overdue',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniStat(
                            context,
                            label: 'You Are Owed (Asset)',
                            value: '$currencySymbol${formatter.format(totalYouAreOwed)}',
                            color: AppColors.credit,
                          ),
                          _buildMiniStat(
                            context,
                            label: 'You Owe (Liability)',
                            value: '$currencySymbol${formatter.format(totalYouOwe)}',
                            color: AppColors.error,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Filter Chips ─────────────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(
                          'Active (${allDebts.where((d) => !d.isSettled).length})',
                        ),
                        selected: _selectedFilterIndex == 0,
                        onSelected: (_) => setState(() => _selectedFilterIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(
                          'You Owe (${allDebts.where((d) => d.type == DebtType.youOwe && !d.isSettled).length})',
                        ),
                        selected: _selectedFilterIndex == 1,
                        onSelected: (_) => setState(() => _selectedFilterIndex = 1),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(
                          'You Are Owed (${allDebts.where((d) => d.type == DebtType.youAreOwed && !d.isSettled).length})',
                        ),
                        selected: _selectedFilterIndex == 2,
                        onSelected: (_) => setState(() => _selectedFilterIndex = 2),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(
                          'Settled (${allDebts.where((d) => d.isSettled).length})',
                        ),
                        selected: _selectedFilterIndex == 3,
                        onSelected: (_) => setState(() => _selectedFilterIndex = 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Debts List ───────────────────────────────────────────────
                if (filteredDebts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Text(
                        _selectedFilterIndex == 3
                            ? 'No settled debts or loans yet.'
                            : 'No records matching this filter.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredDebts.map(
                    (debt) => DebtCard(
                      debt: debt,
                      currencySymbol: currencySymbol,
                      onRecordPayment: () => _showRecordPaymentSheet(
                        context,
                        debt,
                        currencySymbol,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
