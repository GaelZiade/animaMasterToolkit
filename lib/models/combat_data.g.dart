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
      chainAttackTable: fields[3] as bool? ?? false,
      kempoGrade: fields[4] as int? ?? 0,
      taeKwonDoGrade: fields[5] as int? ?? 0,
      additionalAttackTable: fields[6] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CombatData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.weapons)
      ..writeByte(1)
      ..write(obj.armour)
      ..writeByte(2)
      ..write(obj.ambidextrous)
      ..writeByte(3)
      ..write(obj.chainAttackTable)
      ..writeByte(4)
      ..write(obj.kempoGrade)
      ..writeByte(5)
      ..write(obj.taeKwonDoGrade)
      ..writeByte(6)
      ..write(obj.additionalAttackTable);
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
