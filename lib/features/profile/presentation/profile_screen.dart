import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/presentation/providers/auth_controller.dart';
import '../../auth/presentation/providers/auth_state_provider.dart';
import '../domain/models/user_profile.dart';
import 'providers/profile_repository_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileSheet(BuildContext context, UserProfile? profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _EditProfileSheet(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final user = authState.value is AuthAuthenticated
        ? (authState.value as AuthAuthenticated).user
        : null;
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildProfileBody(
          context: context,
          ref: ref,
          profile: null,
          email: email,
        ),
        data: (profile) => _buildProfileBody(
          context: context,
          ref: ref,
          profile: profile,
          email: email,
        ),
      ),
    );
  }

  Widget _buildProfileBody({
    required BuildContext context,
    required WidgetRef ref,
    required UserProfile? profile,
    required String email,
  }) {
    final theme = Theme.of(context);
    final displayName = profile?.fullName?.trim().isNotEmpty == true
        ? profile!.fullName!
        : (email.isNotEmpty ? email.split('@').first : 'User');
    final avatarUrl = profile?.avatarUrl;

    Widget avatarWidget;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('data:image')) {
        try {
          final base64String = avatarUrl.split(',').last;
          avatarWidget = CircleAvatar(
            radius: 32,
            backgroundImage: MemoryImage(base64Decode(base64String)),
          );
        } catch (_) {
          avatarWidget = _buildFallbackAvatar(displayName, email);
        }
      } else {
        avatarWidget = CircleAvatar(
          radius: 32,
          backgroundImage: NetworkImage(avatarUrl),
          onBackgroundImageError: (error, stack) {},
          child: _buildFallbackAvatar(displayName, email),
        );
      }
    } else {
      avatarWidget = _buildFallbackAvatar(displayName, email);
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // ── 1. Profile Header Card ──────────────────────────────────────────
        AppCard(
          child: Row(
            children: [
              avatarWidget,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.credit,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Account Active',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.credit,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit Profile',
                onPressed: () => _showEditProfileSheet(context, profile),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── 2. Basic Information ───────────────────────────────────────────
        Text(
          'BASIC INFORMATION',
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),

        AppCard(
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline, color: AppColors.primary),
                  title: const Text('Full Name'),
                  subtitle: Text(
                    profile?.fullName?.trim().isNotEmpty == true
                        ? profile!.fullName!
                        : 'Not specified',
                  ),
                  trailing: const Icon(Icons.edit_outlined, size: 18),
                  onTap: () => _showEditProfileSheet(context, profile),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                  title: const Text('Email Address'),
                  subtitle: Text(email),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.primary),
                  title: const Text('Default Currency'),
                  subtitle: Text(
                    '${profile?.currencySymbol ?? '₹'} (${profile?.currencyCode ?? 'INR'})',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showEditProfileSheet(context, profile),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── 3. Data Management ─────────────────────────────────────────────
        Text(
          'DATA MANAGEMENT',
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),

        AppCard(
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined,
                      color: AppColors.primary),
                  title: const Text('Accounts & Payment Methods'),
                  subtitle: const Text('Manage banks, cash & wallets'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/accounts'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.category_outlined,
                      color: AppColors.primary),
                  title: const Text('Categories'),
                  subtitle: const Text('Expense & Income categories'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/categories'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.track_changes_outlined,
                      color: AppColors.primary),
                  title: const Text('Budget Limits'),
                  subtitle: const Text('Overall & category monthly caps'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/budgets'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.repeat_rounded,
                      color: AppColors.primary),
                  title: const Text('Recurring Payments'),
                  subtitle: const Text('Subscriptions, bills & schedules'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/recurring'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.savings_outlined,
                      color: AppColors.primary),
                  title: const Text('Savings Goals'),
                  subtitle: const Text('Track targets, deposits & milestones'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/savings-goals'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.primary),
                  title: const Text('Loan & Debt'),
                  subtitle: const Text('Track money owed, lent, interest & installments'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/debts'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined,
                      color: AppColors.primary),
                  title: const Text('Khata Book'),
                  subtitle: const Text('Customer ledger, credits & statements'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/khata'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── 4. Preferences ────────────────────────────────────────────────
        Text(
          'PREFERENCES',
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),

        AppCard(
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard_customize_outlined,
                      color: AppColors.primary),
                  title: const Text('Dashboard Customization'),
                  subtitle: const Text('Reorder widgets & manage visibility'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/customize-dashboard'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── 5. Alerts & Notifications ──────────────────────────────────────
        Text(
          'ALERTS & NOTIFICATIONS',
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),

        AppCard(
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined,
                      color: AppColors.primary),
                  title: const Text('Notification Center'),
                  subtitle: const Text('View all financial alerts & logs'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/notifications'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tune_rounded,
                      color: AppColors.primary),
                  title: const Text('Notification Preferences'),
                  subtitle: const Text('Configure smart alert thresholds'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/notification-settings'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── 5. Data Export & Backup ─────────────────────────────────────────
        Text(
          'DATA EXPORT & BACKUP',
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),

        AppCard(
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined,
                      color: AppColors.primary),
                  title: const Text('Export Financial Data'),
                  subtitle: const Text('Export CSV, customized PDF reports or ZIP backup'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/export'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined,
                      color: AppColors.primary),
                  title: const Text('Import Transactions'),
                  subtitle: const Text('Import bank statements or CSV data'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/import'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── 6. Legal & Support ─────────────────────────────────────────────
        Text(
          'ABOUT & LEGAL',
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),

        AppCard(
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 20),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('Read how your data is protected'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showPolicyDialog(
                    context,
                    title: 'Privacy Policy',
                    content: 'Expense Tracker respects your privacy. All financial data is encrypted and tied exclusively to your authenticated account via Row Level Security (RLS). We never sell your data or share it with third-party advertisers.\n\nFor full details, visit:\n${AppConfig.privacyPolicyUrl}',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.fileText, color: AppColors.primary, size: 20),
                  title: const Text('Terms & Conditions'),
                  subtitle: const Text('Terms of service and usage guidelines'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showPolicyDialog(
                    context,
                    title: 'Terms & Conditions',
                    content: 'By using Expense Tracker, you agree to track your personal and business finances responsibly. The app provides tools for expense management, budgeting, debt tracking, and customer ledgers.\n\nFor full terms, visit:\n${AppConfig.termsAndConditionsUrl}',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.info, color: AppColors.primary, size: 20),
                  title: const Text('App Version'),
                  subtitle: const Text(AppConfig.fullVersionString),
                  trailing: const Text(
                    'Up to date',
                    style: TextStyle(fontSize: 12, color: AppColors.credit, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── 7. Sign Out Button ─────────────────────────────────────────────
        FilledButton.tonalIcon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).signOut();
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign Out'),
        ),
        const SizedBox(height: 12),

        // ── 8. Delete Account Button ───────────────────────────────────────
        OutlinedButton.icon(
          key: const Key('delete_account_button'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => _confirmAccountDeletion(context, ref),
          icon: const Icon(LucideIcons.trash2, size: 18),
          label: const Text('Delete Account & Data'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showPolicyDialog(BuildContext context, {required String title, required String content}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAccountDeletion(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Delete Account?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is irreversible. All your financial data, accounts, categories, budgets, debts, savings goals, and customer Khata records will be permanently removed.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              'You can also request deletion at:\n${AppConfig.accountDeletionUrl}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
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
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleting your account...'),
          backgroundColor: AppColors.error,
        ),
      );
      await ref.read(authControllerProvider.notifier).deleteAccount();
    }
  }

  Widget _buildFallbackAvatar(String name, String email) {
    final char = name.isNotEmpty
        ? name[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : 'U');
    return CircleAvatar(
      radius: 32,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        char,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Profile Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({this.profile});

  final UserProfile? profile;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedCurrencyCode;
  late String _selectedCurrencySymbol;
  String? _avatarDataUrl;
  bool _isSaving = false;

  static const List<(String code, String symbol, String label)> _currencies = [
    ('INR', '₹', 'INR - Indian Rupee (₹)'),
    ('USD', '\$', 'USD - US Dollar (\$)'),
    ('EUR', '€', 'EUR - Euro (€)'),
    ('GBP', '£', 'GBP - British Pound (£)'),
    ('AED', 'د.إ', 'AED - UAE Dirham (د.إ)'),
    ('CAD', '\$', 'CAD - Canadian Dollar (\$)'),
    ('AUD', '\$', 'AUD - Australian Dollar (\$)'),
    ('JPY', '¥', 'JPY - Japanese Yen (¥)'),
    ('SAR', '﷼', 'SAR - Saudi Riyal (﷼)'),
    ('SGD', '\$', 'SGD - Singapore Dollar (\$)'),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.fullName ?? '');
    _selectedCurrencyCode = widget.profile?.currencyCode ?? 'INR';
    _selectedCurrencySymbol = widget.profile?.currencySymbol ?? '₹';
    _avatarDataUrl = widget.profile?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      const maxBytes = 3 * 1024 * 1024; // 3 MB

      if (bytes.lengthInBytes > maxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected photo exceeds 3 MB limit. Please select a smaller photo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final base64String = base64Encode(bytes);
      final mimeType = pickedFile.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      setState(() {
        _avatarDataUrl = 'data:image/$mimeType;base64,$base64String';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Max file size: 3 MB'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              subtitle: const Text('Max file size: 3 MB'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            if (_avatarDataUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _avatarDataUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(
        fullName: _nameController.text.trim(),
        avatarUrl: _avatarDataUrl,
        currencyCode: _selectedCurrencyCode,
        currencySymbol: _selectedCurrencySymbol,
      );

      ref.invalidate(userProfileProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Profile',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Avatar Picker ───────────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: _avatarDataUrl != null && _avatarDataUrl!.isNotEmpty
                          ? (_avatarDataUrl!.startsWith('data:image')
                              ? MemoryImage(base64Decode(_avatarDataUrl!.split(',').last))
                              : NetworkImage(_avatarDataUrl!) as ImageProvider)
                          : null,
                      child: _avatarDataUrl == null
                          ? const Icon(Icons.person, size: 48, color: AppColors.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _showImageSourceDialog,
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Tap camera icon to change photo (Max 3 MB)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),

              // ── Full Name Field ─────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Currency Selection Dropdown ─────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrencyCode,
                decoration: const InputDecoration(
                  labelText: 'Default Currency',
                  prefixIcon: Icon(Icons.currency_exchange_rounded),
                ),
                items: _currencies.map((curr) {
                  return DropdownMenuItem(
                    value: curr.$1,
                    child: Text(curr.$3),
                  );
                }).toList(),
                onChanged: (code) {
                  if (code != null) {
                    final curr = _currencies.firstWhere((c) => c.$1 == code);
                    setState(() {
                      _selectedCurrencyCode = curr.$1;
                      _selectedCurrencySymbol = curr.$2;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // ── Save Button ─────────────────────────────────────────────
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
