import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/khata_customer_model.dart';
import '../providers/khata_providers.dart';

class AddEditCustomerSheet extends ConsumerStatefulWidget {
  const AddEditCustomerSheet({
    super.key,
    this.customerToEdit,
    this.currencySymbol = '₹',
  });

  final KhataCustomerModel? customerToEdit;
  final String currencySymbol;

  @override
  ConsumerState<AddEditCustomerSheet> createState() => _AddEditCustomerSheetState();
}

class _AddEditCustomerSheetState extends ConsumerState<AddEditCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  late final TextEditingController _openingBalanceController;

  bool _isSaving = false;

  bool get isEditing => widget.customerToEdit != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customerToEdit;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _notesController = TextEditingController(text: c?.notes ?? '');
    _openingBalanceController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (isEditing) {
        final updated = widget.customerToEdit!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );
        final success = await ref.read(khataControllerProvider.notifier).updateCustomer(updated);
        if (success && mounted) {
          Navigator.of(context).pop(updated);
        }
      } else {
        final opening = double.tryParse(_openingBalanceController.text.trim());
        final created = await ref.read(khataControllerProvider.notifier).createCustomer(
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
              notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
              openingBalance: opening != null && opening > 0 ? opening : null,
            );
        if (created != null && mounted) {
          Navigator.of(context).pop(created);
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
                    isEditing ? 'Edit Customer' : 'Add New Customer',
                    style: const TextStyle(
                      fontSize: 18,
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

              // Customer Name Field
              TextFormField(
                key: const Key('customer_name_field'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  hintText: 'e.g. Ahmed Khan',
                  prefixIcon: Icon(LucideIcons.user),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Mobile Phone Field
              TextFormField(
                key: const Key('customer_phone_field'),
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *',
                  hintText: 'e.g. 9876543210',
                  prefixIcon: Icon(LucideIcons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Opening Pending Field (Only when creating)
              if (!isEditing) ...[
                TextFormField(
                  key: const Key('customer_opening_balance_field'),
                  controller: _openingBalanceController,
                  decoration: InputDecoration(
                    labelText: 'Previous Pending / Opening Due (Optional)',
                    hintText: '0.00',
                    prefixText: '${widget.currencySymbol} ',
                    prefixIcon: const Icon(LucideIcons.history),
                    helperText: 'Creates an initial GIVEN entry if specified',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty) {
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed < 0) {
                        return 'Enter a valid positive amount';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],

              // Address Field (Optional)
              TextFormField(
                key: const Key('customer_address_field'),
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                  hintText: 'Shop / Area / City',
                  prefixIcon: Icon(LucideIcons.mapPin),
                ),
              ),
              const SizedBox(height: 14),

              // Notes Field (Optional)
              TextFormField(
                key: const Key('customer_notes_field'),
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Additional remarks or reference',
                  prefixIcon: Icon(LucideIcons.fileText),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Submit Button
              FilledButton(
                key: const Key('save_customer_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
                        isEditing ? 'Update Customer' : 'Create Customer',
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
