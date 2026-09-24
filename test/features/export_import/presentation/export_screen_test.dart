import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/export_import/domain/models/export_dataset_type.dart';
import 'package:expense_tracker/features/export_import/domain/models/export_format.dart';
import 'package:expense_tracker/features/export_import/presentation/export_screen.dart';
import 'package:expense_tracker/features/export_import/presentation/providers/export_import_providers.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const ProviderScope(
      child: MaterialApp(
        home: ExportScreen(),
      ),
    );
  }

  group('ExportScreen Widget Tests', () {
    testWidgets('renders all major export format and dataset options', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Export Data'), findsOneWidget);
      expect(find.text('PDF Document'), findsOneWidget);
      expect(find.text('CSV Spreadsheet'), findsOneWidget);

      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Savings Goals'), findsOneWidget);
      expect(find.text('Debts & Loans'), findsOneWidget);
      expect(find.text('Full Backup (.ZIP)'), findsOneWidget);

      expect(find.text('1 Week'), findsOneWidget);
      expect(find.text('1 Month'), findsOneWidget);
      expect(find.text('3 Months'), findsOneWidget);
      expect(find.text('1 Year'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      expect(find.text('Export & Share File'), findsOneWidget);
    });

    testWidgets('switching to Full Backup forces CSV format', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final fullBackupChip = find.text('Full Backup (.ZIP)');
      await tester.tap(fullBackupChip);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(tester.element(find.byType(ExportScreen)));
      final filter = container.read(exportFilterProvider);
      expect(filter.datasetType, ExportDatasetType.fullBackup);
      expect(filter.format, ExportFormat.csv);
    });
  });
}
