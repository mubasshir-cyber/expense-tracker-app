import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../accounts/presentation/providers/account_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../profile/presentation/providers/profile_repository_provider.dart';
import '../../transactions/presentation/providers/data_providers.dart';
import '../domain/models/recurring_transaction_model.dart';
import 'providers/recurring_providers.dart';
import 'widgets/add_edit_recurring_sheet.dart';
import 'widgets/recurring_transaction_card.dart';

class RecurringTransactionsScreen extends ConsumerStatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  ConsumerState<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends ConsumerState<RecurringTransactionsScreen> {
  int _filterTab = 0; // 0: Active, 1: Paused, 2: All

  void _openAddEditSheet([RecurringTransactionModel? itemToEdit]) {
    final profile = ref.read(userProfileProvider).value;
    final currencySymbol = profile?.currencySymbol ?? '₹';

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditRecurringSheet(
        itemToEdit: itemToEdit,
        currencySymbol: currencySymbol,
      ),
    );
  }

  Future<void> _recordOccurrence(RecurringTransactionModel item) async {
    try {
      await ref
          .read(recurringControllerProvider.notifier)
          .recordOccurrence(item);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recorded "${item.description}" into ledger. Next due date updated.',
            ),
            backgroundColor: AppColors.credit,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record transaction: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(RecurringTransactionModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Item?'),
        content: Text(
          'Are you sure you want to delete "${item.description}"? Existing ledger transactions will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(recurringControllerProvider.notifier)
          .deleteRecurring(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recurring template deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _refreshAll() {
    ref.invalidate(allRecurringTransactionsProvider);
    ref.invalidate(activeRecurringTransactionsProvider);
    ref.invalidate(upcomingRecurringProvider);
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(categoriesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider).value;
    final currencySymbol = profile?.currencySymbol ?? '₹';
    final currencyFormat = NumberFormat('#,##,##0.##', 'en_IN');

    final allListAsync = ref.watch(allRecurringTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value ?? [];
    final categoryMap = {for (var c in categories) c.id: c};

    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.value ?? [];
    final accountMap = {for (var a in accounts) a.id: a};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            tooltip: 'Refresh',
            onPressed: _refreshAll,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEditSheet(),
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshAll(),
        child: allListAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.alertCircle,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load recurring transactions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Retry',
                    onPressed: _refreshAll,
                    type: AppButtonType.primary,
                  ),
                ],
              ),
            ),
          ),
          data: (allList) {
            if (allList.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.repeat,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Recurring Transactions',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Never miss a bill or salary date! Add Netflix, Rent, Electricity, Internet, or Salary to automatically track and schedule upcoming payments.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: SizedBox(
                      width: 220,
                      child: AppButton(
                        label: 'Add First Recurring Item',
                        onPressed: () => _openAddEditSheet(),
                        type: AppButtonType.primary,
                      ),
                    ),
                  ),
                ],
              );
            }

            final activeList = allList.where((item) => item.isActive).toList();
            final pausedList = allList.where((item) => !item.isActive).toList();

            final displayedList = _filterTab == 0
                ? activeList
                : (_filterTab == 1 ? pausedList : allList);

            // Compute monthly commitment estimates
            final totalMonthlyExpense = activeList
                .where((i) => i.isExpense)
                .fold<double>(0.0, (sum, i) => sum + i.amount);
            final totalMonthlyIncome = activeList
                .where((i) => i.isCredit)
                .fold<double>(0.0, (sum, i) => sum + i.amount);

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // ── Monthly Commitments Overview Card ────────────────────────
                AppCard(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACTIVE MONTHLY SCHEDULE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scheduled Expenses',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$currencySymbol${currencyFormat.format(totalMonthlyExpense)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scheduled Income',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+$currencySymbol${currencyFormat.format(totalMonthlyIncome)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.credit,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Items',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${activeList.length}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Filter Toggle Chips ──────────────────────────────────────
                Row(
                  children: [
                    FilterChip(
                      label: Text('Active (${activeList.length})'),
                      selected: _filterTab == 0,
                      onSelected: (selected) => setState(() => _filterTab = 0),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text('Paused (${pausedList.length})'),
                      selected: _filterTab == 1,
                      onSelected: (selected) => setState(() => _filterTab = 1),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text('All (${allList.length})'),
                      selected: _filterTab == 2,
                      onSelected: (selected) => setState(() => _filterTab = 2),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── List of Recurring Cards ──────────────────────────────────
                if (displayedList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text(
                        'No items in this filter.',
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
                  ...displayedList.map((item) {
                    final category = categoryMap[item.categoryId];
                    final account = accountMap[item.accountId];

                    return RecurringTransactionCard(
                      item: item,
                      category: category,
                      account: account,
                      currencySymbol: currencySymbol,
                      onRecord: () => _recordOccurrence(item),
                      onEdit: () => _openAddEditSheet(item),
                      onDelete: () => _confirmDelete(item),
                      onToggleActive: (active) {
                        ref
                            .read(recurringControllerProvider.notifier)
                            .toggleActive(item.id, active);
                      },
                    );
                  }),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
    );
  }
}
