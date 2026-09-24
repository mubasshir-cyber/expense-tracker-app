import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/khata_customer_model.dart';
import '../../domain/models/customer_ledger_models.dart';
import '../../domain/models/khata_entry_type.dart';
import '../providers/khata_providers.dart';

class CustomerStatementScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerStatementScreen({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<CustomerStatementScreen> createState() => _CustomerStatementScreenState();
}

class _CustomerStatementScreenState extends ConsumerState<CustomerStatementScreen> {
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');

  DateTimeRange? _selectedDateRange;
  bool _isGeneratingPdf = false;

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 90)),
            end: DateTime.now(),
          ),
      builder: (pickerCtx, child) {
        return Theme(
          data: Theme.of(pickerCtx).copyWith(
            colorScheme: Theme.of(pickerCtx).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _clearDateRange() {
    setState(() => _selectedDateRange = null);
  }

  List<CustomerLedgerItem> _filterLedgerItems(List<CustomerLedgerItem> items) {
    if (_selectedDateRange == null) return items;
    return items.where((item) {
      final date = DateTime(
        item.entry.entryDate.year,
        item.entry.entryDate.month,
        item.entry.entryDate.day,
      );
      final start = DateTime(
        _selectedDateRange!.start.year,
        _selectedDateRange!.start.month,
        _selectedDateRange!.start.day,
      );
      final end = DateTime(
        _selectedDateRange!.end.year,
        _selectedDateRange!.end.month,
        _selectedDateRange!.end.day,
      );
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  Future<void> _exportPdf(
    BuildContext context,
    KhataCustomerModel customer,
    List<CustomerLedgerItem> ledgerItems,
    CustomerBalanceSummary summary,
  ) async {
    setState(() => _isGeneratingPdf = true);

    try {
      final pdf = pw.Document();
      final generatedAtString = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
      final periodString = _selectedDateRange != null
          ? '${_dateFormat.format(_selectedDateRange!.start)} — ${_dateFormat.format(_selectedDateRange!.end)}'
          : 'All Records';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pwContext) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CUSTOMER KHATA STATEMENT',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Period: $periodString',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Expense Tracker Khata',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Generated: $generatedAtString',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),
            ],
          ),
          footer: (pwContext) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Confidential Ledger Document',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${pwContext.pageNumber} of ${pwContext.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
          build: (pwContext) => [
            // ── Customer Info Box ──────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        customer.name,
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      if (customer.phone.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Phone: ${customer.phone}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Closing Balance',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        summary.status == CustomerBalanceStatus.settled
                            ? '₹0.00 (Settled)'
                            : summary.status == CustomerBalanceStatus.advance
                                ? '₹${_currencyFormat.format(summary.currentBalance.abs())} (Advance)'
                                : '₹${_currencyFormat.format(summary.currentBalance)} (Due)',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: summary.status == CustomerBalanceStatus.advance
                              ? PdfColors.blue800
                              : summary.status == CustomerBalanceStatus.due
                                  ? PdfColors.red800
                                  : PdfColors.green800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // ── Financial Summary KPI Cards ────────────────────────────────
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Total Credit Given (+)',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text('₹${_currencyFormat.format(summary.totalGiven)}',
                            style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.red800)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Total Payment Received (-)',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text('₹${_currencyFormat.format(summary.totalReceived)}',
                            style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green800)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Net Pending Balance',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text('₹${_currencyFormat.format(summary.currentBalance.abs())}',
                            style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.indigo900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Ledger Table ────────────────────────────────────────────────
            pw.Text(
              'STATEMENT LEDGER ENTRIES',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 6),

            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Description', 'Given (+)', 'Received (-)', 'Balance'],
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
              ),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
              data: ledgerItems.map((item) {
                final dateStr = _dateFormat.format(item.entry.entryDate);
                final desc = item.entry.isOpeningBalance
                    ? 'Opening Balance'
                    : (item.entry.description?.isNotEmpty == true
                        ? item.entry.description!
                        : (item.entry.type == KhataEntryType.given ? 'Credit Sale' : 'Payment Received'));

                final givenStr = item.entry.type == KhataEntryType.given
                    ? '₹${_currencyFormat.format(item.entry.amount)}'
                    : '-';
                final recStr = item.entry.type == KhataEntryType.received
                    ? '₹${_currencyFormat.format(item.entry.amount)}'
                    : '-';

                final balStr = item.runningBalance == 0
                    ? '₹0.00'
                    : item.runningBalance < 0
                        ? '₹${_currencyFormat.format(item.runningBalance.abs())} Adv'
                        : '₹${_currencyFormat.format(item.runningBalance)} Due';

                return [dateStr, desc, givenStr, recStr, balStr];
              }).toList(),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: '${customer.name.replaceAll(' ', '_')}_Khata_Statement.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerAsync = ref.watch(customerProvider(widget.customerId));
    final balanceSummary = ref.watch(customerBalanceProvider(widget.customerId));
    final allLedgerItems = ref.watch(customerLedgerProvider(widget.customerId));

    return customerAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Statement')),
        body: Center(child: Text('Error: $err')),
      ),
      data: (customer) {
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Statement')),
            body: const Center(child: Text('Customer not found')),
          );
        }

        final filteredItems = _filterLedgerItems(allLedgerItems);
        final summary = balanceSummary ??
            CustomerBalanceSummary(
              customer: customer,
              totalGiven: 0.0,
              totalReceived: 0.0,
              currentBalance: 0.0,
              status: CustomerBalanceStatus.settled,
              lastEntryDate: null,
              entriesCount: 0,
            );

        return Scaffold(
          appBar: AppBar(
            title: Text('${customer.name} - Statement'),
            actions: [
              IconButton(
                icon: _isGeneratingPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.printer),
                tooltip: 'Print / Share PDF',
                onPressed: _isGeneratingPdf
                    ? null
                    : () => _exportPdf(context, customer, filteredItems, summary),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ── 1. Date Filter Header ─────────────────────────────────────
              AppCard(
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDateRange != null
                                ? '${_dateFormat.format(_selectedDateRange!.start)} - ${_dateFormat.format(_selectedDateRange!.end)}'
                                : 'All Time Records',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${filteredItems.length} transactions in period',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedDateRange != null)
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        tooltip: 'Clear Filter',
                        onPressed: _clearDateRange,
                      ),
                    FilledButton.tonalIcon(
                      onPressed: () => _pickDateRange(context),
                      icon: const Icon(LucideIcons.filter, size: 16),
                      label: const Text('Filter'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── 2. Summary Card ───────────────────────────────────────────
              AppCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Given (+)',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${_currencyFormat.format(summary.totalGiven)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Total Received (-)',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${_currencyFormat.format(summary.totalReceived)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.credit,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Net Balance',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${_currencyFormat.format(summary.currentBalance.abs())}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: summary.status == CustomerBalanceStatus.advance
                                    ? Colors.blue
                                    : summary.status == CustomerBalanceStatus.due
                                        ? AppColors.expense
                                        : AppColors.credit,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 3. Statement Table View ────────────────────────────────────
              Text(
                'STATEMENT DETAILS',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),

              if (filteredItems.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No ledger entries in the selected period.'),
                  ),
                )
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      ),
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Description')),
                        DataColumn(label: Text('Given (+)', style: TextStyle(color: AppColors.expense))),
                        DataColumn(label: Text('Received (-)', style: TextStyle(color: AppColors.credit))),
                        DataColumn(label: Text('Balance')),
                      ],
                      rows: filteredItems.map((item) {
                        final dateStr = _dateFormat.format(item.entry.entryDate);
                        final desc = item.entry.isOpeningBalance
                            ? 'Opening Balance'
                            : (item.entry.description?.isNotEmpty == true
                                ? item.entry.description!
                                : (item.entry.type == KhataEntryType.given ? 'Credit' : 'Payment'));

                        final givenStr = item.entry.type == KhataEntryType.given
                            ? '₹${_currencyFormat.format(item.entry.amount)}'
                            : '-';
                        final recStr = item.entry.type == KhataEntryType.received
                            ? '₹${_currencyFormat.format(item.entry.amount)}'
                            : '-';

                        final balStr = item.runningBalance == 0
                            ? '₹0.00'
                            : item.runningBalance < 0
                                ? '₹${_currencyFormat.format(item.runningBalance.abs())} Adv'
                                : '₹${_currencyFormat.format(item.runningBalance)} Due';

                        return DataRow(
                          cells: [
                            DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                            DataCell(
                              Row(
                                children: [
                                  if (item.entry.isOpeningBalance)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('OPENING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  Text(desc, style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            DataCell(Text(
                              givenStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: item.entry.type == KhataEntryType.given ? AppColors.expense : null,
                                fontWeight: item.entry.type == KhataEntryType.given ? FontWeight.w600 : null,
                              ),
                            )),
                            DataCell(Text(
                              recStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: item.entry.type == KhataEntryType.received ? AppColors.credit : null,
                                fontWeight: item.entry.type == KhataEntryType.received ? FontWeight.w600 : null,
                              ),
                            )),
                            DataCell(Text(
                              balStr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: item.runningBalance < 0
                                    ? Colors.blue
                                    : item.runningBalance > 0
                                        ? AppColors.expense
                                        : AppColors.credit,
                              ),
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}
