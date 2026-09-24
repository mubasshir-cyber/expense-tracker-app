/// Execution result summary after processing a CSV import batch.
class ImportResult {
  const ImportResult({
    required this.totalParsedRows,
    required this.importedCount,
    required this.skippedCount,
    required this.failedCount,
    this.errorMessages = const [],
  });

  final int totalParsedRows;
  final int importedCount;
  final int skippedCount;
  final int failedCount;
  final List<String> errorMessages;

  bool get hasErrors => failedCount > 0 || errorMessages.isNotEmpty;
  bool get isSuccess => importedCount > 0 && failedCount == 0;
}
