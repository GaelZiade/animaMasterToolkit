import 'dart:io';

import 'package:amt/models/combat_data.dart';
import 'package:amt/models/rules/additional_attack_rules.dart';
import 'package:amt/models/weapon.dart';
import 'package:amt/utils/xlsx/sheet_to_json.dart';
import 'package:amt/utils/xlsx/xlsx_workbook.dart';
import 'package:flutter_test/flutter_test.dart';

/// Planillas reales de la mesa. No están en el repositorio: si faltan, el test
/// se salta.
const _downloads = 'C:/Users/Pire/Downloads';

CombatData? _combat(String file) {
  final sheet = File('$_downloads/$file');

  if (!sheet.existsSync()) return null;

  final json = SheetToJson.convert(XlsxWorkbook.decode(sheet.readAsBytesSync()));

  return CombatData.fromJson(json['Combate'] as Map<String, dynamic>);
}

Weapon _weapon(CombatData combat, String name) => combat.weapons.firstWhere((weapon) => weapon.name == name);

void main() {
  test('Kaito: dos espadas medianas, ambidiestro, Encadenado, Ataque Adicional y Tae Kwon Do', () {
    final combat = _combat('Kaito Lvl 7 Ultimo.xlsm');

    if (combat == null) return markTestSkipped('Falta la planilla de Kaito');

    expect(combat.ambidextrous, isTrue);
    expect(combat.chainAttackTable, isTrue);
    expect(combat.additionalAttackTable, isTrue);
    expect(combat.taeKwonDoGrade, 1);
    expect(combat.kempoGrade, 0);
    expect(combat.disadvantages, ['Arma exclusiva', 'Desafortunado', 'Endeble']);
    expect(CombatData.hasTrait(combat.kiAbilities, 'Eliminación de penalizadores'), isTrue);
    expect(CombatData.hasTrait(combat.kiAbilities, 'Uso de la energía necesaria'), isTrue);
    expect(CombatData.hasTrait(combat.kiAbilities, 'Control del Ki'), isFalse);
    expect(combat.penaltyTraits.penaltyElimination, isTrue);
    expect(combat.penaltyTraits.voidEssence, isFalse);

    final pair = _weapon(combat, 'Espada Kaitos y Espada Kaitos');

    expect(pair.attack, 210);
    expect(pair.attackSize, 'M');

    final plan = AdditionalAttackRules.plan(weapon: pair, combat: combat, declared: 4)!;

    expect(plan.maxAttacks, 4);
    expect(plan.penaltyPerAttack, -20);
    expect(
      AdditionalAttackRules.suggestedExtraAttacks(weapon: pair, combat: combat),
      [AdditionalAttackRules.secondWeaponAmbidextrous, AdditionalAttackRules.kicks.first],
    );
  });

  test('Teseo: sin ambidestría ni tablas de ataque, armas de distinto tamaño', () {
    final combat = _combat('Teseo Anima Gaia Reborn Nivel 7 Boxeito Ataque final Guardian.xlsm');

    if (combat == null) return markTestSkipped('Falta la planilla de Teseo');

    expect(combat.ambidextrous, isFalse);
    expect(combat.chainAttackTable, isFalse);
    expect(combat.additionalAttackTable, isFalse);
    expect(combat.taeKwonDoGrade, 0);
    expect(combat.advantages, contains('Difícil de matar (2)'.replaceAll('í', 'i')));
    expect(combat.disadvantages, ['Fobia grave']);
    expect(combat.arsMagnus, containsAll(['Guardian', 'Ataque Final']));
    expect(CombatData.hasTrait(combat.kiAbilities, 'Inhumanidad'), isTrue);
    expect(combat.penaltyTraits.penaltyElimination, isFalse);
    expect(_weapon(combat, 'Leviatan').attackSize, 'M');
    expect(_weapon(combat, 'Ojiplato').attackSize, 'G');
    expect(_weapon(combat, 'Hacha de mano').attackSize, 'M');
    expect(AdditionalAttackRules.suggestedExtraAttacks(weapon: _weapon(combat, 'Ojiplato'), combat: combat), isEmpty);
  });

  test('Kiran: artes marciales que no tocan los ataques adicionales', () {
    final combat = _combat('Ficha Anima v8.7.0 but peak (1) kiran.xlsm');

    if (combat == null) return markTestSkipped('Falta la planilla de Kiran');

    expect(combat.ambidextrous, isFalse);
    expect(combat.kempoGrade, 0);
    expect(combat.taeKwonDoGrade, 0);
    expect(combat.chainAttackTable, isFalse);
    expect(combat.additionalAttackTable, isFalse);
  });
}
