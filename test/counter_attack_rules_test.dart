import 'package:amt/models/rules/counter_attack_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Mitad de la diferencia redondeada a 5 (Core p.87)', () {
    expect(CounterAttackRules.bonus(attack: 100, defense: 130), 15);
    expect(CounterAttackRules.bonus(attack: 100, defense: 137), 15);
    expect(CounterAttackRules.bonus(attack: 100, defense: 141), 20);
  });

  test('Máximo 150', () {
    expect(CounterAttackRules.bonus(attack: 0, defense: 500), 150);
  });

  test('Sin contraataque si no supera o si tiene acumulación', () {
    expect(CounterAttackRules.bonus(attack: 100, defense: 100), isNull);
    expect(CounterAttackRules.bonus(attack: 120, defense: 100), isNull);
    expect(CounterAttackRules.bonus(attack: 100, defense: 200, damageAccumulation: true), isNull);
  });

  test('Ganar por menos de 10 da contraataque con +0', () {
    expect(CounterAttackRules.bonus(attack: 100, defense: 108), 0);
  });

  test('Selene dobla el bono y Sacra Aegis suma 75', () {
    expect(CounterAttackRules.bonus(attack: 100, defense: 130, selene: true), 30);
    expect(CounterAttackRules.bonus(attack: 100, defense: 130, sacraAegis: true), 90);
    expect(CounterAttackRules.bonus(attack: 100, defense: 100, sacraAegis: true), isNull);
  });
}
