import 'package:hive/hive.dart';

part 'transaction.g.dart';

/// Type of transaction
enum TransactionType {
  /// Income/revenue
  income,

  /// Deductible expense
  expense,
}

/// Financial transaction (income or expense)
@HiveType(typeId: 2)
class Transaction {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final TransactionType type;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final bool includesVAT;

  @HiveField(7)
  final double? vatRate; // VAT rate if applicable (19% in Romania)

  @HiveField(8)
  final String? invoiceNumber;

  @HiveField(9)
  final String? clientSupplier; // Client name for income, supplier for expense

  @HiveField(10)
  final bool isDeductible; // For expenses only

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    required this.category,
    this.includesVAT = false,
    this.vatRate,
    this.invoiceNumber,
    this.clientSupplier,
    this.isDeductible = true,
  });

  /// Amount without VAT
  double get amountWithoutVAT {
    if (!includesVAT || vatRate == null) return amount;
    return amount / (1 + vatRate! / 100);
  }

  /// VAT amount
  double get vatAmount {
    if (!includesVAT || vatRate == null) return 0;
    return amount - amountWithoutVAT;
  }

  Transaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    DateTime? date,
    String? description,
    String? category,
    bool? includesVAT,
    double? vatRate,
    String? invoiceNumber,
    String? clientSupplier,
    bool? isDeductible,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      category: category ?? this.category,
      includesVAT: includesVAT ?? this.includesVAT,
      vatRate: vatRate ?? this.vatRate,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientSupplier: clientSupplier ?? this.clientSupplier,
      isDeductible: isDeductible ?? this.isDeductible,
    );
  }
}
