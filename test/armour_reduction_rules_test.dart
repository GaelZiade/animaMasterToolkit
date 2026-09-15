import 'package:amt/models/armour.dart';
import 'package:amt/models/armour_data.dart';
import 'package:amt/models/combat_data.dart';
import 'package:amt/models/enums.dart';
import 'package:amt/models/rules/armour_reduction_rules.dart';
import 'package:amt/models/weapon.dart';
import 'package:flutter_test/flutter_test.dart';

Weapon _weapon({int quality = 0, int extra = 0, String type = 'A una mano'}) {
  return Weapon(
    name: 'Arma',
    turn: 0,
    attack: 100,
    defense: 100,
    defenseType: DefenseType.parry,
    damage: 50,
    type: type,
    quality: quality,
    armourReduction: extra,
  );
}

CombatData _combat({List<String> tables = const [], List<String> arts = const []}) {
  return CombatData(armour: ArmourData(calculatedArmour: Armour(), armours: []), weapons: [], styleTables: tables, martialArts: arts);
}

int _total(Weapon weapon, CombatData combat) => ArmourReductionRules.total(weapon: weapon, combat: combat);

void main() {
  test('Calidad: cada +5 resta un tipo (Core, espada +10 resta 2)', () {
    expect(_total(_weapon(quality: 4), _combat()), 0);
    expect(_total(_weapon(quality: 5), _combat()), 1);
    expect(_total(_weapon(quality: 10), _combat()), 2);
    expect(_total(_weapon(quality: 15), _combat()), 3);
    expect(_total(_weapon(quality: -5), _combat()), 0);
  });

  test('Tabla de Reducción de Armadura, una o varias veces', () {
    expect(_total(_weapon(), _combat(tables: ['Tabla de Reduccion de armadura'])), 1);
    expect(_total(_weapon(), _combat(tables: ['Tabla de Reducción de Armadura (2)'])), 2);
  });

  test('Dumah solo sin armas: −2, o −6 en Arcano', () {
    expect(_total(_weapon(type: 'desarmado'), _combat(arts: ['Dumah (Base)'])), 2);
    expect(_total(_weapon(type: 'desarmado'), _combat(arts: ['Dumah (Arcano)'])), 6);
    expect(_total(_weapon(), _combat(arts: ['Dumah (Arcano)'])), 0);
  });

  test('Todo se acumula (Dominus, Destruir armadura), con lo extra del arma', () {
    expect(_total(_weapon(quality: 10, extra: 4), _combat(tables: ['Tabla de Reducción de Armadura'])), 7);
  });

  test('La TA no baja de 0', () {
    expect(ArmourReductionRules.effectiveArmourType(base: 4, reduction: 2), 2);
    expect(ArmourReductionRules.effectiveArmourType(base: 2, reduction: 5), 0);
    expect(ArmourReductionRules.effectiveArmourType(base: 3, modifier: 1, reduction: 3), 1);
  });

  test('La reducción extra del arma se guarda y se copia', () {
    final weapon = Weapon.fromJson(_weapon(quality: 5, extra: 3).toJson())!;

    expect(weapon.armourReduction, 3);
    expect(weapon.copy().armourReduction, 3);
    expect(weapon.copy().quality, 5);
  });
}
