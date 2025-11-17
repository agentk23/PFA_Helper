import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../models/tax_report.dart';
import '../models/caen_code.dart';

/// Utility class for tax calculations with CAEN code support
class TaxCalculator {
  /// CAEN codes that qualify for 3% special tax rate (IT/Software development)
  static final specialRateCodes = CAENCode.specialRateCodes;

  /// Calculate tax report for a given year from list of transactions
  /// Supports mixed tax rates based on CAEN codes
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

    // Track income by tax rate
    double incomeAt3Percent = 0.0;
    double incomeAt10Percent = 0.0;

    // Track by CAEN code
    Map<String, double> incomeByCAEN = {};
    Map<String, double> expensesByCAEN = {};

    for (final transaction in yearTransactions) {
      switch (transaction.category) {
        case TransactionCategory.taxableIncome:
          totalTaxableIncome += transaction.amount;

          // Categorize by tax rate based on CAEN code
          if (transaction.caenCode != null &&
              specialRateCodes.contains(transaction.caenCode)) {
            incomeAt3Percent += transaction.amount;
          } else {
            incomeAt10Percent += transaction.amount;
          }

          // Track by CAEN code
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

          // Track expenses by CAEN code
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
      incomeAt3PercentRate: incomeAt3Percent,
      incomeAt10PercentRate: incomeAt10Percent,
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
