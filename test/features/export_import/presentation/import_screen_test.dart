import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/accounts/domain/models/account_model.dart';
import 'package:expense_tracker/features/accounts/presentation/providers/account_providers.dart';
import 'package:expense_tracker/features/categories/domain/models/category_model.dart';
import 'package:expense_tracker/features/transactions/domain/models/transaction_type.dart';
import 'package:expense_tracker/features/transactions/presentation/providers/data_providers.dart';
import 'package:expense_tracker/features/export_import/data/repositories/export_import_repository.dart';
import 'package:expense_tracker/features/export_import/domain/models/import_preview_row.dart';
import 'package:expense_tracker/features/export_import/domain/services/csv_export_service.dart';
import 'package:expense_tracker/features/export_import/presentation/import_screen.dart';
import 'package:expense_tracker/features/export_import/presentation/providers/export_import_providers.dart';

class FakeExportImportRepository implements ExportImportRepository {
  const FakeExportImportRepository();

  @override
  String getSampleCsvTemplate() {
    return const CsvExportService().generateSampleCsv();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final sampleAccounts = [
    const AccountModel(
      id: 'acc-1',
      userId: 'user-1',
      name: 'Main Bank',
      type: 'bank',
      isActive: true,
      openingBalance: 1000.0,
    ),
  ];

  final sampleCategories = [
    const CategoryModel(
      id: 'cat-1',
      userId: 'user-1',
      name: 'Groceries',
      type: 'expense',
      isActive: true,
    ),
  ];

  Widget createWidgetUnderTest({
    List<ImportPreviewRow> initialPreviewRows = const [],
  }) {
    return ProviderScope(
      overrides: [
        exportImportRepositoryProvider.overrideWithValue(const FakeExportImportRepository()),
        accountsProvider.overrideWith((ref) async => sampleAccounts),
        categoriesProvider.overrideWith((ref) async => sampleCategories),
        importControllerProvider.overrideWith((ref) {
          final controller = ImportController(ref);
          if (initialPreviewRows.isNotEmpty) {
            controller.state = controller.state.copyWith(
              previewRows: initialPreviewRows,
            );
          }
          return controller;
        }),
      ],
      child: const MaterialApp(
        home: ImportScreen(),
      ),
    );
  }

  group('ImportScreen Widget Tests', () {
    testWidgets('renders file picker upload card and sample help button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Import Transactions'), findsOneWidget);
      expect(find.text('Tap to select a CSV file'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);

      // Tap help icon to see sample CSV dialog
      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Sample CSV Format'), findsOneWidget);
      expect(find.text('Copy to Clipboard'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('renders preview rows and enables batch selection toggling', (tester) async {
      final rows = [
        ImportPreviewRow(
          rowIndex: 1,
          rawValues: const {'Date': '2026-09-20', 'Amount': '500'},
          parsedDate: DateTime(2026, 9, 20),
          parsedAmount: 500.0,
          parsedType: TransactionType.expense,
          parsedCategoryName: 'Groceries',
          parsedAccountName: 'Main Bank',
          parsedDescription: 'Grocery item',
          isSelected: true,
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(initialPreviewRows: rows));
      await tester.pumpAndSettle();

      expect(find.text('Total: 1'), findsOneWidget);
      expect(find.text('Valid: 1'), findsOneWidget);
      expect(find.text('Selected: 1'), findsOneWidget);
      expect(find.text('Grocery item'), findsOneWidget);
      expect(find.text('-₹500.00'), findsOneWidget);
      expect(find.text('Import 1 Transaction(s)'), findsOneWidget);
    });
  });
}
