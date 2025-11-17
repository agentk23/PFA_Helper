import 'package:hive/hive.dart';

part 'transaction_category.g.dart';

/// Transaction categories for PFA accounting
@HiveType(typeId: 0)
enum TransactionCategory {
  @HiveField(0)
  taxableIncome, // Venituri impozabile

  @HiveField(1)
  nonTaxableIncome, // Venituri neimpozabile

  @HiveField(2)
  deductibleExpense, // Cheltuieli deductibile

  @HiveField(3)
  nonDeductibleExpense, // Cheltuieli nedeductibile
}

extension TransactionCategoryExtension on TransactionCategory {
  String get displayName {
    switch (this) {
      case TransactionCategory.taxableIncome:
        return 'Venit Impozabil';
      case TransactionCategory.nonTaxableIncome:
        return 'Venit Neimpozabil';
      case TransactionCategory.deductibleExpense:
        return 'Cheltuială Deductibilă';
      case TransactionCategory.nonDeductibleExpense:
        return 'Cheltuială Nedeductibilă';
    }
  }

  bool get isIncome {
    return this == TransactionCategory.taxableIncome ||
        this == TransactionCategory.nonTaxableIncome;
  }

  bool get isExpense {
    return this == TransactionCategory.deductibleExpense ||
        this == TransactionCategory.nonDeductibleExpense;
  }
}
