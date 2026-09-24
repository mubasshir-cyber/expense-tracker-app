import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../domain/models/debt_model.dart';
import '../../domain/models/debt_type.dart';
import '../providers/debt_providers.dart';

/// Modal bottom sheet to record a partial or full payment against a debt or loan.
class RecordRepaymentSheet extends ConsumerStatefulWidget {
  const RecordRepaymentSheet({
    super.key,
    required this.debt,
    this.currencySymbol = '₹',
  });

  final DebtModel debt;
  final String currencySymbol;

  @override
  ConsumerState<RecordRepaymentSheet> createState() => _RecordRepaymentSheetState();
}

class _RecordRepaymentSheetState extends ConsumerState<RecordRepaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  DateTime _repaymentDate = DateTime.now();
  String? _selectedAccountId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
    _selectedAccountId = widget.debt.accountId;
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
      initialDate: _repaymentDate,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _repaymentDate = picked);
    }
  }

  void _fillFullAmount() {
    setState(() {
      _amountController.text = widget.debt.remainingAmount.toStringAsFixed(
        widget.debt.remainingAmount % 1 == 0 ? 0 : 2,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(debtControllerProvider.notifier).recordRepayment(
        debtId: widget.debt.id,
        amount: amount,
        repaymentDate: _repaymentDate,
        accountId: _selectedAccountId,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of ${widget.currencySymbol}$amount recorded successfully.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record payment: $e'),
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

    final isYouOwe = widget.debt.type == DebtType.youOwe;
    final actionTitle = isYouOwe ? 'Record Repayment' : 'Receive Payment';
    final actionSubtitle = isYouOwe
        ? 'Log payment made to ${widget.debt.personName}'
        : 'Log payment received from ${widget.debt.personName}';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actionTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        actionSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
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
              const SizedBox(height: 16),

              // ── Outstanding Balance Banner ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OUTSTANDING BALANCE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.currencySymbol}${formatter.format(widget.debt.remainingAmount)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _fillFullAmount,
                      icon: const Icon(LucideIcons.checkCheck, size: 14),
                      label: const Text('Full Pay'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Amount Input ─────────────────────────────────────────────
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Payment Amount *',
                  hintText: '0.00',
                  prefixText: '${widget.currencySymbol} ',
                  prefixIcon: const Icon(LucideIcons.indianRupee),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  if (parsed > widget.debt.remainingAmount + 0.01) {
                    return 'Cannot exceed outstanding balance (${widget.currencySymbol}${formatter.format(widget.debt.remainingAmount)})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── Date Picker ──────────────────────────────────────────────
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Payment Date',
                    prefixIcon: Icon(LucideIcons.calendar),
                  ),
                  child: Text(
                    DateFormat('EEE, dd MMM yyyy').format(_repaymentDate),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Account Selector ─────────────────────────────────────────
              accountsAsync.when(
                data: (accounts) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Payment Account (Optional)',
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
              const SizedBox(height: 14),

              // ── Notes ────────────────────────────────────────────────────
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Payment Notes (Optional)',
                  hintText: 'e.g. Paid via Google Pay, installment #2',
                  prefixIcon: Icon(LucideIcons.fileText),
                ),
              ),
              const SizedBox(height: 24),

              // ── Submit Button ────────────────────────────────────────────
              AppButton(
                label: 'Save Payment',
                isLoading: _isSaving,
                type: AppButtonType.primary,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
