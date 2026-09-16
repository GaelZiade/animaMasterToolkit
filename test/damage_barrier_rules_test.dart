import 'package:amt/models/armour.dart';
import 'package:amt/models/armour_data.dart';
import 'package:amt/models/combat_data.dart';
import 'package:amt/models/enums.dart';
import 'package:amt/models/rules/damage_barrier_rules.dart';
import 'package:amt/models/weapon.dart';
import 'package:flutter_test/flutter_test.dart';

CombatData _combat({List<String> arts = const [], List<String> ki = const []}) {
  return CombatData(armour: ArmourData(calculatedArmour: Armour(), armours: []), weapons: [], martialArts: arts, kiAbilities: ki);
}

Weapon _weapon({bool? damagesEnergy, int? criticalBonus}) {
  return Weapon(
    name: 'Arma',
    turn: 0,
    attack: 100,
    defense: 100,
    defenseType: DefenseType.parry,
    damage: 50,
    damagesEnergy: damagesEnergy,
    criticalBonus: criticalBonus,
  );
}

void main() {
  test('Un daño base menor que la barrera no quita PV (Core, Estados y Accidentes)', () {
    expect(DamageBarrierRules.blocks(barrier: 100, baseDamage: 40, ignored: false), isTrue);
    expect(DamageBarrierRules.blocks(barrier: 100, baseDamage: 100, ignored: false), isFalse);
    expect(DamageBarrierRules.blocks(barrier: 0, baseDamage: 10, ignored: false), isFalse);
  });

  test('Dañar energía ignora la barrera: el arma marcada o atacar sobre ENE', () {
    expect(DamageBarrierRules.ignores(weapon: _weapon(damagesEnergy: true), damageType: DamageTypes.fil), isTrue);
    expect(DamageBarrierRules.ignores(weapon: _weapon(), damageType: DamageTypes.ene), isTrue);
    expect(DamageBarrierRules.ignores(weapon: _weapon(), damageType: DamageTypes.fil), isFalse);
    expect(DamageBarrierRules.blocks(barrier: 100, baseDamage: 40, ignored: true), isFalse);
  });

  test('Fuentes: a mano, Hanja (60 o 200) y Escudo físico (Presencia base); vale la más alta', () {
    final sources = DamageBarrierRules.sources(
      manual: 80,
      combat: _combat(arts: ['Hanja (Base)'], ki: ['Escudo físico']),
      presence: 70,
    );

    expect(sources.map((source) => '${source.label} ${source.value}'), ['Barrera de daño 80', 'Hanja 60', 'Escudo físico 70']);
    expect(DamageBarrierRules.strongest(sources)!.value, 80);
    expect(DamageBarrierRules.sources(manual: null, combat: _combat(arts: ['Hanja (Arcano)']), presence: 0).single.value, 200);
    expect(DamageBarrierRules.sources(manual: 0, combat: _combat(), presence: 70), isEmpty);
  });

  test('El bono al crítico y «daña energía» se guardan y se copian', () {
    final weapon = Weapon.fromJson(_weapon(damagesEnergy: true, criticalBonus: 20).toJson())!;

    expect([weapon.criticalBonus, weapon.damagesEnergy], [20, true]);
    expect([weapon.copy().criticalBonus, weapon.copy().damagesEnergy], [20, true]);
  });
}
