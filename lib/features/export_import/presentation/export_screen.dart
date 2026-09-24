import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/features/export_import/domain/models/export_dataset_type.dart';
import 'package:expense_tracker/features/export_import/domain/models/export_date_preset.dart';
import 'package:expense_tracker/features/export_import/domain/models/export_format.dart';
import 'package:expense_tracker/features/export_import/presentation/providers/export_import_providers.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final _titleController = TextEditingController(text: 'Personal Financial Report');
  final _subtitleController = TextEditingController(text: 'Generated from Expense Tracker');
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _footerController = TextEditingController(text: 'Confidential Financial Document');

  bool _showPdfCustomization = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _syncPdfConfig() {
    ref.read(pdfReportConfigProvider.notifier).update(
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      footerText: _footerController.text.trim().isNotEmpty ? _footerController.text.trim() : null,
    );
  }

  Future<void> _handleCustomDateRange(BuildContext context) async {
    final currentFilter = ref.read(exportFilterProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: currentFilter.startDate,
        end: currentFilter.endDate.isAfter(DateTime.now()) ? DateTime.now() : currentFilter.endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(exportFilterProvider.notifier).setCustomDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filter = ref.watch(exportFilterProvider);
    final exportState = ref.watch(exportControllerProvider);
    final dateFormat = DateFormat('dd MMM yyyy');

    final isPdf = filter.format == ExportFormat.pdf && filter.datasetType != ExportDatasetType.fullBackup;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Export Format
            _buildSectionHeader(context, 'Export Format', Icons.file_present_rounded),
            const SizedBox(height: 8),
            SegmentedButton<ExportFormat>(
              segments: [
                ButtonSegment<ExportFormat>(
                  value: ExportFormat.pdf,
                  label: const Text('PDF Document'),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  enabled: filter.datasetType != ExportDatasetType.fullBackup,
                ),
                const ButtonSegment<ExportFormat>(
                  value: ExportFormat.csv,
                  label: Text('CSV Spreadsheet'),
                  icon: Icon(Icons.table_chart_rounded),
                ),
              ],
              selected: {filter.format},
              onSelectionChanged: (Set<ExportFormat> selected) {
                ref.read(exportFilterProvider.notifier).setFormat(selected.first);
              },
            ),
            const SizedBox(height: 24),

            // Section 2: Dataset Selection
            _buildSectionHeader(context, 'Select Dataset', Icons.category_rounded),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDatasetChip(
                  context,
                  type: ExportDatasetType.transactions,
                  label: 'Transactions',
                  icon: Icons.receipt_long_rounded,
                  isSelected: filter.datasetType == ExportDatasetType.transactions,
                ),
                _buildDatasetChip(
                  context,
                  type: ExportDatasetType.savingsGoals,
                  label: 'Savings Goals',
                  icon: Icons.savings_rounded,
                  isSelected: filter.datasetType == ExportDatasetType.savingsGoals,
                ),
                _buildDatasetChip(
                  context,
                  type: ExportDatasetType.debtsAndLoans,
                  label: 'Debts & Loans',
                  icon: Icons.handshake_rounded,
                  isSelected: filter.datasetType == ExportDatasetType.debtsAndLoans,
                ),
                _buildDatasetChip(
                  context,
                  type: ExportDatasetType.fullBackup,
                  label: 'Full Backup (.ZIP)',
                  icon: Icons.folder_zip_rounded,
                  isSelected: filter.datasetType == ExportDatasetType.fullBackup,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 3: Date Range Presets
            _buildSectionHeader(context, 'Date Range', Icons.date_range_rounded),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ExportDatePreset.values.map((preset) {
                  final isSelected = filter.datePreset == preset;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(preset.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          if (preset == ExportDatePreset.custom) {
                            _handleCustomDateRange(context);
                          } else {
                            ref.read(exportFilterProvider.notifier).setPreset(preset);
                          }
                        }
                      },
                      selectedColor: AppColors.primary.withAlpha(50),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Period Summary Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : AppColors.primaryContainerLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.primary.withAlpha(40),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Period: ${dateFormat.format(filter.startDate)} → ${dateFormat.format(filter.endDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  if (filter.datePreset == ExportDatePreset.custom)
                    TextButton(
                      onPressed: () => _handleCustomDateRange(context),
                      child: const Text('Change'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 4: PDF Report Customization (Optional Accordion)
            if (isPdf) ...[
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'PDF Header & Formatting Options',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  subtitle: const Text(
                    'Configure report title, business/personal header, and notes',
                    style: TextStyle(fontSize: 12),
                  ),
                  initiallyExpanded: _showPdfCustomization,
                  onExpansionChanged: (expanded) => setState(() => _showPdfCustomization = expanded),
                  children: [
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Report Title',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => _syncPdfConfig(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _subtitleController,
                      decoration: const InputDecoration(
                        labelText: 'Report Subtitle',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => _syncPdfConfig(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Your / Business Name',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => _syncPdfConfig(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => _syncPdfConfig(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => _syncPdfConfig(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => _syncPdfConfig(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _footerController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Footer Note',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => _syncPdfConfig(),
                    ),

                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Error display if any
            if (exportState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.expenseContainerLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.expense.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.expense),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exportState.errorMessage!,
                        style: const TextStyle(color: AppColors.expenseDark, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Button
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                icon: exportState.isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.share_rounded),
                label: Text(
                  exportState.isExporting ? 'Generating Export...' : 'Export & Share File',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: exportState.isExporting
                    ? null
                    : () async {
                        _syncPdfConfig();
                        final success = await ref.read(exportControllerProvider.notifier).exportAndShare();
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Export file generated and shared successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDatasetChip(
    BuildContext context, {
    required ExportDatasetType type,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FilterChip(
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? AppColors.primary : (isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight),
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(exportFilterProvider.notifier).setDatasetType(type);
      },
      selectedColor: AppColors.primary.withAlpha(40),
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.primary
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
