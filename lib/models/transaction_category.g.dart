// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionCategoryAdapter extends TypeAdapter<TransactionCategory> {
  @override
  final int typeId = 0;

  @override
  TransactionCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionCategory.taxableIncome;
      case 1:
        return TransactionCategory.nonTaxableIncome;
      case 2:
        return TransactionCategory.deductibleExpense;
      case 3:
        return TransactionCategory.nonDeductibleExpense;
      default:
        return TransactionCategory.taxableIncome;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionCategory obj) {
    switch (obj) {
      case TransactionCategory.taxableIncome:
        writer.writeByte(0);
        break;
      case TransactionCategory.nonTaxableIncome:
        writer.writeByte(1);
        break;
      case TransactionCategory.deductibleExpense:
        writer.writeByte(2);
        break;
      case TransactionCategory.nonDeductibleExpense:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
