import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/models/debt_model.dart';
import '../../domain/models/debt_type.dart';
import '../../domain/models/interest_type.dart';
import '../providers/debt_providers.dart';

/// Modal bottom sheet form for creating or editing a debt/loan with interest and installment options.
class AddEditDebtSheet extends ConsumerStatefulWidget {
  const AddEditDebtSheet({
    super.key,
    this.debtToEdit,
    this.initialType,
  });

  final DebtModel? debtToEdit;
  final DebtType? initialType;

  @override
  ConsumerState<AddEditDebtSheet> createState() => _AddEditDebtSheetState();
}

class _AddEditDebtSheetState extends ConsumerState<AddEditDebtSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _principalController;
  late final TextEditingController _interestRateController;
  late final TextEditingController _fixedInterestController;
  late final TextEditingController _totalReturnController;
  late final TextEditingController _installmentCountController;
  late final TextEditingController _notesController;

  late DebtType _selectedType;
  late InterestType _selectedInterestType;
  DateTime? _dueDate;
  DateTime _installmentStartDate = DateTime.now();
  String? _selectedAccountId;
  bool _enableInstallments = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.debtToEdit;
    _selectedType = d?.type ?? widget.initialType ?? DebtType.youAreOwed;
    _selectedInterestType = d?.interestType ?? InterestType.none;

    _nameController = TextEditingController(text: d?.personName ?? '');
    _contactController = TextEditingController(text: d?.contactNumber ?? '');
    _principalController = TextEditingController(
      text: d != null ? d.principalAmount.toStringAsFixed(d.principalAmount % 1 == 0 ? 0 : 2) : '',
    );
    _interestRateController = TextEditingController(
      text: d != null && d.interestRate > 0 ? d.interestRate.toStringAsFixed(2) : '',
    );
    _fixedInterestController = TextEditingController(
      text: d != null && d.interestAmount > 0 ? d.interestAmount.toStringAsFixed(d.interestAmount % 1 == 0 ? 0 : 2) : '',
    );
    _totalReturnController = TextEditingController(
      text: d != null ? d.totalRepaymentAmount.toStringAsFixed(d.totalRepaymentAmount % 1 == 0 ? 0 : 2) : '',
    );
    _installmentCountController = TextEditingController(text: '6');
    _notesController = TextEditingController(text: d?.notes ?? '');

    _dueDate = d?.dueDate;
    _selectedAccountId = d?.accountId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _principalController.dispose();
    _interestRateController.dispose();
    _fixedInterestController.dispose();
    _totalReturnController.dispose();
    _installmentCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _principal {
    return double.tryParse(_principalController.text.trim()) ?? 0.0;
  }

  double get _interestAmount {
    if (_selectedInterestType == InterestType.none) return 0.0;
    if (_selectedInterestType == InterestType.percentage) {
      final rate = double.tryParse(_interestRateController.text.trim()) ?? 0.0;
      return _principal * (rate / 100.0);
    }
    // Fixed / Total Amount mode
    final fixed = double.tryParse(_fixedInterestController.text.trim());
    if (fixed != null && fixed >= 0) return fixed;

    final total = double.tryParse(_totalReturnController.text.trim());
    if (total != null && total >= _principal) return total - _principal;

    return 0.0;
  }

  double get _calculatedRate {
    if (_principal <= 0) return 0.0;
    if (_selectedInterestType == InterestType.percentage) {
      return double.tryParse(_interestRateController.text.trim()) ?? 0.0;
    }
    return (_interestAmount / _principal) * 100.0;
  }

  double get _totalRepayment {
    return _principal + _interestAmount;
  }

  void _onPrincipalChanged(String val) {
    final p = double.tryParse(val.trim()) ?? 0.0;
    if (p <= 0) {
      setState(() {});
      return;
    }

    if (_selectedInterestType == InterestType.percentage) {
      final rate = double.tryParse(_interestRateController.text.trim()) ?? 0.0;
      final extra = p * (rate / 100.0);
      _fixedInterestController.text = extra > 0 ? extra.toStringAsFixed(extra % 1 == 0 ? 0 : 2) : '';
      _totalReturnController.text = (p + extra).toStringAsFixed((p + extra) % 1 == 0 ? 0 : 2);
    } else if (_selectedInterestType == InterestType.fixed) {
      final extra = double.tryParse(_fixedInterestController.text.trim()) ?? 0.0;
      if (extra > 0) {
        final rate = (extra / p) * 100.0;
        _interestRateController.text = rate.toStringAsFixed(2);
        _totalReturnController.text = (p + extra).toStringAsFixed((p + extra) % 1 == 0 ? 0 : 2);
      }
    }
    setState(() {});
  }

  void _onRateChanged(String val) {
    final rate = double.tryParse(val.trim()) ?? 0.0;
    final p = _principal;
    if (p > 0) {
      final extra = p * (rate / 100.0);
      _fixedInterestController.text = extra > 0 ? extra.toStringAsFixed(extra % 1 == 0 ? 0 : 2) : '';
      _totalReturnController.text = (p + extra).toStringAsFixed((p + extra) % 1 == 0 ? 0 : 2);
    }
    setState(() {});
  }

  void _onFixedInterestChanged(String val) {
    final extra = double.tryParse(val.trim()) ?? 0.0;
    final p = _principal;
    if (p > 0) {
      final rate = (extra / p) * 100.0;
      _interestRateController.text = rate > 0 ? rate.toStringAsFixed(2) : '';
      _totalReturnController.text = (p + extra).toStringAsFixed((p + extra) % 1 == 0 ? 0 : 2);
    }
    setState(() {});
  }

  void _onTotalReturnChanged(String val) {
    final total = double.tryParse(val.trim()) ?? 0.0;
    final p = _principal;
    if (p > 0 && total >= p) {
      final extra = total - p;
      final rate = (extra / p) * 100.0;
      _fixedInterestController.text = extra > 0 ? extra.toStringAsFixed(extra % 1 == 0 ? 0 : 2) : '';
      _interestRateController.text = rate > 0 ? rate.toStringAsFixed(2) : '';
    }
    setState(() {});
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 30)),
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickInstallmentStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _installmentStartDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _installmentStartDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authStateProvider);
    final supabaseUser = SupabaseConfig.client.auth.currentUser;
    final userId = supabaseUser?.id ??
        (authState.value is AuthAuthenticated ? (authState.value as AuthAuthenticated).user.id : '');

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session not found. Please log in again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final calc = ref.read(debtCalculationServiceProvider);
      final debtId = widget.debtToEdit?.id ?? '';

      final debt = DebtModel(
        id: debtId,
        userId: userId,
        type: _selectedType,
        personName: _nameController.text.trim(),
        contactNumber: _contactController.text.trim().isNotEmpty
            ? _contactController.text.trim()
            : null,
        principalAmount: _principal,
        interestType: _selectedInterestType,
        interestRate: _calculatedRate,
        interestAmount: _interestAmount,
        totalRepaymentAmount: _totalRepayment,
        dueDate: _dueDate,
        accountId: _selectedAccountId,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: widget.debtToEdit?.createdAt ?? DateTime.now(),
      );

      if (widget.debtToEdit != null) {
        await ref.read(debtControllerProvider.notifier).updateDebt(debt);
      } else {
        var installments = const <dynamic>[];
        if (_enableInstallments) {
          final count = int.tryParse(_installmentCountController.text.trim()) ?? 1;
          installments = calc.generateInstallments(
            debtId: debtId,
            userId: userId,
            principal: _principal,
            interestAmount: _interestAmount,
            installmentCount: count,
            startDate: _installmentStartDate,
          );
        }

        await ref.read(debtControllerProvider.notifier).createDebt(
          debt: debt,
          installments: installments.cast(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.debtToEdit != null
                  ? 'Debt record updated successfully.'
                  : 'Debt record created successfully.',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
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

    final isEdit = widget.debtToEdit != null;

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
                  Text(
                    isEdit ? 'Edit Debt / Loan' : 'Add Debt / Loan',
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

              // ── Type Selector Segment ─────────────────────────────────────
              SegmentedButton<DebtType>(
                segments: const [
                  ButtonSegment(
                    value: DebtType.youAreOwed,
                    label: Text('I Lent (Owed to me)'),
                    icon: Icon(LucideIcons.arrowDownLeft, size: 16),
                  ),
                  ButtonSegment(
                    value: DebtType.youOwe,
                    label: Text('I Borrowed (I Owe)'),
                    icon: Icon(LucideIcons.arrowUpRight, size: 16),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (set) {
                  setState(() => _selectedType = set.first);
                },
              ),
              const SizedBox(height: 16),

              // ── Person Name ───────────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _selectedType == DebtType.youAreOwed
                      ? 'Borrower / Person Name *'
                      : 'Lender / Creditor Name *',
                  hintText: 'e.g. Amaan, Bank, Landlord',
                  prefixIcon: const Icon(LucideIcons.user),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── Contact Number ────────────────────────────────────────────
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Number (Optional)',
                  hintText: 'e.g. +91 98765 43210',
                  prefixIcon: Icon(LucideIcons.phone),
                ),
              ),
              const SizedBox(height: 14),

              // ── Principal Amount ──────────────────────────────────────────
              TextFormField(
                controller: _principalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Principal Amount *',
                  hintText: '0.00',
                  prefixIcon: Icon(LucideIcons.indianRupee),
                ),
                onChanged: _onPrincipalChanged,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter principal amount';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid positive amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // ── Interest Type Selector ────────────────────────────────────
              Text(
                'INTEREST SETTINGS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: InterestType.values.map((type) {
                  final isSelected = _selectedInterestType == type;
                  final labelText = type == InterestType.fixed ? 'Fixed / Total (₹)' : type.label;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(
                          labelText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedInterestType = type;
                              if (type == InterestType.none) {
                                _interestRateController.clear();
                                _fixedInterestController.clear();
                                if (_principal > 0) {
                                  _totalReturnController.text = _principal.toStringAsFixed(_principal % 1 == 0 ? 0 : 2);
                                }
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

              // ── Interest Input (Conditional) ──────────────────────────────
              if (_selectedInterestType == InterestType.percentage) ...[
                TextFormField(
                  controller: _interestRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Interest Rate (%)',
                    hintText: 'e.g. 10.64 for 10.64%',
                    prefixIcon: const Icon(LucideIcons.percent),
                    helperText: _principal > 0 && _interestAmount > 0
                        ? 'Extra: ₹${formatter.format(_interestAmount)} | Total: ₹${formatter.format(_totalRepayment)}'
                        : null,
                  ),
                  onChanged: _onRateChanged,
                  validator: (val) {
                    if (_selectedInterestType == InterestType.percentage) {
                      if (val == null || val.trim().isEmpty) return 'Enter interest rate';
                      final r = double.tryParse(val.trim());
                      if (r == null || r < 0) return 'Enter a valid rate';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ] else if (_selectedInterestType == InterestType.fixed) ...[
                // Option A: Total Return Amount
                TextFormField(
                  controller: _totalReturnController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _selectedType == DebtType.youAreOwed
                        ? 'Total Amount to Receive (₹)'
                        : 'Total Amount to Return / Repay (₹)',
                    hintText: 'e.g. 52000',
                    prefixIcon: const Icon(LucideIcons.banknote),
                    helperText: _principal > 0 && _calculatedRate > 0
                        ? 'Calculated Rate: ${_calculatedRate.toStringAsFixed(2)}% | Extra: ₹${formatter.format(_interestAmount)}'
                        : 'Enter total amount including extra/interest',
                  ),
                  onChanged: _onTotalReturnChanged,
                  validator: (val) {
                    if (_selectedInterestType == InterestType.fixed) {
                      final total = double.tryParse(val?.trim() ?? '');
                      if (total != null && total < _principal) {
                        return 'Total return cannot be less than principal';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // Option B: Extra Profit / Interest
                TextFormField(
                  controller: _fixedInterestController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Extra Profit / Interest Amount (₹)',
                    hintText: 'e.g. 5000',
                    prefixIcon: const Icon(LucideIcons.plusCircle),
                    helperText: _principal > 0 && _calculatedRate > 0
                        ? 'Calculated Rate: ${_calculatedRate.toStringAsFixed(2)}%'
                        : null,
                  ),
                  onChanged: _onFixedInterestChanged,
                  validator: (val) {
                    if (_selectedInterestType == InterestType.fixed) {
                      final f = double.tryParse(val?.trim() ?? '');
                      if (f != null && f < 0) return 'Enter a valid positive amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],

              // ── Dynamic Expected Repayment Calculation Card ───────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Principal Amount', style: TextStyle(fontSize: 13)),
                        Text('₹${formatter.format(_principal)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Agreed Interest', style: TextStyle(fontSize: 13)),
                        Text('₹${formatter.format(_interestAmount)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedType == DebtType.youAreOwed
                              ? 'Total to Receive'
                              : 'Total to Repay',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${formatter.format(_totalRepayment)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Due Date Picker ───────────────────────────────────────────
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Overall Due Date (Optional)',
                    prefixIcon: Icon(LucideIcons.calendar),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dueDate != null
                            ? DateFormat('EEE, dd MMM yyyy').format(_dueDate!)
                            : 'No deadline set',
                        style: TextStyle(
                          color: _dueDate != null
                              ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                              : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                        ),
                      ),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: const Icon(Icons.clear, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Installments Schedule Generator (Create only) ─────────────
              if (!isEdit) ...[
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Split into Monthly Installments'),
                  subtitle: const Text('Generate structured monthly EMI / payment schedule'),
                  value: _enableInstallments,
                  onChanged: (val) => setState(() => _enableInstallments = val),
                ),
                if (_enableInstallments) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _installmentCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'No. of Months',
                            prefixIcon: Icon(LucideIcons.calendarRange),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _pickInstallmentStartDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Date',
                              prefixIcon: Icon(LucideIcons.calendar),
                            ),
                            child: Text(
                              DateFormat('dd MMM yyyy').format(_installmentStartDate),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ],

              // ── Linked Account Selector (Optional) ────────────────────────
              accountsAsync.when(
                data: (accounts) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Disbursement / Linked Account (Optional)',
                      prefixIcon: Icon(LucideIcons.wallet),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None (Unspecified)'),
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

              // ── Notes ─────────────────────────────────────────────────────
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes / Agreement Details (Optional)',
                  hintText: 'e.g. For emergency car repairs, paid via UPI',
                  prefixIcon: Icon(LucideIcons.fileText),
                ),
              ),
              const SizedBox(height: 24),

              // ── Submit Button ─────────────────────────────────────────────
              AppButton(
                label: isEdit ? 'Save Changes' : 'Create Debt / Loan',
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
