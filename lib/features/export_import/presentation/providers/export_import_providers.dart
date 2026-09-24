import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expense_tracker/features/accounts/domain/models/account_model.dart';
import 'package:expense_tracker/features/accounts/presentation/providers/account_repository_provider.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:expense_tracker/features/categories/domain/models/category_model.dart';
import 'package:expense_tracker/features/categories/presentation/providers/category_repository_provider.dart';
import 'package:expense_tracker/features/debts/presentation/providers/debt_providers.dart';
import 'package:expense_tracker/features/goals/presentation/providers/goal_providers.dart';
import 'package:expense_tracker/features/transactions/presentation/providers/transaction_repository_provider.dart';
import 'package:expense_tracker/features/export_import/data/repositories/export_import_repository.dart';
import 'package:expense_tracker/features/export_import/domain/models/export_dataset_type.dart';
import 'package:expense_tracker/features/export_import/domain/models/export_date_preset.dart';
import 'package:expense_tracker/features/export_import/domain/models/export_filter.dart';
import 'package:expense_tracker/features/export_import/domain/models/export_format.dart';
import 'package:expense_tracker/features/export_import/domain/models/import_preview_row.dart';
import 'package:expense_tracker/features/export_import/domain/models/import_result.dart';
import 'package:expense_tracker/features/export_import/domain/models/pdf_report_config.dart';

final exportImportRepositoryProvider = Provider<ExportImportRepository>((ref) {
  return ExportImportRepository(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    accountRepo: ref.watch(accountRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    goalRepo: ref.watch(savingsGoalRepositoryProvider),
    debtRepo: ref.watch(debtRepositoryProvider),
  );
});

// --- EXPORT STATE & CONTROLLER ---

final exportFilterProvider = StateNotifierProvider<ExportFilterNotifier, ExportFilter>((ref) {
  return ExportFilterNotifier();
});

class ExportFilterNotifier extends StateNotifier<ExportFilter> {
  ExportFilterNotifier() : super(ExportFilter(datePreset: ExportDatePreset.oneMonth));

  void setPreset(ExportDatePreset preset) {
    if (preset == ExportDatePreset.custom) {
      state = state.copyWith(datePreset: preset);
    } else {
      state = state.withPreset(preset);
    }
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    state = state.copyWith(
      datePreset: ExportDatePreset.custom,
      startDate: start,
      endDate: end,
    );
  }

  void setDatasetType(ExportDatasetType type) {
    // If fullBackup, force CSV
    if (type == ExportDatasetType.fullBackup) {
      state = state.copyWith(
        datasetType: type,
        format: ExportFormat.csv,
      );
    } else {
      state = state.copyWith(datasetType: type);
    }
  }

  void setFormat(ExportFormat format) {
    if (state.datasetType == ExportDatasetType.fullBackup) return;
    state = state.copyWith(format: format);
  }
}

final pdfReportConfigProvider = StateNotifierProvider<PdfReportConfigNotifier, PdfReportConfig>((ref) {
  return PdfReportConfigNotifier();
});

class PdfReportConfigNotifier extends StateNotifier<PdfReportConfig> {
  PdfReportConfigNotifier() : super(const PdfReportConfig());

  void update({
    String? title,
    String? subtitle,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? footerText,
    String? logoPath,
  }) {
    state = state.copyWith(
      title: title,
      subtitle: subtitle,
      name: name,
      phone: phone,
      email: email,
      address: address,
      footerText: footerText,
      logoPath: logoPath,
    );
  }
}

class ExportState {
  final bool isExporting;
  final String? exportedFilePath;
  final String? errorMessage;

  const ExportState({
    this.isExporting = false,
    this.exportedFilePath,
    this.errorMessage,
  });

  ExportState copyWith({
    bool? isExporting,
    String? exportedFilePath,
    String? errorMessage,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      exportedFilePath: exportedFilePath,
      errorMessage: errorMessage,
    );
  }
}

final exportControllerProvider = StateNotifierProvider<ExportController, ExportState>((ref) {
  return ExportController(ref);
});

class ExportController extends StateNotifier<ExportState> {
  final Ref _ref;

  ExportController(this._ref) : super(const ExportState());

  Future<bool> exportAndShare() async {
    state = state.copyWith(isExporting: true, errorMessage: null);
    try {
      final filter = _ref.read(exportFilterProvider);
      final pdfConfig = _ref.read(pdfReportConfigProvider);
      final repo = _ref.read(exportImportRepositoryProvider);

      final path = await repo.exportAndShare(filter: filter, pdfConfig: pdfConfig);
      state = state.copyWith(isExporting: false, exportedFilePath: path);
      return true;
    } catch (e) {
      state = state.copyWith(isExporting: false, errorMessage: e.toString());
      return false;
    }
  }
}

// --- IMPORT STATE & CONTROLLER ---

class ImportState {
  final bool isParsing;
  final bool isImporting;
  final String? rawCsv;
  final List<ImportPreviewRow> previewRows;
  final AccountModel? defaultAccount;
  final CategoryModel? defaultCategory;
  final ImportResult? importResult;
  final String? errorMessage;

  const ImportState({
    this.isParsing = false,
    this.isImporting = false,
    this.rawCsv,
    this.previewRows = const [],
    this.defaultAccount,
    this.defaultCategory,
    this.importResult,
    this.errorMessage,
  });

  ImportState copyWith({
    bool? isParsing,
    bool? isImporting,
    String? rawCsv,
    List<ImportPreviewRow>? previewRows,
    AccountModel? defaultAccount,
    CategoryModel? defaultCategory,
    ImportResult? importResult,
    String? errorMessage,
  }) {
    return ImportState(
      isParsing: isParsing ?? this.isParsing,
      isImporting: isImporting ?? this.isImporting,
      rawCsv: rawCsv ?? this.rawCsv,
      previewRows: previewRows ?? this.previewRows,
      defaultAccount: defaultAccount ?? this.defaultAccount,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      importResult: importResult ?? this.importResult,
      errorMessage: errorMessage,
    );
  }

  int get selectedCount => previewRows.where((r) => r.isSelected && r.isValid).length;
  int get validCount => previewRows.where((r) => r.isValid).length;
  int get errorCount => previewRows.where((r) => !r.isValid).length;
  int get duplicateCount => previewRows.where((r) => r.isDuplicate).length;
}

final importControllerProvider = StateNotifierProvider<ImportController, ImportState>((ref) {
  return ImportController(ref);
});

class ImportController extends StateNotifier<ImportState> {
  final Ref _ref;

  ImportController(this._ref) : super(const ImportState());

  void setDefaultAccount(AccountModel? account) {
    state = state.copyWith(defaultAccount: account);
    _reparseIfPossible();
  }

  void setDefaultCategory(CategoryModel? category) {
    state = state.copyWith(defaultCategory: category);
    _reparseIfPossible();
  }

  Future<void> pickAndParseFile() async {
    state = state.copyWith(isParsing: true, errorMessage: null, importResult: null);
    try {
      final repo = _ref.read(exportImportRepositoryProvider);
      final raw = await repo.pickCsvFile();
      if (raw == null) {
        state = state.copyWith(isParsing: false);
        return;
      }
      final rows = await repo.parseCsvForImport(
        rawCsv: raw,
        defaultAccount: state.defaultAccount,
        defaultCategory: state.defaultCategory,
      );
      state = state.copyWith(
        isParsing: false,
        rawCsv: raw,
        previewRows: rows,
      );
    } catch (e) {
      state = state.copyWith(isParsing: false, errorMessage: e.toString());
    }
  }

  Future<void> loadRawCsv(String raw) async {
    state = state.copyWith(isParsing: true, rawCsv: raw, errorMessage: null, importResult: null);
    try {
      final repo = _ref.read(exportImportRepositoryProvider);
      final rows = await repo.parseCsvForImport(
        rawCsv: raw,
        defaultAccount: state.defaultAccount,
        defaultCategory: state.defaultCategory,
      );
      state = state.copyWith(
        isParsing: false,
        previewRows: rows,
      );
    } catch (e) {
      state = state.copyWith(isParsing: false, errorMessage: e.toString());
    }
  }

  void toggleRowSelection(int rowIndex) {
    final updated = state.previewRows.map((r) {
      if (r.rowIndex == rowIndex) {
        return r.copyWith(isSelected: !r.isSelected);
      }
      return r;
    }).toList();
    state = state.copyWith(previewRows: updated);
  }

  void selectAll(bool select) {
    final updated = state.previewRows.map((r) {
      if (!r.isValid) return r.copyWith(isSelected: false);
      return r.copyWith(isSelected: select);
    }).toList();
    state = state.copyWith(previewRows: updated);
  }

  void reset() {
    state = const ImportState();
  }

  Future<ImportResult?> commitImport() async {
    final authRepo = _ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;
    if (user == null) {
      state = state.copyWith(errorMessage: 'User is not authenticated.');
      return null;
    }

    state = state.copyWith(isImporting: true, errorMessage: null);
    try {
      final repo = _ref.read(exportImportRepositoryProvider);
      final result = await repo.commitImport(
        rows: state.previewRows,
        userId: user.id,
      );
      state = state.copyWith(
        isImporting: false,
        importResult: result,
      );
      return result;
    } catch (e) {
      state = state.copyWith(isImporting: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<void> _reparseIfPossible() async {
    if (state.rawCsv == null || state.rawCsv!.isEmpty) return;
    try {
      final repo = _ref.read(exportImportRepositoryProvider);
      final rows = await repo.parseCsvForImport(
        rawCsv: state.rawCsv!,
        defaultAccount: state.defaultAccount,
        defaultCategory: state.defaultCategory,
      );
      state = state.copyWith(previewRows: rows);
    } catch (_) {}
  }
}
