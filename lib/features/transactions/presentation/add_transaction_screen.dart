import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../accounts/presentation/providers/account_providers.dart';
import '../../profile/presentation/providers/profile_repository_provider.dart';
import '../domain/models/transaction_model.dart';
import '../domain/models/transaction_type.dart';
import 'providers/data_providers.dart';
import 'providers/transaction_repository_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? transactionToEdit;
  final TransactionType? initialType;

  const AddTransactionScreen({
    super.key,
    this.transactionToEdit,
    this.initialType,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TransactionType _selectedType;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  String? _selectedPaymentMethod;
  bool _isSaving = false;
  bool _isDeleting = false;

  final List<String> _paymentMethods = [
    'UPI',
    'Cash',
    'Bank Transfer',
    'Credit Card',
    'Debit Card',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.transactionToEdit;

    if (edit != null) {
      _selectedType = edit.type.toUpperCase() == 'CREDIT'
          ? TransactionType.credit
          : TransactionType.expense;
      _amountController =
          TextEditingController(text: edit.amount.toStringAsFixed(2));
      _descriptionController =
          TextEditingController(text: edit.description ?? '');
      _selectedDate = edit.transactionDate;
      _selectedCategoryId = edit.categoryId;
      _selectedAccountId = edit.accountId;
      _selectedPaymentMethod = edit.paymentMethod;
    } else {
      _selectedType = widget.initialType ?? TransactionType.expense;
      _amountController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedDate = DateTime.now();
      _selectedPaymentMethod = 'UPI';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _invalidateProviders() {
    ref.invalidate(overallSummaryProvider);
    ref.invalidate(currentMonthSummaryProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(accountsProvider);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final categories = ref.read(categoriesProvider).value ?? [];
    final accounts = ref.read(accountsProvider).value ?? [];
    final targetType = _selectedType == TransactionType.expense ? 'EXPENSE' : 'CREDIT';
    final filteredCategories = categories.where((c) => c.type.toUpperCase() == targetType).toList();
    final activeAccounts = accounts.where((a) => a.isActive).toList();

    final categoryId = (_selectedCategoryId != null && filteredCategories.any((c) => c.id == _selectedCategoryId))
        ? _selectedCategoryId!
        : (filteredCategories.isNotEmpty ? filteredCategories.first.id : null);

    final accountId = (_selectedAccountId != null && activeAccounts.any((a) => a.id == _selectedAccountId))
        ? _selectedAccountId!
        : (activeAccounts.isNotEmpty ? activeAccounts.first.id : null);

    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    if (accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(transactionRepositoryProvider);
      final isEditing = widget.transactionToEdit != null;

      if (isEditing) {
        await repo.updateTransaction(
          transactionId: widget.transactionToEdit!.id,
          accountId: accountId,
          categoryId: categoryId,
          type: _selectedType,
          amount: amount,
          date: _selectedDate,
          note: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      } else {
        await repo.createTransaction(
          accountId: accountId,
          categoryId: categoryId,
          type: _selectedType,
          amount: amount,
          date: _selectedDate,
          note: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      }

      _invalidateProviders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Transaction updated successfully.' : 'Transaction saved successfully.',
            ),
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save transaction: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text(
          'This transaction will be removed from your records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isDeleting = true;
      });

      try {
        final repo = ref.read(transactionRepositoryProvider);
        await repo.deleteTransaction(widget.transactionToEdit!.id);

        _invalidateProviders();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted.')),
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete transaction: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.transactionToEdit != null;

    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final currencySymbol = profileAsync.value?.currencySymbol ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (isEditing)
            IconButton(
              key: const Key('delete_transaction_button'),
              icon: const Icon(LucideIcons.trash2, color: AppColors.error),
              tooltip: 'Delete Transaction',
              onPressed: _isDeleting ? null : _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Transaction Type Segmented Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Expense Toggle
                      Expanded(
                        child: GestureDetector(
                          key: const Key('type_toggle_expense'),
                          onTap: () {
                            setState(() {
                              _selectedType = TransactionType.expense;
                              _selectedCategoryId = null; // reset category on switch
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedType == TransactionType.expense
                                  ? (isDark ? AppColors.surfaceDark : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedType == TransactionType.expense
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.arrowDownLeft,
                                  size: 16,
                                  color: _selectedType == TransactionType.expense
                                      ? AppColors.expense
                                      : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Expense',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _selectedType == TransactionType.expense
                                        ? AppColors.expense
                                        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Credit Toggle
                      Expanded(
                        child: GestureDetector(
                          key: const Key('type_toggle_credit'),
                          onTap: () {
                            setState(() {
                              _selectedType = TransactionType.credit;
                              _selectedCategoryId = null; // reset category on switch
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedType == TransactionType.credit
                                  ? (isDark ? AppColors.surfaceDark : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedType == TransactionType.credit
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.arrowUpRight,
                                  size: 16,
                                  color: _selectedType == TransactionType.credit
                                      ? AppColors.credit
                                      : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Credit',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _selectedType == TransactionType.credit
                                        ? AppColors.credit
                                        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Amount Input Field
                Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('transaction_amount_field'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _selectedType == TransactionType.expense
                        ? AppColors.expense
                        : AppColors.credit,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Text(
                        currencySymbol,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _selectedType == TransactionType.expense
                              ? AppColors.expense
                              : AppColors.credit,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: '0.00',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final numVal = double.tryParse(value.trim());
                    if (numVal == null || numVal <= 0) {
                      return 'Amount must be greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 3. Category Selector
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  loading: () => const SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (err, stack) => Text('Failed to load categories: $err'),
                  data: (categories) {
                    final targetType = _selectedType == TransactionType.expense ? 'EXPENSE' : 'CREDIT';
                    final filteredCategories = categories
                        .where((c) => c.type.toUpperCase() == targetType)
                        .toList();

                    if (filteredCategories.isEmpty) {
                      return const Text('No categories found for this type.');
                    }

                    final effectiveCategoryId = (_selectedCategoryId != null &&
                            filteredCategories.any((c) => c.id == _selectedCategoryId))
                        ? _selectedCategoryId!
                        : filteredCategories.first.id;

                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      key: ValueKey('category_dropdown_${_selectedType.name}_$effectiveCategoryId'),
                      initialValue: effectiveCategoryId,
                      items: filteredCategories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.tag, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Flexible(child: Text(cat.name, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                        });
                      },
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 4. Account Selector
                Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                accountsAsync.when(
                  loading: () => const SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (err, stack) => Text('Failed to load accounts: $err'),
                  data: (accounts) {
                    final activeAccounts = accounts.where((a) => a.isActive).toList();

                    if (activeAccounts.isEmpty) {
                      return const Text('No active accounts found.');
                    }

                    final effectiveAccountId = (_selectedAccountId != null &&
                            activeAccounts.any((a) => a.id == _selectedAccountId))
                        ? _selectedAccountId!
                        : activeAccounts.first.id;

                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      key: ValueKey('account_dropdown_$effectiveAccountId'),
                      initialValue: effectiveAccountId,
                      items: activeAccounts.map((acc) {
                        return DropdownMenuItem<String>(
                          value: acc.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.wallet, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Flexible(child: Text(acc.name, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedAccountId = val;
                        });
                      },
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 5. Date Picker
                Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                AppCard(
                  onTap: _selectDate,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  borderRadius: 12,
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Payment Method Selector (Optional)
                Text(
                  'Payment Method (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: const Key('transaction_payment_method_dropdown'),
                  initialValue: _selectedPaymentMethod,
                  items: _paymentMethods.map((pm) {
                    return DropdownMenuItem<String>(
                      value: pm,
                      child: Text(pm),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedPaymentMethod = val;
                    });
                  },
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),

                // 7. Description / Note
                Text(
                  'Description / Note (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('transaction_description_field'),
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Lunch with team, monthly salary, etc.',
                  ),
                ),
                const SizedBox(height: 32),

                // 8. Save Button
                AppButton(
                  key: const Key('save_transaction_button'),
                  label: _isSaving
                      ? 'Saving...'
                      : (isEditing ? 'Update Transaction' : 'Save Transaction'),
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _saveTransaction,
                  type: AppButtonType.primary,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                  type: AppButtonType.outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
