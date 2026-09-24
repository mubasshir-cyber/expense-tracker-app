import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../transactions/presentation/providers/data_providers.dart';
import '../../domain/models/savings_goal_model.dart';
import '../providers/goal_providers.dart';

class AddEditGoalSheet extends ConsumerStatefulWidget {
  const AddEditGoalSheet({
    super.key,
    this.goalToEdit,
  });

  final SavingsGoalModel? goalToEdit;

  @override
  ConsumerState<AddEditGoalSheet> createState() => _AddEditGoalSheetState();
}

class _AddEditGoalSheetState extends ConsumerState<AddEditGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  DateTime? _targetDate;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  String _selectedIcon = 'piggy-bank';
  String _selectedColor = '#4F46E5';
  bool _isActive = true;
  bool _isSaving = false;

  static const List<(String id, String label, IconData icon)> _iconOptions = [
    ('piggy-bank', 'Savings', LucideIcons.piggyBank),
    ('shield', 'Emergency', LucideIcons.shieldCheck),
    ('plane', 'Vacation', LucideIcons.plane),
    ('car', 'Vehicle', LucideIcons.car),
    ('laptop', 'Tech', LucideIcons.laptop),
    ('home', 'House', LucideIcons.home),
    ('gift', 'Gift', LucideIcons.gift),
    ('heart', 'Personal', LucideIcons.heart),
    ('education', 'Education', LucideIcons.graduationCap),
    ('target', 'Goal', LucideIcons.target),
  ];

  static const List<(String hex, Color color)> _colorOptions = [
    ('#4F46E5', Color(0xFF4F46E5)), // Indigo
    ('#10B981', Color(0xFF10B981)), // Emerald Green
    ('#8B5CF6', Color(0xFF8B5CF6)), // Purple
    ('#F59E0B', Color(0xFFF59E0B)), // Amber
    ('#06B6D4', Color(0xFF06B6D4)), // Cyan
    ('#EC4899', Color(0xFFEC4899)), // Pink
    ('#F97316', Color(0xFFF97316)), // Orange
    ('#3B82F6', Color(0xFF3B82F6)), // Blue
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.goalToEdit;
    _nameController = TextEditingController(text: g?.name ?? '');
    _amountController = TextEditingController(
      text: g != null ? g.targetAmount.toStringAsFixed(0) : '',
    );
    _notesController = TextEditingController(text: g?.notes ?? '');
    _targetDate = g?.targetDate;
    _selectedAccountId = g?.accountId;
    _selectedCategoryId = g?.categoryId;
    _selectedIcon = g?.icon ?? 'piggy-bank';
    _selectedColor = g?.color ?? '#4F46E5';
    _isActive = g?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: DateTime(now.year + 20),
    );

    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final targetAmount = double.tryParse(_amountController.text.trim());
    if (targetAmount == null || targetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target amount')),
      );
      return;
    }

    final authState = ref.read(authStateProvider);
    final user = authState.value is AuthAuthenticated
        ? (authState.value as AuthAuthenticated).user
        : null;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final controller = ref.read(savingsGoalControllerProvider.notifier);

      if (widget.goalToEdit != null) {
        final updated = widget.goalToEdit!.copyWith(
          name: _nameController.text.trim(),
          targetAmount: targetAmount,
          targetDate: _targetDate,
          clearTargetDate: _targetDate == null,
          icon: _selectedIcon,
          color: _selectedColor,
          accountId: _selectedAccountId,
          clearAccountId: _selectedAccountId == null,
          categoryId: _selectedCategoryId,
          clearCategoryId: _selectedCategoryId == null,
          isActive: _isActive,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );
        await controller.updateGoal(updated);
      } else {
        final newGoal = SavingsGoalModel(
          id: '',
          userId: user.id,
          name: _nameController.text.trim(),
          targetAmount: targetAmount,
          targetDate: _targetDate,
          icon: _selectedIcon,
          color: _selectedColor,
          accountId: _selectedAccountId,
          categoryId: _selectedCategoryId,
          isActive: _isActive,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          createdAt: DateTime.now(),
        );
        await controller.createGoal(newGoal);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.goalToEdit != null
                  ? 'Goal updated successfully.'
                  : 'Goal created successfully.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save goal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.goalToEdit != null;

    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              // ── Header ─────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Savings Goal' : 'Create Savings Goal',
                    style: theme.textTheme.titleLarge?.copyWith(
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

              // ── Goal Name (Required) ───────────────────────────────────────
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Goal Name *',
                  hintText: 'e.g., Emergency Fund, Vacation to Bali',
                  prefixIcon: Icon(LucideIcons.target),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a goal name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Target Amount (Required) ───────────────────────────────────
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target Amount (₹) *',
                  hintText: 'e.g., 50000',
                  prefixIcon: Icon(LucideIcons.indianRupee),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a target amount';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Target Date Picker (Optional) ──────────────────────────────
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Date (Optional)',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _targetDate != null
                                  ? DateFormat('dd MMMM yyyy').format(_targetDate!)
                                  : 'No deadline set',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_targetDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _targetDate = null),
                        )
                      else
                        const Icon(LucideIcons.chevronRight, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Icon Selector ──────────────────────────────────────────────
              Text(
                'CHOOSE ICON',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _iconOptions.map((opt) {
                    final isSelected = _selectedIcon == opt.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = opt.$1),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          opt.$3,
                          size: 22,
                          color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // ── Color Palette Selector ─────────────────────────────────────
              Text(
                'COLOR THEME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _colorOptions.map((opt) {
                    final isSelected = _selectedColor == opt.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = opt.$1),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: opt.$2,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: opt.$2.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // ── Default Funding Account (Optional) ─────────────────────────
              accountsAsync.when(
                data: (accounts) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Default Funding Account (Optional)',
                      prefixIcon: Icon(LucideIcons.wallet),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None (Select on deposit)'),
                      ),
                      ...accounts.map(
                        (acc) => DropdownMenuItem(
                          value: acc.id,
                          child: Text('${acc.name} (${acc.type})'),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedAccountId = val),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // ── Category Link (Optional) ───────────────────────────────────
              categoriesAsync.when(
                data: (categories) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Linked Category (Optional)',
                      prefixIcon: Icon(LucideIcons.tag),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None'),
                      ),
                      ...categories.map(
                        (cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // ── Notes (Optional) ───────────────────────────────────────────
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes / Motivation (Optional)',
                  hintText: 'Why are you saving for this goal?',
                  prefixIcon: Icon(LucideIcons.fileText),
                ),
              ),
              const SizedBox(height: 24),

              // ── Submit Button ──────────────────────────────────────────────
              AppButton(
                label: isEditing ? 'Save Changes' : 'Create Goal',
                type: AppButtonType.primary,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
