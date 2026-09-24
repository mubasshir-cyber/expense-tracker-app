import 'export_dataset_type.dart';
import 'export_date_preset.dart';
import 'export_format.dart';
import 'pdf_report_config.dart';

/// Immutable filter controlling dataset scope, date boundaries, format, and PDF options.
class ExportFilter {
  ExportFilter({
    this.datePreset = ExportDatePreset.oneMonth,
    DateTime? startDate,
    DateTime? endDate,
    this.datasetType = ExportDatasetType.transactions,
    this.format = ExportFormat.csv,
    this.accountId,
    this.categoryId,
    this.pdfConfig = const PdfReportConfig(),
  })  : startDate = startDate ?? datePreset.calculateDateRange().startDate,
        endDate = endDate ?? datePreset.calculateDateRange().endDate;

  final ExportDatePreset datePreset;
  final DateTime startDate;
  final DateTime endDate;
  final ExportDatasetType datasetType;
  final ExportFormat format;
  final String? accountId;
  final String? categoryId;
  final PdfReportConfig pdfConfig;

  /// True if start date is on or before end date.
  bool get isValidDateRange => !startDate.isAfter(endDate);

  /// True if date range was manually specified by user.
  bool get isCustom => datePreset == ExportDatePreset.custom;

  ExportFilter copyWith({
    ExportDatePreset? datePreset,
    DateTime? startDate,
    DateTime? endDate,
    ExportDatasetType? datasetType,
    ExportFormat? format,
    String? accountId,
    String? categoryId,
    PdfReportConfig? pdfConfig,
  }) {
    return ExportFilter(
      datePreset: datePreset ?? this.datePreset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      datasetType: datasetType ?? this.datasetType,
      format: format ?? this.format,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      pdfConfig: pdfConfig ?? this.pdfConfig,
    );
  }

  /// Updates preset and recalculates start/end dates automatically.
  ExportFilter withPreset(ExportDatePreset preset, [DateTime? asOfDate]) {
    if (preset == ExportDatePreset.custom) {
      return copyWith(datePreset: ExportDatePreset.custom);
    }
    final range = preset.calculateDateRange(asOfDate);
    return copyWith(
      datePreset: preset,
      startDate: range.startDate,
      endDate: range.endDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportFilter &&
          runtimeType == other.runtimeType &&
          datePreset == other.datePreset &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          datasetType == other.datasetType &&
          format == other.format &&
          accountId == other.accountId &&
          categoryId == other.categoryId &&
          pdfConfig == other.pdfConfig;

  @override
  int get hashCode =>
      datePreset.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      datasetType.hashCode ^
      format.hashCode ^
      accountId.hashCode ^
      categoryId.hashCode ^
      pdfConfig.hashCode;
}
