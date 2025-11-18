// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caen_code.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CaenCodeAdapter extends TypeAdapter<CaenCode> {
  @override
  final int typeId = 3;

  @override
  CaenCode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CaenCode(
      code: fields[0] as String,
      description: fields[1] as String,
      category: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CaenCode obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.code)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaenCodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
