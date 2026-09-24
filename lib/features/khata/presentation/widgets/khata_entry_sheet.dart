import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/khata_entry_model.dart';
import '../../domain/models/khata_entry_type.dart';
import '../providers/khata_providers.dart';

class KhataEntrySheet extends ConsumerStatefulWidget {
  const KhataEntrySheet({
    super.key,
    required this.customerId,
    this.initialType = KhataEntryType.given,
    this.entryToEdit,
    this.currencySymbol = '₹',
  });

  final String customerId;
  final KhataEntryType initialType;
  final KhataEntryModel? entryToEdit;
  final String currencySymbol;

  @override
  ConsumerState<KhataEntrySheet> createState() => _KhataEntrySheetState();
}

class _KhataEntrySheetState extends ConsumerState<KhataEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late KhataEntryType _selectedType;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;

  bool _isSaving = false;

  bool get isEditing => widget.entryToEdit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entryToEdit;
    _selectedType = e?.type ?? widget.initialType;
    _amountController = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(2) : '',
    );
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _selectedDate = e?.entryDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) return;

    setState(() => _isSaving = true);

    try {
      if (isEditing) {
        final updated = widget.entryToEdit!.copyWith(
          type: _selectedType,
          amount: amount,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          entryDate: _selectedDate,
        );
        final success = await ref.read(khataControllerProvider.notifier).updateEntry(updated);
        if (success && mounted) {
          Navigator.of(context).pop(updated);
        }
      } else {
        final success = await ref.read(khataControllerProvider.notifier).addEntry(
              customerId: widget.customerId,
              type: _selectedType,
              amount: amount,
              entryDate: _selectedDate,
              description: _descriptionController.text.trim().isNotEmpty
                  ? _descriptionController.text.trim()
                  : null,
            );
        if (success && mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isGiven = _selectedType == KhataEntryType.given;
    final activeColor = isGiven ? AppColors.error : AppColors.credit;

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
                    isEditing ? 'Edit Entry' : (isGiven ? 'You Gave (Credit)' : 'You Received (Payment)'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Segmented Type Selector
              SegmentedButton<KhataEntryType>(
                segments: const [
                  ButtonSegment(
                    value: KhataEntryType.given,
                    label: Text('+ GIVEN (Credit)'),
                    icon: Icon(LucideIcons.arrowUpRight),
                  ),
                  ButtonSegment(
                    value: KhataEntryType.received,
                    label: Text('- RECEIVED (Payment)'),
                    icon: Icon(LucideIcons.arrowDownLeft),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (set) {
                  setState(() => _selectedType = set.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return activeColor.withValues(alpha: 0.15);
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return activeColor;
                    }
                    return isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
                  }),
                ),
              ),
              const SizedBox(height: 18),

              // Amount Field
              TextFormField(
                key: const Key('entry_amount_field'),
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount *',
                  hintText: '0.00',
                  prefixText: '${widget.currencySymbol} ',
                  prefixIcon: const Icon(LucideIcons.banknote),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: !isEditing,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Please enter a valid amount greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Date Picker Field
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(LucideIcons.calendar),
                    suffixIcon: Icon(LucideIcons.chevronDown, size: 16),
                  ),
                  child: Text(
                    DateFormat('d MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Description Field
              TextFormField(
                key: const Key('entry_description_field'),
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: isGiven ? 'e.g. Products, Invoice #123' : 'e.g. Cash, UPI, Part Payment',
                  prefixIcon: const Icon(LucideIcons.fileText),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              FilledButton(
                key: const Key('save_entry_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditing ? 'Update Entry' : (isGiven ? 'Save + GIVEN' : 'Save + RECEIVED'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
