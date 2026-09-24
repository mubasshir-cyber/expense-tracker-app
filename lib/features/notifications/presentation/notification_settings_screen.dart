import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/notifications/local_notification_provider.dart';
import '../../../core/notifications/system_notification_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import 'providers/notification_providers.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool? _isPermissionGranted;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final localNotif = ref.read(localNotificationServiceProvider);
    final granted = await localNotif.permissionService.isPermissionGranted();
    if (mounted) {
      setState(() {
        _isPermissionGranted = granted;
      });
    }
  }

  Future<void> _requestAndEnableSystemNotifs(
      SystemNotificationPreferences currentPrefs) async {
    final localNotif = ref.read(localNotificationServiceProvider);
    final granted = await localNotif.permissionService.requestPermission();

    if (mounted) {
      setState(() {
        _isPermissionGranted = granted;
      });
    }

    if (granted) {
      await ref
          .read(systemNotificationPreferencesProvider.notifier)
          .updatePreferences(
            currentPrefs.copyWith(systemNotificationsEnabled: true),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('System notifications enabled successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permission is disabled in Android Settings.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 20),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inAppSettingsAsync = ref.watch(notificationSettingsProvider);
    final sysPrefsAsync = ref.watch(systemNotificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: inAppSettingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text('Failed to load notification preferences: $err'),
        ),
        data: (inAppSettings) {
          final sysPrefs = sysPrefsAsync.value ??
              const SystemNotificationPreferences();
          final controller =
              ref.read(notificationsControllerProvider.notifier);
          final sysNotifier =
              ref.read(systemNotificationPreferencesProvider.notifier);

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
                            'Real-time financial alerts, bill reminders, and ledger updates.',
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

              // ── Section 1: Android System Notifications ─────────────────────
              _buildSectionHeader(
                  context, 'System & OS Notifications', LucideIcons.smartphone),
              AppCard(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Device Status Bar Alerts',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Display banners and alerts in the Android notification tray when the app is minimized.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: sysPrefs.systemNotificationsEnabled &&
                          (_isPermissionGranted ?? true),
                      onChanged: (val) async {
                        if (val) {
                          await _requestAndEnableSystemNotifs(sysPrefs);
                        } else {
                          await sysNotifier.updatePreferences(
                            sysPrefs.copyWith(
                                systemNotificationsEnabled: false),
                          );
                        }
                      },
                    ),
                    if (_isPermissionGranted == false) ...[
                      const Divider(height: 1),
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: AppColors.error.withValues(alpha: 0.08),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertCircle,
                                color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Notification permission is blocked. Please enable it in Android App Settings to receive alerts.',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text(
                        'Hide Sensitive Balances',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Hide exact currency figures in OS notifications for privacy on the lock screen.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: sysPrefs.hideSensitiveAmounts,
                      onChanged: (val) {
                        sysNotifier.updatePreferences(
                          sysPrefs.copyWith(hideSensitiveAmounts: val),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(LucideIcons.send,
                          size: 18, color: AppColors.primary),
                      title: const Text(
                        'Send Test Notification',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                      subtitle: const Text(
                        'Verify device audio and banner delivery immediately.',
                        style: TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(LucideIcons.chevronRight, size: 16),
                      onTap: () async {
                        final localNotif =
                            ref.read(localNotificationServiceProvider);
                        final hasPerm = await localNotif.permissionService
                            .isPermissionGranted();
                        if (!hasPerm) {
                          await _requestAndEnableSystemNotifs(sysPrefs);
                        }
                        await localNotif.showTestNotification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Test notification triggered! Check your status bar.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              // ── Section 2: Budgets ─────────────────────────────────────────
              _buildSectionHeader(
                  context, 'Budget Alerts', LucideIcons.pieChart),
              AppCard(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Budget Warning (80% Threshold)',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Receive an alert when your spending approaches 80% of a budget.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: inAppSettings.budgetWarningEnabled,
                      onChanged: (val) {
                        controller.updateSettings(
                          inAppSettings.copyWith(budgetWarningEnabled: val),
                        );
                        sysNotifier.updatePreferences(
                          sysPrefs.copyWith(budgetAlertsEnabled: val),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text(
                        'Budget Exceeded Alert',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Instant alert when total spending exceeds any active budget.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: inAppSettings.budgetExceededEnabled,
                      onChanged: (val) {
                        controller.updateSettings(
                          inAppSettings.copyWith(budgetExceededEnabled: val),
                        );
                        sysNotifier.updatePreferences(
                          sysPrefs.copyWith(budgetAlertsEnabled: val),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Section 3: Recurring Payments ──────────────────────────────
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
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Reminders 1–3 days before scheduled recurring bills and subscriptions.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: inAppSettings.recurringUpcomingEnabled,
                      onChanged: (val) {
                        controller.updateSettings(
                          inAppSettings.copyWith(
                              recurringUpcomingEnabled: val),
                        );
                        sysNotifier.updatePreferences(
                          sysPrefs.copyWith(recurringAlertsEnabled: val),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text(
                        'Auto-Created Transactions',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Confirmation when recurring schedules automatically post to your ledger.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: inAppSettings.recurringAutoCreatedEnabled,
                      onChanged: (val) {
                        controller.updateSettings(
                          inAppSettings.copyWith(
                              recurringAutoCreatedEnabled: val),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Section 4: Loans, Debts & Khata ────────────────────────────
              _buildSectionHeader(
                  context, 'Loans, Debts & Khata', LucideIcons.landmark),
              AppCard(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Loan & Debt Reminders',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Reminders for approaching debt & loan repayment due dates.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: sysPrefs.loanAlertsEnabled,
                      onChanged: (val) {
                        sysNotifier.updatePreferences(
                          sysPrefs.copyWith(loanAlertsEnabled: val),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text(
                        'Khata Customer Due Alerts',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Reminders for pending customer credit balances in your Khata book.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: sysPrefs.khataAlertsEnabled,
                      onChanged: (val) {
                        sysNotifier.updatePreferences(
                          sysPrefs.copyWith(khataAlertsEnabled: val),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Section 5: Savings Goals & Insights ────────────────────────
              _buildSectionHeader(
                  context, 'Savings Goals & Insights', LucideIcons.target),
              AppCard(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Savings Goal Milestones',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Celebratory alerts when reaching 25%, 50%, 75%, or 100% of your goals.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: sysPrefs.savingsAlertsEnabled,
                      onChanged: (val) {
                        sysNotifier.updatePreferences(
                          sysPrefs.copyWith(savingsAlertsEnabled: val),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text(
                        'Spending Surge Alerts',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Alert when monthly expenses surge unexpectedly compared to previous months.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: inAppSettings.spendingAlertsEnabled,
                      onChanged: (val) {
                        controller.updateSettings(
                          inAppSettings.copyWith(spendingAlertsEnabled: val),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text(
                        'Monthly Financial Summary',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'End-of-month overview of your total income, expenses, and savings.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: inAppSettings.monthlySummaryEnabled,
                      onChanged: (val) {
                        controller.updateSettings(
                          inAppSettings.copyWith(monthlySummaryEnabled: val),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}
