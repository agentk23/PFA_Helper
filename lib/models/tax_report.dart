/// Tax report model for calculating annual taxes
class TaxReport {
  final double totalTaxableIncome;
  final double totalNonTaxableIncome;
  final double totalDeductibleExpenses;
  final double totalNonDeductibleExpenses;
  final int year;

  TaxReport({
    required this.totalTaxableIncome,
    required this.totalNonTaxableIncome,
    required this.totalDeductibleExpenses,
    required this.totalNonDeductibleExpenses,
    required this.year,
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

  /// Income tax (10% of net taxable income)
  double get incomeTax {
    return netTaxableIncome * 0.10;
  }

  /// Minimum gross salary for 2025
  static const double minimumGrossSalary2025 = 4050.0;

  /// CAS (Social Security Contribution) - 25% on calculation base
  /// Thresholds: 12 or 24 minimum gross salaries
  double get casContribution {
    final threshold12 = 12 * minimumGrossSalary2025; // 48,600 RON
    final threshold24 = 24 * minimumGrossSalary2025; // 97,200 RON

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
    final minThreshold = 6 * minimumGrossSalary2025; // 24,300 RON
    final maxThreshold = 60 * minimumGrossSalary2025; // 243,000 RON

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

  /// Check if income exceeds VAT registration threshold (395,000 RON as of Sept 2025)
  bool get requiresVATRegistration {
    return totalIncome >= 395000.0;
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
