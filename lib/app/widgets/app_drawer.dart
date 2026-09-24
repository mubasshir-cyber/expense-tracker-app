import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/profile/presentation/providers/profile_repository_provider.dart';
import '../../features/notifications/presentation/providers/notification_providers.dart';

/// A modern, silky-smooth side navigation drawer for secondary tools and modules.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  void _navigateTo(BuildContext context, String path) {
    Navigator.of(context).pop(); // Close drawer
    context.push(path);
  }

  void _switchTab(BuildContext context, String path) {
    Navigator.of(context).pop(); // Close drawer
    context.go(path);
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.logOut, color: AppColors.error, size: 22),
            SizedBox(width: 10),
            Text('Sign Out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop(); // Close drawer
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authStateProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

    final user = authState.value is AuthAuthenticated
        ? (authState.value as AuthAuthenticated).user
        : null;
    final email = user?.email ?? '';
    final profile = profileAsync.value;

    final displayName = profile?.fullName?.trim().isNotEmpty == true
        ? profile!.fullName!
        : (email.isNotEmpty ? email.split('@').first : 'User');

    final unreadCount = unreadCountAsync.value ?? 0;

    return Drawer(
      child: ListView(
        // Seamless unified scroll with smooth inertia and bouncing physics
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.zero,
        children: [
          // ── 1. Drawer Header ──────────────────────────────────────────
          _buildDrawerHeader(
            context: context,
            isDark: isDark,
            displayName: displayName,
            email: email,
            avatarUrl: profile?.avatarUrl,
          ),

          // ── 2. Navigation Menu Items ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main / Home
                _DrawerTile(
                  icon: LucideIcons.home,
                  title: 'Home',
                  onTap: () => _switchTab(context, '/'),
                ),

                const SizedBox(height: 12),
                _buildSectionHeader('FINANCIAL TOOLS', isDark),
                const SizedBox(height: 4),

                _DrawerTile(
                  icon: LucideIcons.landmark,
                  iconColor: const Color(0xFFE11D48),
                  title: 'Loan & Debt',
                  subtitle: 'Borrowing, lending & installments',
                  onTap: () => _navigateTo(context, '/debts'),
                ),
                _DrawerTile(
                  icon: LucideIcons.bookOpenCheck,
                  iconColor: const Color(0xFF0284C7),
                  title: 'Khata Book',
                  subtitle: 'Customer ledger, credits & statements',
                  onTap: () => _navigateTo(context, '/khata'),
                ),
                _DrawerTile(
                  icon: LucideIcons.target,
                  iconColor: const Color(0xFF10B981),
                  title: 'Savings Goals',
                  subtitle: 'Targets, deposits & milestones',
                  onTap: () => _navigateTo(context, '/savings-goals'),
                ),
                _DrawerTile(
                  icon: LucideIcons.pieChart,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Budget Limits',
                  subtitle: 'Monthly spending caps & alerts',
                  onTap: () => _navigateTo(context, '/budgets'),
                ),
                _DrawerTile(
                  icon: LucideIcons.repeat,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Recurring Payments',
                  subtitle: 'Subscriptions & automated bills',
                  onTap: () => _navigateTo(context, '/recurring'),
                ),

                const SizedBox(height: 12),
                _buildSectionHeader('ACCOUNT & DATA', isDark),
                const SizedBox(height: 4),

                _DrawerTile(
                  icon: LucideIcons.walletCards,
                  iconColor: const Color(0xFF4F46E5),
                  title: 'Accounts',
                  subtitle: 'Banks, cash & digital wallets',
                  onTap: () => _navigateTo(context, '/accounts'),
                ),
                _DrawerTile(
                  icon: LucideIcons.tags,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Categories',
                  subtitle: 'Income & Expense classification',
                  onTap: () => _navigateTo(context, '/categories'),
                ),
                _DrawerTile(
                  icon: LucideIcons.barChart3,
                  iconColor: const Color(0xFF0EA5E9),
                  title: 'Reports & Analytics',
                  subtitle: 'Trends, category breakdowns & cashflow',
                  onTap: () => _switchTab(context, '/reports'),
                ),
                _DrawerTile(
                  icon: LucideIcons.bell,
                  iconColor: const Color(0xFFF97316),
                  title: 'Notifications',
                  badgeCount: unreadCount > 0 ? unreadCount : null,
                  onTap: () => _navigateTo(context, '/notifications'),
                ),

                const SizedBox(height: 12),
                _buildSectionHeader('SETTINGS & PREFERENCES', isDark),
                const SizedBox(height: 4),

                _DrawerTile(
                  icon: LucideIcons.slidersHorizontal,
                  iconColor: const Color(0xFF4F46E5),
                  title: 'Customize Dashboard',
                  subtitle: 'Reorder cards & manage visibility',
                  onTap: () => _navigateTo(context, '/customize-dashboard'),
                ),
                _DrawerTile(
                  icon: LucideIcons.fileSpreadsheet,
                  iconColor: const Color(0xFF10B981),
                  title: 'Export Financial Data',
                  subtitle: 'Export CSV, PDF reports & ZIP backup',
                  onTap: () => _navigateTo(context, '/export'),
                ),
                _DrawerTile(
                  icon: LucideIcons.fileUp,
                  iconColor: const Color(0xFF6B7280),
                  title: 'Import Transactions',
                  subtitle: 'Import bank statements & CSV files',
                  onTap: () => _navigateTo(context, '/import'),
                ),
                _DrawerTile(
                  icon: LucideIcons.settings,
                  title: 'Settings & Profile',
                  onTap: () => _switchTab(context, '/profile'),
                ),
              ],
            ),
          ),

          // ── 3. Footer / Sign Out ──────────────────────────────────────
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _confirmLogout(context, ref),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.logOut,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader({
    required BuildContext context,
    required bool isDark,
    required String displayName,
    required String email,
    required String? avatarUrl,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFF4F46E5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.wallet,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Tracker',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Financial & Khata Suite',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // User Profile Pill / Card
          InkWell(
            onTap: () => _switchTab(context, '/profile'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  _buildUserAvatar(displayName, email, avatarUrl),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(String displayName, String email, String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('data:image')) {
        try {
          final base64String = avatarUrl.split(',').last;
          return CircleAvatar(
            radius: 18,
            backgroundImage: MemoryImage(base64Decode(base64String)),
          );
        } catch (_) {}
      } else {
        return CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(avatarUrl),
          onBackgroundImageError: (error, stack) {},
          child: _avatarFallback(displayName, email),
        );
      }
    }
    return _avatarFallback(displayName, email);
  }

  Widget _avatarFallback(String displayName, String email) {
    final char = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : 'U');
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.white.withValues(alpha: 0.3),
      child: Text(
        char,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.badgeCount,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final int? badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultIconColor = isDark ? Colors.white70 : AppColors.textPrimaryLight;

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: (iconColor ?? defaultIconColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: badgeCount != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : const Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
