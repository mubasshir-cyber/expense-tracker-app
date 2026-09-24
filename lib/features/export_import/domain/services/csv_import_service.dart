import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import 'package:expense_tracker/features/accounts/domain/models/account_model.dart';
import 'package:expense_tracker/features/categories/domain/models/category_model.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_type.dart';
import 'package:expense_tracker/features/export_import/domain/models/import_preview_row.dart';

/// Service responsible for parsing raw CSV content, mapping headers,
/// resolving category/account references, detecting duplicates, and producing
/// preview rows for user confirmation before database insertion.
class CsvImportService {
  const CsvImportService();

  /// Parses raw CSV string into a list of [ImportPreviewRow] with validation and duplicate checks.
  List<ImportPreviewRow> parseCsv({
    required String rawCsv,
    required List<AccountModel> existingAccounts,
    required List<CategoryModel> existingCategories,
    required List<TransactionModel> existingTransactions,
    AccountModel? defaultAccount,
    CategoryModel? defaultCategory,
  }) {
    if (rawCsv.trim().isEmpty) {
      return [];
    }

    final List<List<dynamic>> rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(rawCsv);

    if (rows.isEmpty) {
      return [];
    }

    // Find header row and map column indices
    final headerRow = rows.first;
    final colMap = _detectColumns(headerRow);

    if (!colMap.containsKey('date') || !colMap.containsKey('amount')) {
      // Must at minimum have date and amount
      return [
        ImportPreviewRow(
          rowIndex: 0,
          rawValues: {for (int i = 0; i < headerRow.length; i++) 'col_$i': headerRow[i]?.toString() ?? ''},
          validationErrors: const ['Required columns missing: CSV must have "Date" and "Amount" headers.'],
          isSelected: false,
        ),
      ];
    }

    final previewRows = <ImportPreviewRow>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || (row.length == 1 && (row[0] == null || row[0].toString().trim().isEmpty))) {
        continue; // skip blank line
      }

      final rawValues = <String, String>{};
      for (int c = 0; c < row.length; c++) {
        final colName = c < headerRow.length ? headerRow[c]?.toString() ?? 'col_$c' : 'col_$c';
        rawValues[colName] = row[c]?.toString() ?? '';
      }

      final errors = <String>[];

      // 1. Parse Date
      final dateStr = _getValue(row, colMap['date']);
      final parsedDate = _parseDate(dateStr);
      if (parsedDate == null) {
        errors.add('Invalid date format "$dateStr". Expected YYYY-MM-DD, DD/MM/YYYY, or MM/DD/YYYY.');
      }

      // 2. Parse Amount
      final amountStr = _getValue(row, colMap['amount']);
      final parsedAmount = _parseAmount(amountStr);
      if (parsedAmount == null || parsedAmount <= 0) {
        errors.add('Invalid amount "$amountStr". Must be a positive number.');
      }

      // 3. Parse Type
      final typeStr = _getValue(row, colMap['type']);
      final parsedType = _parseTransactionType(typeStr);

      // 4. Resolve Category
      final categoryStr = _getValue(row, colMap['category']);
      final resolvedCategory = _resolveCategory(
        categoryStr,
        parsedType,
        existingCategories,
        defaultCategory,
      );
      if (resolvedCategory == null) {
        errors.add('Category "$categoryStr" could not be resolved and no valid default category was provided.');
      }

      // 5. Resolve Account
      final accountStr = _getValue(row, colMap['account']);
      final resolvedAccount = _resolveAccount(
        accountStr,
        existingAccounts,
        defaultAccount,
      );
      if (resolvedAccount == null) {
        errors.add('Account "$accountStr" could not be resolved and no default account was provided.');
      }

      // 6. Optional Description
      final descriptionStr = _getValue(row, colMap['description']) ?? _getValue(row, colMap['note']);

      // 7. Duplicate Check
      bool isDuplicate = false;
      if (parsedDate != null && parsedAmount != null && errors.isEmpty) {
        isDuplicate = existingTransactions.any((tx) {
          final sameDate = tx.transactionDate.year == parsedDate.year &&
              tx.transactionDate.month == parsedDate.month &&
              tx.transactionDate.day == parsedDate.day;
          final sameAmount = (tx.amount - parsedAmount).abs() < 0.001;
          final sameType = tx.type.toUpperCase() == parsedType.value;
          final sameDesc = (tx.description ?? '').trim().toLowerCase() == (descriptionStr ?? '').trim().toLowerCase();
          return sameDate && sameAmount && sameType && sameDesc;
        });
      }

      previewRows.add(
        ImportPreviewRow(
          rowIndex: i,
          rawValues: rawValues,
          parsedDate: parsedDate,
          parsedAmount: parsedAmount,
          parsedType: parsedType,
          categoryId: resolvedCategory?.id,
          parsedCategoryName: resolvedCategory?.name ?? categoryStr,
          accountId: resolvedAccount?.id,
          parsedAccountName: resolvedAccount?.name ?? accountStr,
          parsedDescription: descriptionStr?.isNotEmpty == true ? descriptionStr : null,
          validationErrors: errors,
          isDuplicate: isDuplicate,
          isSelected: errors.isEmpty && !isDuplicate,
        ),
      );
    }

    return previewRows;
  }

  Map<String, int> _detectColumns(List<dynamic> headerRow) {
    final map = <String, int>{};
    for (int i = 0; i < headerRow.length; i++) {
      final name = headerRow[i]?.toString().trim().toLowerCase() ?? '';
      if (name == 'date' || name == 'transaction date' || name == 'txn date') {
        map['date'] = i;
      } else if (name == 'amount' || name == 'txn amount' || name == 'value') {
        map['amount'] = i;
      } else if (name == 'type' || name == 'txn type' || name == 'transaction type') {
        map['type'] = i;
      } else if (name == 'category' || name == 'category name') {
        map['category'] = i;
      } else if (name == 'account' || name == 'account name' || name == 'wallet') {
        map['account'] = i;
      } else if (name == 'description' || name == 'memo' || name == 'note' || name == 'notes') {
        map['description'] = i;
      }
    }
    return map;
  }

  String? _getValue(List<dynamic> row, int? index) {
    if (index == null || index < 0 || index >= row.length) {
      return null;
    }
    final val = row[index]?.toString().trim();
    return val?.isEmpty == true ? null : val;
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final clean = raw.trim();

    // Try ISO format
    try {
      return DateTime.parse(clean);
    } catch (_) {}

    // Formats to attempt
    final formats = [
      'yyyy-MM-dd',
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'dd-MM-yyyy',
      'MM-dd-yyyy',
      'd/M/yyyy',
      'M/d/yyyy',
      'd-M-yyyy',
      'yyyy/MM/dd',
    ];

    for (final fmt in formats) {
      try {
        return DateFormat(fmt).parseStrict(clean);
      } catch (_) {}
    }

    return null;
  }

  double? _parseAmount(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    // Remove currency signs, commas, whitespace
    final cleaned = raw.replaceAll(RegExp(r'[₹$€£,\s]'), '');
    return double.tryParse(cleaned);
  }

  TransactionType _parseTransactionType(String? raw) {
    if (raw == null || raw.isEmpty) {
      return TransactionType.expense;
    }
    final lower = raw.toLowerCase().trim();
    if (lower == 'income' || lower == 'credit' || lower == 'cr') {
      return TransactionType.credit;
    }
    return TransactionType.expense;
  }

  CategoryModel? _resolveCategory(
    String? name,
    TransactionType type,
    List<CategoryModel> existingCategories,
    CategoryModel? defaultCategory,
  ) {
    final typeStr = type == TransactionType.credit ? 'income' : 'expense';
    if (name != null && name.isNotEmpty) {
      final match = existingCategories.where((c) =>
        c.name.trim().toLowerCase() == name.trim().toLowerCase() &&
        c.type.toLowerCase() == typeStr
      );
      if (match.isNotEmpty) return match.first;

      // Fallback matching by name only
      final nameOnlyMatch = existingCategories.where((c) =>
        c.name.trim().toLowerCase() == name.trim().toLowerCase()
      );
      if (nameOnlyMatch.isNotEmpty) return nameOnlyMatch.first;
    }

    if (defaultCategory != null) {
      return defaultCategory;
    }

    // Default to first matching category for the transaction type
    final typeMatches = existingCategories.where((c) => c.type.toLowerCase() == typeStr);
    if (typeMatches.isNotEmpty) return typeMatches.first;

    return existingCategories.isNotEmpty ? existingCategories.first : null;
  }

  AccountModel? _resolveAccount(
    String? name,
    List<AccountModel> existingAccounts,
    AccountModel? defaultAccount,
  ) {
    if (name != null && name.isNotEmpty) {
      final match = existingAccounts.where((a) =>
        a.name.trim().toLowerCase() == name.trim().toLowerCase()
      );
      if (match.isNotEmpty) return match.first;
    }

    if (defaultAccount != null) {
      return defaultAccount;
    }

    final active = existingAccounts.where((a) => a.isActive);
    if (active.isNotEmpty) return active.first;

    return existingAccounts.isNotEmpty ? existingAccounts.first : null;
  }
}
