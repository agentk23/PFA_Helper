import '../models/transaction.dart';
import '../models/tax_report.dart';
import '../models/pfa.dart';

/// Romanian PFA tax calculator based on fiscal law
class TaxCalculator {
  // 2024 Romanian minimum wage (RON)
  static const double minimumWage = 3700.0;

  // Tax rates for real income system
  static const double incomeTaxRate = 0.10; // 10%
  static const double casRate = 0.25; // 25% - Social security
  static const double cassRate = 0.10; // 10% - Health insurance

  // CAS thresholds (in minimum wages)
  static const double casMinimumThreshold = 12.0; // 12 minimum wages/year
  static const double casMaximumThreshold = 24.0; // 24 minimum wages/year

  // CASS thresholds (in minimum wages)
  static const double cassMinimumThreshold = 6.0; // 6 minimum wages/year

  /// Calculate annual minimum CAS base
  static double get annualCasMinimum => minimumWage * casMinimumThreshold;

  /// Calculate annual maximum CAS base
  static double get annualCasMaximum => minimumWage * casMaximumThreshold;

  /// Calculate annual minimum CASS base
  static double get annualCassMinimum => minimumWage * cassMinimumThreshold;

  /// Calculate taxes for a given period
  static TaxReport calculateTaxReport({
    required List<Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
    required TaxationSystem taxationSystem,
  }) {
    // Filter transactions for the period
    final periodTransactions = transactions.where((t) {
      return t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Calculate totals
    final totalIncome = periodTransactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amountWithoutVAT);

    final totalExpenses = periodTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amountWithoutVAT);

    final deductibleExpenses = periodTransactions
        .where((t) => t.type == TransactionType.expense && t.isDeductible)
        .fold<double>(0, (sum, t) => sum + t.amountWithoutVAT);

    // Net income (for real income system)
    final netIncome = totalIncome - deductibleExpenses;

    // Calculate taxes based on system
    double incomeTax = 0;
    double cas = 0;
    double cass = 0;

    if (taxationSystem == TaxationSystem.realIncome) {
      // Income tax: 10% on net income
      incomeTax = netIncome * incomeTaxRate;

      // CAS calculation (25% on declared income, within thresholds)
      final casBase = _calculateCasBase(totalIncome, startDate, endDate);
      cas = casBase * casRate;

      // CASS calculation (10% on declared income, above minimum)
      final cassBase = _calculateCassBase(totalIncome, startDate, endDate);
      cass = cassBase * cassRate;
    }

    final totalTaxes = incomeTax + cas + cass;

    return TaxReport(
      startDate: startDate,
      endDate: endDate,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      deductibleExpenses: deductibleExpenses,
      netIncome: netIncome,
      incomeTax: incomeTax,
      cas: cas,
      cass: cass,
      totalTaxes: totalTaxes,
      transactionCount: periodTransactions.length,
    );
  }

  /// Calculate CAS base considering annual thresholds
  static double _calculateCasBase(
    double income,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Calculate proportion of year for the period
    final yearFraction = _calculateYearFraction(startDate, endDate);

    // Minimum and maximum for this period
    final periodMinimum = annualCasMinimum * yearFraction;
    final periodMaximum = annualCasMaximum * yearFraction;

    // CAS is mandatory if income exceeds minimum threshold
    if (income < periodMinimum) {
      return 0; // Below minimum, no CAS required
    }

    // Cap at maximum
    if (income > periodMaximum) {
      return periodMaximum;
    }

    return income;
  }

  /// Calculate CASS base considering annual thresholds
  static double _calculateCassBase(
    double income,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Calculate proportion of year for the period
    final yearFraction = _calculateYearFraction(startDate, endDate);

    // Minimum for this period
    final periodMinimum = annualCassMinimum * yearFraction;

    // CASS is always calculated, minimum threshold applies
    if (income < periodMinimum) {
      return periodMinimum;
    }

    return income;
  }

  /// Calculate what fraction of the year a period represents
  static double _calculateYearFraction(DateTime startDate, DateTime endDate) {
    final days = endDate.difference(startDate).inDays + 1;
    final yearDays = _isLeapYear(startDate.year) ? 366 : 365;
    return days / yearDays;
  }

  /// Check if year is leap year
  static bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Calculate quarterly estimated tax payment
  static double calculateQuarterlyPayment({
    required double quarterIncome,
    required TaxationSystem taxationSystem,
  }) {
    if (taxationSystem == TaxationSystem.realIncome) {
      // Quarterly income tax: 10% on estimated net income
      // Simplified: assume 70% net margin for estimation
      final estimatedNet = quarterIncome * 0.7;
      return estimatedNet * incomeTaxRate;
    }
    return 0;
  }

  /// Get tax summary text
  static String getTaxSummary(TaxReport report) {
    final buffer = StringBuffer();
    buffer.writeln('Perioada: ${_formatDate(report.startDate)} - ${_formatDate(report.endDate)}');
    buffer.writeln('Venituri totale: ${_formatCurrency(report.totalIncome)}');
    buffer.writeln('Cheltuieli deductibile: ${_formatCurrency(report.deductibleExpenses)}');
    buffer.writeln('Venit net: ${_formatCurrency(report.netIncome)}');
    buffer.writeln('\nTaxe:');
    buffer.writeln('  Impozit pe venit (10%): ${_formatCurrency(report.incomeTax)}');
    buffer.writeln('  CAS (25%): ${_formatCurrency(report.cas)}');
    buffer.writeln('  CASS (10%): ${_formatCurrency(report.cass)}');
    buffer.writeln('Total taxe: ${_formatCurrency(report.totalTaxes)}');
    buffer.writeln('\nProfit net (după taxe): ${_formatCurrency(report.netProfit)}');
    return buffer.toString();
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  static String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} RON';
  }
}
