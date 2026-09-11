import 'dart:io';

import 'package:amt/models/armour.dart';
import 'package:amt/models/armour_data.dart';
import 'package:amt/models/combat_data.dart';
import 'package:amt/models/enums.dart';
import 'package:amt/models/rules/combat_traits.dart';
import 'package:amt/models/weapon.dart';
import 'package:amt/resources/modifier_groups.dart';
import 'package:amt/resources/modifiers.dart';
import 'package:amt/utils/xlsx/sheet_to_json.dart';
import 'package:amt/utils/xlsx/xlsx_workbook.dart';
import 'package:flutter_test/flutter_test.dart';

CombatData _combat({List<String> tables = const [], List<String> arts = const []}) {
  return CombatData(
    armour: ArmourData(calculatedArmour: Armour(), armours: []),
    weapons: [],
    styleTables: tables,
    martialArts: arts,
  );
}

Weapon _weapon(String name, {String type = 'A una mano'}) {
  return Weapon(name: name, turn: 0, attack: 150, defense: 150, defenseType: DefenseType.parry, damage: 50, type: type);
}

final _unarmed = _weapon('Artes Marciales', type: 'desarmado');

/// Modificador situacional de ese tipo, o de estado si no está entre aquellos.
int _value(String name, ModifiersType type) {
  final situational = Modifiers.getSituationalModifiers(type).where((modifier) => modifier.name == name).firstOrNull;

  if (situational != null) {
    return switch (type) {
      ModifiersType.attack => situational.attack,
      ModifiersType.parry => situational.parry,
      ModifiersType.dodge => situational.dodge,
      ModifiersType.turn => situational.turn,
      ModifiersType.action => situational.physicalAction,
    };
  }

  final status = Modifiers.getStatusModifiers().firstWhere((modifier) => modifier.name == name);

  return switch (type) {
    ModifiersType.attack => status.attack,
    ModifiersType.parry => status.parry,
    ModifiersType.dodge => status.dodge,
    ModifiersType.turn => status.turn,
    ModifiersType.action => status.physicalAction,
  };
}

CombatData? _sheet(String file) {
  final sheet = File('C:/Users/Pire/Downloads/$file');

  if (!sheet.existsSync()) return null;

  final json = SheetToJson.convert(XlsxWorkbook.decode(sheet.readAsBytesSync()));

  return CombatData.fromJson(json['Combate'] as Map<String, dynamic>);
}

void main() {
  final names = {
    for (final type in ModifiersType.values) ...Modifiers.getSituationalModifiers(type).map((modifier) => modifier.name),
    ...Modifiers.getStatusModifiers().map((modifier) => modifier.name),
  };

  group('Catálogo', () {
    test('Cada sugerencia apunta a un modificador que existe', () {
      for (final name in CombatTraits.suggestedModifierNames) {
        expect(names, contains(name), reason: name);
      }
    });

    test('Cada opción de un grupo excluyente existe', () {
      for (final group in ModifierGroup.all) {
        for (final name in group.names) {
          expect(names, contains(name), reason: '${group.label}: $name');
        }
      }
    });

    test('Distingue artes marciales de tablas', () {
      expect(CombatTraits.isMartialArt('Sambo (Avanzado)'), isTrue);
      expect(CombatTraits.isMartialArt('Lama Tsu'), isTrue);
      expect(CombatTraits.isMartialArt('Estilo de la casa (Supremo)'), isTrue);
      expect(CombatTraits.isMartialArt('Tabla de Área'), isFalse);
    });
  });

  group('Catálogo único de modificadores', () {
    List<String> namesFor(ModifiersType type) => Modifiers.getSituationalModifiers(type).map((modifier) => modifier.name).toList();

    test('La defensa ve los positivos que antes solo eran estados', () {
      expect(namesFor(ModifiersType.parry), containsAll(['Defensa total', 'Defensa total con Shephon', 'Defensa total con Shephon arcano']));
      expect(_value('Defensa total', ModifiersType.dodge), 30);
    });

    test('No se ofrece nada que no cambie la tirada', () {
      for (final type in ModifiersType.values) {
        for (final modifier in Modifiers.getSituationalModifiers(type)) {
          final value = switch (type) {
            ModifiersType.attack => modifier.attack,
            ModifiersType.parry => modifier.parry,
            ModifiersType.dodge => modifier.dodge,
            ModifiersType.turn => modifier.turn,
            ModifiersType.action => modifier.physicalAction,
          };

          expect(value, isNot(0), reason: '${type.name}: ${modifier.name}');
        }
      }
    });

    test('Fuera lo que no está en los manuales', () {
      expect(names, isNot(contains('Ataque total')));
      expect(names, isNot(contains('A la defensiva')));
      expect(names, isNot(contains('A la ofensiva')));
      expect(names, isNot(contains('Escasa visibilidad')));
    });

    test('El panel del personaje incluye las maniobras y no repite nombres', () {
      final status = Modifiers.getStatusModifiers().map((modifier) => modifier.name).toList();

      expect(status, containsAll(['Derribo', 'Flanco', 'Dolor']));
      expect(status.length, status.toSet().length);
    });
  });

  group('Valores de los manuales', () {
    test('Maniobras del Core', () {
      expect(_value('Derribo', ModifiersType.attack), -30);
      expect(_value('Derribo con arma corta', ModifiersType.attack), -60);
      expect(_value('Presa', ModifiersType.attack), -40);
      expect(_value('Desarmar', ModifiersType.attack), -40);
      expect(_value('Ataque en área', ModifiersType.attack), -50);
      expect(_value('Engatillar', ModifiersType.attack), -100);
      expect(_value('Crítico secundario', ModifiersType.attack), -10);
      expect(_value('Apartar a otro', ModifiersType.parry), -30);
      expect(_value('Resistir el golpe', ModifiersType.dodge), -80);
    });

    test('Tabla 29: el arma que no se domina penaliza ataque y parada', () {
      expect(_value('Arma similar', ModifiersType.parry), -20);
      expect(_value('Arma mixta', ModifiersType.parry), -40);
      expect(_value('Arma distinta / Desarmado', ModifiersType.parry), -60);
    });

    test('Defensa total no penaliza el ataque: directamente no se ataca', () {
      expect(_value('Defensa total', ModifiersType.dodge), 30);
      expect(Modifiers.getSituationalModifiers(ModifiersType.attack).map((modifier) => modifier.name), isNot(contains('Defensa total')));
    });

    test('Estados de Estados y Accidentes: toda acción, iniciativa a la mitad', () {
      expect(_value('Dolor', ModifiersType.attack), -40);
      expect(_value('Dolor', ModifiersType.turn), -20);
      expect(_value('Dolor extremo', ModifiersType.parry), -80);
      expect(_value('Dolor leve', ModifiersType.action), -20);
      expect(_value('Miedo', ModifiersType.turn), -30);
      expect(_value('2 puntos restantes de cansancio', ModifiersType.attack), -40);
      expect(_value('2 puntos restantes de cansancio', ModifiersType.turn), -20);
      expect(_value('0 puntos restantes de cansancio', ModifiersType.turn), -60);
    });

    test('Artes avanzadas del Dominus', () {
      expect(_value('Seraphite base', ModifiersType.attack), 20);
      expect(_value('Seraphite base', ModifiersType.parry), -30);
      expect(_value('Defensa total con Shephon', ModifiersType.parry), 60);
      expect(_value('Defensa total con Shephon arcano', ModifiersType.dodge), 100);
    });
  });

  group('Sugerencias por ficha', () {
    test('Grappling base sugiere Presa a mitad; en avanzado ya no penaliza y no sugiere nada', () {
      expect(CombatTraits.suggestedModifiers(_combat(arts: ['Grappling (Base)'])), contains('Presa a mitad (Pankration, Grappling, Sambo avanzado)'));
      expect(CombatTraits.suggestedModifiers(_combat(arts: ['Grappling (Avanzado)'])), isEmpty);
    });

    test('Lama no se confunde con Lama Tsu', () {
      expect(_combat(arts: ['Lama Tsu (Base)']).martialArtGrade('Lama'), 0);
    });

    test('Una planilla sin acentos coincide con el catálogo', () {
      expect(CombatTraits.suggestedModifiers(_combat(tables: ['Tabla de Area'])), contains('Ataque en área a mitad (Tabla de Área, Sambo avanzado)'));
    });
  });

  group('Defensas sin penalizador', () {
    test('Lama y Lama Tsu, peleando sin armas', () {
      expect(CombatTraits.suggestedFreeDefenses(weapon: _unarmed, combat: _combat(arts: ['Lama (Avanzado)'])), 1);
      expect(CombatTraits.suggestedFreeDefenses(weapon: _unarmed, combat: _combat(arts: ['Lama (Supremo)', 'Lama Tsu (Base)'])), 4);
      expect(CombatTraits.suggestedFreeDefenses(weapon: _unarmed, combat: _combat(arts: ['Lama Tsu (Arcano)'])), -1);
      expect(CombatTraits.suggestedFreeDefenses(weapon: _weapon('Espada larga'), combat: _combat(arts: ['Lama (Supremo)'])), 0);
    });

    test('Tabla de 2ª Arma: Estilo Defensivo con dos armas', () {
      final combat = _combat(tables: ['Tabla de 2ª Arma: Estilo Defensivo']);

      expect(CombatTraits.suggestedFreeDefenses(weapon: _weapon('Espada y Daga'), combat: combat), 1);
      expect(CombatTraits.suggestedFreeDefenses(weapon: _weapon('Espada larga'), combat: combat), 0);
    });
  });

  group('Planillas reales', () {
    test('Kiran: Kuan, Soo Bahk y Lama supremo', () {
      final combat = _sheet('Ficha Anima v8.7.0 but peak (1) kiran.xlsm');

      if (combat == null) return markTestSkipped('Falta la planilla de Kiran');

      final suggested = CombatTraits.suggestedModifiers(combat);

      expect(combat.martialArts, contains('Lama (Supremo)'));
      expect(suggested, contains('Proyectil Lanzado con Kuan'));
      expect(suggested, contains('Flanco con Soo Bahk'));
      expect(CombatTraits.suggestedFreeDefenses(weapon: combat.weapons.first, combat: combat), 2);
    });

    test('Teseo: Tabla de Área y Defensa contra Proyectiles', () {
      final combat = _sheet('Teseo Anima Gaia Reborn Nivel 7 Boxeito Ataque final Guardian.xlsm');

      if (combat == null) return markTestSkipped('Falta la planilla de Teseo');

      final suggested = CombatTraits.suggestedModifiers(combat);

      expect(suggested, contains('Ataque en área a mitad (Tabla de Área, Sambo avanzado)'));
      expect(suggested, contains('Proyectil Disparado (escudo)'));
    });
  });
}
