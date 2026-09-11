import 'package:amt/models/character_model/status_modifier.dart';
import 'package:amt/models/rules/fatigue_rules.dart';
import 'package:amt/resources/modifiers.dart';
import 'package:flutter_test/flutter_test.dart';

int _attack(List<StatusModifier> modifiers) => modifiers.fold(0, (total, modifier) => total + modifier.attack);

StatusModifier _status(String name) => Modifiers.getStatusModifiers().firstWhere((modifier) => modifier.name == name);

void main() {
  group('Agotamiento (Core, Tabla 27)', () {
    test('Con 5 o más no penaliza', () {
      expect(FatigueRules.modifierFor(maximum: 8, actual: 5), isNull);
    });

    test('Con 2 puntos: −40 a toda acción y −20 a la iniciativa', () {
      final fatigue = FatigueRules.modifierFor(maximum: 8, actual: 2)!;

      expect(fatigue.attack, -40);
      expect(fatigue.parry, -40);
      expect(fatigue.dodge, -40);
      expect(fatigue.physicalAction, -40);
      expect(fatigue.turn, -20);
    });

    test('Agotado del todo: −120, y un Cansancio negativo cuenta como 0', () {
      expect(FatigueRules.modifierFor(maximum: 8, actual: 0)!.attack, -120);
      expect(FatigueRules.modifierFor(maximum: 8, actual: -2)!.attack, -120);
      expect(FatigueRules.modifierFor(maximum: 8, actual: 4)!.turn, -5);
    });

    test('Con base menor a 5 no lo sufre hasta perder el primer punto', () {
      expect(FatigueRules.modifierFor(maximum: 3, actual: 3), isNull);
      expect(FatigueRules.modifierFor(maximum: 3, actual: 2)!.attack, -40);
    });

    test('Sin Cansancio cargado no aplica nada', () {
      expect(FatigueRules.modifierFor(maximum: 0, actual: 0), isNull);
    });

    test('No se cuenta dos veces si también se eligió a mano', () {
      final fatigue = FatigueRules.modifierFor(maximum: 8, actual: 2);
      final active = FatigueRules.activeModifiers([_status('4 puntos restantes de cansancio')], fatigue);

      expect(_attack(active), -40);
    });

    test('Los demás estados elegidos se suman', () {
      final fatigue = FatigueRules.modifierFor(maximum: 8, actual: 2);

      expect(_attack(FatigueRules.activeModifiers([_status('Dolor')], fatigue)), -80);
    });

    test('Sin agotamiento, el cansancio elegido a mano se respeta', () {
      final active = FatigueRules.activeModifiers([_status('3 puntos restantes de cansancio')], null);

      expect(_attack(active), -20);
    });
  });
}
