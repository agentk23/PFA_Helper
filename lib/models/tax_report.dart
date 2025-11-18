/// Tax report model for calculating annual taxes
///
/// IMPORTANT: All PFA (Persoană Fizică Autorizată) income in Romania is taxed at 10%
/// regardless of activity type or CAEN code. The previous 3% rate was INCORRECT.
///
/// Legal basis: Codul Fiscal Art. 68 (2025)
class TaxReport {
  final double totalTaxableIncome;
  final double totalNonTaxableIncome;
  final double totalDeductibleExpenses;
  final double totalNonDeductibleExpenses;
  final int year;

  // CAEN breakdown (code -> amount) - for informational purposes only
  // Does NOT affect tax rate calculation (all PFA income taxed at 10%)
  final Map<String, double>? incomeByCAEN;
  final Map<String, double>? expensesByCAEN;

  // Deprecated fields - kept for backward compatibility but not used
  @Deprecated('PFA income is always taxed at 10%. This field is no longer used.')
  final double incomeAt3PercentRate;
  @Deprecated('All PFA income is taxed at 10%. Use totalTaxableIncome instead.')
  final double incomeAt10PercentRate;

  TaxReport({
    required this.totalTaxableIncome,
    required this.totalNonTaxableIncome,
    required this.totalDeductibleExpenses,
    required this.totalNonDeductibleExpenses,
    required this.year,
    @Deprecated('Not used - all PFA income taxed at 10%') this.incomeAt3PercentRate = 0.0,
    @Deprecated('Not used - all PFA income taxed at 10%') this.incomeAt10PercentRate = 0.0,
    this.incomeByCAEN,
    this.expensesByCAEN,
  });

  /// Net taxable income (taxable income - deductible expenses)
  double get netTaxableIncome {
    return (totalTaxableIncome - totalDeductibleExpenses).clamp(0, double.infinity);
  }

  /// Total income (all income)
  double get totalIncome {
    return totalTaxableIncome + totalNonTaxableIncome;
  }

  /// Total expenses (all expenses)
  double get totalExpenses {
    return totalDeductibleExpenses + totalNonDeductibleExpenses;
  }

  /// Income tax for PFA (Persoană Fizică Autorizată)
  ///
  /// FIXED in v2.0.0: ALL PFA income in Romania is taxed at 10% flat rate
  /// regardless of activity type or CAEN code.
  ///
  /// Previous versions incorrectly calculated 3% for certain IT CAEN codes.
  /// The 3% rate applies ONLY to SRL microenterprises, NOT to PFA.
  ///
  /// Calculation:
  /// Net Taxable Income = Gross Income - Deductible Expenses - CAS - CASS
  /// Income Tax = Net Taxable Income × 10%
  ///
  /// Legal basis: Codul Fiscal Art. 68 (2025)
  double get incomeTax {
    // First, calculate net income after deducting CAS and CASS
    // (these are deductible for PFA in sistem real)
    final netIncomeAfterContributions = netTaxableIncome - casContribution - cassContribution;
    final taxableBase = netIncomeAfterContributions.clamp(0.0, double.infinity);

    // Apply 10% flat rate to all PFA income
    return taxableBase * 0.10;
  }

  /// Get breakdown of income tax by rate
  ///
  /// UPDATED in v2.0.0: Now returns only 10% standard rate for PFA
  /// The 'special' rate is kept at 0.0 for backward compatibility
  Map<String, double> get incomeTaxBreakdown {
    return {
      'standard': incomeTax,
      'special': 0.0, // No special rate for PFA (only for SRL microenterprises)
    };
  }

  /// Minimum gross salary for 2025
  static const double minimumGrossSalary2025 = 4050.0;

  /// CAS (Social Security Contribution) - 25% on calculation base
  /// Thresholds: 12 or 24 minimum gross salaries
  double get casContribution {
    const threshold12 = 12 * minimumGrossSalary2025; // 48,600 RON
    const threshold24 = 24 * minimumGrossSalary2025; // 97,200 RON

    if (netTaxableIncome >= threshold24) {
      return 24300.0; // Fixed for income >= 24 minimum salaries
    } else if (netTaxableIncome >= threshold12) {
      return 12150.0; // Fixed for income >= 12 minimum salaries
    } else {
      return 0.0; // No CAS contribution below threshold
    }
  }

  /// CASS (Health Insurance Contribution) - 10% of net taxable income
  /// With minimum and maximum thresholds
  double get cassContribution {
    const minThreshold = 6 * minimumGrossSalary2025; // 24,300 RON
    const maxThreshold = 60 * minimumGrossSalary2025; // 243,000 RON

    if (netTaxableIncome < minThreshold) {
      return 2430.0; // Minimum CASS
    } else if (netTaxableIncome > maxThreshold) {
      return 24300.0; // Maximum CASS
    } else {
      return netTaxableIncome * 0.10; // 10% of net income
    }
  }

  /// Total taxes and contributions
  double get totalTaxes {
    return incomeTax + casContribution + cassContribution;
  }

  /// Net profit after all taxes
  double get netProfitAfterTaxes {
    return netTaxableIncome - totalTaxes;
  }

  /// Check if income exceeds VAT registration threshold
  ///
  /// UPDATED in v2.0.0: Threshold reduced from 395,000 to 300,000 RON (2024 legislation)
  /// Legal basis: Codul Fiscal Art. 291 (modified 2024)
  bool get requiresVATRegistration {
    return totalIncome >= 300000.0;
  }

  /// Generate summary map for display
  Map<String, dynamic> toSummaryMap() {
    return {
      'year': year,
      'totalIncome': totalIncome,
      'totalTaxableIncome': totalTaxableIncome,
      'totalNonTaxableIncome': totalNonTaxableIncome,
      'totalExpenses': totalExpenses,
      'totalDeductibleExpenses': totalDeductibleExpenses,
      'totalNonDeductibleExpenses': totalNonDeductibleExpenses,
      'netTaxableIncome': netTaxableIncome,
      'incomeTax': incomeTax,
      'casContribution': casContribution,
      'cassContribution': cassContribution,
      'totalTaxes': totalTaxes,
      'netProfitAfterTaxes': netProfitAfterTaxes,
      'requiresVATRegistration': requiresVATRegistration,
    };
  }
}
