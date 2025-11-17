// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pfa.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PFAAdapter extends TypeAdapter<PFA> {
  @override
  final int typeId = 1;

  @override
  PFA read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PFA(
      cui: fields[0] as String,
      name: fields[1] as String,
      address: fields[2] as String,
      phone: fields[3] as String?,
      email: fields[4] as String?,
      registrationDate: fields[5] as DateTime,
      isRealSystem: fields[6] as bool,
      activityType: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PFA obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.cui)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.registrationDate)
      ..writeByte(6)
      ..write(obj.isRealSystem)
      ..writeByte(7)
      ..write(obj.activityType);
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
