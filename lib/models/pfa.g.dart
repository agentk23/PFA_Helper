// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pfa.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PFAAdapter extends TypeAdapter<PFA> {
  @override
  final int typeId = 0;

  @override
  PFA read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PFA(
      firstName: fields[0] as String,
      lastName: fields[1] as String,
      cui: fields[2] as String,
      caenCode: fields[3] as String,
      caenDescription: fields[4] as String,
      registrationDate: fields[5] as DateTime,
      taxationSystem: fields[6] as TaxationSystem,
      isVATRegistered: fields[7] as bool,
      vatRegistrationDate: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PFA obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.firstName)
      ..writeByte(1)
      ..write(obj.lastName)
      ..writeByte(2)
      ..write(obj.cui)
      ..writeByte(3)
      ..write(obj.caenCode)
      ..writeByte(4)
      ..write(obj.caenDescription)
      ..writeByte(5)
      ..write(obj.registrationDate)
      ..writeByte(6)
      ..write(obj.taxationSystem)
      ..writeByte(7)
      ..write(obj.isVATRegistered)
      ..writeByte(8)
      ..write(obj.vatRegistrationDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PFAAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
