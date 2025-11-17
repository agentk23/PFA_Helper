import 'package:hive/hive.dart';
import 'transaction_category.dart';

part 'transaction.g.dart';

/// Transaction model for PFA accounting
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

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.category,
    required this.description,
    this.invoiceNumber,
    this.notes,
    required this.createdAt,
  });

  Transaction copyWith({
    String? id,
    double? amount,
    DateTime? date,
    TransactionCategory? category,
    String? description,
    String? invoiceNumber,
    String? notes,
    DateTime? createdAt,
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
    );
  }

  bool get isIncome => category.isIncome;
  bool get isExpense => category.isExpense;
}
