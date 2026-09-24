import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:expense_tracker/features/accounts/data/repositories/account_repository.dart';
import 'package:expense_tracker/features/accounts/domain/models/account_model.dart';
import 'package:expense_tracker/features/categories/data/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/models/category_model.dart';
import 'package:expense_tracker/features/debts/data/repositories/debt_repository.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_installment_model.dart';
import 'package:expense_tracker/features/debts/domain/models/debt_repayment_model.dart';
import 'package:expense_tracker/features/goals/data/repositories/savings_goal_repository.dart';
import 'package:expense_tracker/features/goals/domain/models/savings_goal_model.dart';
import 'package:expense_tracker/features/goals/domain/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/transactions/data/repositories/transaction_repository.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_model.dart';
import 'package:expense_tracker/features/export_import/domain/models/export_dataset_type.dart';
import 'package:expense_tracker/features/export_import/domain/models/export_filter.dart';
import 'package:expense_tracker/features/export_import/domain/models/export_format.dart';
import 'package:expense_tracker/features/export_import/domain/models/import_preview_row.dart';
import 'package:expense_tracker/features/export_import/domain/models/import_result.dart';
import 'package:expense_tracker/features/export_import/domain/models/pdf_report_config.dart';
import 'package:expense_tracker/features/export_import/domain/services/csv_export_service.dart';
import 'package:expense_tracker/features/export_import/domain/services/csv_import_service.dart';
import 'package:expense_tracker/features/export_import/domain/services/pdf_export_service.dart';

class ExportDataBundle {
  final List<TransactionModel> transactions;
  final List<AccountModel> accounts;
  final List<CategoryModel> categories;
  final List<SavingsGoalModel> goals;
  final List<GoalContributionModel> contributions;
  final List<DebtModel> debts;
  final List<DebtInstallmentModel> installments;
  final List<DebtRepaymentModel> repayments;

  const ExportDataBundle({
    this.transactions = const [],
    this.accounts = const [],
    this.categories = const [],
    this.goals = const [],
    this.contributions = const [],
    this.debts = const [],
    this.installments = const [],
    this.repayments = const [],
  });
}

class ExportImportRepository {
  final TransactionRepository transactionRepo;
  final AccountRepository accountRepo;
  final CategoryRepository categoryRepo;
  final SavingsGoalRepository goalRepo;
  final DebtRepository debtRepo;
  final CsvExportService csvExportService;
  final PdfExportService pdfExportService;
  final CsvImportService csvImportService;

  ExportImportRepository({
    required this.transactionRepo,
    required this.accountRepo,
    required this.categoryRepo,
    required this.goalRepo,
    required this.debtRepo,
    this.csvExportService = const CsvExportService(),
    this.pdfExportService = const PdfExportService(),
    this.csvImportService = const CsvImportService(),
  });

  /// Fetches filtered data according to date ranges.
  Future<ExportDataBundle> fetchExportData(ExportFilter filter) async {
    final allTxs = await transactionRepo.getTransactions();
    final accounts = await accountRepo.getAccounts();
    final categories = await categoryRepo.getCategories();
    final goals = await goalRepo.getGoals(activeOnly: false);
    final debts = await debtRepo.getDebts();

    // Collect all contributions from all goals
    final allContributions = <GoalContributionModel>[];
    for (final g in goals) {
      final contribs = await goalRepo.getContributions(g.id);
      allContributions.addAll(contribs);
    }

    // Filter transactions by date range
    final filteredTxs = allTxs.where((tx) {
      final date = tx.transactionDate;
      final start = DateTime(filter.startDate.year, filter.startDate.month, filter.startDate.day);
      final end = DateTime(filter.endDate.year, filter.endDate.month, filter.endDate.day, 23, 59, 59);
      return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          date.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();

    return ExportDataBundle(
      transactions: filteredTxs,
      accounts: accounts,
      categories: categories,
      goals: goals,
      contributions: allContributions,
      debts: debts,
    );
  }

  /// Exports data to file bytes and shares/saves it.
  Future<String> exportAndShare({
    required ExportFilter filter,
    required PdfReportConfig pdfConfig,
  }) async {
    final bundle = await fetchExportData(filter);
    final accountNames = {for (final a in bundle.accounts) a.id: a.name};
    final categoryNames = {for (final c in bundle.categories) c.id: c.name};
    final contributionsMap = <String, List<GoalContributionModel>>{};
    for (final c in bundle.contributions) {
      contributionsMap.putIfAbsent(c.goalId, () => []).add(c);
    }

    final fileNameBase = 'expense_tracker_${filter.datasetType.name}_${filter.startDate.toIso8601String().split('T').first}_to_${filter.endDate.toIso8601String().split('T').first}';

    Uint8List fileBytes;
    String extension;
    String mimeType;

    if (filter.datasetType == ExportDatasetType.fullBackup) {
      final zipBytes = csvExportService.generateFullBackupZip(
        transactions: bundle.transactions,
        accounts: bundle.accounts,
        categories: bundle.categories,
        savingsGoals: bundle.goals,
        goalContributions: bundle.contributions,
        debts: bundle.debts,
        accountNames: accountNames,
        categoryNames: categoryNames,
      );
      fileBytes = Uint8List.fromList(zipBytes);
      extension = 'zip';
      mimeType = 'application/zip';
    } else if (filter.format == ExportFormat.pdf) {
      final totalOpeningBalance = bundle.accounts.fold<double>(
        0.0,
        (sum, a) => sum + a.openingBalance,
      );
      fileBytes = await pdfExportService.generateFinancialReportPdf(
        config: pdfConfig,
        startDate: filter.startDate,
        endDate: filter.endDate,
        openingBalance: totalOpeningBalance,
        transactions: bundle.transactions,
        savingsGoals: bundle.goals,
        debts: bundle.debts,
        accountNames: accountNames,
        categoryNames: categoryNames,
        includeTransactions: filter.datasetType == ExportDatasetType.transactions,
        includeSavings: filter.datasetType == ExportDatasetType.savingsGoals,
        includeDebts: filter.datasetType == ExportDatasetType.debtsAndLoans,
      );
      extension = 'pdf';
      mimeType = 'application/pdf';
    } else {
      // CSV
      String csvContent;
      switch (filter.datasetType) {
        case ExportDatasetType.transactions:
          csvContent = csvExportService.exportTransactionsCsv(
            bundle.transactions,
            accountNames: accountNames,
            categoryNames: categoryNames,
          );
          break;
        case ExportDatasetType.savingsGoals:
          csvContent = csvExportService.exportSavingsGoalsCsv(
            bundle.goals,
            contributions: contributionsMap,
            accountNames: accountNames,
          );
          break;
        case ExportDatasetType.debtsAndLoans:
          csvContent = csvExportService.exportDebtsCsv(
            bundle.debts,
            accountNames: accountNames,
          );
          break;
        case ExportDatasetType.fullBackup:
          csvContent = '';
          break;
      }
      fileBytes = Uint8List.fromList(utf8.encode(csvContent));
      extension = 'csv';
      mimeType = 'text/csv';
    }

    // Write to temp file and share
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$fileNameBase.$extension';
    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    await Share.shareXFiles(
      [XFile(filePath, mimeType: mimeType)],
      subject: 'Expense Tracker Export ($extension)',
    );

    return filePath;
  }

  /// Picks a CSV file from local storage.
  Future<String?> pickCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    if (file.bytes != null) {
      return utf8.decode(file.bytes!, allowMalformed: true);
    } else if (file.path != null) {
      return File(file.path!).readAsString();
    }
    return null;
  }

  /// Parses CSV and returns preview rows.
  Future<List<ImportPreviewRow>> parseCsvForImport({
    required String rawCsv,
    AccountModel? defaultAccount,
    CategoryModel? defaultCategory,
  }) async {
    final accounts = await accountRepo.getAccounts();
    final categories = await categoryRepo.getCategories();
    final existingTxs = await transactionRepo.getTransactions();

    return csvImportService.parseCsv(
      rawCsv: rawCsv,
      existingAccounts: accounts,
      existingCategories: categories,
      existingTransactions: existingTxs,
      defaultAccount: defaultAccount,
      defaultCategory: defaultCategory,
    );
  }

  /// Commits selected preview rows to the database.
  Future<ImportResult> commitImport({
    required List<ImportPreviewRow> rows,
    required String userId,
  }) async {
    int insertedCount = 0;
    int skippedCount = 0;
    final errors = <String>[];

    final selectedRows = rows.where((r) => r.canImport).toList();
    skippedCount = rows.length - selectedRows.length;

    for (final row in selectedRows) {
      try {
        await transactionRepo.createTransaction(
          accountId: row.accountId ?? '',
          categoryId: row.categoryId ?? '',
          type: row.parsedType,
          amount: row.parsedAmount ?? 0.0,
          date: row.parsedDate ?? DateTime.now(),
          note: row.parsedDescription,
        );
        insertedCount++;
      } catch (e) {
        errors.add('Row ${row.rowIndex}: ${e.toString()}');
      }
    }

    return ImportResult(
      totalParsedRows: rows.length,
      importedCount: insertedCount,
      skippedCount: skippedCount,
      failedCount: errors.length,
      errorMessages: errors,
    );
  }

  /// Returns sample CSV template string.
  String getSampleCsvTemplate() {
    return csvExportService.generateSampleCsv();
  }
}
