/// D212 Annual Tax Declaration Model
///
/// Implements the Romanian Single Declaration (Declarația Unică) form 212
/// for PFA annual income tax and contributions reporting
///
/// Based on 2025 legislation and form structure
/// Reference: ANAF Formular 212 - Declarație Unică
class D212Declaration {
  // Personal identification
  final String cnp; // Cod Numeric Personal (Personal Numeric Code)
  final String lastName;
  final String firstName;
  final String address;
  final String phone;
  final String email;

  // PFA identification
  final String cui; // CUI/CIF
  final String pfaName;

  // Fiscal period
  final int fiscalYear;

  // Chapter I - Section 1: Income from independent activities
  final double totalGrossIncome; // Total venituri brute
  final double totalDeductibleExpenses; // Total cheltuieli deductibile
  final double netTaxableIncome; // Venit net impozabil

  // Income split by tax rate
  final double incomeAt3PercentRate; // Venituri cu cotă 3% (IT/software)
  final double incomeAt10PercentRate; // Venituri cu cotă 10% (standard)

  // Expenses allocated proportionally
  final double expensesFor3PercentIncome; // Cheltuieli alocate veniturilor 3%
  final double expensesFor10PercentIncome; // Cheltuieli alocate veniturilor 10%

  // Chapter I - Section 3: Social insurance contributions
  final double casContribution; // Contribuția la asigurări sociale (CAS)
  final double cassContribution; // Contribuția la asigurări sociale de sănătate (CASS)

  // Chapter I - Section 4: Income tax calculation
  final double incomeTaxFrom3PercentRate; // Impozit venit pentru activități IT
  final double incomeTaxFrom10PercentRate; // Impozit venit pentru activități standard
  final double totalIncomeTax; // Total impozit pe venit

  // Total obligations
  final double totalAnnualTaxObligation; // Total obligații fiscale anuale

  // Payment information
  final double advancePaymentsMade; // Plăți în avans efectuate
  final double balanceDue; // Diferență de plată
  final double balanceToRefund; // Diferență de rambursat

  // Declaration metadata
  final DateTime declarationDate;
  final bool isRectificative; // Declarație rectificativă
  final String? previousDeclarationNumber; // Număr declarație anterioară

  D212Declaration({
    required this.cnp,
    required this.lastName,
    required this.firstName,
    required this.address,
    required this.phone,
    required this.email,
    required this.cui,
    required this.pfaName,
    required this.fiscalYear,
    required this.totalGrossIncome,
    required this.totalDeductibleExpenses,
    required this.netTaxableIncome,
    required this.incomeAt3PercentRate,
    required this.incomeAt10PercentRate,
    required this.expensesFor3PercentIncome,
    required this.expensesFor10PercentIncome,
    required this.casContribution,
    required this.cassContribution,
    required this.incomeTaxFrom3PercentRate,
    required this.incomeTaxFrom10PercentRate,
    required this.totalIncomeTax,
    required this.totalAnnualTaxObligation,
    this.advancePaymentsMade = 0.0,
    required this.balanceDue,
    required this.balanceToRefund,
    required this.declarationDate,
    this.isRectificative = false,
    this.previousDeclarationNumber,
  });

  /// Calculate balance due or to refund
  static double calculateBalance(double totalObligation, double advancePayments) {
    return totalObligation - advancePayments;
  }

  /// Check if VAT registration is required
  bool get requiresVATRegistration => totalGrossIncome >= 395000.0;

  /// Get formatted CNP
  String get formattedCNP => cnp.padLeft(13, '0');

  /// Get formatted CUI
  String get formattedCUI => cui.startsWith('RO') ? cui : 'RO$cui';

  /// Get fiscal period description
  String get fiscalPeriodDescription => '01.01.$fiscalYear - 31.12.$fiscalYear';

  /// Export to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'cnp': cnp,
      'lastName': lastName,
      'firstName': firstName,
      'address': address,
      'phone': phone,
      'email': email,
      'cui': cui,
      'pfaName': pfaName,
      'fiscalYear': fiscalYear,
      'totalGrossIncome': totalGrossIncome,
      'totalDeductibleExpenses': totalDeductibleExpenses,
      'netTaxableIncome': netTaxableIncome,
      'incomeAt3PercentRate': incomeAt3PercentRate,
      'incomeAt10PercentRate': incomeAt10PercentRate,
      'expensesFor3PercentIncome': expensesFor3PercentIncome,
      'expensesFor10PercentIncome': expensesFor10PercentIncome,
      'casContribution': casContribution,
      'cassContribution': cassContribution,
      'incomeTaxFrom3PercentRate': incomeTaxFrom3PercentRate,
      'incomeTaxFrom10PercentRate': incomeTaxFrom10PercentRate,
      'totalIncomeTax': totalIncomeTax,
      'totalAnnualTaxObligation': totalAnnualTaxObligation,
      'advancePaymentsMade': advancePaymentsMade,
      'balanceDue': balanceDue,
      'balanceToRefund': balanceToRefund,
      'declarationDate': declarationDate.toIso8601String(),
      'isRectificative': isRectificative,
      'previousDeclarationNumber': previousDeclarationNumber,
    };
  }

  /// Create from Map (deserialization)
  factory D212Declaration.fromMap(Map<String, dynamic> map) {
    return D212Declaration(
      cnp: map['cnp'] as String,
      lastName: map['lastName'] as String,
      firstName: map['firstName'] as String,
      address: map['address'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String,
      cui: map['cui'] as String,
      pfaName: map['pfaName'] as String,
      fiscalYear: map['fiscalYear'] as int,
      totalGrossIncome: (map['totalGrossIncome'] as num).toDouble(),
      totalDeductibleExpenses: (map['totalDeductibleExpenses'] as num).toDouble(),
      netTaxableIncome: (map['netTaxableIncome'] as num).toDouble(),
      incomeAt3PercentRate: (map['incomeAt3PercentRate'] as num).toDouble(),
      incomeAt10PercentRate: (map['incomeAt10PercentRate'] as num).toDouble(),
      expensesFor3PercentIncome: (map['expensesFor3PercentIncome'] as num).toDouble(),
      expensesFor10PercentIncome: (map['expensesFor10PercentIncome'] as num).toDouble(),
      casContribution: (map['casContribution'] as num).toDouble(),
      cassContribution: (map['cassContribution'] as num).toDouble(),
      incomeTaxFrom3PercentRate: (map['incomeTaxFrom3PercentRate'] as num).toDouble(),
      incomeTaxFrom10PercentRate: (map['incomeTaxFrom10PercentRate'] as num).toDouble(),
      totalIncomeTax: (map['totalIncomeTax'] as num).toDouble(),
      totalAnnualTaxObligation: (map['totalAnnualTaxObligation'] as num).toDouble(),
      advancePaymentsMade: (map['advancePaymentsMade'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (map['balanceDue'] as num).toDouble(),
      balanceToRefund: (map['balanceToRefund'] as num).toDouble(),
      declarationDate: DateTime.parse(map['declarationDate'] as String),
      isRectificative: map['isRectificative'] as bool? ?? false,
      previousDeclarationNumber: map['previousDeclarationNumber'] as String?,
    );
  }
}

/// D212 Section breakdown for detailed reporting
class D212Section {
  final String sectionNumber;
  final String sectionTitle;
  final List<D212Field> fields;

  const D212Section({
    required this.sectionNumber,
    required this.sectionTitle,
    required this.fields,
  });
}

/// Individual field in D212 form
class D212Field {
  final String fieldCode; // Field code (e.g., "A1", "B2", "C3")
  final String fieldName;
  final dynamic value;
  final String? unit; // RON, %, etc.

  const D212Field({
    required this.fieldCode,
    required this.fieldName,
    required this.value,
    this.unit,
  });

  /// Format value for display
  String get formattedValue {
    if (value is double) {
      return '${(value as double).toStringAsFixed(2)}${unit != null ? ' $unit' : ''}';
    }
    return value.toString();
  }
}
