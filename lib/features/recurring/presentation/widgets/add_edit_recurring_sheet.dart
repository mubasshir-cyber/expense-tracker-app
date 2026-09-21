import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../transactions/domain/models/transaction_type.dart';
import '../../../transactions/presentation/providers/data_providers.dart';
import '../../domain/models/recurring_frequency.dart';
import '../../domain/models/recurring_transaction_model.dart';
import '../providers/recurring_providers.dart';

class AddEditRecurringSheet extends ConsumerStatefulWidget {
  const AddEditRecurringSheet({
    super.key,
    this.itemToEdit,
    this.currencySymbol = '₹',
  });

  final RecurringTransactionModel? itemToEdit;
  final String currencySymbol;

  @override
  ConsumerState<AddEditRecurringSheet> createState() =>
      _AddEditRecurringSheetState();
}

class _AddEditRecurringSheetState extends ConsumerState<AddEditRecurringSheet> {
  final _formKey = GlobalKey<FormState>();

  late TransactionType _selectedType;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late RecurringFrequency _selectedFrequency;
  late DateTime _startDate;
  late DateTime _nextOccurrence;
  DateTime? _endDate;
  late bool _autoCreate;
  late bool _isActive;

  String? _selectedAccountId;
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.itemToEdit;
    _selectedType = edit?.type ?? TransactionType.expense;
    _descriptionController = TextEditingController(text: edit?.description ?? '');
    _amountController = TextEditingController(
      text: edit != null ? edit.amount.toStringAsFixed(0) : '',
    );
    _selectedFrequency = edit?.frequency ?? RecurringFrequency.monthly;
    _startDate = edit?.startDate ?? DateTime.now();
    _nextOccurrence = edit?.nextOccurrence ?? DateTime.now();
    _endDate = edit?.endDate;
    _autoCreate = edit?.autoCreate ?? false;
    _isActive = edit?.isActive ?? true;
    _selectedAccountId = edit?.accountId;
    _selectedCategoryId = edit?.categoryId;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(int dateType) async {
    // 0: start, 1: nextOccurrence, 2: end
    final initialDate = dateType == 0
        ? _startDate
        : (dateType == 1 ? _nextOccurrence : (_endDate ?? _nextOccurrence));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (dateType == 0) {
          _startDate = picked;
          if (_nextOccurrence.isBefore(_startDate)) {
            _nextOccurrence = _startDate;
          }
        } else if (dateType == 1) {
          _nextOccurrence = picked;
        } else if (dateType == 2) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveRecurring() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;
    if (_selectedAccountId == null || _selectedCategoryId == null) return;

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(recurringControllerProvider.notifier);

      if (widget.itemToEdit != null) {
        final updated = widget.itemToEdit!.copyWith(
          accountId: _selectedAccountId!,
          categoryId: _selectedCategoryId!,
          type: _selectedType,
          amount: amount,
          description: _descriptionController.text.trim(),
          frequency: _selectedFrequency,
          startDate: _startDate,
          nextOccurrence: _nextOccurrence,
          endDate: _endDate,
          clearEndDate: _endDate == null,
          isActive: _isActive,
          autoCreate: _autoCreate,
        );
        await controller.updateRecurring(updated);
      } else {
        await controller.createRecurring(
          accountId: _selectedAccountId!,
          categoryId: _selectedCategoryId!,
          type: _selectedType.value,
          amount: amount,
          description: _descriptionController.text.trim(),
          frequency: _selectedFrequency.value,
          startDate: _startDate,
          nextOccurrence: _nextOccurrence,
          endDate: _endDate,
          isActive: _isActive,
          autoCreate: _autoCreate,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.itemToEdit != null
                  ? 'Recurring transaction updated'
                  : 'Recurring transaction created',
            ),
            backgroundColor: AppColors.credit,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save recurring item: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.value ?? [];

    final categoriesAsync = ref.watch(categoriesProvider);
    final typeFilteredCategories = (categoriesAsync.value ?? []).where((c) {
      return _selectedType == TransactionType.expense
          ? c.type.toUpperCase() == 'EXPENSE'
          : c.type.toUpperCase() == 'CREDIT';
    }).toList();

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Handle Bar ───────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Title & Close ────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.itemToEdit != null
                        ? 'Edit Recurring Item'
                        : 'New Recurring Transaction',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Type Toggle (Expense vs Income) ──────────────────────────
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(LucideIcons.arrowUpRight, size: 16),
                  ),
                  ButtonSegment(
                    value: TransactionType.credit,
                    label: Text('Income / Credit'),
                    icon: Icon(LucideIcons.arrowDownLeft, size: 16),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedType = selection.first;
                    _selectedCategoryId = null; // Reset category selection on type switch
                  });
                },
              ),
              const SizedBox(height: 16),

              // ── Description Input ────────────────────────────────────────
              Text(
                'Description / Title',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'e.g. Netflix, House Rent, Monthly Salary',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter a description' : null,
              ),
              const SizedBox(height: 14),

              // ── Amount Input ─────────────────────────────────────────────
              Text(
                'Amount (${widget.currencySymbol})',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Text(
                      widget.currencySymbol,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  hintText: '649',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter amount';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── Category & Account Row ───────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategoryId ??
                              (typeFilteredCategories.isNotEmpty
                                  ? typeFilteredCategories.first.id
                                  : null),
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: typeFilteredCategories.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (catId) =>
                              setState(() => _selectedCategoryId = catId),
                          validator: (val) =>
                              val == null ? 'Select category' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Account Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedAccountId ??
                              (accounts.isNotEmpty ? accounts.first.id : null),
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: accounts.map((a) {
                            return DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (accId) =>
                              setState(() => _selectedAccountId = accId),
                          validator: (val) =>
                              val == null ? 'Select account' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Frequency Selector ───────────────────────────────────────
              Text(
                'Frequency',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<RecurringFrequency>(
                initialValue: _selectedFrequency,
                decoration: InputDecoration(
                  prefixIcon: const Icon(LucideIcons.repeat,
                      size: 18, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: RecurringFrequency.values.map((f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Text(f.label),
                  );
                }).toList(),
                onChanged: (freq) {
                  if (freq != null) {
                    setState(() => _selectedFrequency = freq);
                  }
                },
              ),
              const SizedBox(height: 14),

              // ── Next Occurrence Date ─────────────────────────────────────
              Text(
                'Next Occurrence Date',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(LucideIcons.calendar, size: 18),
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMMM yyyy').format(_nextOccurrence),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 16),
                  ],
                ),
                onPressed: () => _pickDate(1),
              ),
              const SizedBox(height: 14),

              // ── Auto-Create Switch ───────────────────────────────────────
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Auto-Create Transaction',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  'Automatically post this transaction into the ledger on due date.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                value: _autoCreate,
                onChanged: (val) => setState(() => _autoCreate = val),
              ),
              const SizedBox(height: 20),

              // ── Submit Button ────────────────────────────────────────────
              AppButton(
                label: widget.itemToEdit != null
                    ? 'Save Changes'
                    : 'Create Recurring Schedule',
                isLoading: _isLoading,
                type: AppButtonType.primary,
                onPressed: _saveRecurring,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
