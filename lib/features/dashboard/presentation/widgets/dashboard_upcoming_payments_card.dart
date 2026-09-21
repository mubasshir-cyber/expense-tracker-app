import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../recurring/presentation/providers/recurring_providers.dart';

class DashboardUpcomingPaymentsCard extends ConsumerWidget {
  const DashboardUpcomingPaymentsCard({
    super.key,
    required this.currencySymbol,
  });

  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,##,##0.##', 'en_IN');
    final dateFormat = DateFormat('dd MMM');

    final upcomingAsync = ref.watch(upcomingRecurringProvider);

    return upcomingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (upcomingList) {
        if (upcomingList.isEmpty) {
          return AppCard(
            margin: EdgeInsets.zero,
            onTap: () => context.push('/recurring'),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.repeat,
                    color: Color(0xFF8B5CF6),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recurring Payments & Bills',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Automate Netflix, rent, bills & salary.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: Colors.grey,
                ),
              ],
            ),
          );
        }

        final displayedList = upcomingList.take(3).toList();

        return AppCard(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Row ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.calendarClock,
                          size: 16, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 6),
                      Text(
                        'Upcoming Payments',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.push('/recurring'),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            'See All (${upcomingList.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 14,
                            color: Color(0xFF8B5CF6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── List of Items ────────────────────────────────────────────
              ...displayedList.map((item) {
                final isDue = item.isDue();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: (item.isCredit ? AppColors.credit : AppColors.expense)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item.isCredit
                              ? LucideIcons.arrowDownLeft
                              : LucideIcons.arrowUpRight,
                          size: 16,
                          color: item.isCredit
                              ? AppColors.credit
                              : AppColors.expense,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.description,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isDue
                                  ? 'Due Today'
                                  : 'Due ${dateFormat.format(item.nextOccurrence)} • ${item.frequency.label}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    isDue ? FontWeight.bold : FontWeight.w500,
                                color: isDue
                                    ? const Color(0xFFF59E0B)
                                    : (isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${item.isCredit ? '+' : '-'}$currencySymbol${currencyFormat.format(item.amount)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: item.isCredit
                              ? AppColors.credit
                              : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
