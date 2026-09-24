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
import '../domain/models/savings_goal_model.dart';
import 'providers/goal_providers.dart';
import 'widgets/add_edit_goal_sheet.dart';
import 'widgets/deposit_withdraw_sheet.dart';

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({
    super.key,
    required this.goalId,
  });

  final String goalId;

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return AppColors.primary;
    try {
      final hex = colorStr.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  void _showEditSheet(BuildContext context, SavingsGoalModel goal) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditGoalSheet(goalToEdit: goal),
    );
  }

  void _showDepositWithdrawSheet(
    BuildContext context,
    SavingsGoalModel goal,
    bool isDeposit,
    String currencySymbol,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DepositWithdrawSheet(
        goal: goal,
        isDeposit: isDeposit,
        currencySymbol: currencySymbol,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Savings Goal?'),
        content: const Text(
          'Are you sure you want to delete this goal? All allocation records will also be removed.',
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
      await ref
          .read(savingsGoalControllerProvider.notifier)
          .deleteGoal(goalId);
      if (context.mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatter = NumberFormat('#,##,##0.##', 'en_IN');

    final goalAsync = ref.watch(goalDetailProvider(goalId));
    final contributionsAsync = ref.watch(goalContributionsProvider(goalId));
    final accountsAsync = ref.watch(accountsProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final currencySymbol = profileAsync.value?.currencySymbol ?? '₹';

    final accountMap = <String, String>{};
    if (accountsAsync.hasValue) {
      for (final acc in accountsAsync.value!) {
        accountMap[acc.id] = acc.name;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(goalAsync.value?.name ?? 'Goal Details'),
        actions: [
          if (goalAsync.hasValue && goalAsync.value != null) ...[
            IconButton(
              icon: const Icon(LucideIcons.pencil, size: 19),
              tooltip: 'Edit Goal',
              onPressed: () => _showEditSheet(context, goalAsync.value!),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 19, color: AppColors.error),
              tooltip: 'Delete Goal',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ],
      ),
      body: goalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                const Text('Failed to load goal details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Retry',
                  type: AppButtonType.secondary,
                  onPressed: () => ref.invalidate(goalDetailProvider(goalId)),
                ),
              ],
            ),
          ),
        ),
        data: (goal) {
          if (goal == null) {
            return const Center(child: Text('Goal not found'));
          }

          final goalColor = _parseColor(goal.color);
          final projection = ref.watch(goalProjectionProvider(goal));
          final milestones = ref.watch(goalMilestonesProvider(goal));

          final formattedSaved =
              '$currencySymbol${formatter.format(goal.currentAmount)}';
          final formattedTarget =
              '$currencySymbol${formatter.format(goal.targetAmount)}';
          final formattedRemaining =
              '$currencySymbol${formatter.format(goal.remainingAmount)}';

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(goalDetailProvider(goalId));
              ref.invalidate(goalContributionsProvider(goalId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // ── 1. Hero Goal Card ────────────────────────────────────────
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CURRENT PROGRESS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: goal.isCompleted
                                  ? AppColors.credit.withValues(alpha: 0.15)
                                  : goalColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              goal.isCompleted
                                  ? '🎉 Completed'
                                  : '${goal.savedPercentage.toInt()}% Saved',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: goal.isCompleted
                                    ? AppColors.credit
                                    : goalColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            formattedSaved,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '/ $formattedTarget',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Linear Meter
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: goal.progressRatio,
                          minHeight: 10,
                          backgroundColor: isDark
                              ? Colors.white12
                              : Colors.black.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            goal.isCompleted ? AppColors.credit : goalColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Milestone Badges ───────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: milestones.map((m) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: m.isAchieved
                                  ? AppColors.credit.withValues(alpha: 0.12)
                                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: m.isAchieved
                                    ? AppColors.credit
                                    : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    if (m.isAchieved)
                                      const Icon(LucideIcons.check,
                                          size: 11, color: AppColors.credit),
                                    Text(
                                      '${m.percentage}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: m.isAchieved
                                            ? AppColors.credit
                                            : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$currencySymbol${formatter.format(m.targetAmount)}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 2. Projection & Timeline Card ────────────────────────────
                if (goal.targetDate != null)
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.trendingUp,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                projection.isTargetReached
                                    ? 'Target Reached!'
                                    : (projection.isDeadlinePassed
                                        ? 'Target Date Passed'
                                        : 'Projected Savings Pace'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (projection.isTargetReached)
                                const Text(
                                  'You have achieved your target goal amount.',
                                  style: TextStyle(fontSize: 12),
                                )
                              else if (projection.isDeadlinePassed)
                                Text(
                                  'Remaining $formattedRemaining deficit. Target was ${DateFormat('dd MMM yyyy').format(goal.targetDate!)}.',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.error),
                                )
                              else if (projection.requiredMonthlyRate != null)
                                Text(
                                  'Save $currencySymbol${formatter.format(projection.requiredMonthlyRate!)}/month ($currencySymbol${formatter.format(projection.requiredWeeklyRate!)}/week) to hit goal by ${DateFormat('dd MMM yyyy').format(goal.targetDate!)} (${projection.daysRemaining} days left).',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // ── 3. Quick Action Buttons ──────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _showDepositWithdrawSheet(
                            context, goal, true, currencySymbol),
                        icon: const Icon(LucideIcons.plusCircle, size: 18),
                        label: const Text('Add Money'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: goal.currentAmount > 0
                            ? () => _showDepositWithdrawSheet(
                                context, goal, false, currencySymbol)
                            : null,
                        icon: const Icon(LucideIcons.minusCircle, size: 18),
                        label: const Text('Withdraw'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── 4. Contribution Ledger History ───────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CONTRIBUTION LEDGER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    contributionsAsync.when(
                      data: (list) => Text(
                        '${list.length} entries',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                contributionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, st) => Text('Failed to load history: $err'),
                  data: (contributions) {
                    if (contributions.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            'No deposits or withdrawals logged yet.\nTap "Add Money" to start allocating funds.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: contributions.map((c) {
                        final formattedAmount =
                            '$currencySymbol${formatter.format(c.absoluteAmount)}';
                        final accountName = c.accountId != null
                            ? accountMap[c.accountId!]
                            : null;

                        return AppCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: c.isDeposit
                                      ? AppColors.credit
                                          .withValues(alpha: 0.12)
                                      : AppColors.error.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  c.isDeposit
                                      ? LucideIcons.arrowDownLeft
                                      : LucideIcons.arrowUpRight,
                                  color: c.isDeposit
                                      ? AppColors.credit
                                      : AppColors.error,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.isDeposit ? 'Deposit' : 'Withdrawal',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${DateFormat('dd MMM yyyy').format(c.contributionDate)}${accountName != null ? ' • $accountName' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textMutedDark
                                            : AppColors.textMutedLight,
                                      ),
                                    ),
                                    if (c.notes != null && c.notes!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          c.notes!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '${c.isDeposit ? '+' : '-'}$formattedAmount',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: c.isDeposit
                                      ? AppColors.credit
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
