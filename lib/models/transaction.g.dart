// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 2;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      type: fields[1] as TransactionType,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      description: fields[4] as String,
      category: fields[5] as String,
      includesVAT: fields[6] as bool,
      vatRate: fields[7] as double?,
      invoiceNumber: fields[8] as String?,
      clientSupplier: fields[9] as String?,
      isDeductible: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.includesVAT)
      ..writeByte(7)
      ..write(obj.vatRate)
      ..writeByte(8)
      ..write(obj.invoiceNumber)
      ..writeByte(9)
      ..write(obj.clientSupplier)
      ..writeByte(10)
      ..write(obj.isDeductible);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
