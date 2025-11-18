import 'package:hive/hive.dart';

part 'transaction_category.g.dart';

/// Transaction category for better organization
@HiveType(typeId: 1)
class TransactionCategory {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final bool isDeductible; // For expenses: whether it's tax deductible

  TransactionCategory({
    required this.name,
    required this.description,
    this.isDeductible = true,
  });
}
