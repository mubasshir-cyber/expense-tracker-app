import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/export_import/domain/models/export_dataset_type.dart';
import 'package:expense_tracker/features/export_import/domain/models/export_date_preset.dart';
import 'package:expense_tracker/features/export_import/domain/models/export_filter.dart';
import 'package:expense_tracker/features/export_import/domain/models/export_format.dart';

void main() {
  group('ExportDatePreset & ExportFilter Tests', () {
    final fixedNow = DateTime(2026, 9, 23, 14, 30); // 23 Sep 2026

    test('oneWeek calculates 7 days range ending today', () {
      final range = ExportDatePreset.oneWeek.calculateDateRange(fixedNow);
      expect(range.startDate, DateTime(2026, 9, 17));
      expect(range.endDate, DateTime(2026, 9, 23));
      expect(ExportDatePreset.oneWeek.label, '1 Week');
    });

    test('oneMonth calculates 1st of month to today', () {
      final range = ExportDatePreset.oneMonth.calculateDateRange(fixedNow);
      expect(range.startDate, DateTime(2026, 9, 1));
      expect(range.endDate, DateTime(2026, 9, 23));
      expect(ExportDatePreset.oneMonth.label, '1 Month');
    });

    test('threeMonths calculates 1st of 2 months ago to today', () {
      final range = ExportDatePreset.threeMonths.calculateDateRange(fixedNow);
      expect(range.startDate, DateTime(2026, 7, 1));
      expect(range.endDate, DateTime(2026, 9, 23));
      expect(ExportDatePreset.threeMonths.label, '3 Months');
    });

    test('oneYear calculates 1st of 11 months ago to today', () {
      final range = ExportDatePreset.oneYear.calculateDateRange(fixedNow);
      expect(range.startDate, DateTime(2025, 10, 1));
      expect(range.endDate, DateTime(2026, 9, 23));
      expect(ExportDatePreset.oneYear.label, '1 Year');
    });

    test('custom returns baseline date range', () {
      final range = ExportDatePreset.custom.calculateDateRange(fixedNow);
      expect(range.startDate, DateTime(2026, 9, 23));
      expect(range.endDate, DateTime(2026, 9, 23));
      expect(ExportDatePreset.custom.label, 'Custom');
    });

    test('ExportFilter isValidDateRange and presets work correctly', () {
      final filter = ExportFilter(
        datePreset: ExportDatePreset.oneMonth,
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 23),
        datasetType: ExportDatasetType.transactions,
        format: ExportFormat.pdf,
      );

      expect(filter.isValidDateRange, isTrue);
      expect(filter.isCustom, isFalse);

      final updated = filter.withPreset(ExportDatePreset.threeMonths, fixedNow);
      expect(updated.datePreset, ExportDatePreset.threeMonths);
      expect(updated.startDate, DateTime(2026, 7, 1));
      expect(updated.endDate, DateTime(2026, 9, 23));

      final invalidRangeFilter = filter.copyWith(
        startDate: DateTime(2026, 9, 30),
        endDate: DateTime(2026, 9, 1),
      );
      expect(invalidRangeFilter.isValidDateRange, isFalse);
    });
  });
}
