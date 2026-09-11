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
    expect(combat.disadvantages, ['Mudo', 'Fobia grave', 'Vulnerable a frio o calor']);
    expect(CombatData.hasTrait(combat.kiAbilities, 'Control del Ki'), isTrue);
    expect(CombatData.hasTrait(combat.kiAbilities, 'Escudo físico'), isTrue);
    expect(CombatData.hasTrait(combat.kiAbilities, 'Eliminación de penalizadores'), isFalse);
    expect(combat.styleTables, contains('Tabla de Desvio'));
  });

  test('Kael: Ataque Encadenado, Arma distinta y un Ars Magnus', () {
    final combat = _combat('Kael Avelar BOX.xlsm');

    if (combat == null) return markTestSkipped('Falta la planilla de Kael');

    expect(combat.chainAttackTable, isTrue);
    expect(combat.additionalAttackTable, isFalse);
    expect(combat.styleTables, contains('Arma distinta / Desarmado'));
    expect(combat.arsMagnus, ['Leo: Armas-pistola']);
    expect(combat.disadvantages, ['Fobia grave', 'Secreto inconfesable', 'Maldito (2)']);
    expect(CombatData.hasTrait(combat.advantages, 'Acumulación plena'), isTrue);
    expect(CombatData.hasTrait(combat.kiAbilities, 'Ataque elemental'), isTrue);
    expect(combat.martialArts, isEmpty);
  });

  test('Stéphan: mago con dos armas pequeñas sueltas y casi sin Ki', () {
    final combat = _combat('Stéphan Durand Deville Lvl7.xlsm');

    if (combat == null) return markTestSkipped('Falta la planilla de Stéphan');

    expect(_weapon(combat, 'Espada corta').attackSize, 'P');
    expect(_weapon(combat, 'Daga').attackSize, 'P');
    expect(AdditionalAttackRules.suggestedExtraAttacks(weapon: _weapon(combat, 'Espada corta'), combat: combat), isEmpty);
    expect(combat.kiAbilities.length, 2);
    expect(CombatData.hasTrait(combat.kiAbilities, 'Inhumanidad'), isTrue);
    expect(CombatData.hasTrait(combat.advantages, 'Versatilidad metamágica'), isTrue);
    expect(combat.disadvantages.length, 3);
    expect(CombatData.hasTrait(combat.disadvantages, 'Miopía'), isTrue);
    expect(combat.styleTables, isEmpty);
    expect(combat.ambidextrous, isFalse);
  });
}
