import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/presentation/providers/auth_controller.dart';
import '../../auth/presentation/providers/auth_state_provider.dart';
import '../domain/models/user_profile.dart';
import 'providers/profile_repository_provider.dart';

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
                  title: const Text('Budgets & Spending Limits'),
                  subtitle: const Text('Overall & category monthly caps'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/budgets'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.repeat_rounded,
                      color: AppColors.primary),
                  title: const Text('Recurring Transactions'),
                  subtitle: const Text('Subscriptions, bills & schedules'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/recurring'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── 4. Alerts & Notifications ──────────────────────────────────────
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
        const SizedBox(height: 24),

        // ── 5. Sign Out Button ─────────────────────────────────────────────
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
      ],
    );
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
