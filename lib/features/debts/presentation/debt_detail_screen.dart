import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../accounts/presentation/providers/account_providers.dart';
import '../../profile/presentation/providers/profile_repository_provider.dart';
import '../domain/models/debt_model.dart';
import '../domain/models/debt_type.dart';
import '../domain/models/interest_type.dart';
import 'providers/debt_providers.dart';
import 'widgets/add_edit_debt_sheet.dart';
import 'widgets/record_repayment_sheet.dart';

/// Comprehensive detail screen for an individual debt or loan.
class DebtDetailScreen extends ConsumerWidget {
  const DebtDetailScreen({
    super.key,
    required this.debtId,
  });

  final String debtId;

  void _showEditSheet(BuildContext context, DebtModel debt) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditDebtSheet(debtToEdit: debt),
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Debt Record?'),
        content: const Text(
          'Are you sure you want to delete this record? All payment ledger entries and schedules will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(debtControllerProvider.notifier).deleteDebt(debtId);
      if (context.mounted) {
        context.pop();
      }
    }
  }

  Future<void> _confirmDeleteRepayment(
    BuildContext context,
    WidgetRef ref,
    String repaymentId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment Record?'),
        content: const Text('Are you sure you want to delete this payment entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(debtControllerProvider.notifier).deleteRepayment(repaymentId, debtId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatter = NumberFormat('#,##,##0.##', 'en_IN');

    final debtAsync = ref.watch(debtDetailProvider(debtId));
    final profileAsync = ref.watch(userProfileProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final currencySymbol = profileAsync.value?.currencySymbol ?? '₹';

    final accountMap = <String, String>{};
    if (accountsAsync.hasValue) {
      for (final acc in accountsAsync.value!) {
        accountMap[acc.id] = acc.name;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(debtAsync.value?.personName ?? 'Debt Details'),
        actions: [
          if (debtAsync.hasValue && debtAsync.value != null) ...[
            IconButton(
              icon: const Icon(LucideIcons.pencil, size: 19),
              tooltip: 'Edit',
              onPressed: () => _showEditSheet(context, debtAsync.value!),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 19, color: AppColors.error),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ],
      ),
      body: debtAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                const Text('Failed to load debt details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Retry',
                  type: AppButtonType.secondary,
                  onPressed: () => ref.invalidate(debtDetailProvider(debtId)),
                ),
              ],
            ),
          ),
        ),
        data: (debt) {
          if (debt == null) {
            return const Center(child: Text('Debt record not found'));
          }

          final isYouOwe = debt.type == DebtType.youOwe;
          final typeColor = isYouOwe ? AppColors.error : AppColors.credit;
          final isOverdue = debt.isOverdue();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(debtDetailProvider(debtId));
              ref.invalidate(debtInstallmentsProvider(debtId));
              ref.invalidate(debtRepaymentsProvider(debtId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // ── 1. Hero Debt Summary Card ────────────────────────────────
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(debt.type.icon, size: 13, color: typeColor),
                                const SizedBox(width: 4),
                                Text(
                                  debt.type.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: typeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (debt.isSettled)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.credit.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Settled',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.credit,
                                ),
                              ),
                            )
                          else if (isOverdue)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Overdue (${debt.daysOverdue}d)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            )
                          else if (debt.dueDate != null)
                            Text(
                              'Due ${DateFormat('dd MMM yyyy').format(debt.dueDate!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'REMAINING OUTSTANDING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currencySymbol${formatter.format(debt.remainingAmount)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: debt.progressRatio,
                          minHeight: 8,
                          backgroundColor: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            debt.isSettled ? AppColors.credit : typeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Paid: $currencySymbol${formatter.format(debt.totalPaid)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${debt.progressPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Total: $currencySymbol${formatter.format(debt.totalRepaymentAmount)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 2. Interest & Breakdown Card ─────────────────────────────
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INTEREST & COMPOSITION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context,
                        label: 'Principal Amount',
                        value: '$currencySymbol${formatter.format(debt.principalAmount)}',
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        context,
                        label: 'Interest Calculation',
                        value: debt.interestType.label,
                      ),
                      if (debt.interestType == InterestType.percentage) ...[
                        const Divider(height: 16),
                        _buildDetailRow(
                          context,
                          label: 'Interest Rate',
                          value: '${debt.interestRate.toStringAsFixed(1)}%',
                        ),
                      ],
                      const Divider(height: 16),
                      _buildDetailRow(
                        context,
                        label: 'Interest Amount',
                        value: '$currencySymbol${formatter.format(debt.interestAmount)}',
                        valueColor: AppColors.primary,
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        context,
                        label: 'Total Expected Repayment',
                        value: '$currencySymbol${formatter.format(debt.totalRepaymentAmount)}',
                        isBold: true,
                      ),
                      if (debt.contactNumber != null) ...[
                        const Divider(height: 16),
                        _buildDetailRow(
                          context,
                          label: 'Contact Number',
                          value: debt.contactNumber!,
                        ),
                      ],
                      if (debt.notes != null && debt.notes!.isNotEmpty) ...[
                        const Divider(height: 16),
                        _buildDetailRow(
                          context,
                          label: 'Notes',
                          value: debt.notes!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 3. Quick Action Buttons ──────────────────────────────────
                if (!debt.isSettled) ...[
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _showRecordPaymentSheet(
                            context,
                            debt,
                            currencySymbol,
                          ),
                          icon: const Icon(LucideIcons.plusCircle, size: 18),
                          label: Text(isYouOwe ? 'Record Repayment' : 'Receive Payment'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // ── 4. Repayment Schedule (Installments) ──────────────────────
                if (debt.installments.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'REPAYMENT SCHEDULE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      Text(
                        '${debt.installments.where((i) => i.isPaid).length} of ${debt.installments.length} Paid',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...debt.installments.map((inst) {
                    final isInstOverdue = inst.isOverdue();
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: inst.isPaid
                                  ? AppColors.credit.withValues(alpha: 0.12)
                                  : (inst.isPartial
                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04))),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: inst.isPaid
                                  ? const Icon(LucideIcons.check, size: 16, color: AppColors.credit)
                                  : Text(
                                      '#${inst.installmentNumber}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Due: ${DateFormat('dd MMM yyyy').format(inst.dueDate)}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    if (isInstOverdue) ...[
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Overdue',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Principal: $currencySymbol${formatter.format(inst.principalDue)}  •  Interest: $currencySymbol${formatter.format(inst.interestDue)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$currencySymbol${formatter.format(inst.totalDue)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: inst.isPaid
                                      ? AppColors.credit.withValues(alpha: 0.1)
                                      : (inst.isPartial
                                          ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                                          : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04))),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  inst.status.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: inst.isPaid
                                        ? AppColors.credit
                                        : (inst.isPartial ? const Color(0xFFF59E0B) : (isDark ? Colors.white70 : Colors.black54)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // ── 5. Payment Ledger History ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PAYMENT HISTORY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    Text(
                      '${debt.repayments.length} Payments',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (debt.repayments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'No payments recorded yet.\nTap "Record Repayment" to log transactions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ),
                  )
                else
                  ...debt.repayments.map((r) {
                    final accName = r.accountId != null ? accountMap[r.accountId!] : null;
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.credit.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.arrowDownLeft, color: AppColors.credit, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('dd MMMM yyyy').format(r.repaymentDate),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  r.notes?.isNotEmpty == true
                                      ? r.notes!
                                      : (accName != null ? 'Via $accName' : 'Direct Payment'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$currencySymbol${formatter.format(r.amount)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.credit,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash, size: 16, color: Colors.grey),
                            tooltip: 'Delete Payment',
                            onPressed: () => _confirmDeleteRepayment(context, ref, r.id),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
        ),
      ],
    );
  }
}
