import 'dart:math';

import 'package:amt/models/armour.dart';
import 'package:amt/models/armour_data.dart';
import 'package:amt/models/weapon.dart';
import 'package:amt/utils/json_utils.dart';
import 'package:hive/hive.dart';

part 'combat_data.g.dart';

@HiveType(typeId: 5, adapterName: 'CombatDataAdapter')
class CombatData {
  /// [chainAttackTable], [additionalAttackTable], [kempoGrade] y
  /// [taeKwonDoGrade] son atajos que se vuelcan en las listas: sirven para
  /// crear datos a mano y para leer fichas guardadas antes de que existieran.
  CombatData({
    required this.armour,
    required this.weapons,
    this.ambidextrous = false,
    List<String>? styleTables,
    List<String>? martialArts,
    bool chainAttackTable = false,
    bool additionalAttackTable = false,
    int kempoGrade = 0,
    int taeKwonDoGrade = 0,
  })  : styleTables = [...{...?styleTables}],
        martialArts = [...{...?martialArts}] {
    if (chainAttackTable) _addStyleTable('Tabla de Ataque Encadenado');
    if (additionalAttackTable) _addStyleTable('Tabla de Ataque Adicional');
    if (kempoGrade > 0) _setMartialArt('Kempo', kempoGrade);
    if (taeKwonDoGrade > 0) _setMartialArt('Tae Kwon Do', taeKwonDoGrade);
  }

  static CombatData? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    List<String> list(String key) => ((json[key] as List<dynamic>?) ?? const []).map((entry) => '$entry').toList();

    return CombatData(
      armour: ArmourData.fromJson(json.getMap('armadura')) ?? ArmourData(calculatedArmour: Armour(), armours: []),
      weapons: json.getList('armas').map(Weapon.fromJson).nonNulls.toList(),
      ambidextrous: JsonUtils.boolean(json['ambidestria'], placeholder: false),
      // Una planilla trae sus tablas y artes marciales como tablas con nombre y
      // descripción; solo interesan los nombres, como "Tae Kwon Do (Base)".
      // Ataque Encadenado y Ataque Adicional son Tablas de Estilos, que la
      // planilla exporta como EstilosDeCombate.
      styleTables: [
        ...?json.getMap('TablasDeArmas')?.keys,
        ...?json.getMap('EstilosDeCombate')?.keys,
        ...list('tablasEstilo'),
      ],
      martialArts: [...?json.getMap('ArtesMarciales')?.keys, ...list('artesMarciales')],
      // Fichas exportadas antes de que existieran las listas.
      chainAttackTable: JsonUtils.boolean(json['tablaAtaqueEncadenado'], placeholder: false),
      additionalAttackTable: JsonUtils.boolean(json['tablaAtaqueAdicional'], placeholder: false),
      kempoGrade: JsonUtils.integer(json['kempo'], 0).clamp(0, 3),
      taeKwonDoGrade: JsonUtils.integer(json['taeKwonDo'], 0).clamp(0, 3),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'armadura': armour.toJson(),
      'armas': weapons.map((e) => e.toJson()).toList(),
      'ambidestria': ambidextrous,
      'tablasEstilo': styleTables,
      'artesMarciales': martialArts,
    };
  }

  @HiveField(0)
  late List<Weapon> weapons;
  @HiveField(1)
  late ArmourData armour;

  /// Sugiere el ataque extra con un arma adicional a −10 en vez de −40.
  @HiveField(2)
  bool ambidextrous;

  /// Tablas de armas y de estilos que domina, por nombre.
  @HiveField(7)
  List<String> styleTables;

  /// Artes marciales con su grado: "Sambo (Avanzado)", "Selene (Arcano)".
  @HiveField(8)
  List<String> martialArts;

  bool get chainAttackTable => hasStyleTable('ataque encadenado');
  bool get additionalAttackTable => hasStyleTable('ataque adicional');
  int get kempoGrade => martialArtGrade('Kempo');
  int get taeKwonDoGrade => max(martialArtGrade('Tae Kwon Do'), martialArtGrade('Taekwondo'));

  /// Indica si alguna tabla contiene [text] en su nombre.
  bool hasStyleTable(String text) {
    final wanted = normalizeTrait(text);

    return styleTables.any((table) => normalizeTrait(table).contains(wanted));
  }

  /// Grado en un arte marcial por nombre exacto: 0 si no la domina. "Lama" no
  /// confunde a "Lama Tsu".
  int martialArtGrade(String name) {
    final wanted = normalizeTrait(name);
    var grade = 0;

    for (final art in martialArts) {
      if (traitName(art) == wanted) grade = max(grade, traitGrade(art));
    }

    return grade;
  }

  /// Nombre sin grado y normalizado: "Sambo (Avanzado)" → "sambo".
  static String traitName(String entry) => normalizeTrait(entry.split('(').first);

  /// 1 base (o sin grado), 2 avanzado, 3 supremo o arcano.
  static int traitGrade(String entry) {
    final text = normalizeTrait(entry);

    if (text.contains('suprem') || text.contains('arcan')) return 3;
    if (text.contains('avanzad')) return 2;

    return 1;
  }

  /// Minúsculas, sin acentos ni espacios repetidos: la planilla exporta los
  /// nombres sin acentos.
  static String normalizeTrait(String text) {
    const accents = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n'};

    return text.toLowerCase().split('').map((char) => accents[char] ?? char).join().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _addStyleTable(String name) {
    if (!hasStyleTable(name)) styleTables.add(name);
  }

  void _setMartialArt(String name, int grade) {
    const grades = ['Base', 'Avanzado', 'Supremo'];

    martialArts
      ..removeWhere((art) => traitName(art) == normalizeTrait(name))
      ..add('$name (${grades[grade.clamp(1, 3) - 1]})');
  }

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
      styleTables: styleTables,
      martialArts: martialArts,
    );
  }
}
