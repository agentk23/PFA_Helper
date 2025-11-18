/// Fiscal Constraints for PFA (Persoană Fizică Autorizată) in Romania
///
/// This file models all legal constraints, thresholds, and rates applicable to PFA
/// based on Romanian fiscal legislation (Codul Fiscal, Codul de Procedură Fiscală)
/// Updated for 2025
///
/// Legal basis:
/// - Codul Fiscal (Legea 227/2015, modificată)
/// - Codul de Procedură Fiscală (Legea 207/2015, modificată prin OG 11/2025)
/// - OUG 44/2008 (PFA authorization)

/// Fiscal year configuration
class FiscalYear {
  final int year;
  final double minimumGrossSalary;

  const FiscalYear({
    required this.year,
    required this.minimumGrossSalary,
  });

  /// 2025 Fiscal Year
  static const FiscalYear year2025 = FiscalYear(
    year: 2025,
    minimumGrossSalary: 4050.0,
  );

  /// 2024 Fiscal Year
  static const FiscalYear year2024 = FiscalYear(
    year: 2024,
    minimumGrossSalary: 3700.0,
  );
}

/// Income Tax Configuration
///
/// Legal basis: Codul Fiscal, Art. 68
class IncomeTaxConfig {
  /// Standard income tax rate for ALL PFA
  ///
  /// IMPORTANT: There is NO special 3% rate for PFA.
  /// The 3% rate applies ONLY to SRL microenterprises.
  ///
  /// Legal basis: Codul Fiscal Art. 68
  static const double standardRate = 0.10; // 10%

  /// DEPRECATED: Special rate - NOT applicable to PFA
  ///
  /// This rate applies to SRL (limited liability companies) with
  /// microenterprise status, NOT to PFA.
  ///
  /// Legal basis: Codul Fiscal Art. 52 (microenterprises)
  @Deprecated('Not applicable to PFA - only for SRL microenterprises')
  static const double specialRateSRL = 0.03; // 3% - SRL only!

  /// Calculate income tax for PFA
  ///
  /// Formula:
  /// Net Taxable Income = Gross Income - Deductible Expenses - CAS - CASS
  /// Income Tax = Net Taxable Income × 10%
  static double calculate(double netTaxableIncome, double cas, double cass) {
    final taxableBase = (netTaxableIncome - cas - cass).clamp(0.0, double.infinity);
    return taxableBase * standardRate;
  }
}

/// CAS (Social Insurance Contribution) Configuration
///
/// Legal basis: Codul Fiscal Art. 137-139, Legea 263/2010
class CASConfig {
  /// CAS contribution rate
  static const double rate = 0.25; // 25%

  /// Threshold: 12 minimum gross salaries
  /// Below this, CAS is NOT owed
  static double threshold12Salaries(FiscalYear fiscalYear) {
    return 12 * fiscalYear.minimumGrossSalary;
  }

  /// Threshold: 24 minimum gross salaries
  /// At or above this, fixed CAS amount is owed
  static double threshold24Salaries(FiscalYear fiscalYear) {
    return 24 * fiscalYear.minimumGrossSalary;
  }

  /// Minimum CAS for income >= 12 salaries
  static double minimumCAS12(FiscalYear fiscalYear) {
    return threshold12Salaries(fiscalYear) * rate;
  }

  /// Minimum CAS for income >= 24 salaries
  static double minimumCAS24(FiscalYear fiscalYear) {
    return threshold24Salaries(fiscalYear) * rate;
  }

  /// Calculate CAS contribution
  ///
  /// Rules:
  /// - Net income < 12 salaries: NO CAS
  /// - Net income >= 12 salaries: Minimum 12 salaries × 25%
  /// - Net income >= 24 salaries: Minimum 24 salaries × 25%
  /// - PFA can choose higher base for higher pension
  static double calculate(double netIncome, FiscalYear fiscalYear) {
    final threshold12 = threshold12Salaries(fiscalYear);
    final threshold24 = threshold24Salaries(fiscalYear);

    if (netIncome < threshold12) {
      return 0.0; // No CAS below threshold
    } else if (netIncome >= threshold24) {
      return minimumCAS24(fiscalYear); // Fixed for >= 24 salaries
    } else {
      return minimumCAS12(fiscalYear); // Fixed for >= 12 salaries
    }
  }

  /// Exemptions from CAS
  ///
  /// The following categories do NOT owe CAS:
  static const List<String> exemptions = [
    'Pensionari (orice tip de pensie)',
    'Persoane asigurate în sisteme proprii (avocați, notari, executori judecătorești)',
    'Auditori financiari',
    'Venit net < 12 salarii minime brute pe economie',
  ];
}

/// CASS (Health Insurance Contribution) Configuration
///
/// Legal basis: Codul Fiscal Art. 170-171, Legea 95/2006
class CASSConfig {
  /// CASS contribution rate
  static const double rate = 0.10; // 10%

  /// Minimum base: 6 minimum gross salaries
  static double minimumBase(FiscalYear fiscalYear) {
    return 6 * fiscalYear.minimumGrossSalary;
  }

  /// Maximum base: 60 minimum gross salaries
  static double maximumBase(FiscalYear fiscalYear) {
    return 60 * fiscalYear.minimumGrossSalary;
  }

  /// Minimum CASS amount
  static double minimumCASSAmount(FiscalYear fiscalYear) {
    return minimumBase(fiscalYear) * rate;
  }

  /// Maximum CASS amount
  static double maximumCASSAmount(FiscalYear fiscalYear) {
    return maximumBase(fiscalYear) * rate;
  }

  /// Calculate CASS contribution
  ///
  /// Rules:
  /// - Always owed (unlike CAS)
  /// - Minimum: 6 salaries × 10%
  /// - Maximum: 60 salaries × 10%
  /// - Between min and max: Net income × 10%
  static double calculate(double netIncome, FiscalYear fiscalYear) {
    final minBase = minimumBase(fiscalYear);
    final maxBase = maximumBase(fiscalYear);

    if (netIncome < minBase) {
      return minimumCASSAmount(fiscalYear);
    } else if (netIncome > maxBase) {
      return maximumCASSAmount(fiscalYear);
    } else {
      return netIncome * rate;
    }
  }

  /// Exemptions from CASS
  ///
  /// The following categories do NOT owe CASS if they have health insurance from another source:
  static const List<String> exemptions = [
    'Salariați cu contract de muncă (asigurați prin angajator)',
    'Pensionari (asigurați ca pensionari)',
    'Copii, elevi, studenți (asigurați prin lege)',
    'Persoane asistate social',
    'Alte categorii cu asigurare conform legii',
  ];
}

/// VAT (TVA) Configuration
///
/// Legal basis: Codul Fiscal Art. 291
class VATConfig {
  /// Standard VAT rate
  static const double standardRate = 0.19; // 19%

  /// Reduced VAT rate (9%)
  /// Applicable to: food, drinks, restaurants, hotels, etc.
  static const double reducedRate9 = 0.09; // 9%

  /// Reduced VAT rate (5%)
  /// Applicable to: books, newspapers, medicines, prosthetics, accommodation
  static const double reducedRate5 = 0.05; // 5%

  /// Mandatory VAT registration threshold
  ///
  /// UPDATED 2024: Reduced from 395,000 RON to 300,000 RON
  /// Legal basis: Codul Fiscal Art. 291 (modified 2024)
  static const double mandatoryRegistrationThreshold = 300000.0; // RON

  /// Previous threshold (before 2024)
  @Deprecated('Use mandatoryRegistrationThreshold instead (300,000 RON since 2024)')
  static const double oldThreshold = 395000.0; // RON

  /// Check if VAT registration is mandatory
  static bool isMandatoryRegistration(double annualRevenue) {
    return annualRevenue >= mandatoryRegistrationThreshold;
  }
}

/// CAEN Code Constraints
///
/// Legal basis: OUG 44/2008 Art. 4
class CAENCodeConstraints {
  /// Maximum number of CAEN codes allowed per PFA
  ///
  /// Legal basis: OUG 44/2008, Art. 4
  static const int maxCAENCodes = 5;

  /// Minimum number of CAEN codes required
  static const int minCAENCodes = 1;

  /// CAEN codes restricted to "sistem real" only (cannot use normă de venit)
  ///
  /// Since 2024, the following CAEN codes MUST use "sistem real":
  /// - 6202: IT consultancy
  /// - 6203: IT management
  ///
  /// Legal basis: Codul Fiscal modifications 2024
  static const List<String> sistemRealOnlyCodes = [
    '6202', // Activități de consultanță în tehnologia informației
    '6203', // Activități de management (gestiune și exploatare) a mijloacelor de calcul
  ];

  /// Check if CAEN code requires sistem real
  static bool requiresSistemReal(String caenCode) {
    return sistemRealOnlyCodes.contains(caenCode);
  }

  /// Check if number of CAEN codes is valid
  static bool isValidCodeCount(int count) {
    return count >= minCAENCodes && count <= maxCAENCodes;
  }
}

/// Taxation System Configuration
class TaxationSystemConfig {
  /// Threshold for mandatory "sistem real" (25,000 EUR equivalent in RON)
  ///
  /// If annual gross income exceeds this amount, PFA MUST use "sistem real"
  /// from the following fiscal year.
  ///
  /// Conversion: Use BNR (Banca Națională a României) average annual exchange rate
  ///
  /// Legal basis: Codul Fiscal Art. 69
  static const double eurThreshold = 25000.0; // EUR

  /// Approximate RON threshold (using ~5 RON/EUR estimate)
  /// Actual calculation should use BNR annual average rate
  static const double approximateRONThreshold = 125000.0; // RON (indicative)

  /// Calculate RON threshold for given EUR/RON exchange rate
  static double calculateRONThreshold(double eurRonRate) {
    return eurThreshold * eurRonRate;
  }
}

/// Declaration Deadlines
///
/// Legal basis: Codul de Procedură Fiscală Art. 122
class DeclarationDeadlines {
  /// Deadline for D212 (Declarația Unică) submission
  ///
  /// Must be submitted by May 25 of the year following the fiscal year
  /// If May 25 falls on weekend, deadline is next working day
  ///
  /// Legal basis: Codul de Procedură Fiscală Art. 122
  static DateTime getD212Deadline(int fiscalYear) {
    var deadline = DateTime(fiscalYear + 1, 5, 25);

    // If weekend, move to next Monday
    if (deadline.weekday == DateTime.saturday) {
      deadline = deadline.add(const Duration(days: 2));
    } else if (deadline.weekday == DateTime.sunday) {
      deadline = deadline.add(const Duration(days: 1));
    }

    return deadline;
  }

  /// Deadline for tax payment (same as declaration deadline)
  static DateTime getPaymentDeadline(int fiscalYear) {
    return getD212Deadline(fiscalYear);
  }

  /// E-Factura mandatory date (B2C)
  ///
  /// From July 1, 2025, ALL invoices (including B2C) must be transmitted via SPV
  ///
  /// Legal basis: OG 11/2022 privind RO e-Factura
  static final DateTime eFact uraB2CMandatory = DateTime(2025, 7, 1);

  /// E-Factura mandatory date (B2B)
  ///
  /// B2B invoices have been mandatory since earlier
  static final DateTime eFacturaB2BMandatory = DateTime(2024, 1, 1);
}

/// Document Retention Period
///
/// Legal basis: Codul de Procedură Fiscală Art. 107
class DocumentRetention {
  /// Minimum retention period for fiscal documents
  ///
  /// All fiscal documents (invoices, registers, declarations, contracts)
  /// must be kept for at least 10 years from the date of registration
  ///
  /// Legal basis: Codul de Procedură Fiscală Art. 107
  static const int minimumYears = 10;

  /// Calculate retention deadline for a document
  static DateTime getRetentionDeadline(DateTime documentDate) {
    return DateTime(
      documentDate.year + minimumYears,
      documentDate.month,
      documentDate.day,
    );
  }

  /// Check if document can be deleted
  static bool canDelete(DateTime documentDate, DateTime currentDate) {
    final deadline = getRetentionDeadline(documentDate);
    return currentDate.isAfter(deadline);
  }
}

/// Penalties and Interest Configuration
///
/// Legal basis: Codul de Procedură Fiscală Art. 183
class PenaltiesConfig {
  /// Penalty for late declaration (D212)
  ///
  /// - Up to 30 days late: 500 RON
  /// - Over 30 days late: up to 1,000 RON
  static const double lateDeclarationPenaltyMin = 500.0; // RON
  static const double lateDeclarationPenaltyMax = 1000.0; // RON

  /// Daily interest rate for late payment
  ///
  /// 0.01% per day of delay
  /// Legal basis: Codul de Procedură Fiscală Art. 183
  static const double dailyInterestRate = 0.0001; // 0.01%

  /// Calculate interest for late payment
  static double calculateInterest(double amount, int daysLate) {
    return amount * dailyInterestRate * daysLate;
  }

  /// Penalty for not issuing invoice
  ///
  /// For individuals (PFA): 500 - 1,000 RON
  static const double noInvoicePenaltyMin = 500.0; // RON
  static const double noInvoicePenaltyMax = 1000.0; // RON

  /// Penalty for not transmitting e-Factura
  ///
  /// First offense: 500 RON
  /// Subsequent offenses: progressive increases
  static const double eFacturaPenalty = 500.0; // RON
}

/// Complete 2025 Fiscal Configuration
class FiscalConfig2025 {
  static final fiscalYear = FiscalYear.year2025;

  // Thresholds for 2025
  static const double minimumGrossSalary = 4050.0; // RON

  // CAS thresholds
  static final casThreshold12 = CASConfig.threshold12Salaries(fiscalYear); // 48,600 RON
  static final casThreshold24 = CASConfig.threshold24Salaries(fiscalYear); // 97,200 RON
  static final casMinimum12 = CASConfig.minimumCAS12(fiscalYear); // 12,150 RON
  static final casMinimum24 = CASConfig.minimumCAS24(fiscalYear); // 24,300 RON

  // CASS thresholds
  static final cassMinimumBase = CASSConfig.minimumBase(fiscalYear); // 24,300 RON
  static final cassMaximumBase = CASSConfig.maximumBase(fiscalYear); // 243,000 RON
  static final cassMinimumAmount = CASSConfig.minimumCASSAmount(fiscalYear); // 2,430 RON
  static final cassMaximumAmount = CASSConfig.maximumCASSAmount(fiscalYear); // 24,300 RON

  // Tax rates
  static const incomeTaxRate = IncomeTaxConfig.standardRate; // 10%
  static const casRate = CASConfig.rate; // 25%
  static const cassRate = CASSConfig.rate; // 10%

  // VAT
  static const vatThreshold = VATConfig.mandatoryRegistrationThreshold; // 300,000 RON
  static const vatStandardRate = VATConfig.standardRate; // 19%

  // CAEN
  static const maxCAENCodes = CAENCodeConstraints.maxCAENCodes; // 5

  // Deadlines
  static DateTime declarationDeadline(int year) => DeclarationDeadlines.getD212Deadline(year);
  static const documentRetentionYears = DocumentRetention.minimumYears; // 10 years
}
