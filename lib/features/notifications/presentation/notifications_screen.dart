import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/models/notification_model.dart';
import '../domain/models/notification_type.dart';
import 'providers/notification_providers.dart';
import 'widgets/notification_card.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Unread, 2: Budgets, 3: Recurring

  @override
  void initState() {
    super.initState();
    // Auto-sync domain alerts in background on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsControllerProvider.notifier).syncDomainAlerts();
    });
  }

  void _handleNotificationTap(NotificationModel item) {
    if (item.isUnread) {
      ref.read(notificationsControllerProvider.notifier).markAsRead(item.id);
    }

    // Contextual deep navigation
    switch (item.type) {
      case NotificationType.budgetWarning:
      case NotificationType.budgetExceeded:
        context.push('/budgets');
        break;
      case NotificationType.recurringUpcoming:
      case NotificationType.recurringDue:
      case NotificationType.recurringCompleted:
        context.push('/recurring');
        break;
      case NotificationType.spendingAlert:
      case NotificationType.monthlySummary:
        context.push('/reports');
        break;
      case NotificationType.debtDue:
        final debtId = item.referenceId;
        context.push(debtId != null ? '/debts/$debtId' : '/debts');
        break;
      case NotificationType.goalMilestone:
        final goalId = item.referenceId;
        context.push(goalId != null ? '/savings-goals/$goalId' : '/savings-goals');
        break;
      case NotificationType.khataDue:
        final custId = item.referenceId;
        context.push(custId != null ? '/khata/$custId' : '/khata');
        break;
      case NotificationType.system:
        break;
    }
  }

  List<NotificationModel> _applyFilter(List<NotificationModel> list) {
    switch (_selectedFilterIndex) {
      case 1: // Unread
        return list.where((n) => n.isUnread).toList();
      case 2: // Alerts (Budgets, Spending, Monthly)
        return list
            .where((n) =>
                n.type == NotificationType.budgetWarning ||
                n.type == NotificationType.budgetExceeded ||
                n.type == NotificationType.spendingAlert ||
                n.type == NotificationType.monthlySummary)
            .toList();
      case 3: // Reminders (Recurring)
        return list
            .where((n) =>
                n.type == NotificationType.recurringUpcoming ||
                n.type == NotificationType.recurringDue ||
                n.type == NotificationType.recurringCompleted)
            .toList();
      case 0: // All
      default:
        return list;
    }
  }

  Map<String, List<NotificationModel>> _groupByDate(List<NotificationModel> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<NotificationModel>>{};

    for (final item in list) {
      final itemDate = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );

      String header;
      if (itemDate == today) {
        header = 'Today';
      } else if (itemDate == yesterday) {
        header = 'Yesterday';
      } else {
        header = DateFormat('MMMM yyyy').format(itemDate);
      }

      groups.putIfAbsent(header, () => []).add(item);
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notificationsAsync = ref.watch(notificationsListProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadCountAsync.value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(LucideIcons.checkCheck, size: 20),
              tooltip: 'Mark all as read',
              onPressed: () async {
                await ref
                    .read(notificationsControllerProvider.notifier)
                    .markAllAsRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(LucideIcons.slidersHorizontal, size: 19),
            tooltip: 'Settings',
            onPressed: () => context.push('/notification-settings'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, size: 20),
            onSelected: (val) async {
              if (val == 'clear_all') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All Notifications?'),
                    content: const Text(
                      'Are you sure you want to clear all notification history?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref
                      .read(notificationsControllerProvider.notifier)
                      .clearAll();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Clear All History',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(notificationsControllerProvider.notifier)
              .syncDomainAlerts();
          ref.invalidate(notificationsListProvider);
        },
        child: notificationsAsync.when(
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
                    'Failed to load notifications',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Retry',
                    type: AppButtonType.secondary,
                    onPressed: () => ref.invalidate(notificationsListProvider),
                  ),
                ],
              ),
            ),
          ),
          data: (allNotifications) {
            if (allNotifications.isEmpty) {
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
                        LucideIcons.bellOff,
                        size: 44,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Notifications Yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You're all caught up! Smart alerts about budget limits, upcoming bills, and spending trends will appear here.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              );
            }

            final filteredList = _applyFilter(allNotifications);
            final grouped = _groupByDate(filteredList);

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // ── Filter Chips ─────────────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text('All (${allNotifications.length})'),
                        selected: _selectedFilterIndex == 0,
                        onSelected: (_) =>
                            setState(() => _selectedFilterIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('Unread ($unreadCount)'),
                        selected: _selectedFilterIndex == 1,
                        onSelected: (_) =>
                            setState(() => _selectedFilterIndex = 1),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Alerts'),
                        selected: _selectedFilterIndex == 2,
                        onSelected: (_) =>
                            setState(() => _selectedFilterIndex = 2),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Reminders'),
                        selected: _selectedFilterIndex == 3,
                        onSelected: (_) =>
                            setState(() => _selectedFilterIndex = 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Grouped Notifications ────────────────────────────────────
                if (filteredList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Text(
                        'No notifications in this filter.',
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
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ),
                    for (final notification in entry.value)
                      NotificationCard(
                        item: notification,
                        onTap: () => _handleNotificationTap(notification),
                        onDelete: () => ref
                            .read(notificationsControllerProvider.notifier)
                            .deleteNotification(notification.id),
                      ),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}
