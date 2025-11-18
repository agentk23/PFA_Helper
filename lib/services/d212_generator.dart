import '../models/pfa.dart';
import '../models/transaction.dart';
import '../models/tax_report.dart';
import '../models/d212_declaration.dart';
import '../utils/tax_calculator.dart';
import 'dart:developer' as developer;

/// D212 Annual Tax Declaration Generator
///
/// Generates the Romanian Single Declaration (Formularul 212)
/// for PFA annual income tax and social contributions
///
/// Uses transaction data and calculates all required fields
/// according to Romanian fiscal legislation
class D212Generator {
  /// Generate D212 declaration for a specific fiscal year
  ///
  /// Parameters:
  /// - [pfa]: PFA information (name, CUI, etc.)
  /// - [transactions]: List of all transactions
  /// - [fiscalYear]: Year for the declaration
  /// - [personalData]: Personal identification data (CNP, etc.)
  /// - [advancePayments]: Optional advance payments made during the year
  static D212Declaration generate({
    required PFA pfa,
    required List<Transaction> transactions,
    required int fiscalYear,
    required Map<String, String> personalData,
    double advancePayments = 0.0,
  }) {
    try {
      // Calculate annual tax report using existing logic
      final taxReport = TaxCalculator.calculateAnnualReport(
        transactions,
        fiscalYear,
      );

      // Calculate income tax components
      final incomeTaxFrom3Percent = _calculateIncomeTaxAt3Percent(taxReport);
      final incomeTaxFrom10Percent = _calculateIncomeTaxAt10Percent(taxReport);

      // Calculate total obligations
      final totalObligation = taxReport.totalTaxes;

      // Calculate balance
      final balance = D212Declaration.calculateBalance(
        totalObligation,
        advancePayments,
      );

      final balanceDue = balance > 0 ? balance : 0.0;
      final balanceToRefund = balance < 0 ? balance.abs() : 0.0;

      developer.log(
        'Generated D212 for fiscal year $fiscalYear',
        name: 'D212Generator',
      );

      return D212Declaration(
        // Personal identification
        cnp: personalData['cnp'] ?? '',
        lastName: personalData['lastName'] ?? '',
        firstName: personalData['firstName'] ?? '',
        address: pfa.address,
        phone: pfa.phone ?? '',
        email: pfa.email ?? '',

        // PFA identification
        cui: pfa.cui,
        pfaName: pfa.name,

        // Fiscal period
        fiscalYear: fiscalYear,

        // Income data
        totalGrossIncome: taxReport.totalIncome,
        totalDeductibleExpenses: taxReport.totalDeductibleExpenses,
        netTaxableIncome: taxReport.netTaxableIncome,

        // Income split by rate
        incomeAt3PercentRate: taxReport.incomeAt3PercentRate,
        incomeAt10PercentRate: taxReport.incomeAt10PercentRate,

        // Expenses allocated proportionally
        expensesFor3PercentIncome: taxReport.expensesAllocatedTo3Percent,
        expensesFor10PercentIncome: taxReport.expensesAllocatedTo10Percent,

        // Social contributions
        casContribution: taxReport.casContribution,
        cassContribution: taxReport.cassContribution,

        // Income tax
        incomeTaxFrom3PercentRate: incomeTaxFrom3Percent,
        incomeTaxFrom10PercentRate: incomeTaxFrom10Percent,
        totalIncomeTax: taxReport.incomeTax,

        // Total obligations
        totalAnnualTaxObligation: totalObligation,

        // Payments and balance
        advancePaymentsMade: advancePayments,
        balanceDue: balanceDue,
        balanceToRefund: balanceToRefund,

        // Declaration metadata
        declarationDate: DateTime.now(),
        isRectificative: false,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to generate D212',
        name: 'D212Generator',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Calculate income tax for 3% rate activities (IT/software)
  static double _calculateIncomeTaxAt3Percent(TaxReport report) {
    if (report.incomeAt3PercentRate == 0) return 0.0;

    final netIncome = report.incomeAt3PercentRate -
        report.expensesAllocatedTo3Percent;

    return netIncome * 0.03;
  }

  /// Calculate income tax for 10% rate activities (standard)
  static double _calculateIncomeTaxAt10Percent(TaxReport report) {
    if (report.incomeAt10PercentRate == 0) return 0.0;

    final netIncome = report.incomeAt10PercentRate -
        report.expensesAllocatedTo10Percent;

    return netIncome * 0.10;
  }

  /// Generate detailed section breakdown for D212
  static List<D212Section> generateSectionBreakdown(D212Declaration declaration) {
    return [
      // Chapter I - Section 1: Income data
      D212Section(
        sectionNumber: 'I.1',
        sectionTitle: 'Date privind veniturile din activități independente',
        fields: [
          D212Field(
            fieldCode: 'A1',
            fieldName: 'Venituri brute totale',
            value: declaration.totalGrossIncome,
            unit: 'RON',
          ),
          D212Field(
            fieldCode: 'A2',
            fieldName: 'Cheltuieli deductibile totale',
            value: declaration.totalDeductibleExpenses,
            unit: 'RON',
          ),
          D212Field(
            fieldCode: 'A3',
            fieldName: 'Venit net impozabil',
            value: declaration.netTaxableIncome,
            unit: 'RON',
          ),
        ],
      ),

      // Chapter I - Section 1.1: Income at 3% rate
      if (declaration.incomeAt3PercentRate > 0)
        D212Section(
          sectionNumber: 'I.1.1',
          sectionTitle: 'Venituri cu cotă specială 3% (IT/software)',
          fields: [
            D212Field(
              fieldCode: 'B1',
              fieldName: 'Venituri IT/software',
              value: declaration.incomeAt3PercentRate,
              unit: 'RON',
            ),
            D212Field(
              fieldCode: 'B2',
              fieldName: 'Cheltuieli alocate',
              value: declaration.expensesFor3PercentIncome,
              unit: 'RON',
            ),
            D212Field(
              fieldCode: 'B3',
              fieldName: 'Venit net IT/software',
              value: declaration.incomeAt3PercentRate -
                  declaration.expensesFor3PercentIncome,
              unit: 'RON',
            ),
            D212Field(
              fieldCode: 'B4',
              fieldName: 'Impozit pe venit (3%)',
              value: declaration.incomeTaxFrom3PercentRate,
              unit: 'RON',
            ),
          ],
        ),

      // Chapter I - Section 1.2: Income at 10% rate
      if (declaration.incomeAt10PercentRate > 0)
        D212Section(
          sectionNumber: 'I.1.2',
          sectionTitle: 'Venituri cu cotă standard 10%',
          fields: [
            D212Field(
              fieldCode: 'C1',
              fieldName: 'Venituri standard',
              value: declaration.incomeAt10PercentRate,
              unit: 'RON',
            ),
            D212Field(
              fieldCode: 'C2',
              fieldName: 'Cheltuieli alocate',
              value: declaration.expensesFor10PercentIncome,
              unit: 'RON',
            ),
            D212Field(
              fieldCode: 'C3',
              fieldName: 'Venit net standard',
              value: declaration.incomeAt10PercentRate -
                  declaration.expensesFor10PercentIncome,
              unit: 'RON',
            ),
            D212Field(
              fieldCode: 'C4',
              fieldName: 'Impozit pe venit (10%)',
              value: declaration.incomeTaxFrom10PercentRate,
              unit: 'RON',
            ),
          ],
        ),

      // Chapter I - Section 3: Social insurance contributions
      D212Section(
        sectionNumber: 'I.3',
        sectionTitle: 'Contribuții de asigurări sociale',
        fields: [
          D212Field(
            fieldCode: 'D1',
            fieldName: 'Contribuția CAS (asigurări sociale)',
            value: declaration.casContribution,
            unit: 'RON',
          ),
          D212Field(
            fieldCode: 'D2',
            fieldName: 'Contribuția CASS (asigurări de sănătate)',
            value: declaration.cassContribution,
            unit: 'RON',
          ),
        ],
      ),

      // Chapter I - Section 4: Total tax obligations
      D212Section(
        sectionNumber: 'I.4',
        sectionTitle: 'Obligații fiscale anuale totale',
        fields: [
          D212Field(
            fieldCode: 'E1',
            fieldName: 'Impozit pe venit total',
            value: declaration.totalIncomeTax,
            unit: 'RON',
          ),
          D212Field(
            fieldCode: 'E2',
            fieldName: 'Contribuții sociale totale (CAS + CASS)',
            value: declaration.casContribution + declaration.cassContribution,
            unit: 'RON',
          ),
          D212Field(
            fieldCode: 'E3',
            fieldName: 'Total obligații fiscale',
            value: declaration.totalAnnualTaxObligation,
            unit: 'RON',
          ),
        ],
      ),

      // Payment summary
      D212Section(
        sectionNumber: 'II',
        sectionTitle: 'Situația plăților',
        fields: [
          D212Field(
            fieldCode: 'F1',
            fieldName: 'Plăți în avans efectuate',
            value: declaration.advancePaymentsMade,
            unit: 'RON',
          ),
          if (declaration.balanceDue > 0)
            D212Field(
              fieldCode: 'F2',
              fieldName: 'Diferență de plată',
              value: declaration.balanceDue,
              unit: 'RON',
            ),
          if (declaration.balanceToRefund > 0)
            D212Field(
              fieldCode: 'F3',
              fieldName: 'Diferență de rambursat',
              value: declaration.balanceToRefund,
              unit: 'RON',
            ),
        ],
      ),
    ];
  }

  /// Generate ANAF-compliant XML representation
  ///
  /// Creates XML structure compatible with ANAF D212 XSD schema
  /// for electronic submission via SPV (Spațiul Privat Virtual)
  static String generateXML(D212Declaration declaration) {
    final buffer = StringBuffer();
    final now = DateTime.now();

    // XML header with encoding
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');

    // Root element with namespace declarations
    buffer.writeln('<declaratie xmlns="mfp:anaf:dgti:d212:declaratie:v1" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');

    // Declaration metadata
    buffer.writeln('  <meta>');
    buffer.writeln('    <dataDeclaratie>${now.toIso8601String().split('T')[0]}</dataDeclaratie>');
    buffer.writeln('    <tipDeclaratie>${declaration.isRectificative ? 'rectificativa' : 'initiala'}</tipDeclaratie>');
    if (declaration.isRectificative && declaration.previousDeclarationNumber != null) {
      buffer.writeln('    <numarDeclaratieAnterioara>${declaration.previousDeclarationNumber}</numarDeclaratieAnterioara>');
    }
    buffer.writeln('    <anRaportat>${declaration.fiscalYear}</anRaportat>');
    buffer.writeln('  </meta>');

    // Personal identification section
    buffer.writeln('  <identificare>');
    buffer.writeln('    <persoanaFizica>');
    buffer.writeln('      <cnp>${declaration.formattedCNP}</cnp>');
    buffer.writeln('      <nume>${_xmlEscape(declaration.lastName)}</nume>');
    buffer.writeln('      <prenume>${_xmlEscape(declaration.firstName)}</prenume>');
    buffer.writeln('      <adresa>${_xmlEscape(declaration.address)}</adresa>');
    buffer.writeln('      <telefon>${_xmlEscape(declaration.phone)}</telefon>');
    buffer.writeln('      <email>${_xmlEscape(declaration.email)}</email>');
    buffer.writeln('    </persoanaFizica>');
    buffer.writeln('    <pfa>');
    buffer.writeln('      <cui>${declaration.formattedCUI}</cui>');
    buffer.writeln('      <denumire>${_xmlEscape(declaration.pfaName)}</denumire>');
    buffer.writeln('    </pfa>');
    buffer.writeln('  </identificare>');

    // Fiscal period
    buffer.writeln('  <perioadaFiscala>');
    buffer.writeln('    <dataInceput>${declaration.fiscalYear}-01-01</dataInceput>');
    buffer.writeln('    <dataSfarsit>${declaration.fiscalYear}-12-31</dataSfarsit>');
    buffer.writeln('  </perioadaFiscala>');

    // Chapter I: Independent activities income
    buffer.writeln('  <capitolI>');

    // Section 1: Income details
    buffer.writeln('    <sectiune1>');
    buffer.writeln('      <titlu>Date privind veniturile din activitati independente</titlu>');
    buffer.writeln('      <venituri>');
    buffer.writeln('        <totalVenituriRealizeate>${_formatAmount(declaration.totalGrossIncome)}</totalVenituriRealizeate>');
    buffer.writeln('        <venituriBazaCalcul3Procent>${_formatAmount(declaration.incomeAt3PercentRate)}</venituriBazaCalcul3Procent>');
    buffer.writeln('        <venituriBazaCalcul10Procent>${_formatAmount(declaration.incomeAt10PercentRate)}</venituriBazaCalcul10Procent>');
    buffer.writeln('      </venituri>');
    buffer.writeln('      <cheltuieli>');
    buffer.writeln('        <totalCheltuieliDeductibile>${_formatAmount(declaration.totalDeductibleExpenses)}</totalCheltuieliDeductibile>');
    buffer.writeln('        <cheltuieliAlocate3Procent>${_formatAmount(declaration.expensesFor3PercentIncome)}</cheltuieliAlocate3Procent>');
    buffer.writeln('        <cheltuieliAlocate10Procent>${_formatAmount(declaration.expensesFor10PercentIncome)}</cheltuieliAlocate10Procent>');
    buffer.writeln('      </cheltuieli>');
    buffer.writeln('      <venitNetImpozabil>${_formatAmount(declaration.netTaxableIncome)}</venitNetImpozabil>');
    buffer.writeln('    </sectiune1>');

    // Section 3: Social insurance contributions
    buffer.writeln('    <sectiune3>');
    buffer.writeln('      <titlu>Determinarea contributiilor sociale obligatorii</titlu>');
    buffer.writeln('      <contributii>');
    buffer.writeln('        <cas>');
    buffer.writeln('          <suma>${_formatAmount(declaration.casContribution)}</suma>');
    buffer.writeln('          <cota>25</cota>');
    buffer.writeln('        </cas>');
    buffer.writeln('        <cass>');
    buffer.writeln('          <suma>${_formatAmount(declaration.cassContribution)}</suma>');
    buffer.writeln('          <cota>10</cota>');
    buffer.writeln('        </cass>');
    buffer.writeln('      </contributii>');
    buffer.writeln('    </sectiune3>');

    // Section 4: Income tax calculation
    buffer.writeln('    <sectiune4>');
    buffer.writeln('      <titlu>Determinarea impozitului pe venit</titlu>');
    buffer.writeln('      <impozit>');
    buffer.writeln('        <impozit3Procent>');
    buffer.writeln('          <suma>${_formatAmount(declaration.incomeTaxFrom3PercentRate)}</suma>');
    buffer.writeln('          <cota>3</cota>');
    buffer.writeln('          <bazaCalcul>${_formatAmount(declaration.incomeAt3PercentRate - declaration.expensesFor3PercentIncome)}</bazaCalcul>');
    buffer.writeln('        </impozit3Procent>');
    buffer.writeln('        <impozit10Procent>');
    buffer.writeln('          <suma>${_formatAmount(declaration.incomeTaxFrom10PercentRate)}</suma>');
    buffer.writeln('          <cota>10</cota>');
    buffer.writeln('          <bazaCalcul>${_formatAmount(declaration.incomeAt10PercentRate - declaration.expensesFor10PercentIncome)}</bazaCalcul>');
    buffer.writeln('        </impozit10Procent>');
    buffer.writeln('        <totalImpozitVenit>${_formatAmount(declaration.totalIncomeTax)}</totalImpozitVenit>');
    buffer.writeln('      </impozit>');
    buffer.writeln('    </sectiune4>');

    buffer.writeln('  </capitolI>');

    // Summary section
    buffer.writeln('  <rezumat>');
    buffer.writeln('    <totalObligatiiAnuale>');
    buffer.writeln('      <impozitVenit>${_formatAmount(declaration.totalIncomeTax)}</impozitVenit>');
    buffer.writeln('      <contributiiCAS>${_formatAmount(declaration.casContribution)}</contributiiCAS>');
    buffer.writeln('      <contributiiCASS>${_formatAmount(declaration.cassContribution)}</contributiiCASS>');
    buffer.writeln('      <total>${_formatAmount(declaration.totalAnnualTaxObligation)}</total>');
    buffer.writeln('    </totalObligatiiAnuale>');
    buffer.writeln('    <platiAvans>');
    buffer.writeln('      <suma>${_formatAmount(declaration.advancePaymentsMade)}</suma>');
    buffer.writeln('    </platiAvans>');
    if (declaration.balanceDue > 0) {
      buffer.writeln('    <diferentaPlata>');
      buffer.writeln('      <suma>${_formatAmount(declaration.balanceDue)}</suma>');
      buffer.writeln('    </diferentaPlata>');
    }
    if (declaration.balanceToRefund > 0) {
      buffer.writeln('    <diferentaRambursat>');
      buffer.writeln('      <suma>${_formatAmount(declaration.balanceToRefund)}</suma>');
      buffer.writeln('    </diferentaRambursat>');
    }
    buffer.writeln('  </rezumat>');

    // Declaration signature
    buffer.writeln('  <semnatura>');
    buffer.writeln('    <numeComplet>${_xmlEscape(declaration.firstName)} ${_xmlEscape(declaration.lastName)}</numeComplet>');
    buffer.writeln('    <dataDeclaratie>${declaration.declarationDate.toIso8601String().split('T')[0]}</dataDeclaratie>');
    buffer.writeln('  </semnatura>');

    buffer.writeln('</declaratie>');

    return buffer.toString();
  }

  /// Format amount for XML (2 decimal places, no thousands separator)
  static String _formatAmount(double amount) {
    return amount.toStringAsFixed(2);
  }

  /// Escape special XML characters
  static String _xmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
