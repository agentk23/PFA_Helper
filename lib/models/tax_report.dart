/// Tax report model for calculating annual taxes
/// Supports mixed tax rates based on CAEN codes (standard 10% + special 3% rate)
class TaxReport {
  final double totalTaxableIncome;
  final double totalNonTaxableIncome;
  final double totalDeductibleExpenses;
  final double totalNonDeductibleExpenses;
  final int year;

  // CAEN-specific income tracking
  final double incomeAt3PercentRate; // Income from CAEN codes with 3% special rate
  final double incomeAt10PercentRate; // Income from standard CAEN codes

  // CAEN breakdown (code -> amount)
  final Map<String, double>? incomeByCAEN;
  final Map<String, double>? expensesByCAEN;

  TaxReport({
    required this.totalTaxableIncome,
    required this.totalNonTaxableIncome,
    required this.totalDeductibleExpenses,
    required this.totalNonDeductibleExpenses,
    required this.year,
    this.incomeAt3PercentRate = 0.0,
    this.incomeAt10PercentRate = 0.0,
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

  /// Income tax with support for mixed rates (3% for IT/software + 10% standard)
  /// Calculates proportionally based on income from different CAEN categories
  double get incomeTax {
    // If we have specific breakdown, calculate with mixed rates
    if (incomeAt3PercentRate > 0 || incomeAt10PercentRate > 0) {
      // Calculate net income proportionally
      final totalIncome = incomeAt3PercentRate + incomeAt10PercentRate;
      if (totalIncome <= 0) return 0;

      // Proportion of expenses to each income type
      final ratio3Percent = incomeAt3PercentRate / totalIncome;
      final ratio10Percent = incomeAt10PercentRate / totalIncome;

      final expenses3Percent = totalDeductibleExpenses * ratio3Percent;
      final expenses10Percent = totalDeductibleExpenses * ratio10Percent;

      final netIncome3Percent = (incomeAt3PercentRate - expenses3Percent).clamp(0.0, double.infinity);
      final netIncome10Percent = (incomeAt10PercentRate - expenses10Percent).clamp(0.0, double.infinity);

      return (netIncome3Percent * 0.03) + (netIncome10Percent * 0.10);
    }

    // Fallback: standard 10% rate
    return netTaxableIncome * 0.10;
  }

  /// Get breakdown of income tax by rate
  Map<String, double> get incomeTaxBreakdown {
    if (incomeAt3PercentRate > 0 || incomeAt10PercentRate > 0) {
      final totalIncome = incomeAt3PercentRate + incomeAt10PercentRate;
      if (totalIncome <= 0) {
        return {'standard': 0.0, 'special': 0.0};
      }

      final ratio3Percent = incomeAt3PercentRate / totalIncome;
      final ratio10Percent = incomeAt10PercentRate / totalIncome;

      final expenses3Percent = totalDeductibleExpenses * ratio3Percent;
      final expenses10Percent = totalDeductibleExpenses * ratio10Percent;

      final netIncome3Percent = (incomeAt3PercentRate - expenses3Percent).clamp(0.0, double.infinity);
      final netIncome10Percent = (incomeAt10PercentRate - expenses10Percent).clamp(0.0, double.infinity);

      return {
        'special': netIncome3Percent * 0.03,
        'standard': netIncome10Percent * 0.10,
      };
    }

    return {'standard': netTaxableIncome * 0.10, 'special': 0.0};
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
