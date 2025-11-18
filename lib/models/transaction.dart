import 'package:hive/hive.dart';
import 'transaction_category.dart';

part 'transaction.g.dart';

/// Transaction model for PFA accounting
/// Each transaction can be associated with a specific CAEN code (economic activity)
@HiveType(typeId: 2)
class Transaction extends HiveObject {
  @HiveField(0)
  String id; // Unique identifier

  @HiveField(1)
  double amount; // Amount in RON

  @HiveField(2)
  DateTime date; // Transaction date

  @HiveField(3)
  TransactionCategory category; // Transaction category

  @HiveField(4)
  String description; // Transaction description

  @HiveField(5)
  String? invoiceNumber; // Optional invoice/receipt number

  @HiveField(6)
  String? notes; // Optional additional notes

  @HiveField(7)
  DateTime createdAt; // When the transaction was recorded

  @HiveField(8)
  String? caenCode; // Associated CAEN code (stores the code string, e.g., "6201")

  @HiveField(9)
  double? customTaxRate; // Optional custom tax rate for this specific transaction (overrides CAEN default)

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.category,
    required this.description,
    this.invoiceNumber,
    this.notes,
    required this.createdAt,
    this.caenCode,
    this.customTaxRate,
  });

  /// Creates a copy of this Transaction with the given fields replaced with new values
  ///
  /// Returns a new [Transaction] instance with the specified fields updated.
  /// Any field that is not provided will retain its current value.
  Transaction copyWith({
    String? id,
    double? amount,
    DateTime? date,
    TransactionCategory? category,
    String? description,
    String? invoiceNumber,
    String? notes,
    DateTime? createdAt,
    String? caenCode,
    double? customTaxRate,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      caenCode: caenCode ?? this.caenCode,
      customTaxRate: customTaxRate ?? this.customTaxRate,
    );
  }

  /// Returns true if this transaction is income (taxable or non-taxable)
  bool get isIncome => category.isIncome;

  /// Returns true if this transaction is an expense (deductible or non-deductible)
  bool get isExpense => category.isExpense;

  /// Get the effective tax rate for this transaction
  /// Priority: custom rate > CAEN-specific rate > standard 10%
  double getEffectiveTaxRate({List<String>? specialRateCodes}) {
    // If custom rate is set, use it
    if (customTaxRate != null) {
      return customTaxRate!;
    }

    // If CAEN code has special rate (3% for IT/software)
    if (caenCode != null && specialRateCodes != null) {
      if (specialRateCodes.contains(caenCode)) {
        return 0.03; // 3% special rate
      }
    }

    // Standard rate
    return 0.10; // 10% standard income tax
  }
}
