import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:intl/intl.dart';
import '../models/pfa.dart';
import '../models/tax_report.dart';

/// Service for generating PDF reports
class PDFService {
  final _currencyFormat = NumberFormat.currency(locale: 'ro_RO', symbol: 'RON');
  final _dateFormat = DateFormat('dd MMMM yyyy', 'ro_RO');

  /// Generate tax report PDF
  Future<void> generateTaxReport({
    required PFA pfa,
    required TaxReport report,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(pfa, report),
          pw.SizedBox(height: 20),
          _buildReportPeriod(report),
          pw.SizedBox(height: 20),
          _buildIncomeSection(report),
          pw.SizedBox(height: 20),
          _buildTaxesSection(report),
          pw.SizedBox(height: 20),
          _buildSummarySection(report),
          pw.SizedBox(height: 30),
          _buildFooter(),
        ],
      ),
    );

    await _savePDF(pdf, 'Raport_Fiscal_${_getFilenameDateRange(report)}');
  }

  pw.Widget _buildHeader(PFA pfa, TaxReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RAPORT FISCAL PFA',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  pfa.fullName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('CUI: ${pfa.cui}'),
                pw.Text('CAEN: ${pfa.caenCode} - ${pfa.caenDescription}'),
                pw.Text(
                  'Sistem taxare: ${pfa.taxationSystem == TaxationSystem.realIncome ? "Venit real" : "Norme de venit"}',
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Generat: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildReportPeriod(TaxReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'Perioada: ${_dateFormat.format(report.startDate)} - ${_dateFormat.format(report.endDate)}',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildIncomeSection(TaxReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'VENITURI ȘI CHELTUIELI',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _buildTableRow('Venituri totale', _currencyFormat.format(report.totalIncome), true),
            _buildTableRow('Cheltuieli totale', _currencyFormat.format(report.totalExpenses)),
            _buildTableRow('Cheltuieli deductibile', _currencyFormat.format(report.deductibleExpenses)),
            _buildTableRow(
              'VENIT NET',
              _currencyFormat.format(report.netIncome),
              true,
              PdfColors.blue700,
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTaxesSection(TaxReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'TAXE DE PLATĂ',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _buildTableRow(
              'Impozit pe venit (10%)',
              _currencyFormat.format(report.incomeTax),
              false,
              PdfColors.red700,
            ),
            _buildTableRow(
              'CAS - Contribuție asigurări sociale (25%)',
              _currencyFormat.format(report.cas),
              false,
              PdfColors.red700,
            ),
            _buildTableRow(
              'CASS - Contribuție asigurări sănătate (10%)',
              _currencyFormat.format(report.cass),
              false,
              PdfColors.red700,
            ),
            _buildTableRow(
              'TOTAL TAXE',
              _currencyFormat.format(report.totalTaxes),
              true,
              PdfColors.red900,
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.red50,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Note importante:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '• Impozitul pe venit se calculează la 10% din venitul net',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                '• CAS se datorează pentru venituri peste ${_currencyFormat.format(3700 * 12)} anual',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                '• CASS se datorează cu un minimum de ${_currencyFormat.format(3700 * 6)} anual',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummarySection(TaxReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'REZULTAT FINAL',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.green50,
            border: pw.Border.all(color: PdfColors.green700, width: 2),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'PROFIT NET (după taxe)',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _currencyFormat.format(report.netProfit),
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Rată efectivă de taxare:'),
                  pw.Text(
                    '${report.effectiveTaxRate.toStringAsFixed(2)}%',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Număr tranzacții:'),
                  pw.Text('${report.transactionCount}'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          'Document generat automat de PFA Helper',
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey600,
          ),
        ),
        pw.Text(
          'Acest document este orientativ. Consultați un consultant fiscal pentru validare.',
          style: const pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  pw.TableRow _buildTableRow(
    String label,
    String value, [
    bool isBold = false,
    PdfColor? color,
  ]) {
    return pw.TableRow(
      decoration: isBold
          ? const pw.BoxDecoration(color: PdfColors.grey100)
          : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getFilenameDateRange(TaxReport report) {
    final startStr = DateFormat('yyyy_MM_dd').format(report.startDate);
    final endStr = DateFormat('yyyy_MM_dd').format(report.endDate);
    return '${startStr}_to_$endStr';
  }

  Future<void> _savePDF(pw.Document pdf, String filename) async {
    try {
      final bytes = await pdf.save();

      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename.pdf');

      // Write the file
      await file.writeAsBytes(bytes);

      // Share the PDF
      final xFile = share_plus.XFile(file.path);
      await share_plus.Share.shareXFiles(
        [xFile],
        subject: 'Raport fiscal PFA',
        text: 'Raport fiscal generat de PFA Helper',
      );
    } catch (e) {
      rethrow;
    }
  }
}
