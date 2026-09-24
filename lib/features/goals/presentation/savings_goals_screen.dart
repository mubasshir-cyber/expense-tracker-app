import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../profile/presentation/providers/profile_repository_provider.dart';
import '../domain/models/savings_goal_model.dart';
import 'providers/goal_providers.dart';
import 'widgets/add_edit_goal_sheet.dart';
import 'widgets/deposit_withdraw_sheet.dart';
import 'widgets/savings_goal_card.dart';

class SavingsGoalsScreen extends ConsumerStatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  ConsumerState<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends ConsumerState<SavingsGoalsScreen> {
  int _selectedFilterIndex = 0; // 0: Active, 1: Completed, 2: All

  void _showAddGoalSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddEditGoalSheet(),
    );
  }

  void _showDepositSheet(BuildContext context, SavingsGoalModel goal, String currencySymbol) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DepositWithdrawSheet(
        goal: goal,
        isDeposit: true,
        currencySymbol: currencySymbol,
      ),
    );
  }

  List<SavingsGoalModel> _filterGoals(List<SavingsGoalModel> goals) {
    switch (_selectedFilterIndex) {
      case 0: // Active (not completed and isActive)
        return goals.where((g) => !g.isCompleted && g.isActive).toList();
      case 1: // Completed / Reached
        return goals.where((g) => g.isCompleted).toList();
      case 2: // All
      default:
        return goals;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatter = NumberFormat('#,##,##0.##', 'en_IN');

    final goalsAsync = ref.watch(allSavingsGoalsProvider);
    final summaryAsync = ref.watch(savingsGoalsSummaryProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final currencySymbol = profileAsync.value?.currencySymbol ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, size: 22),
            tooltip: 'New Goal',
            onPressed: () => _showAddGoalSheet(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allSavingsGoalsProvider);
          ref.invalidate(activeSavingsGoalsProvider);
          ref.invalidate(savingsGoalsSummaryProvider);
        },
        child: goalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.alertCircle,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load savings goals',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Retry',
                    type: AppButtonType.secondary,
                    onPressed: () {
                      ref.invalidate(allSavingsGoalsProvider);
                    },
                  ),
                ],
              ),
            ),
          ),
          data: (allGoals) {
            final summary = summaryAsync.value;
            final filteredList = _filterGoals(allGoals);

            if (allGoals.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(32.0),
                children: [
                  const SizedBox(height: 60),
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.piggyBank,
                        size: 44,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Savings Goals Yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set up financial targets for vacations, emergency funds, tech upgrades, or future investments.',
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
                      label: 'Create First Goal',
                      type: AppButtonType.primary,
                      icon: LucideIcons.plus,
                      isFullWidth: false,
                      onPressed: () => _showAddGoalSheet(context),
                    ),
                  ),
                ],
              );
            }

            final totalSavedFormatted =
                '$currencySymbol${formatter.format(summary?.totalSaved ?? 0.0)}';
            final totalTargetFormatted =
                '$currencySymbol${formatter.format(summary?.totalTarget ?? 0.0)}';

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // ── Summary Overview Banner ──────────────────────────────────
                AppCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PORTFOLIO SAVINGS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                          Text(
                            '${(summary?.overallPercentage ?? 0.0).toInt()}% of target',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.credit,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        totalSavedFormatted,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total target across active goals: $totalTargetFormatted',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: summary?.overallProgressRatio ?? 0.0,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.06),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.credit,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Filter Tabs ──────────────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(
                          'Active (${allGoals.where((g) => !g.isCompleted && g.isActive).length})',
                        ),
                        selected: _selectedFilterIndex == 0,
                        onSelected: (_) =>
                            setState(() => _selectedFilterIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(
                          'Reached (${allGoals.where((g) => g.isCompleted).length})',
                        ),
                        selected: _selectedFilterIndex == 1,
                        onSelected: (_) =>
                            setState(() => _selectedFilterIndex = 1),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('All (${allGoals.length})'),
                        selected: _selectedFilterIndex == 2,
                        onSelected: (_) =>
                            setState(() => _selectedFilterIndex = 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Goals List ───────────────────────────────────────────────
                if (filteredList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Text(
                        _selectedFilterIndex == 1
                            ? 'No goals reached yet. Keep saving!'
                            : 'No goals in this filter.',
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
                  for (final goal in filteredList)
                    SavingsGoalCard(
                      goal: goal,
                      currencySymbol: currencySymbol,
                      onTap: () => context.push('/savings-goals/${goal.id}'),
                      onDeposit: () =>
                          _showDepositSheet(context, goal, currencySymbol),
                    ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Goal',
        onPressed: () => _showAddGoalSheet(context),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}
