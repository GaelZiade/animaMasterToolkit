import 'package:amt/models/armour.dart';
import 'package:amt/models/armour_data.dart';
import 'package:amt/models/combat_data.dart';
import 'package:amt/models/enums.dart';
import 'package:amt/models/rules/additional_attack_rules.dart';
import 'package:amt/models/weapon.dart';
import 'package:flutter_test/flutter_test.dart';

Weapon _weapon(String name, int attack, {String type = 'A una mano', String? size}) {
  return Weapon(name: name, turn: 0, attack: attack, defense: 0, defenseType: DefenseType.parry, damage: 50, type: type, attackSize: size);
}

CombatData _combat({bool ambidextrous = false, bool chain = false, int kempo = 0, int taeKwonDo = 0, bool extraTable = false}) {
  return CombatData(
    armour: ArmourData(calculatedArmour: Armour(), armours: []),
    weapons: [],
    ambidextrous: ambidextrous,
    chainAttackTable: chain,
    kempoGrade: kempo,
    taeKwonDoGrade: taeKwonDo,
    additionalAttackTable: extraTable,
  );
}

int _ability(AttackPlan plan, int base, AttackSlot slot) => base + plan.sharedPenalty + plan.penaltyFor(slot);

void main() {
  group('Ejemplos del Core (p. 91)', () {
    test('HA 220 con arma media: tres ataques con 160', () {
      final plan = AdditionalAttackRules.plan(weapon: _weapon('Espada larga', 220), combat: _combat(), declared: 3)!;

      expect(plan.maxAttacks, 3);
      expect(_ability(plan, 220, AttackSlot.main), 160);
    });

    test('HA 220 con mandoble: tres ataques con 140', () {
      final plan = AdditionalAttackRules.plan(weapon: _weapon('Mandoble', 220), combat: _combat(), declared: 3)!;

      expect(_ability(plan, 220, AttackSlot.main), 140);
    });

    test('HA 60: un solo ataque', () {
      final plan = AdditionalAttackRules.plan(weapon: _weapon('Espada larga', 60), combat: _combat(), declared: 3)!;

      expect(plan.maxAttacks, 1);
      expect(plan.declared, 1);
    });

    test('Lemures: dos espadas cortas, ambidiestro, un adicional: 120, 120 y 110', () {
      final plan = AdditionalAttackRules.plan(
        weapon: _weapon('Espada corta y Espada corta', 140),
        combat: _combat(ambidextrous: true),
        declared: 2,
        secondWeapon: true,
      )!;

      expect(_ability(plan, 140, AttackSlot.main), 120);
      expect(_ability(plan, 140, AttackSlot.secondWeapon), 110);
    });

    test('Lemures sin ataque adicional: 140 y 130', () {
      final plan = AdditionalAttackRules.plan(
        weapon: _weapon('Espada corta y Espada corta', 140),
        combat: _combat(ambidextrous: true),
        secondWeapon: true,
      )!;

      expect(_ability(plan, 140, AttackSlot.main), 140);
      expect(_ability(plan, 140, AttackSlot.secondWeapon), 130);
    });
  });

  group('Artes marciales (Dominus)', () {
    test('Kempo supremo con HA 200: cuatro ataques con 170', () {
      final plan = AdditionalAttackRules.plan(weapon: _weapon('Desarmado', 200, type: 'desarmado'), combat: _combat(kempo: 3), declared: 4)!;

      expect(plan.maxAttacks, 4);
      expect(_ability(plan, 200, AttackSlot.main), 170);
    });

    test('Kempo base aplica −15 y no afecta a un arma', () {
      final unarmed = AdditionalAttackRules.plan(weapon: _weapon('Desarmado', 200, type: 'desarmado'), combat: _combat(kempo: 1), declared: 2)!;
      final armed = AdditionalAttackRules.plan(weapon: _weapon('Espada larga', 200), combat: _combat(kempo: 1), declared: 2)!;

      expect(unarmed.penaltyPerAttack, -15);
      expect(armed.penaltyPerAttack, -30);
    });

    test('Desarmado sin arte marcial: −20 y sin segunda arma', () {
      final plan = AdditionalAttackRules.plan(weapon: _weapon('Desarmado', 200, type: 'desarmado'), combat: _combat(), declared: 2, secondWeapon: true)!;

      expect(plan.penaltyPerAttack, -20);
      expect(plan.secondWeaponAllowed, isFalse);
      expect(plan.secondWeapon, isFalse);
    });

    test('Patada de Tae Kwon Do por grado', () {
      expect(AdditionalAttackRules.kickPenalty(1), -30);
      expect(AdditionalAttackRules.kickPenalty(2), -20);
      expect(AdditionalAttackRules.kickPenalty(3), 0);
    });
  });

  group('Tamaño y tablas', () {
    test('Ataque Encadenado: grande −30, media −20, pequeña igual', () {
      expect(AdditionalAttackRules.penaltyPerAttack(size: AttackSize.large, unarmed: false, chainAttackTable: true), -30);
      expect(AdditionalAttackRules.penaltyPerAttack(size: AttackSize.medium, unarmed: false, chainAttackTable: true), -20);
      expect(AdditionalAttackRules.penaltyPerAttack(size: AttackSize.small, unarmed: false, chainAttackTable: true), -20);
    });

    test('Deduce el tamaño del nombre', () {
      expect(AdditionalAttackRules.suggestSize('Espada corta'), AttackSize.small);
      expect(AdditionalAttackRules.suggestSize('Espada Kaitos y Espada Kaitos'), AttackSize.medium);
      expect(AdditionalAttackRules.suggestSize('Martillo de guerra y Escudo medio'), AttackSize.medium);
      expect(AdditionalAttackRules.suggestSize('Daga y Mandoble'), AttackSize.large);
      expect(AdditionalAttackRules.suggestSize('Gran martillo de guerra'), AttackSize.medium);
      expect(AdditionalAttackRules.suggestSize('Espada bastarda'), AttackSize.large);
      expect(AdditionalAttackRules.suggestSize('Escudo medio'), isNull);
      expect(AdditionalAttackRules.suggestSize('Tópico épico'), isNull);
    });

    test('El tamaño elegido a mano manda sobre el nombre', () {
      final plan = AdditionalAttackRules.plan(weapon: _weapon('Espada corta', 200, size: 'G'), combat: _combat(), declared: 2)!;

      expect(plan.penaltyPerAttack, -40);
    });

    test('Sin tamaño no penaliza y lo avisa', () {
      final plan = AdditionalAttackRules.plan(weapon: _weapon('Colmillo del Alba', 200), combat: _combat(), declared: 2)!;

      expect(plan.sharedPenalty, 0);
      expect(plan.needsSize, isTrue);
    });

    test('Las proyecciones no usan estas reglas', () {
      expect(AdditionalAttackRules.plan(weapon: _weapon('Proyeccion Magica', 200, type: 'Mistico'), combat: _combat()), isNull);
    });
  });

  group('Importación', () {
    test('Lee artes marciales y Ataque Encadenado de la planilla', () {
      final combat = CombatData.fromJson({
        'armas': <dynamic>[],
        'ArtesMarciales': {'Kempo': 'Avanzado', 'Tae Kwon Do': 'Base'},
        'TablasDeArmas': {'Tabla de estilo': 'Tabla de Ataque Encadenado'},
      })!;

      expect(combat.kempoGrade, 2);
      expect(combat.taeKwonDoGrade, 1);
      expect(combat.chainAttackTable, isTrue);
      expect(combat.ambidextrous, isFalse);
    });

    test('Una ficha exportada conserva lo elegido a mano', () {
      final original = _combat(ambidextrous: true, kempo: 3);
      final restored = CombatData.fromJson(original.toJson()..['armadura'] = null)!;

      expect(restored.ambidextrous, isTrue);
      expect(restored.kempoGrade, 3);
      expect(restored.chainAttackTable, isFalse);
    });

    test('Lee la Tabla de Ataque Adicional de la planilla', () {
      final combat = CombatData.fromJson({
        'armas': <dynamic>[],
        'TablasDeArmas': {'Tabla de estilo': 'Tabla de Ataque Adicional'},
      })!;

      expect(combat.additionalAttackTable, isTrue);
      expect(combat.chainAttackTable, isFalse);
    });
  });

  group('Kaito', () {
    test('HA 210, espadas medias con Encadenado, Ataque Adicional, ambidiestro y Tae Kwon Do: 6 ataques', () {
      final plan = AdditionalAttackRules.plan(
        weapon: _weapon('Espada Kaitos y Espada Kaitos', 210),
        combat: _combat(ambidextrous: true, chain: true, taeKwonDo: 1, extraTable: true),
        declared: 4,
        secondWeapon: true,
        kick: true,
      )!;

      expect(plan.maxAttacks, 4);
      expect(plan.maxAttacksBreakdown, '1 base + 2 por HA + 1 por Tabla de Ataque Adicional');
      expect(plan.size, AttackSize.medium);
      expect(plan.penaltySize, AttackSize.small);
      expect(plan.totalAttacks, 6);
      expect(_ability(plan, 210, AttackSlot.main), 150);
      expect(_ability(plan, 210, AttackSlot.secondWeapon), 140);
      expect(_ability(plan, 210, AttackSlot.kick), 120);
    });
  });
}
