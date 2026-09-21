import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../core/widgets/app_card.dart';
import '../../transactions/presentation/providers/data_providers.dart';
import '../domain/models/account_model.dart';
import 'providers/account_providers.dart';
import 'providers/account_repository_provider.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  bool _showInactive = false;
  bool _hideBalances = false;

  void _showAddEditAccountDialog([AccountModel? account]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _AddEditAccountSheet(account: account),
    );
  }

  Future<void> _confirmDeleteAccount(AccountModel account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deactivate Account?'),
        content: Text(
          'Are you sure you want to deactivate "${account.name}"? '
          'This account will no longer appear for new transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(accountRepositoryProvider);
        await repo.deleteAccount(account.id);

        ref.invalidate(accountsProvider);
        ref.invalidate(allAccountsProvider);
        ref.invalidate(overallSummaryProvider);
        ref.invalidate(currentMonthSummaryProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account "${account.name}" deactivated.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to deactivate account: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(allAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            tooltip: _hideBalances ? 'Show Balances' : 'Hide Balances',
            icon: Icon(
              _hideBalances
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
            ),
            onPressed: () {
              setState(() {
                _hideBalances = !_hideBalances;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Filter Options',
            onSelected: (val) {
              if (val == 'toggle_inactive') {
                setState(() {
                  _showInactive = !_showInactive;
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_inactive',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showInactive
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _showInactive ? 'Hide Inactive' : 'Show Inactive',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditAccountDialog(),
        tooltip: 'Add Account',
        child: const Icon(Icons.add_rounded),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load accounts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(allAccountsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (accounts) {
          final displayAccounts = _showInactive
              ? accounts
              : accounts.where((a) => a.isActive).toList();

          if (displayAccounts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _showInactive
                          ? 'No accounts found'
                          : 'No active accounts',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the button below to add your first payment account.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allAccountsProvider);
              ref.invalidate(accountsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: displayAccounts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final account = displayAccounts[index];
                return _AccountCard(
                  account: account,
                  hideBalance: _hideBalances,
                  onEdit: () => _showAddEditAccountDialog(account),
                  onDelete: () => _confirmDeleteAccount(account),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({
    required this.account,
    required this.hideBalance,
    required this.onEdit,
    required this.onDelete,
  });

  final AccountModel account;
  final bool hideBalance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  IconData _getAccountIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bank':
        return Icons.account_balance_rounded;
      case 'cash':
        return Icons.money_rounded;
      case 'credit card':
      case 'credit_card':
        return Icons.credit_card_rounded;
      case 'digital wallet':
      case 'wallet':
      case 'upi':
        return Icons.account_balance_wallet_rounded;
      case 'investment':
      case 'savings':
        return Icons.savings_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(accountBalanceProvider(account.id));
    final iconData = _getAccountIcon(account.type);

    return AppCard(
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: account.isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.2),
          child: Icon(
            iconData,
            color: account.isActive ? AppColors.primary : Colors.grey,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                account.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: account.isActive ? null : Colors.grey,
                    ),
              ),
            ),
            if (!account.isActive)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Inactive',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              account.type.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 6),
            balanceAsync.when(
              loading: () => const SizedBox(
                height: 16,
                width: 60,
                child: LinearProgressIndicator(minHeight: 2),
              ),
              error: (_, _) => Text(
                'Opening: ₹${account.openingBalance.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              data: (balance) => Row(
                children: [
                  Text(
                    'Balance: ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  if (hideBalance)
                    const Text(
                      '••••••',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    )
                  else
                    AmountDisplay(
                      amount: balance,
                      customStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            if (account.isActive)
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.block_rounded,
                        size: 20, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Text(
                      'Deactivate',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
}

class _AddEditAccountSheet extends ConsumerStatefulWidget {
  const _AddEditAccountSheet({this.account});

  final AccountModel? account;

  @override
  ConsumerState<_AddEditAccountSheet> createState() => _AddEditAccountSheetState();
}

class _AddEditAccountSheetState extends ConsumerState<_AddEditAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _openingBalanceController;
  late String _selectedType;
  late bool _isActive;
  bool _isSaving = false;

  static const Map<String, String> _typeDisplayMap = {
    'BANK': 'Bank Account',
    'CASH': 'Cash',
    'UPI': 'UPI',
    'WALLET': 'Digital Wallet',
    'SAVINGS': 'Savings Account',
    'OTHER': 'Other',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _openingBalanceController = TextEditingController(
      text: widget.account != null
          ? widget.account!.openingBalance.toStringAsFixed(2)
          : '0.00',
    );
    final initialType = (widget.account?.type ?? 'BANK').toUpperCase();
    _selectedType = _typeDisplayMap.containsKey(initialType) ? initialType : 'BANK';
    _isActive = widget.account?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(accountRepositoryProvider);
      final openingBalance = double.tryParse(_openingBalanceController.text.trim()) ?? 0.0;

      if (widget.account == null) {
        await repo.createAccount(
          name: _nameController.text.trim(),
          type: _selectedType,
          openingBalance: openingBalance,
        );
      } else {
        await repo.updateAccount(
          accountId: widget.account!.id,
          name: _nameController.text.trim(),
          type: _selectedType,
          isActive: _isActive,
        );
      }

      ref.invalidate(accountsProvider);
      ref.invalidate(allAccountsProvider);
      ref.invalidate(overallSummaryProvider);
      ref.invalidate(currentMonthSummaryProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.account == null
                  ? 'Account created successfully.'
                  : 'Account updated successfully.',
            ),
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
            content: Text('Failed to save account: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;

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
                    isEditing ? 'Edit Account' : 'New Account',
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name *',
                  hintText: 'e.g. HDFC Bank, Main Cash, Wallet',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an account name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Account Type *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _typeDisplayMap.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              if (!isEditing) ...[
                TextFormField(
                  controller: _openingBalanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Opening Balance',
                    prefixText: '₹ ',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null || parsed < 0) {
                      return 'Please enter a valid positive number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (isEditing) ...[
                SwitchListTile(
                  title: const Text('Active Account'),
                  subtitle: const Text('Inactive accounts are hidden from transaction input'),
                  value: _isActive,
                  onChanged: (val) {
                    setState(() {
                      _isActive = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
