// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combat_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CombatDataAdapter extends TypeAdapter<CombatData> {
  @override
  final int typeId = 5;

  @override
  CombatData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CombatData(
      armour: fields[1] as ArmourData,
      weapons: (fields[0] as List).cast<Weapon>(),
      ambidextrous: fields[2] as bool? ?? false,
      styleTables: (fields[7] as List?)?.cast<String>(),
      martialArts: (fields[8] as List?)?.cast<String>(),
      // Campos de fichas guardadas antes de las listas.
      chainAttackTable: fields[3] as bool? ?? false,
      kempoGrade: fields[4] as int? ?? 0,
      taeKwonDoGrade: fields[5] as int? ?? 0,
      additionalAttackTable: fields[6] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CombatData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.weapons)
      ..writeByte(1)
      ..write(obj.armour)
      ..writeByte(2)
      ..write(obj.ambidextrous)
      ..writeByte(7)
      ..write(obj.styleTables)
      ..writeByte(8)
      ..write(obj.martialArts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CombatDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
