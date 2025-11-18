import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../models/tax_report.dart';

/// Utility class for PFA tax calculations (Romania 2025)
///
/// IMPORTANT: All PFA income in Romania is taxed at 10% flat rate.
/// The previous implementation incorrectly applied 3% for certain CAEN codes.
///
/// Legal basis: Codul Fiscal Art. 68 (2025)
class TaxCalculator {
  /// Calculate tax report for a given year from list of transactions
  ///
  /// Calculates annual tax obligations for PFA including:
  /// - Income tax (10% on net taxable income after CAS/CASS)
  /// - CAS (social security) - 25% with thresholds
  /// - CASS (health insurance) - 10% with min/max limits
  ///
  /// CAEN codes are tracked for informational purposes but do NOT
  /// affect tax rate calculations (all PFA income taxed at 10%).
  static TaxReport calculateAnnualReport(
    List<Transaction> transactions,
    int year,
  ) {
    // Filter transactions for the specified year
    final yearTransactions = transactions.where((t) {
      return t.date.year == year;
    }).toList();

    double totalTaxableIncome = 0.0;
    double totalNonTaxableIncome = 0.0;
    double totalDeductibleExpenses = 0.0;
    double totalNonDeductibleExpenses = 0.0;

    // Track by CAEN code (for informational/reporting purposes only)
    Map<String, double> incomeByCAEN = {};
    Map<String, double> expensesByCAEN = {};

    for (final transaction in yearTransactions) {
      switch (transaction.category) {
        case TransactionCategory.taxableIncome:
          totalTaxableIncome += transaction.amount;

          // Track by CAEN code for reporting (not used for tax calculation)
          if (transaction.caenCode != null) {
            incomeByCAEN[transaction.caenCode!] =
                (incomeByCAEN[transaction.caenCode!] ?? 0.0) + transaction.amount;
          }
          break;

        case TransactionCategory.nonTaxableIncome:
          totalNonTaxableIncome += transaction.amount;
          break;

        case TransactionCategory.deductibleExpense:
          totalDeductibleExpenses += transaction.amount;

          // Track expenses by CAEN code for reporting
          if (transaction.caenCode != null) {
            expensesByCAEN[transaction.caenCode!] =
                (expensesByCAEN[transaction.caenCode!] ?? 0.0) + transaction.amount;
          }
          break;

        case TransactionCategory.nonDeductibleExpense:
          totalNonDeductibleExpenses += transaction.amount;
          break;
      }
    }

    return TaxReport(
      totalTaxableIncome: totalTaxableIncome,
      totalNonTaxableIncome: totalNonTaxableIncome,
      totalDeductibleExpenses: totalDeductibleExpenses,
      totalNonDeductibleExpenses: totalNonDeductibleExpenses,
      year: year,
      // Deprecated fields - set to 0 for backward compatibility
      incomeAt3PercentRate: 0.0,
      incomeAt10PercentRate: totalTaxableIncome,
      incomeByCAEN: incomeByCAEN.isNotEmpty ? incomeByCAEN : null,
      expensesByCAEN: expensesByCAEN.isNotEmpty ? expensesByCAEN : null,
    );
  }

  /// Calculate monthly summary
  static Map<String, double> calculateMonthlySummary(
    List<Transaction> transactions,
    int year,
    int month,
  ) {
    final monthTransactions = transactions.where((t) {
      return t.date.year == year && t.date.month == month;
    }).toList();

    double totalIncome = 0.0;
    double totalExpenses = 0.0;

    for (final transaction in monthTransactions) {
      if (transaction.isIncome) {
        totalIncome += transaction.amount;
      } else if (transaction.isExpense) {
        totalExpenses += transaction.amount;
      }
    }

    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netProfit': totalIncome - totalExpenses,
    };
  }

  /// Format currency in RON
  static String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} RON';
  }

  /// Calculate quarterly summary (for quarterly tax payments if needed)
  static Map<String, double> calculateQuarterlySummary(
    List<Transaction> transactions,
    int year,
    int quarter,
  ) {
    assert(quarter >= 1 && quarter <= 4, 'Quarter must be between 1 and 4');

    final startMonth = (quarter - 1) * 3 + 1;
    final endMonth = startMonth + 2;

    final quarterTransactions = transactions.where((t) {
      return t.date.year == year &&
          t.date.month >= startMonth &&
          t.date.month <= endMonth;
    }).toList();

    double totalTaxableIncome = 0.0;
    double totalDeductibleExpenses = 0.0;

    for (final transaction in quarterTransactions) {
      if (transaction.category == TransactionCategory.taxableIncome) {
        totalTaxableIncome += transaction.amount;
      } else if (transaction.category == TransactionCategory.deductibleExpense) {
        totalDeductibleExpenses += transaction.amount;
      }
    }

    final netIncome = (totalTaxableIncome - totalDeductibleExpenses).clamp(0.0, double.infinity);

    final estimatedTax = netIncome * 0.10;

    return {
      'totalTaxableIncome': totalTaxableIncome,
      'totalDeductibleExpenses': totalDeductibleExpenses,
      'netIncome': netIncome,
      'estimatedTax': estimatedTax,
    };
  }
}
