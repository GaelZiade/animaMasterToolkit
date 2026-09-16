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

Weapon _weapon({bool? damagesEnergy, int? criticalBonus, String? type}) {
  return Weapon(
    name: 'Arma',
    turn: 0,
    attack: 100,
    defense: 100,
    defenseType: DefenseType.parry,
    damage: 50,
    type: type,
    damagesEnergy: damagesEnergy,
    criticalBonus: criticalBonus,
  );
}

void main() {
  test('Un daño base menor que la barrera no quita PV (Core, Estados y Accidentes)', () {
    expect(DamageBarrierRules.blocks(barrier: 100, baseDamage: 40), isTrue);
    expect(DamageBarrierRules.blocks(barrier: 100, baseDamage: 100), isFalse, reason: 'igual o mayor la atraviesa');
    expect(DamageBarrierRules.blocks(barrier: 0, baseDamage: 10), isFalse);
  });

  test('Dañar energía ignora la barrera; atacar sobre ENE no alcanza', () {
    String? source(Weapon weapon, {List<String> ki = const []}) => DamageBarrierRules.energyDamageSource(weapon: weapon, combat: _combat(ki: ki));

    expect(source(_weapon(damagesEnergy: true)), 'el arma daña energía');
    expect(source(_weapon()), isNull);
    expect(source(_weapon(), ki: ['Extrusión de presencia']), isNull, reason: 'la Extrusión solo alcanza al cuerpo');
    expect(source(_weapon(type: 'desarmado'), ki: ['Extrusión de presencia']), 'Extrusión de presencia');
    expect(source(_weapon(), ki: ['Extrusión de presencia', 'Extensión del aura al arma']), 'Extensión del aura al arma');
  });

  test('Las proyecciones mágica y psíquica son ataques sobrenaturales', () {
    final projection = Weapon(name: 'Proyección Mágica', turn: 0, attack: 100, defense: 0, defenseType: DefenseType.parry, damage: 0);

    expect(DamageBarrierRules.energyDamageSource(weapon: projection, combat: _combat()), 'ataque sobrenatural');
  });

  test('Quien daña energía solo choca con una barrera contra energía (Comunión con la Tierra)', () {
    const physical = [DamageBarrierSource('Barrera de daño', 200)];
    final energy = DamageBarrierRules.energySources(manual: 80);

    expect(DamageBarrierRules.applicable(physical: physical, energy: energy, energyDamageSource: null)!.value, 200);
    expect(DamageBarrierRules.applicable(physical: physical, energy: energy, energyDamageSource: 'Extrusión de presencia')!.value, 80);
    expect(DamageBarrierRules.applicable(physical: physical, energy: const [], energyDamageSource: 'arma mística'), isNull);
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
