/// Tax report for a specific period
class TaxReport {
  final DateTime startDate;
  final DateTime endDate;
  final double totalIncome;
  final double totalExpenses;
  final double deductibleExpenses;
  final double netIncome;
  final double incomeTax;
  final double cas; // Social security contribution
  final double cass; // Health insurance contribution
  final double totalTaxes;
  final int transactionCount;

  TaxReport({
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpenses,
    required this.deductibleExpenses,
    required this.netIncome,
    required this.incomeTax,
    required this.cas,
    required this.cass,
    required this.totalTaxes,
    required this.transactionCount,
  });

  /// Net profit after all taxes and expenses
  double get netProfit => netIncome - totalTaxes;

  /// Effective tax rate as percentage
  double get effectiveTaxRate {
    if (totalIncome == 0) return 0;
    return (totalTaxes / totalIncome) * 100;
  }
}
