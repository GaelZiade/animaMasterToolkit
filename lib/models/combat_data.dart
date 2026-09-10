import 'package:amt/models/armour.dart';
import 'package:amt/models/armour_data.dart';
import 'package:amt/models/weapon.dart';
import 'package:amt/utils/json_utils.dart';
import 'package:hive/hive.dart';

part 'combat_data.g.dart';

@HiveType(typeId: 5, adapterName: 'CombatDataAdapter')
class CombatData {
  CombatData({
    required this.armour,
    required this.weapons,
    this.ambidextrous = false,
    this.chainAttackTable = false,
    this.kempoGrade = 0,
    this.taeKwonDoGrade = 0,
    this.additionalAttackTable = false,
  });

  static CombatData? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final martialArts = json.getMap('ArtesMarciales') ?? const <String, dynamic>{};
    final weaponTables = json.getMap('TablasDeArmas') ?? const <String, dynamic>{};

    return CombatData(
      armour: ArmourData.fromJson(json.getMap('armadura')) ?? ArmourData(calculatedArmour: Armour(), armours: []),
      weapons: json.getList('armas').map(Weapon.fromJson).nonNulls.toList(),
      // Una ficha exportada desde la aplicación trae lo que se eligió a mano;
      // una planilla solo trae sus tablas de armas y artes marciales.
      ambidextrous: JsonUtils.boolean(json['ambidestria'], placeholder: false),
      chainAttackTable: json.containsKey('tablaAtaqueEncadenado')
          ? JsonUtils.boolean(json['tablaAtaqueEncadenado'], placeholder: false)
          : _grade(weaponTables, const ['ataque encadenado']) > 0,
      kempoGrade: json.containsKey('kempo') ? JsonUtils.integer(json['kempo'], 0).clamp(0, 3) : _grade(martialArts, const ['kempo']),
      taeKwonDoGrade: json.containsKey('taeKwonDo')
          ? JsonUtils.integer(json['taeKwonDo'], 0).clamp(0, 3)
          : _grade(martialArts, const ['tae kwon do', 'taekwondo', 'tae kwondo']),
      additionalAttackTable: json.containsKey('tablaAtaqueAdicional')
          ? JsonUtils.boolean(json['tablaAtaqueAdicional'], placeholder: false)
          : _grade(weaponTables, const ['ataque adicional']) > 0,
    );
  }

  /// Grado de lo que nombra [aliases] en una tabla de la planilla: 0 si no
  /// figura, 1 base, 2 avanzado, 3 supremo.
  static int _grade(Map<String, dynamic> table, List<String> aliases) {
    var grade = 0;

    for (final entry in table.entries) {
      final text = '${entry.key} ${entry.value}'.toLowerCase();

      if (!aliases.any(text.contains)) continue;

      final found = text.contains('suprem')
          ? 3
          : text.contains('avanzad')
              ? 2
              : 1;

      if (found > grade) grade = found;
    }

    return grade;
  }

  Map<String, dynamic> toJson() {
    return {
      'armadura': armour.toJson(),
      'armas': weapons.map((e) => e.toJson()).toList(),
      'ambidestria': ambidextrous,
      'tablaAtaqueEncadenado': chainAttackTable,
      'kempo': kempoGrade,
      'taeKwonDo': taeKwonDoGrade,
      'tablaAtaqueAdicional': additionalAttackTable,
    };
  }

  @HiveField(0)
  late List<Weapon> weapons;
  @HiveField(1)
  late ArmourData armour;

  /// Reduce a −10 el ataque con un arma adicional.
  @HiveField(2)
  bool ambidextrous;

  /// Tabla de Ataque Encadenado: armas grandes como medias y medias como
  /// pequeñas al hacer ataques adicionales.
  @HiveField(3)
  bool chainAttackTable;

  /// Grado en Kempo y en Tae Kwon Do: 0 no lo domina, 1 base, 2 avanzado,
  /// 3 supremo.
  @HiveField(4)
  int kempoGrade;
  @HiveField(5)
  int taeKwonDoGrade;

  /// Tabla de Ataque Adicional: un ataque más al tope (planilla, Pantalla del
  /// Director).
  @HiveField(6)
  bool additionalAttackTable;

  void updateWeapon(Weapon weapon) {
    for (var i = 0; i > weapons.length; i++) {
      if (weapons[i].name == weapon.name) {
        weapons[i] = weapon;
        return;
      }
    }
  }

  CombatData copy() {
    return CombatData(
      armour: armour,
      weapons: weapons,
      ambidextrous: ambidextrous,
      chainAttackTable: chainAttackTable,
      kempoGrade: kempoGrade,
      taeKwonDoGrade: taeKwonDoGrade,
      additionalAttackTable: additionalAttackTable,
    );
  }
}
