import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/savings_goal_model.dart';

class SavingsGoalCard extends StatelessWidget {
  const SavingsGoalCard({
    super.key,
    required this.goal,
    required this.currencySymbol,
    this.onTap,
    this.onDeposit,
    this.onEdit,
    this.onDelete,
  });

  final SavingsGoalModel goal;
  final String currencySymbol;
  final VoidCallback? onTap;
  final VoidCallback? onDeposit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return AppColors.primary;
    try {
      final hex = colorStr.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'piggy-bank':
      case 'savings':
        return LucideIcons.piggyBank;
      case 'shield':
      case 'emergency':
        return LucideIcons.shieldCheck;
      case 'plane':
      case 'vacation':
        return LucideIcons.plane;
      case 'car':
      case 'vehicle':
        return LucideIcons.car;
      case 'laptop':
      case 'tech':
        return LucideIcons.laptop;
      case 'home':
      case 'house':
        return LucideIcons.home;
      case 'gift':
        return LucideIcons.gift;
      case 'heart':
        return LucideIcons.heart;
      case 'graduation-cap':
      case 'education':
        return LucideIcons.graduationCap;
      default:
        return LucideIcons.target;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatter = NumberFormat('#,##,##0.##', 'en_IN');
    final goalColor = _parseColor(goal.color);
    final isCompleted = goal.isCompleted;

    final formattedSaved = '$currencySymbol${formatter.format(goal.currentAmount)}';
    final formattedTarget = '$currencySymbol${formatter.format(goal.targetAmount)}';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Icon, Title, Status & Actions ─────────────────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: goalColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(goal.icon),
                  color: goalColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (goal.targetDate != null)
                      Text(
                        goal.daysRemaining != null && goal.daysRemaining! < 0
                            ? 'Target date passed'
                            : (goal.daysRemaining == 0
                                ? 'Target date is today'
                                : '${goal.daysRemaining} days left (${DateFormat('dd MMM yyyy').format(goal.targetDate!)})'),
                        style: TextStyle(
                          fontSize: 12,
                          color: goal.daysRemaining != null && goal.daysRemaining! < 0 && !isCompleted
                              ? AppColors.error
                              : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                        ),
                      )
                    else
                      Text(
                        'No deadline set',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.credit.withValues(alpha: 0.15)
                      : goalColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCompleted) ...[
                      const Icon(LucideIcons.checkCircle2, size: 13, color: AppColors.credit),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isCompleted ? '100% Reached' : '${goal.savedPercentage.toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppColors.credit : goalColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Progress Bar ───────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal.progressRatio,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? AppColors.credit : goalColor,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Bottom Row: Amounts & Quick Action ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  Text(
                    '$formattedSaved / $formattedTarget',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (!isCompleted && onDeposit != null)
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onDeposit,
                  icon: const Icon(LucideIcons.plusCircle, size: 15),
                  label: const Text('Add Money', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
