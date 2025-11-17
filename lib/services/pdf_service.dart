import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/pfa.dart';
import '../models/tax_report.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';

/// Service for generating PDF reports for ANAF
class PDFService {
  /// Generate annual tax report PDF
  static Future<File> generateAnnualTaxReport({
    required PFA pfa,
    required TaxReport taxReport,
    required List<Transaction> transactions,
  }) async {
    final pdf = pw.Document();

    // Format currency
    String formatCurrency(double amount) {
      return '${amount.toStringAsFixed(2)} RON';
    }

    // Add cover page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                color: PdfColors.blue900,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RAPORT FISCAL ANUAL ${taxReport.year}',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'PFA ${pfa.name}',
                      style: const pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // PFA Information
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INFORMAȚII PFA',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('CUI: ${pfa.cui}'),
                    pw.Text('Nume: ${pfa.name}'),
                    pw.Text('Adresă: ${pfa.address}'),
                    pw.Text('Tip activitate: ${pfa.activityType}'),
                    pw.Text(
                        'Sistem de taxare: ${pfa.isRealSystem ? "Sistem Real" : "Norme de venit"}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Summary
              pw.Text(
                'SUMAR FINANCIAR',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),

              // Income and Expenses Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Categorie',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Sumă (RON)',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Data rows
                  _buildTableRow('Venituri Impozabile',
                      formatCurrency(taxReport.totalTaxableIncome)),
                  _buildTableRow('Venituri Neimpozabile',
                      formatCurrency(taxReport.totalNonTaxableIncome)),
                  _buildTableRow('Total Venituri',
                      formatCurrency(taxReport.totalIncome)),
                  _buildTableRow('Cheltuieli Deductibile',
                      formatCurrency(taxReport.totalDeductibleExpenses)),
                  _buildTableRow('Cheltuieli Nedeductibile',
                      formatCurrency(taxReport.totalNonDeductibleExpenses)),
                  _buildTableRow('Total Cheltuieli',
                      formatCurrency(taxReport.totalExpenses)),
                  _buildTableRow('Venit Net Impozabil',
                      formatCurrency(taxReport.netTaxableIncome),
                      isHighlight: true),
                ],
              ),
              pw.SizedBox(height: 30),

              // Taxes Table
              pw.Text(
                'TAXE ȘI CONTRIBUȚII',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Tip Taxă',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Sumă (RON)',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  _buildTableRow(
                      'Impozit pe venit (10%)', formatCurrency(taxReport.incomeTax)),
                  _buildTableRow(
                      'CAS (25%)', formatCurrency(taxReport.casContribution)),
                  _buildTableRow(
                      'CASS (10%)', formatCurrency(taxReport.cassContribution)),
                  _buildTableRow('TOTAL TAXE', formatCurrency(taxReport.totalTaxes),
                      isHighlight: true),
                ],
              ),
              pw.SizedBox(height: 20),

              // Net Profit
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green700, width: 2),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'PROFIT NET (după taxe)',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      formatCurrency(taxReport.netProfitAfterTaxes),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                  ],
                ),
              ),

              // VAT Warning if applicable
              if (taxReport.requiresVATRegistration) ...[
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    border: pw.Border.all(color: PdfColors.red700, width: 2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '⚠ ATENȚIE: Obligație înregistrare TVA',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red900,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Venitul total depășește pragul de 395.000 RON. Este necesară înregistrarea pentru TVA.',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],

              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.Text(
                'Generat pe: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/raport_fiscal_${taxReport.year}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Build table row helper
  static pw.TableRow _buildTableRow(String label, String value,
      {bool isHighlight = false}) {
    return pw.TableRow(
      decoration: isHighlight
          ? const pw.BoxDecoration(color: PdfColors.yellow50)
          : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: isHighlight
                ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                : null,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: isHighlight
                ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                : null,
          ),
        ),
      ],
    );
  }

  /// Generate transactions list PDF
  static Future<File> generateTransactionsList({
    required PFA pfa,
    required List<Transaction> transactions,
    required int year,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy');

    // Sort transactions by date
    transactions.sort((a, b) => a.date.compareTo(b.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              color: PdfColors.blue900,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'REGISTRU VENITURI ȘI CHELTUIELI $year',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'PFA ${pfa.name} - CUI: ${pfa.cui}',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Transactions table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildHeaderCell('Data'),
                    _buildHeaderCell('Descriere'),
                    _buildHeaderCell('Categorie'),
                    _buildHeaderCell('Nr. Fact.'),
                    _buildHeaderCell('Sumă (RON)'),
                  ],
                ),
                // Data rows
                ...transactions.map((t) {
                  return pw.TableRow(
                    children: [
                      _buildCell(dateFormat.format(t.date)),
                      _buildCell(t.description),
                      _buildCell(_getCategoryName(t.category)),
                      _buildCell(t.invoiceNumber ?? '-'),
                      _buildCell(
                        t.amount.toStringAsFixed(2),
                        color: t.isIncome ? PdfColors.green900 : PdfColors.red900,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/registru_tranzactii_$year.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildCell(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, color: color),
      ),
    );
  }

  static String _getCategoryName(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.taxableIncome:
        return 'Venit Impozabil';
      case TransactionCategory.nonTaxableIncome:
        return 'Venit Neimpozabil';
      case TransactionCategory.deductibleExpense:
        return 'Cheltuială Deductibilă';
      case TransactionCategory.nonDeductibleExpense:
        return 'Cheltuială Nedeductibilă';
    }
  }
}
