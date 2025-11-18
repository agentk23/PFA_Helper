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

  /// Generate XML representation (simplified, would need full XSD compliance)
  static String generateXML(D212Declaration declaration) {
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<declaratieD212>');
    buffer.writeln('  <identificare>');
    buffer.writeln('    <cnp>${declaration.formattedCNP}</cnp>');
    buffer.writeln('    <nume>${declaration.lastName}</nume>');
    buffer.writeln('    <prenume>${declaration.firstName}</prenume>');
    buffer.writeln('    <cui>${declaration.formattedCUI}</cui>');
    buffer.writeln('    <denumire>${declaration.pfaName}</denumire>');
    buffer.writeln('  </identificare>');
    buffer.writeln('  <perioadaFiscala>');
    buffer.writeln('    <an>${declaration.fiscalYear}</an>');
    buffer.writeln('  </perioadaFiscala>');
    buffer.writeln('  <capitolI>');
    buffer.writeln('    <sectiune1>');
    buffer.writeln('      <venituriTotale>${declaration.totalGrossIncome.toStringAsFixed(2)}</venituriTotale>');
    buffer.writeln('      <cheltuieliDeductibile>${declaration.totalDeductibleExpenses.toStringAsFixed(2)}</cheltuieliDeductibile>');
    buffer.writeln('      <venitNetImpozabil>${declaration.netTaxableIncome.toStringAsFixed(2)}</venitNetImpozabil>');
    buffer.writeln('    </sectiune1>');
    buffer.writeln('    <sectiune3>');
    buffer.writeln('      <contributiiCAS>${declaration.casContribution.toStringAsFixed(2)}</contributiiCAS>');
    buffer.writeln('      <contributiiCASS>${declaration.cassContribution.toStringAsFixed(2)}</contributiiCASS>');
    buffer.writeln('    </sectiune3>');
    buffer.writeln('    <sectiune4>');
    buffer.writeln('      <impozitVenit>${declaration.totalIncomeTax.toStringAsFixed(2)}</impozitVenit>');
    buffer.writeln('      <totalObligatii>${declaration.totalAnnualTaxObligation.toStringAsFixed(2)}</totalObligatii>');
    buffer.writeln('    </sectiune4>');
    buffer.writeln('  </capitolI>');
    buffer.writeln('</declaratieD212>');

    return buffer.toString();
  }
}
