import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/features/accounts/domain/models/account_model.dart';
import 'package:expense_tracker/features/accounts/presentation/providers/account_providers.dart';
import 'package:expense_tracker/features/categories/domain/models/category_model.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_type.dart';
import 'package:expense_tracker/features/transactions/presentation/providers/data_providers.dart';
import 'package:expense_tracker/features/export_import/domain/models/import_preview_row.dart';
import 'package:expense_tracker/features/export_import/domain/models/import_result.dart';
import 'package:expense_tracker/features/export_import/presentation/providers/export_import_providers.dart';

class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});

  void _showSampleCsvDialog(BuildContext context, WidgetRef ref) {
    final sample = ref.read(exportImportRepositoryProvider).getSampleCsvTemplate();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sample CSV Format'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copy or reference this standard format for importing transactions:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  sample,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: sample));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sample CSV copied to clipboard!')),
              );
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCommitConfirmation(BuildContext context, WidgetRef ref, ImportState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Import'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to import ${state.selectedCount} selected transaction(s)?'),
            const SizedBox(height: 12),
            if (state.duplicateCount > 0)
              Text(
                'Note: ${state.duplicateCount} duplicate transactions were detected and deselected by default.',
                style: const TextStyle(fontSize: 12, color: AppColors.warning),
              ),
            if (state.errorCount > 0)
              Text(
                'Note: ${state.errorCount} row(s) contain validation errors and will be skipped.',
                style: const TextStyle(fontSize: 12, color: AppColors.expense),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await ref.read(importControllerProvider.notifier).commitImport();
              if (result != null && context.mounted) {
                _showResultDialog(context, ref, result);
              }
            },
            child: const Text('Import Now'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(BuildContext context, WidgetRef ref, ImportResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.hasErrors ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              color: result.hasErrors ? AppColors.warning : AppColors.success,
            ),
            const SizedBox(width: 8),
            const Text('Import Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow('Total Rows Processed', '${result.totalParsedRows}'),
            _buildResultRow('Successfully Inserted', '${result.importedCount}', color: AppColors.success),
            _buildResultRow('Duplicates / Skipped', '${result.skippedCount}', color: AppColors.warning),
            if (result.failedCount > 0)
              _buildResultRow('Errors Encountered', '${result.failedCount}', color: AppColors.expense),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(importControllerProvider.notifier).reset();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final importState = ref.watch(importControllerProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Sample CSV Format',
            onPressed: () => _showSampleCsvDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upload / Pick File Card
            InkWell(
              onTap: importState.isParsing || importState.isImporting
                  ? null
                  : () => ref.read(importControllerProvider.notifier).pickAndParseFile(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(80),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    if (importState.isParsing)
                      const CircularProgressIndicator()
                    else
                      Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary),
                    const SizedBox(height: 12),
                    Text(
                      importState.previewRows.isEmpty
                          ? 'Tap to select a CSV file'
                          : 'CSV Loaded (${importState.previewRows.length} rows detected)',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supports standard dates, amounts, categories, and accounts',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fallback Defaults (Account & Category)
            Row(
              children: [
                Expanded(
                  child: accountsAsync.when(
                    data: (accounts) => DropdownButtonFormField<AccountModel>(
                      initialValue: importState.defaultAccount ?? (accounts.isNotEmpty ? accounts.first : null),
                      decoration: const InputDecoration(
                        labelText: 'Fallback Account',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: accounts.map((a) => DropdownMenuItem(value: a, child: Text(a.name, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (acc) => ref.read(importControllerProvider.notifier).setDefaultAccount(acc),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: categoriesAsync.when(
                    data: (categories) => DropdownButtonFormField<CategoryModel>(
                      initialValue: importState.defaultCategory,
                      decoration: const InputDecoration(
                        labelText: 'Fallback Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (cat) => ref.read(importControllerProvider.notifier).setDefaultCategory(cat),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Preview Section
            if (importState.previewRows.isNotEmpty) ...[
              // Summary Stats Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatBadge(context, 'Total: ${importState.previewRows.length}', AppColors.info),
                  _buildStatBadge(context, 'Valid: ${importState.validCount}', AppColors.success),
                  if (importState.duplicateCount > 0)
                    _buildStatBadge(context, 'Duplicates: ${importState.duplicateCount}', AppColors.warning),
                  if (importState.errorCount > 0)
                    _buildStatBadge(context, 'Errors: ${importState.errorCount}', AppColors.expense),
                  _buildStatBadge(context, 'Selected: ${importState.selectedCount}', AppColors.primary),
                ],
              ),
              const SizedBox(height: 12),

              // Selection Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Preview & Verification',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => ref.read(importControllerProvider.notifier).selectAll(true),
                        child: const Text('Select All'),
                      ),
                      TextButton(
                        onPressed: () => ref.read(importControllerProvider.notifier).selectAll(false),
                        child: const Text('Deselect All'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Preview Row List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: importState.previewRows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = importState.previewRows[index];
                  return _buildPreviewRowCard(context, ref, row);
                },
              ),
              const SizedBox(height: 24),

              // Commit Import Button
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  icon: importState.isImporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    importState.isImporting
                        ? 'Importing...'
                        : 'Import ${importState.selectedCount} Transaction(s)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.credit,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: importState.isImporting || importState.selectedCount == 0
                      ? null
                      : () => _showCommitConfirmation(context, ref, importState),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildPreviewRowCard(BuildContext context, WidgetRef ref, ImportPreviewRow row) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy');
    final isExpense = row.parsedType == TransactionType.expense;

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: !row.isValid
              ? AppColors.expense.withAlpha(120)
              : (row.isDuplicate
                  ? AppColors.warning.withAlpha(120)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight)),
        ),
      ),
      child: CheckboxListTile(
        value: row.isSelected,
        onChanged: row.isValid
            ? (_) => ref.read(importControllerProvider.notifier).toggleRowSelection(row.rowIndex)
            : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isExpense
                    ? AppColors.expenseContainerLight
                    : AppColors.creditContainerLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isExpense ? 'EXPENSE' : 'INCOME',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isExpense ? AppColors.expenseDark : AppColors.creditDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                row.parsedDescription ?? row.parsedCategoryName ?? 'Transaction #${row.rowIndex}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${isExpense ? '-' : '+'}₹${(row.parsedAmount ?? 0).toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isExpense ? AppColors.expense : AppColors.credit,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    row.parsedDate != null ? dateFormat.format(row.parsedDate!) : 'Invalid Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight)),
                  const SizedBox(width: 8),
                  Text(
                    row.parsedAccountName ?? 'No Account',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              if (row.isDuplicate)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
                      SizedBox(width: 4),
                      Text(
                        'Duplicate transaction detected',
                        style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              if (!row.isValid)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.expense),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          row.validationErrors.join(', '),
                          style: const TextStyle(fontSize: 11, color: AppColors.expense),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}
