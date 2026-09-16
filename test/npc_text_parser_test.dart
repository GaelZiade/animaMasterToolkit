import 'dart:io';

import 'package:amt/models/combat_data.dart';
import 'package:amt/models/enums.dart';
import 'package:amt/utils/npc_parser/npc_text_parser.dart';
import 'package:flutter_test/flutter_test.dart';

List<NpcParseResult> _sample(String file) => NpcTextParser.parseAll(File('test/npc_samples/$file.txt').readAsStringSync());

NpcParseResult _named(List<NpcParseResult> results, String name) => results.firstWhere((result) => result.name == name);

Map<String, dynamic> _profile(NpcParseResult result) => result.json['datosElementales'] as Map<String, dynamic>;

CombatData _combat(NpcParseResult result) => CombatData.fromJson(result.json['Combate'] as Map<String, dynamic>)!;

const _knight = '''
Caballero
Categoría Maestro de Armas; Nivel 2
Turno 55/35/5; Pv 135; TA Placas; HA 90; HP 90; Armas Espada Larga
/ Lanza de Caballería; Daño 55/85
AGI: 5 DES: 8 CON: 7 FUE: 7 PER: 5 INT: 5 VOL: 6 POD: 5
Resistencias: RF 45, RE 45, RV 45, RM 40, RP 40.
''';

const _peasantAndHorse = '''
Campesino
Categoría Novel; Nivel 0
Turno 40; Pv 70; TA No; HA 20; HE 20; Armas No; Daño 10
AGI: 5 DES: 5 CON: 5 FUE: 5 PER: 5 INT: 5 VOL: 5 POD: 5
Resistencias: RF 30, RE 30, RV 30, RM 30, RP 30.

Caballo
Categoría Novel; Nivel 0 Turno 40; Pv 300; TA 3; HA 40; Armas Natural; Daño 55 AGI: 10 DES: 3 CON: 8 FUE: 10 PER: 4 INT: 2 VOL: 2 POD: 5 Especial: Acumulación de daño, Arma natural: Coz (CON). Resistencias: RF 30, RE 30, RV 30, RM 20, RP 5.
''';

const _technique = '''
Sacra Aegis
Nivel: 1 CM: 30 El escudo del Alius emite un fulgor dorado.
Efectos: Habilidad de Parada +50.
''';

void main() {
  group('Formato largo (Core, Bestiario)', () {
    final results = _sample('long_core');

    test('Separa los tres perfiles y arregla los nombres en versalitas', () {
      expect(results.map((result) => result.name), ['Dragón (Menor)', 'Zombi', 'Asagiri']);
    });

    test('Dragón: vida con punto de miles, acumulación y características', () {
      final dragon = _named(results, 'Dragón (Menor)');

      expect(_profile(dragon)['puntosDeVida'], '3005');
      expect(_profile(dragon)['acumDanio'], 'Si');
      expect(_profile(dragon)['cansancio'], '14');
      expect(dragon.json['Atributos'], containsPair('FUE', '14'));
      expect(dragon.json['Resistencias'], {'RF': '95', 'RM': '110', 'RP': '75', 'RV': '95', 'RE': '95'});
      expect(dragon.json['Habilidades'], containsPair('Resistir el dolor', '85'));
    });

    test('Dragón: un arma por ataque, con su daño, crítico y Armadura -1', () {
      final weapons = _combat(_named(results, 'Dragón (Menor)')).weapons;

      expect(weapons.map((weapon) => weapon.name), ['Garras', 'Mordisco', 'Aliento', 'Coletazo']);
      expect(weapons.map((weapon) => weapon.attack), [190, 170, 190, 140]);
      expect(weapons.map((weapon) => weapon.damage), [130, 150, 120, 100]);
      expect(weapons[1].principalDamage, DamageTypes.pen);
      expect(weapons[3].principalDamage, DamageTypes.con);
      expect(weapons.map((weapon) => weapon.armourReduction), [1, 1, 0, 0]);
      expect(_profile(_named(results, 'Dragón (Menor)'))['barreraDanio'], '80');
    });

    test('Dragón: TA por tipo', () {
      final armour = _combat(_named(results, 'Dragón (Menor)')).armour.calculatedArmour;

      expect([armour.fil, armour.con, armour.pen, armour.ene], [7, 7, 7, 6]);
    });

    test('Zombi: armas separadas, «como arma» avisado, TA natural sin Energía, incansable', () {
      final zombie = _named(results, 'Zombi');
      final combat = _combat(zombie);

      expect(combat.weapons.map((weapon) => weapon.name), ['Mordisco', 'Golpes']);
      expect(combat.weapons.first.principalDamage, DamageTypes.con);
      expect(combat.weapons.first.secondaryDamage, DamageTypes.pen);
      expect([combat.armour.calculatedArmour.fil, combat.armour.calculatedArmour.ene], [3, 0]);
      expect(_profile(zombie)['cansancio'], '0');
      expect(zombie.warnings, contains(contains('usa armas que el perfil no detalla')));
    });

    test('Asagiri: defensa en esquiva', () {
      final weapon = _combat(_named(results, 'Asagiri')).weapons.single;

      expect(weapon.defense, 110);
      expect(weapon.defenseType, DefenseType.dodge);
      expect(weapon.turn, 120);
    });
  });

  group('Formato compacto (personajes comunes)', () {
    final results = _sample('compact');

    test('Alto Caballero: TA por nombre, críticos por tabla de armas y tablas', () {
      final knight = _named(results, 'Alto Caballero de Santa Helena');
      final combat = _combat(knight);
      final armour = combat.armour.calculatedArmour;
      final weapon = combat.weapons.single;

      expect(knight.warnings, isEmpty);
      expect([armour.fil, armour.con, armour.pen, armour.cal, armour.ele, armour.fri, armour.ene], [4, 4, 4, 2, 0, 1, 1]);
      expect([weapon.name, weapon.attack, weapon.defense, weapon.damage, weapon.turn], ['Espada bastarda', 115, 120, 80, 80]);
      expect([weapon.principalDamage, weapon.secondaryDamage], [DamageTypes.fil, DamageTypes.con]);
      expect(weapon.defenseType, DefenseType.parry);
      expect(combat.styleTables, ['Tabla de armas de Caballero']);
    });

    test('Guardia de Abel: Cuero tachonado en el orden de la Tabla 38', () {
      final guard = _named(results, 'Guardia de Abel');
      final armour = _combat(guard).armour.calculatedArmour;

      expect([armour.fil, armour.con, armour.pen], [3, 1, 2]);
      expect(guard.json['Habilidades'], containsPair('Resistir el dolor', '5'));
      expect(guard.json['Atributos'], hasLength(8));
      // Sin esos datos en el perfil: Cansancio = CON, movimiento = AGI y
      // regeneración por la Tabla 23.
      expect([_profile(guard)['cansancio'], _profile(guard)['movimiento'], _profile(guard)['regeneracion']], ['7', '6', '1']);
    });

    test('«Maestro de Armas» no es el campo Armas; varias armas con daño por orden', () {
      final result = NpcTextParser.parseAll(_knight).single;
      final weapons = _combat(result).weapons;

      expect(_profile(result)['categoria'], 'Maestro de Armas');
      expect(weapons.map((weapon) => weapon.name), ['Espada Larga', 'Lanza de Caballería']);
      expect(weapons.map((weapon) => weapon.damage), [55, 85]);
    });

    test('Sin armas ni armadura; animales con arma natural y acumulación en Especial', () {
      final results = NpcTextParser.parseAll(_peasantAndHorse);
      final peasant = _combat(results.first).weapons.single;
      final horse = results.last;

      expect([peasant.name, peasant.type, peasant.principalDamage], ['Desarmado', 'desarmado', DamageTypes.con]);
      expect(_combat(results.first).armour.calculatedArmour.fil, 0);
      expect(results.first.warnings, isEmpty);
      expect(_profile(horse)['acumDanio'], 'Si');
      expect(_combat(horse).weapons.single.name, 'Coz');
      expect(_combat(horse).weapons.single.principalDamage, DamageTypes.con);
      expect(horse.warnings, isEmpty);
    });
  });

  group('Capturas (Bestiario, Gaïa)', () {
    final results = _sample('screenshots');

    test('Grendel: turno por arma y tabla de armas', () {
      final combat = _combat(_named(results, 'Grendel'));
      final sword = combat.weapons.firstWhere((weapon) => weapon.name == 'Espada larga');
      final claws = combat.weapons.firstWhere((weapon) => weapon.name == 'Garras');

      expect([sword.turn, sword.damage], [55, 60]);
      expect([claws.turn, claws.damage], [75, 50]);
      expect(combat.styleTables, ['Tabla de armas de Cazador']);
    });

    test('Arias Vayu: −2 a la TA, proyección ofensiva, Zeon y sin armadura', () {
      final arias = _named(results, 'Arias Vayu');
      final combat = _combat(arias);
      final blade = combat.weapons.first;
      final projection = combat.weapons.last;

      expect([blade.name, blade.armourReduction, blade.defenseType], ['Cuchilla de Viento', 2, DefenseType.dodge]);
      expect([projection.name, projection.attack, projection.defense], ['Proyección Mágica', 200, 0]);
      expect(arias.json['Misticos'], containsPair('zeon', '900'));
      expect(combat.armour.calculatedArmour.fil, 0);
    });
  });

  test('Chthon: «Armas Diamantinas» es un arma, TA en dos renglones y un daño sin habilidad propia', () {
    final chthon = _sample('chthon').single;
    final combat = _combat(chthon);
    final armour = combat.armour.calculatedArmour;
    final (blade, release, projection) = (combat.weapons[0], combat.weapons[1], combat.weapons[2]);

    expect(chthon.name, 'Chthon');
    expect(_profile(chthon)['puntosDeVida'], '7000');
    expect([blade.name, blade.attack, blade.damage, blade.armourReduction], ['Armas Diamantinas', 230, 150, 5]);
    expect([blade.principalDamage, blade.secondaryDamage], [DamageTypes.fil, DamageTypes.con]);
    expect([release.name, release.attack, release.damage, release.principalDamage], ['Liberación de Energía', 230, 100, DamageTypes.ene]);
    expect([projection.name, projection.attack, projection.defense], ['Proyección Mágica', 20, 0]);
    expect([armour.fil, armour.ele, armour.ene], [12, 12, 8]);
    expect(chthon.warnings.single, contains('no da su habilidad de ataque'));

    // «+20 al Crítico» solo en las Armas Diamantinas; «Daña Energía» en todos
    // sus ataques; «Barrera de Daño 160» dentro de Cuerpo de Diamante.
    expect([blade.criticalBonus, release.criticalBonus], [20, 0]);
    expect([blade.damagesEnergy, release.damagesEnergy], [true, true]);
    expect(_profile(chthon)['barreraDanio'], '160');
  });

  test('Captura de dos columnas leída con OCR: «Mayor» hereda el nombre y «Per 10» sin dos puntos', () {
    final results = _sample('ocr_two_columns');

    expect(results.map((result) => result.name), ['Dragon (Menor)', 'Dragon (Mayor)']);
    expect(results.map((result) => result.json['Atributos']['PER']), ['10', '10']);
    expect(results.map((result) => _profile(result)['puntosDeVida']), ['3005', '5000']);
    expect(_combat(results.last).weapons.first.attack, 220);
    expect(_combat(results.last).armour.calculatedArmour.fil, 9);
    expect(results.every((result) => !result.warnings.any((warning) => warning.contains('características'))), isTrue);
  });

  group('Texto real de la lectura de las capturas del usuario', () {
    final long = _sample('ocr_real_long');
    final compact = _sample('ocr_real_compact');

    test('Reconoce los siete perfiles con sus nombres, sin restos de la ilustración', () {
      expect(long.map((result) => result.name), ['Dragón (Menor)', 'Dragón (Mayor)', 'Grendel', 'Arias Vayu']);
      expect(compact.map((result) => result.name), ['Guardia de Abel', 'Alto Caballero de Santa Helena', 'Gran Erudito Ilmorense']);
    });

    test('«RE 95 RM…» es RF por el orden del formato; «RY» es RV; «Yol» es Vol', () {
      expect(long[0].json['Resistencias'], {'RF': '95', 'RM': '110', 'RP': '75', 'RV': '95', 'RE': '95'});
      expect(long[1].json['Resistencias'], {'RF': '110', 'RM': '120', 'RP': '90', 'RV': '110', 'RE': '110'});
      expect(long[1].json['Atributos'], containsPair('VOL', '11'));
      expect(long[2].json['Resistencias'], {'RF': '50', 'RM': '45', 'RP': '45', 'RV': '80', 'RE': '50'});
      expect(compact[2].json['Resistencias'], containsPair('RV', '40'));
    });

    test('Dragón Mayor: «Mordisco:» con dos puntos por punto y coma, Armadura -2 y barrera 120', () {
      final weapons = _combat(long[1]).weapons;

      expect(weapons.map((weapon) => weapon.name), ['Garras', 'Mordisco', 'Aliento', 'Coletazo']);
      expect(weapons.map((weapon) => weapon.attack), [220, 200, 220, 170]);
      expect(weapons.map((weapon) => weapon.damage), [150, 170, 150, 120]);
      expect(weapons.first.armourReduction, 2);
      expect(_profile(long[1])['barreraDanio'], '120');
    });

    test('Arias Vayu: «Regeneración: |» es 1 y una RF imposible se avisa', () {
      expect(_profile(long[3])['regeneracion'], '1');
      expect(long[3].warnings, contains('RF 865: parece mal leída, revisala'));
    });

    test('Grendel y los compactos salen como en el libro', () {
      expect(long[2].json['Atributos'], containsPair('PER', '8'));
      expect(_combat(long[2]).armour.calculatedArmour.ene, 0);
      expect(compact[0].warnings, isEmpty);
      expect(compact[1].warnings, isEmpty);
    });

    test('Erudito: «HE 0» es una defensa leída y «Combate desarmado» ataca en CON', () {
      final weapon = _combat(compact[2]).weapons.single;

      expect(compact[2].warnings, isEmpty);
      expect([weapon.defense, weapon.defenseType, weapon.principalDamage, weapon.type], [0, DefenseType.dodge, DamageTypes.con, 'desarmado']);
      expect(_profile(compact[2])['puntosDeVida'], '85');
    });
  });

  test('Descarta técnicas y conjuros que también empiezan con «Nivel:»', () {
    expect(NpcTextParser.parseAll(_technique), isEmpty);
  });

  test('Manuales digitalizados: lee la mayoría de los perfiles sin avisos', () {
    final folder = Directory('C:/Users/Pire/Desktop/marker-manuales/subir-ANIMA');

    if (!folder.existsSync()) return markTestSkipped('Faltan los manuales digitalizados');

    final results = [
      for (final file in folder.listSync().whereType<File>().where((file) => file.path.endsWith('.md')))
        ...NpcTextParser.parseAll(file.readAsStringSync()),
    ];

    expect(results.length, greaterThan(180));
    expect(results.where((result) => result.warnings.isEmpty).length / results.length, greaterThan(0.5));
  });
}
