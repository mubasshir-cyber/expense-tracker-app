import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import 'providers/notification_providers.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text('Failed to load notification preferences: $err'),
        ),
        data: (settings) {
          final controller =
              ref.read(notificationsControllerProvider.notifier);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ── Top Summary Card ───────────────────────────────────────────
              AppCard(
                margin: const EdgeInsets.only(bottom: 8),
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
                        LucideIcons.bellRing,
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
                            'Smart Notification Engine',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Customize your real-time financial alerts and bill reminders.',
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
                  ],
                ),
              ),

              // ── Section 1: Budgets ─────────────────────────────────────────
              _buildSectionHeader(context, 'Budget Alerts', LucideIcons.pieChart),
              AppCard(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Budget Warning (80% Threshold)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Receive an alert when your spending approaches 80% of a budget.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: settings.budgetWarningEnabled,
                      onChanged: (val) {
                        controller.updateSettings(
                          settings.copyWith(budgetWarningEnabled: val),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text(
                        'Budget Exceeded Alert',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Instant alert when total spending exceeds any active budget.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: settings.budgetExceededEnabled,
                      onChanged: (val) {
                        controller.updateSettings(
                          settings.copyWith(budgetExceededEnabled: val),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Section 2: Recurring Payments ──────────────────────────────
              _buildSectionHeader(
                  context, 'Recurring & Upcoming Bills', LucideIcons.repeat),
              AppCard(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Upcoming Bill Reminders',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Reminders 1–3 days before scheduled recurring bills and subscriptions.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: settings.recurringUpcomingEnabled,
                      onChanged: (val) {
                        controller.updateSettings(
                          settings.copyWith(recurringUpcomingEnabled: val),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text(
                        'Auto-Created Transactions',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Confirmation when recurring schedules automatically post to your ledger.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: settings.recurringAutoCreatedEnabled,
                      onChanged: (val) {
                        controller.updateSettings(
                          settings.copyWith(recurringAutoCreatedEnabled: val),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Section 3: Spending & Reports ──────────────────────────────
              _buildSectionHeader(
                  context, 'Spending Insights & Reports', LucideIcons.trendingUp),
              AppCard(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Spending Surge Alerts',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Alert when monthly expenses surge unexpectedly compared to previous months.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: settings.spendingAlertsEnabled,
                      onChanged: (val) {
                        controller.updateSettings(
                          settings.copyWith(spendingAlertsEnabled: val),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text(
                        'Monthly Financial Summary',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'End-of-month overview of your total income, expenses, and savings.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: settings.monthlySummaryEnabled,
                      onChanged: (val) {
                        controller.updateSettings(
                          settings.copyWith(monthlySummaryEnabled: val),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
