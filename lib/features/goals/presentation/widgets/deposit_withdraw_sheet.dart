import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../domain/models/savings_goal_model.dart';
import '../providers/goal_providers.dart';

class DepositWithdrawSheet extends ConsumerStatefulWidget {
  const DepositWithdrawSheet({
    super.key,
    required this.goal,
    required this.isDeposit,
    this.currencySymbol = '₹',
  });

  final SavingsGoalModel goal;
  final bool isDeposit;
  final String currencySymbol;

  @override
  ConsumerState<DepositWithdrawSheet> createState() =>
      _DepositWithdrawSheetState();
}

class _DepositWithdrawSheetState extends ConsumerState<DepositWithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
    _selectedAccountId = widget.goal.accountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (!widget.isDeposit && amount > widget.goal.currentAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Withdrawal amount cannot exceed current saved balance (${widget.currencySymbol}${widget.goal.currentAmount.toStringAsFixed(0)}).',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final controller = ref.read(savingsGoalControllerProvider.notifier);

      if (widget.isDeposit) {
        await controller.addDeposit(
          goalId: widget.goal.id,
          amount: amount,
          accountId: _selectedAccountId,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          date: _selectedDate,
        );
      } else {
        await controller.withdrawFunds(
          goalId: widget.goal.id,
          amount: amount,
          accountId: _selectedAccountId,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          date: _selectedDate,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isDeposit
                  ? 'Deposit of ${widget.currencySymbol}${amount.toStringAsFixed(0)} logged.'
                  : 'Withdrawal of ${widget.currencySymbol}${amount.toStringAsFixed(0)} logged.',
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
            content: Text('Transaction failed: $e'),
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
    final accountsAsync = ref.watch(accountsProvider);
    final formatter = NumberFormat('#,##,##0.##', 'en_IN');
    final formattedBalance =
        '${widget.currencySymbol}${formatter.format(widget.goal.currentAmount)}';

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.isDeposit
                              ? AppColors.credit.withValues(alpha: 0.15)
                              : AppColors.error.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isDeposit
                              ? LucideIcons.plusCircle
                              : LucideIcons.minusCircle,
                          size: 20,
                          color: widget.isDeposit ? AppColors.credit : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.isDeposit ? 'Add Money to Goal' : 'Withdraw from Goal',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Goal Context Banner ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.goal.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Current: $formattedBalance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Amount Input ───────────────────────────────────────────────
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: widget.isDeposit
                      ? 'Deposit Amount (${widget.currencySymbol}) *'
                      : 'Withdrawal Amount (${widget.currencySymbol}) *',
                  hintText: 'e.g., 5000',
                  prefixIcon: const Icon(LucideIcons.indianRupee),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  if (!widget.isDeposit && parsed > widget.goal.currentAmount) {
                    return 'Cannot withdraw more than saved balance ($formattedBalance)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Account Selector ───────────────────────────────────────────
              accountsAsync.when(
                data: (accounts) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Funding Account (Optional)',
                      prefixIcon: Icon(LucideIcons.wallet),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Unspecified Account'),
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

              // ── Date Picker ────────────────────────────────────────────────
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
                        child: Text(
                          DateFormat('dd MMMM yyyy').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Notes / Memo ───────────────────────────────────────────────
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'e.g., Monthly savings allocation',
                  prefixIcon: Icon(LucideIcons.fileText),
                ),
              ),
              const SizedBox(height: 24),

              // ── Action Button ──────────────────────────────────────────────
              AppButton(
                label: widget.isDeposit ? 'Add Deposit' : 'Confirm Withdrawal',
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
