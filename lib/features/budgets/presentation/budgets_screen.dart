import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../profile/presentation/providers/profile_repository_provider.dart';
import '../../transactions/presentation/providers/data_providers.dart';
import '../domain/models/budget_model.dart';
import 'providers/budget_providers.dart';
import 'widgets/add_edit_budget_sheet.dart';
import 'widgets/budget_card.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  bool _showActiveOnly = true;

  void _openAddEditSheet([BudgetModel? budgetToEdit]) {
    final profile = ref.read(userProfileProvider).value;
    final currencySymbol = profile?.currencySymbol ?? '₹';

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditBudgetSheet(
        budgetToEdit: budgetToEdit,
        currencySymbol: currencySymbol,
      ),
    );
  }

  Future<void> _confirmDelete(BudgetModel budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: Text('Are you sure you want to delete "${budget.name}"?'),
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
      await ref.read(budgetControllerProvider.notifier).deleteBudget(budget.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _refreshAll() {
    ref.invalidate(allBudgetsProvider);
    ref.invalidate(activeBudgetsProvider);
    ref.invalidate(activeBudgetsProgressProvider);
    ref.invalidate(allTransactionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider).value;
    final currencySymbol = profile?.currencySymbol ?? '₹';
    final currencyFormat = NumberFormat('#,##,##0.##', 'en_IN');

    final budgetsListAsync = _showActiveOnly
        ? ref.watch(activeBudgetsProvider)
        : ref.watch(allBudgetsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value ?? [];
    final categoryMap = {for (var c in categories) c.id: c};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets & Spending Limits'),
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
        child: budgetsListAsync.when(
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
                    'Failed to load budgets',
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
          data: (budgets) {
            if (budgets.isEmpty) {
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
                        LucideIcons.wallet,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Budgets Set Yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take control of your spending! Set overall monthly limits or category-specific budgets to track your financial health in real-time.',
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
                      width: 200,
                      child: AppButton(
                        label: 'Create First Budget',
                        onPressed: () => _openAddEditSheet(),
                        type: AppButtonType.primary,
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // ── Summary Overview Card ────────────────────────────────────
                Consumer(
                  builder: (context, ref, child) {
                    final progressListAsync =
                        ref.watch(activeBudgetsProgressProvider);
                    final progressList = progressListAsync.value ?? [];
                    if (progressList.isEmpty) return const SizedBox.shrink();

                    final totalLimit = progressList.fold<double>(
                      0.0,
                      (sum, p) => sum + p.budget.amount,
                    );
                    final totalSpent = progressList.fold<double>(
                      0.0,
                      (sum, p) => sum + p.spent,
                    );
                    final totalRemaining = totalLimit - totalSpent;

                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTIVE BUDGETS SUMMARY',
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
                                    'Total Budget',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.textMutedDark
                                          : AppColors.textMutedLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$currencySymbol${currencyFormat.format(totalLimit)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Spent',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.textMutedDark
                                          : AppColors.textMutedLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$currencySymbol${currencyFormat.format(totalSpent)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: totalSpent > totalLimit
                                          ? AppColors.expense
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Remaining',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.textMutedDark
                                          : AppColors.textMutedLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$currencySymbol${currencyFormat.format(totalRemaining)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: totalRemaining < 0
                                          ? AppColors.expense
                                          : AppColors.credit,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // ── Filter Toggle Chips ──────────────────────────────────────
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Active Budgets'),
                      selected: _showActiveOnly,
                      onSelected: (selected) {
                        setState(() => _showActiveOnly = true);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('All Budgets'),
                      selected: !_showActiveOnly,
                      onSelected: (selected) {
                        setState(() => _showActiveOnly = false);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Budgets Cards List ───────────────────────────────────────
                ...budgets.map((budget) {
                  return Consumer(
                    builder: (context, ref, child) {
                      final progressAsync =
                          ref.watch(budgetProgressFamily(budget));

                      return progressAsync.when(
                        loading: () => AppCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: const SizedBox(
                            height: 80,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        error: (e, _) => AppCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Text('Error loading progress: $e'),
                        ),
                        data: (progress) {
                          final category = budget.categoryId != null
                              ? categoryMap[budget.categoryId]
                              : null;

                          return BudgetCard(
                            progress: progress,
                            category: category,
                            currencySymbol: currencySymbol,
                            onEdit: () => _openAddEditSheet(budget),
                            onDelete: () => _confirmDelete(budget),
                            onToggleActive: (active) {
                              ref
                                  .read(budgetControllerProvider.notifier)
                                  .toggleBudgetActive(budget.id, active);
                            },
                          );
                        },
                      );
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
