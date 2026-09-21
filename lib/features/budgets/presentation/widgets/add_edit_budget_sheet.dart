import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../transactions/presentation/providers/data_providers.dart';
import '../../domain/models/budget_model.dart';
import '../../domain/models/budget_period.dart';
import '../providers/budget_providers.dart';

class AddEditBudgetSheet extends ConsumerStatefulWidget {
  const AddEditBudgetSheet({
    super.key,
    this.budgetToEdit,
    this.currencySymbol = '₹',
  });

  final BudgetModel? budgetToEdit;
  final String currencySymbol;

  @override
  ConsumerState<AddEditBudgetSheet> createState() => _AddEditBudgetSheetState();
}

class _AddEditBudgetSheetState extends ConsumerState<AddEditBudgetSheet> {
  final _formKey = GlobalKey<FormState>();

  late bool _isOverall;
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late BudgetPeriod _selectedPeriod;
  late double _alertThreshold;
  late bool _isActive;

  String? _selectedCategoryId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.budgetToEdit;
    _isOverall = edit != null ? edit.isOverallBudget : true;
    _selectedCategoryId = edit?.categoryId;
    _nameController = TextEditingController(
      text: edit?.name ?? (_isOverall ? 'Overall Monthly Budget' : ''),
    );
    _amountController = TextEditingController(
      text: edit != null ? edit.amount.toStringAsFixed(0) : '',
    );
    _selectedPeriod = edit?.period ?? BudgetPeriod.monthly;
    _alertThreshold = edit?.alertThreshold ?? 0.80;
    _isActive = edit?.isActive ?? true;
    _startDate = edit?.startDate ?? DateTime.now();
    _endDate = edit?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initialDate = isStart ? _startDate : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(budgetControllerProvider.notifier);

      if (widget.budgetToEdit != null) {
        final updated = widget.budgetToEdit!.copyWith(
          name: _nameController.text.trim(),
          amount: amount,
          categoryId: _isOverall ? null : _selectedCategoryId,
          clearCategoryId: _isOverall,
          period: _selectedPeriod,
          startDate: _startDate,
          endDate: _selectedPeriod == BudgetPeriod.custom ? _endDate : null,
          clearEndDate: _selectedPeriod != BudgetPeriod.custom,
          alertThreshold: _alertThreshold,
          isActive: _isActive,
        );
        await controller.updateBudget(updated);
      } else {
        await controller.createBudget(
          name: _nameController.text.trim(),
          amount: amount,
          categoryId: _isOverall ? null : _selectedCategoryId,
          period: _selectedPeriod.value,
          startDate: _startDate,
          endDate: _selectedPeriod == BudgetPeriod.custom ? _endDate : null,
          alertThreshold: _alertThreshold,
          isActive: _isActive,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.budgetToEdit != null
                  ? 'Budget updated successfully'
                  : 'Budget created successfully',
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
            content: Text('Failed to save budget: $e'),
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
    final categoriesAsync = ref.watch(categoriesProvider);
    final expenseCategories = (categoriesAsync.value ?? [])
        .where((c) => c.type.toUpperCase() == 'EXPENSE')
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                    widget.budgetToEdit != null ? 'Edit Budget' : 'Set New Budget',
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

              // ── Scope Selector (Overall vs Category) ─────────────────────
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Overall Budget'),
                    icon: Icon(LucideIcons.wallet, size: 16),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Category Budget'),
                    icon: Icon(LucideIcons.tag, size: 16),
                  ),
                ],
                selected: {_isOverall},
                onSelectionChanged: (selection) {
                  final overall = selection.first;
                  setState(() {
                    _isOverall = overall;
                    if (_isOverall) {
                      _selectedCategoryId = null;
                      if (_nameController.text.isEmpty ||
                          _nameController.text.contains('Budget')) {
                        _nameController.text = 'Overall Monthly Budget';
                      }
                    } else if (expenseCategories.isNotEmpty) {
                      _selectedCategoryId ??= expenseCategories.first.id;
                      final selectedCat = expenseCategories.firstWhere(
                        (c) => c.id == _selectedCategoryId,
                        orElse: () => expenseCategories.first,
                      );
                      _nameController.text = '${selectedCat.name} Budget';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // ── Category Dropdown (if Category Budget) ───────────────────
              if (!_isOverall) ...[
                Text(
                  'Category',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId ??
                      (expenseCategories.isNotEmpty
                          ? expenseCategories.first.id
                          : null),
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(LucideIcons.tag, size: 18, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: expenseCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (catId) {
                    if (catId != null) {
                      setState(() {
                        _selectedCategoryId = catId;
                        final cat = expenseCategories
                            .firstWhere((c) => c.id == catId);
                        _nameController.text = '${cat.name} Budget';
                      });
                    }
                  },
                  validator: (val) =>
                      val == null ? 'Please select a category' : null,
                ),
                const SizedBox(height: 14),
              ],

              // ── Budget Name ──────────────────────────────────────────────
              Text(
                'Budget Name',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Food & Dining, Shopping, Overall',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 14),

              // ── Budget Amount ────────────────────────────────────────────
              Text(
                'Spending Limit (${widget.currencySymbol})',
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
                  hintText: '5000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter budget limit amount';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── Period Selector ──────────────────────────────────────────
              Text(
                'Budget Period',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: BudgetPeriod.values.map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Center(
                          child: Text(
                            period.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPeriod = period;
                              if (period == BudgetPeriod.custom &&
                                  _endDate == null) {
                                _endDate =
                                    _startDate.add(const Duration(days: 30));
                              }
                            });
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // ── Custom Dates (if Custom Period) ──────────────────────────
              if (_selectedPeriod == BudgetPeriod.custom) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.calendar, size: 14),
                        label: Text(
                          'From: ${DateFormat('dd MMM yyyy').format(_startDate)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () => _pickDate(true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.calendar, size: 14),
                        label: Text(
                          _endDate != null
                              ? 'To: ${DateFormat('dd MMM yyyy').format(_endDate!)}'
                              : 'Pick End Date',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () => _pickDate(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Alert Threshold Slider ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Warning Alert Threshold',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(_alertThreshold * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _alertThreshold,
                min: 0.50,
                max: 1.00,
                divisions: 10,
                activeColor: const Color(0xFFF59E0B),
                label: '${(_alertThreshold * 100).toInt()}%',
                onChanged: (val) => setState(() => _alertThreshold = val),
              ),
              Text(
                'We will highlight this budget in yellow when spending reaches ${(_alertThreshold * 100).toInt()}% of the limit.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 20),

              // ── Submit Button ────────────────────────────────────────────
              AppButton(
                label: widget.budgetToEdit != null
                    ? 'Save Changes'
                    : 'Create Budget',
                isLoading: _isLoading,
                type: AppButtonType.primary,
                onPressed: _saveBudget,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
