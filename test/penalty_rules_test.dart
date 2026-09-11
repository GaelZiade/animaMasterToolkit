import 'package:amt/models/character_model/status_modifier.dart';
import 'package:amt/models/rules/fatigue_rules.dart';
import 'package:amt/models/rules/penalty_rules.dart';
import 'package:amt/resources/modifiers.dart';
import 'package:flutter_test/flutter_test.dart';

StatusModifier _status(String name) => Modifiers.getStatusModifiers().firstWhere((modifier) => modifier.name == name);

StatusModifier _fatigue(int actual) => FatigueRules.modifierFor(maximum: 8, actual: actual)!;

/// Crítico como lo crea la tarjeta de crítico.
StatusModifier _critical(int result) {
  return StatusModifier(
    name: 'Critico ($result)',
    attack: -result,
    parry: -result,
    dodge: -result,
    turn: -result,
    physicalAction: -result,
    isOfCritical: true,
    midValue: result < 50 ? 0 : -(result ~/ 2),
  );
}

/// Total de un campo con los ajustes aplicados.
int _total(List<StatusModifier> active, PenaltyTraits traits, int Function(StatusModifier) field, {int roll = 0}) {
  final all = [...active, ...PenaltyRules.adjustments(active: active, traits: traits, painResistanceRoll: roll)];

  return all.fold(0, (total, modifier) => total + field(modifier));
}

int _attack(StatusModifier modifier) => modifier.attack;
int _action(StatusModifier modifier) => modifier.physicalAction;
int _turn(StatusModifier modifier) => modifier.turn;

void main() {
  group('Resistir el dolor (Tabla 15)', () {
    test('Negativo anulado por resultado', () {
      expect(PenaltyRules.painResistanceFor(79), 0);
      expect(PenaltyRules.painResistanceFor(80), 10);
      expect(PenaltyRules.painResistanceFor(150), 30);
      expect(PenaltyRules.painResistanceFor(440), 80);
    });

    test('Anula hasta lo que haya, nunca da bono', () {
      expect(_total([_fatigue(2)], const PenaltyTraits(), _attack, roll: 150), -10);
      expect(_total([_fatigue(4)], const PenaltyTraits(), _attack, roll: 440), 0);
    });

    test('Solo reduce dolor, cansancio y la parte de dolor de un crítico', () {
      final active = [_critical(80), _status('Ceguera parcial')];

      // Crítico 80: −40 de dolor y −40 de deterioro físico; la ceguera no cuenta.
      expect(_total(active, const PenaltyTraits(), _attack, roll: 180), -80 - 30 + 40);
    });
  });

  group('Ventajas y desventajas', () {
    test('Inmunidad al dolor y al cansancio: ambos a la mitad', () {
      const traits = PenaltyTraits(painAndFatigueImmunity: true);

      expect(_total([_status('Dolor')], traits, _attack), -20);
      expect(_total([_fatigue(2)], traits, _attack), -20);
      expect(_total([_fatigue(2)], traits, _turn), -10);
    });

    test('Exhausto dobla el cansancio, no el dolor', () {
      const traits = PenaltyTraits(exhausted: true);

      expect(_total([_fatigue(2)], traits, _attack), -80);
      expect(_total([_status('Dolor')], traits, _attack), -40);
    });

    test('Exhausto con Inmunidad se compensan', () {
      expect(_total([_fatigue(2)], const PenaltyTraits(exhausted: true, painAndFatigueImmunity: true), _attack), -40);
    });
  });

  group('Habilidades del Ki', () {
    test('Eliminación de penalizadores: cansancio y dolor de críticos a la mitad', () {
      const traits = PenaltyTraits(penaltyElimination: true);

      expect(_total([_fatigue(2)], traits, _attack), -20);
      expect(_total([_critical(80)], traits, _attack), -60);
      expect(_total([_status('Dolor')], traits, _attack), -40);
    });

    test('Dos fuentes de mitad no la aplican dos veces', () {
      expect(_total([_fatigue(1)], const PenaltyTraits(painAndFatigueImmunity: true, penaltyElimination: true), _attack), -40);
    });

    test('Esencia de vacío anula dolor, cansancio y dolor de críticos', () {
      const traits = PenaltyTraits(voidEssence: true);
      final active = [_fatigue(0), _status('Dolor extremo'), _critical(80), _status('Ceguera parcial')];

      expect(_total(active, traits, _attack), -40 - 30);
    });
  });

  group('Berserker', () {
    test('Ignora dolor y cansancio solo en acciones físicas', () {
      final active = [_fatigue(2), _status('Dolor'), _status('Berserker (Ars Magnus)')];

      expect(_total(active, const PenaltyTraits(), _action), 0);
      expect(_total(active, const PenaltyTraits(), _attack), -40 - 40 + 10);
    });
  });

  test('Sin rasgos ni tirada no hay ajustes', () {
    expect(PenaltyRules.adjustments(active: [_fatigue(2), _status('Dolor')], traits: const PenaltyTraits()), isEmpty);
  });
}
