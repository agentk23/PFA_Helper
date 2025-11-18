import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/d212_declaration.dart';

/// D212 PDF Export Service
///
/// Generates professional PDF documents for D212 annual tax declarations
/// compliant with Romanian ANAF requirements
class D212PdfExporter {
  static final _dateFormat = DateFormat('dd.MM.yyyy');
  static final _currencyFormat = NumberFormat('#,##0.00', 'ro_RO');

  /// Generate PDF document for D212 declaration
  ///
  /// Returns a PDF document ready to be saved or printed
  static Future<pw.Document> generatePDF(D212Declaration declaration) async {
    final pdf = pw.Document(
      title: 'Declarație Unică D212 - ${declaration.fiscalYear}',
      author: '${declaration.firstName} ${declaration.lastName}',
      creator: 'PFA Helper',
      subject: 'Declarație privind impozitul pe venit și contribuțiile sociale',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(declaration),
          pw.SizedBox(height: 20),
          _buildPersonalInfo(declaration),
          pw.SizedBox(height: 20),
          _buildPFAInfo(declaration),
          pw.SizedBox(height: 20),
          _buildChapterI(declaration),
          pw.SizedBox(height: 20),
          _buildSummary(declaration),
          pw.SizedBox(height: 30),
          _buildSignature(declaration),
        ],
        footer: (context) => _buildFooter(context, declaration),
      ),
    );

    return pdf;
  }

  /// Build document header
  static pw.Widget _buildHeader(D212Declaration declaration) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'DECLARAȚIE UNICĂ',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'privind impozitul pe venit și contribuțiile sociale datorate',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.Text(
          'de persoanele fizice (formular 212)',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'An fiscal: ${declaration.fiscalYear}',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (declaration.isRectificative) ...[
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.red, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'DECLARAȚIE RECTIFICATIVĂ',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red,
              ),
            ),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 2),
      ],
    );
  }

  /// Build personal information section
  static pw.Widget _buildPersonalInfo(D212Declaration declaration) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DATE DE IDENTIFICARE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('Nume', declaration.lastName),
          _buildInfoRow('Prenume', declaration.firstName),
          _buildInfoRow('CNP', declaration.formattedCNP),
          _buildInfoRow('Adresă', declaration.address),
          _buildInfoRow('Telefon', declaration.phone),
          _buildInfoRow('Email', declaration.email),
        ],
      ),
    );
  }

  /// Build PFA information section
  static pw.Widget _buildPFAInfo(D212Declaration declaration) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DATE PFA',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('Denumire PFA', declaration.pfaName),
          _buildInfoRow('CUI/CIF', declaration.formattedCUI),
          _buildInfoRow('Perioadă fiscală', declaration.fiscalPeriodDescription),
        ],
      ),
    );
  }

  /// Build Chapter I - Income and contributions
  static pw.Widget _buildChapterI(D212Declaration declaration) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          child: pw.Text(
            'CAPITOLUL I - VENITURI DIN ACTIVITĂȚI INDEPENDENTE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 12),

        // Section 1: Income
        pw.Text(
          'Secțiunea 1: Date privind veniturile',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        _buildTable([
          ['Indicator', 'Descriere', 'Sumă (RON)'],
          [
            'A1',
            'Total venituri brute',
            _formatCurrency(declaration.totalGrossIncome),
          ],
          [
            'A2',
            'Venituri din activități IT (cotă 3%)',
            _formatCurrency(declaration.incomeAt3PercentRate),
          ],
          [
            'A3',
            'Venituri din alte activități (cotă 10%)',
            _formatCurrency(declaration.incomeAt10PercentRate),
          ],
        ]),
        pw.SizedBox(height: 16),

        // Section 2: Expenses
        pw.Text(
          'Secțiunea 2: Cheltuieli deductibile',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        _buildTable([
          ['Indicator', 'Descriere', 'Sumă (RON)'],
          [
            'B1',
            'Total cheltuieli deductibile',
            _formatCurrency(declaration.totalDeductibleExpenses),
          ],
          [
            'B2',
            'Cheltuieli alocate veniturilor 3%',
            _formatCurrency(declaration.expensesFor3PercentIncome),
          ],
          [
            'B3',
            'Cheltuieli alocate veniturilor 10%',
            _formatCurrency(declaration.expensesFor10PercentIncome),
          ],
          [
            'B4',
            'Venit net impozabil',
            _formatCurrency(declaration.netTaxableIncome),
          ],
        ]),
        pw.SizedBox(height: 16),

        // Section 3: Social contributions
        pw.Text(
          'Secțiunea 3: Contribuții sociale',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        _buildTable([
          ['Indicator', 'Descriere', 'Sumă (RON)'],
          [
            'C1',
            'Contribuție CAS (asigurări sociale)',
            _formatCurrency(declaration.casContribution),
          ],
          [
            'C2',
            'Contribuție CASS (asigurări sociale de sănătate)',
            _formatCurrency(declaration.cassContribution),
          ],
        ]),
        pw.SizedBox(height: 16),

        // Section 4: Income tax
        pw.Text(
          'Secțiunea 4: Impozit pe venit',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        _buildTable([
          ['Indicator', 'Descriere', 'Sumă (RON)'],
          [
            'D1',
            'Impozit venit pentru activități IT (3%)',
            _formatCurrency(declaration.incomeTaxFrom3PercentRate),
          ],
          [
            'D2',
            'Impozit venit pentru alte activități (10%)',
            _formatCurrency(declaration.incomeTaxFrom10PercentRate),
          ],
          [
            'D3',
            'Total impozit pe venit',
            _formatCurrency(declaration.totalIncomeTax),
          ],
        ]),
      ],
    );
  }

  /// Build financial summary section
  static pw.Widget _buildSummary(D212Declaration declaration) {
    final balance = declaration.balanceDue - declaration.balanceToRefund;
    final isPayable = balance > 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'REZUMAT OBLIGAȚII FISCALE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildSummaryRow(
            'Total impozit pe venit',
            declaration.totalIncomeTax,
          ),
          _buildSummaryRow(
            'Total contribuții CAS',
            declaration.casContribution,
          ),
          _buildSummaryRow(
            'Total contribuții CASS',
            declaration.cassContribution,
          ),
          pw.Divider(thickness: 1),
          _buildSummaryRow(
            'TOTAL OBLIGAȚII FISCALE ANUALE',
            declaration.totalAnnualTaxObligation,
            bold: true,
          ),
          pw.SizedBox(height: 8),
          _buildSummaryRow(
            'Plăți în avans efectuate',
            declaration.advancePaymentsMade,
          ),
          pw.Divider(thickness: 1),
          if (isPayable)
            _buildSummaryRow(
              'DIFERENȚĂ DE PLATĂ',
              declaration.balanceDue,
              bold: true,
              color: PdfColors.red900,
            )
          else if (declaration.balanceToRefund > 0)
            _buildSummaryRow(
              'DIFERENȚĂ DE RAMBURSAT',
              declaration.balanceToRefund,
              bold: true,
              color: PdfColors.green900,
            )
          else
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'STATUS',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'ACHITAT',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green900,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Build signature section
  static pw.Widget _buildSignature(D212Declaration declaration) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DECLARAȚIE PE PROPRIA RĂSPUNDERE',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Subsemnatul(a) ${declaration.firstName} ${declaration.lastName}, '
          'declar pe propria răspundere că datele înscrise în această declarație '
          'sunt corecte și complete.',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Data: ${_dateFormat.format(declaration.declarationDate)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Semnătura:',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  width: 150,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Build page footer
  static pw.Widget _buildFooter(pw.Context context, D212Declaration declaration) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        children: [
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 4),
          pw.Text(
            'Declarație D212 - ${declaration.fiscalYear} | '
            'Generat: ${_dateFormat.format(DateTime.now())} | '
            'Pagina ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Build info row helper
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// Build table helper
  static pw.Widget _buildTable(List<List<String>> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
      },
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        final isHeader = index == 0;

        return pw.TableRow(
          decoration: isHeader
              ? const pw.BoxDecoration(color: PdfColors.grey300)
              : null,
          children: row.map((cell) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                cell,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
                textAlign: row.indexOf(cell) == 2
                    ? pw.TextAlign.right
                    : pw.TextAlign.left,
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  /// Build summary row helper
  static pw.Widget _buildSummaryRow(
    String label,
    double amount, {
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: bold ? 12 : 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
          pw.Text(
            '${_formatCurrency(amount)} RON',
            style: pw.TextStyle(
              fontSize: bold ? 12 : 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Format currency helper
  static String _formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Save PDF to file
  static Future<File> savePDF(
    pw.Document pdf,
    String filePath,
  ) async {
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Generate suggested filename for D212 PDF
  static String getSuggestedFilename(D212Declaration declaration) {
    final sanitizedName = declaration.lastName.replaceAll(' ', '_');
    return 'D212_${declaration.fiscalYear}_${sanitizedName}_${declaration.formattedCNP}.pdf';
  }
}
