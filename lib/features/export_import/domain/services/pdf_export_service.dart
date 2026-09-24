import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../debts/domain/models/debt_model.dart';
import '../../../goals/domain/models/savings_goal_model.dart';
import '../../../transactions/domain/models/transaction_model.dart';
import '../models/pdf_report_config.dart';

/// Pure domain service generating styled multi-page PDF financial statements.
class PdfExportService {
  const PdfExportService();

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');

  /// Generates complete PDF document bytes matching the requested configuration.
  Future<Uint8List> generateFinancialReportPdf({
    required PdfReportConfig config,
    required DateTime startDate,
    required DateTime endDate,
    required double openingBalance,
    required List<TransactionModel> transactions,
    required List<SavingsGoalModel> savingsGoals,
    required List<DebtModel> debts,
    required Map<String, String> accountNames,
    required Map<String, String> categoryNames,
    String currencySymbol = '₹',
    bool includeTransactions = true,
    bool includeSavings = true,
    bool includeDebts = true,
  }) async {
    final pdf = pw.Document();

    // Financial calculations for period
    var totalIncome = 0.0;
    var totalExpense = 0.0;

    for (final tx in transactions) {
      if (tx.type.toUpperCase() == 'CREDIT' || tx.type.toUpperCase() == 'INCOME') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }

    final netCashFlow = totalIncome - totalExpense;
    final closingBalance = openingBalance + netCashFlow;

    final periodString = '${_dateFormat.format(startDate)} — ${_dateFormat.format(endDate)}';
    final generatedAtString = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(config, periodString),
        footer: (context) => _buildFooter(context, config, generatedAtString),
        build: (context) => [
          // ── 1. Executive Financial Summary ─────────────────────────────────
          pw.Text(
            'EXECUTIVE FINANCIAL SUMMARY',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildSummaryGrid(
            openingBalance: openingBalance,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            netCashFlow: netCashFlow,
            closingBalance: closingBalance,
            currencySymbol: currencySymbol,
          ),
          pw.SizedBox(height: 24),

          // ── 2. Transaction Ledger ──────────────────────────────────────────
          if (includeTransactions) ...[
            pw.Text(
              'TRANSACTION LEDGER (${transactions.length} Records)',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 8),
            if (transactions.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Center(
                  child: pw.Text('No transactions recorded for this period.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ),
              )
            else
              _buildTransactionsTable(
                transactions,
                accountNames: accountNames,
                categoryNames: categoryNames,
                currencySymbol: currencySymbol,
              ),
            pw.SizedBox(height: 24),
          ],

          // ── 3. Savings Goals (if selected) ──────────────────────────────────
          if (includeSavings) ...[
            pw.Text(
              'SAVINGS GOALS & ALLOCATIONS (${savingsGoals.length} Goals)',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 8),
            if (savingsGoals.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Center(
                  child: pw.Text('No savings goals recorded.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ),
              )
            else
              _buildSavingsTable(savingsGoals, currencySymbol: currencySymbol),
            pw.SizedBox(height: 24),
          ],

          // ── 4. Debts & Loans (if selected) ─────────────────────────────────
          if (includeDebts) ...[
            pw.Text(
              'DEBTS & LOANS SCHEDULE (${debts.length} Records)',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 8),
            if (debts.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Center(
                  child: pw.Text('No debts or loans recorded.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ),
              )
            else
              _buildDebtsTable(debts, currencySymbol: currencySymbol),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(PdfReportConfig config, String periodString) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.indigo600, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  config.title,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
                if (config.subtitle?.isNotEmpty == true)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      config.subtitle!,
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                    ),
                  ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Statement Period: $periodString',
                  style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          if (config.name != null || config.email != null || config.phone != null || config.address != null)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (config.name != null)
                  pw.Text(
                    config.name!,
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
                  ),
                if (config.email != null)
                  pw.Text(config.email!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                if (config.phone != null)
                  pw.Text(config.phone!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                if (config.address != null)
                  pw.Text(config.address!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, PdfReportConfig config, String generatedAt) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            config.footerText,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Generated on $generatedAt',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryGrid({
    required double openingBalance,
    required double totalIncome,
    required double totalExpense,
    required double netCashFlow,
    required double closingBalance,
    required String currencySymbol,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryBox('Opening Balance', '$currencySymbol${_currencyFormat.format(openingBalance)}', PdfColors.grey800),
          _buildSummaryBox('Total Income', '+$currencySymbol${_currencyFormat.format(totalIncome)}', PdfColors.green700),
          _buildSummaryBox('Total Expense', '-$currencySymbol${_currencyFormat.format(totalExpense)}', PdfColors.red700),
          _buildSummaryBox('Net Cash Flow', '${netCashFlow >= 0 ? '+' : ''}$currencySymbol${_currencyFormat.format(netCashFlow)}', netCashFlow >= 0 ? PdfColors.green700 : PdfColors.red700),
          _buildSummaryBox('Closing Balance', '$currencySymbol${_currencyFormat.format(closingBalance)}', PdfColors.indigo800),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryBox(String title, String amount, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 3),
        pw.Text(
          amount,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }

  pw.Widget _buildTransactionsTable(
    List<TransactionModel> transactions, {
    required Map<String, String> accountNames,
    required Map<String, String> categoryNames,
    required String currencySymbol,
  }) {
    return pw.TableHelper.fromTextArray(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
      headerHeight: 22,
      cellHeight: 20,
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
      },
      headers: ['Date', 'Description', 'Category', 'Account', 'Type', 'Amount'],
      data: transactions.map((tx) {
        final isCredit = tx.type.toUpperCase() == 'CREDIT' || tx.type.toUpperCase() == 'INCOME';
        return [
          _dateFormat.format(tx.transactionDate),
          tx.description?.isNotEmpty == true ? tx.description! : '—',
          categoryNames[tx.categoryId] ?? tx.categoryId,
          accountNames[tx.accountId] ?? tx.accountId,
          isCredit ? 'CREDIT' : 'EXPENSE',
          '${isCredit ? '+' : '-'}$currencySymbol${_currencyFormat.format(tx.amount)}',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildSavingsTable(
    List<SavingsGoalModel> goals, {
    required String currencySymbol,
  }) {
    return pw.TableHelper.fromTextArray(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
      headerHeight: 22,
      cellHeight: 20,
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.center,
      },
      headers: ['Goal Name', 'Target Amount', 'Current Saved', 'Progress %', 'Remaining', 'Status'],
      data: goals.map((g) {
        return [
          g.name,
          '$currencySymbol${_currencyFormat.format(g.targetAmount)}',
          '$currencySymbol${_currencyFormat.format(g.currentAmount)}',
          '${g.savedPercentage.toStringAsFixed(1)}%',
          '$currencySymbol${_currencyFormat.format(g.remainingAmount)}',
          g.isCompleted ? 'COMPLETED' : 'ACTIVE',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildDebtsTable(
    List<DebtModel> debts, {
    required String currencySymbol,
  }) {
    return pw.TableHelper.fromTextArray(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      headerHeight: 22,
      cellHeight: 20,
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.center,
        6: pw.Alignment.center,
      },
      headers: ['Person', 'Type', 'Principal', 'Total Expected', 'Remaining', 'Due Date', 'Status'],
      data: debts.map((d) {
        return [
          d.personName,
          d.type.name.toUpperCase(),
          '$currencySymbol${_currencyFormat.format(d.principalAmount)}',
          '$currencySymbol${_currencyFormat.format(d.totalRepaymentAmount)}',
          '$currencySymbol${_currencyFormat.format(d.remainingAmount)}',
          d.dueDate != null ? _dateFormat.format(d.dueDate!) : '—',
          d.status.name.toUpperCase(),
        ];
      }).toList(),
    );
  }
}
