import '../../../transactions/domain/models/transaction_type.dart';

/// Represents a single parsed row from an imported CSV with validation and duplicate state.
class ImportPreviewRow {
  const ImportPreviewRow({
    required this.rowIndex,
    required this.rawValues,
    this.parsedDate,
    this.parsedAmount,
    this.parsedType = TransactionType.expense,
    this.parsedCategoryName,
    this.parsedAccountName,
    this.parsedDescription,
    this.categoryId,
    this.accountId,
    this.validationErrors = const [],
    this.isDuplicate = false,
    this.isSelected = true,
  });

  final int rowIndex;
  final Map<String, String> rawValues;
  final DateTime? parsedDate;
  final double? parsedAmount;
  final TransactionType parsedType;
  final String? parsedCategoryName;
  final String? parsedAccountName;
  final String? parsedDescription;
  final String? categoryId;
  final String? accountId;
  final List<String> validationErrors;
  final bool isDuplicate;
  final bool isSelected;

  /// True if row contains no parsing or schema validation errors.
  bool get isValid => validationErrors.isEmpty && parsedDate != null && parsedAmount != null && parsedAmount! > 0;

  /// True if eligible to be imported into the ledger.
  bool get canImport => isValid && isSelected;

  ImportPreviewRow copyWith({
    int? rowIndex,
    Map<String, String>? rawValues,
    DateTime? parsedDate,
    double? parsedAmount,
    TransactionType? parsedType,
    String? parsedCategoryName,
    String? parsedAccountName,
    String? parsedDescription,
    String? categoryId,
    String? accountId,
    List<String>? validationErrors,
    bool? isDuplicate,
    bool? isSelected,
  }) {
    return ImportPreviewRow(
      rowIndex: rowIndex ?? this.rowIndex,
      rawValues: rawValues ?? this.rawValues,
      parsedDate: parsedDate ?? this.parsedDate,
      parsedAmount: parsedAmount ?? this.parsedAmount,
      parsedType: parsedType ?? this.parsedType,
      parsedCategoryName: parsedCategoryName ?? this.parsedCategoryName,
      parsedAccountName: parsedAccountName ?? this.parsedAccountName,
      parsedDescription: parsedDescription ?? this.parsedDescription,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      validationErrors: validationErrors ?? this.validationErrors,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
