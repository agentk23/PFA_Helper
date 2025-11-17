// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caen_code.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CAENCodeAdapter extends TypeAdapter<CAENCode> {
  @override
  final int typeId = 3;

  @override
  CAENCode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CAENCode(
      code: fields[0] as String,
      description: fields[1] as String,
      hasSpecialTaxRate: fields[2] as bool,
      specialTaxRate: fields[3] as double?,
      isPrimary: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CAENCode obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.code)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.hasSpecialTaxRate)
      ..writeByte(3)
      ..write(obj.specialTaxRate)
      ..writeByte(4)
      ..write(obj.isPrimary);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CAENCodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
