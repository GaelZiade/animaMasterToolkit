import 'dart:math';

import 'package:amt/models/combat_data.dart';
import 'package:amt/models/weapon.dart';
import 'package:amt/resources/modifiers.dart';

/// Tamaño de un arma a efectos de ataques adicionales (Core, p. 91).
enum AttackSize {
  small('P', 'Pequeña'),
  medium('M', 'Media'),
  large('G', 'Grande');

  const AttackSize(this.code, this.label);

  final String code;
  final String label;

  static AttackSize? fromCode(String? code) {
    final normalized = code?.trim().toUpperCase();

    for (final size in values) {
      if (size.code == normalized) return size;
    }

    return null;
  }
}

/// Ataques que declara un personaje con su arma en el asalto y lo que le
/// cuestan.
class AttackPlan {
  const AttackPlan({
    required this.maxAttacks,
    required this.declared,
    required this.size,
    required this.penaltySize,
    required this.additionalAttackTable,
    required this.kempoSupreme,
    required this.unarmed,
    required this.penaltyPerAttack,
    required this.penaltySource,
  });

  /// Ataques posibles con la habilidad de la ficha: uno más por cada 100.
  final int maxAttacks;

  /// Ataques con el arma, contando el primero.
  final int declared;

  /// Null si el arma no tiene tamaño elegido ni se pudo deducir del nombre.
  final AttackSize? size;

  /// Tamaño con el que penaliza: con Ataque Encadenado, uno menos que [size].
  final AttackSize? penaltySize;

  /// Tope aumentado por la Tabla de Ataque Adicional o por Kempo supremo.
  final bool additionalAttackTable;
  final bool kempoSupreme;
  final bool unarmed;

  /// Penalizador por cada ataque adicional. Null mientras falte el tamaño.
  final int? penaltyPerAttack;
  final String penaltySource;

  int get additionalAttacks => declared - 1;

  /// Penalizador que se aplica a todos los ataques del asalto.
  int get sharedPenalty => additionalAttacks * (penaltyPerAttack ?? 0);

  String get sharedLabel => 'Ataques adicionales ($additionalAttacks × ${penaltyPerAttack ?? 0}, $penaltySource)';

  /// El tamaño hace falta solo cuando hay ataques adicionales que penalizar.
  bool get needsSize => penaltyPerAttack == null && additionalAttacks > 0;

  /// De dónde sale el tope, para mostrarlo.
  String get maxAttacksBreakdown {
    final byAbility = maxAttacks - 1 - (kempoSupreme ? 1 : 0) - (additionalAttackTable ? 1 : 0);

    return [
      '1 base',
      if (byAbility > 0) '$byAbility por HA',
      if (additionalAttackTable) '1 por Tabla de Ataque Adicional',
      if (kempoSupreme) '1 por Kempo supremo',
    ].join(' + ');
  }
}

/// Ataques adicionales y lo que los modifica.
///
/// Acá se calcula lo automático: el tope y el penalizador que comparten todos
/// los ataques declarados con el arma. Los ataques fuera del tope (segunda
/// arma, patada de Tae Kwon Do, técnicas) son modificadores situacionales del
/// grupo "Ataque extra"; esta clase solo sugiere cuáles corresponden.
///
/// Fuentes: Core Exxet, "Ataques adicionales" y "Ataques con armas
/// adicionales" (p. 91), tipos de arma (p. 76) y tablas de armas; Dominus Exxet
/// para Kempo y Tae Kwon Do, que como regla específica manda sobre el Core.
abstract class AdditionalAttackRules {
  static const martialArtGrades = ['No', 'Base', 'Avanzado', 'Supremo'];

  /// Nombres de los modificadores de ataque extra (ver [Modifiers]).
  static const secondWeapon = '${Modifiers.extraAttackPrefix}Segunda arma';
  static const secondWeaponAmbidextrous = '${Modifiers.extraAttackPrefix}Segunda arma con Ambidestría';
  static const kicks = [
    '${Modifiers.extraAttackPrefix}Patada de Tae Kwon Do (Base)',
    '${Modifiers.extraAttackPrefix}Patada de Tae Kwon Do (Avanzado)',
    '${Modifiers.extraAttackPrefix}Patada de Tae Kwon Do (Supremo)',
  ];

  /// Un golpe adicional por cada 100 puntos de ataque. Kempo en grado supremo
  /// suma otro, como si se tuvieran 100 puntos más.
  ///
  /// La Tabla de Ataque Adicional también suma uno. No está en los manuales
  /// digitalizados: viene de la planilla y de la Pantalla del Director, y
  /// penaliza como cualquier otro ataque adicional.
  static int maxAttacksFor({required int attackAbility, bool kempoSupreme = false, bool additionalAttackTable = false}) {
    return max(1, 1 + attackAbility ~/ 100) + (kempoSupreme ? 1 : 0) + (additionalAttackTable ? 1 : 0);
  }

  /// Con Ataque Encadenado las armas grandes penalizan como medias y las
  /// medias como pequeñas.
  static AttackSize chainedSize(AttackSize size, {required bool chainAttackTable}) {
    return chainAttackTable && size != AttackSize.small ? AttackSize.values[size.index - 1] : size;
  }

  /// Penalizador por cada ataque adicional. Null si falta el tamaño del arma.
  static int? penaltyPerAttack({
    required AttackSize? size,
    required bool unarmed,
    int kempoGrade = 0,
    bool chainAttackTable = false,
  }) {
    if (unarmed) {
      if (kempoGrade >= 2) return -10;
      if (kempoGrade == 1) return -15;

      // Los manuales no dan el penalizador del combate desarmado sin arte
      // marcial: se lo trata como un arma pequeña.
      return -20;
    }

    return switch (size) {
      AttackSize.small => -20,
      AttackSize.medium => chainAttackTable ? -20 : -30,
      AttackSize.large => chainAttackTable ? -30 : -40,
      null => null,
    };
  }

  static String penaltySource({
    required AttackSize? size,
    required bool unarmed,
    int kempoGrade = 0,
    bool chainAttackTable = false,
  }) {
    if (unarmed) {
      return switch (kempoGrade) {
        >= 3 => 'Kempo supremo',
        2 => 'Kempo avanzado',
        1 => 'Kempo',
        _ => 'desarmado',
      };
    }

    if (size == null) return 'tamaño sin definir';

    final chained = chainedSize(size, chainAttackTable: chainAttackTable);

    if (chained != size) return 'arma ${size.label.toLowerCase()} como ${chained.label.toLowerCase()}, Ataque Encadenado';

    return 'arma ${size.label.toLowerCase()}';
  }

  /// Ataques extra que corresponden al personaje con el arma que empuña, para
  /// mostrarlos primero entre los modificadores. El resto sigue disponible.
  static List<String> suggestedExtraAttacks({required Weapon weapon, required CombatData combat}) {
    return [
      // Combatir sin armas no admite un arma adicional.
      if (!isUnarmed(weapon) && wieldsTwoWeapons(weapon)) combat.ambidextrous ? secondWeaponAmbidextrous : secondWeapon,
      if (combat.taeKwonDoGrade > 0) kicks[min(combat.taeKwonDoGrade, kicks.length) - 1],
    ];
  }

  /// La planilla nombra juntas las armas de las dos manos: "Espada y Daga".
  static bool wieldsTwoWeapons(Weapon weapon) => RegExp(r'\S\s+y\s+\S').hasMatch(weapon.name);

  static bool isUnarmed(Weapon weapon) {
    final type = _normalize(weapon.type ?? '');
    final name = _normalize(weapon.name);

    return type == 'desarmado' || name.contains('desarmado') || name.contains('sin armas');
  }

  /// La proyección mágica y la psíquica se importan como armas, pero no usan
  /// estas reglas.
  static bool isProjection(Weapon weapon) {
    final type = _normalize(weapon.type ?? '');

    return _normalize(weapon.name).contains('proyeccion') || type == 'mistico' || type == 'psiquica';
  }

  /// Deduce el tamaño a partir del nombre, con las tablas de armas del Core.
  ///
  /// La planilla junta las dos manos en un solo nombre ("Espada y Daga"), y con
  /// dos armas manda la de mayor tamaño. Una parte que no se reconoce, como un
  /// escudo, no cuenta.
  static AttackSize? suggestSize(String name) {
    AttackSize? result;

    for (final part in _normalize(name).split(RegExp(r'\s+y\s+|\s*[+/,&]\s*'))) {
      final size = _sizeOfPart(part);

      if (size != null && (result == null || size.index > result.index)) result = size;
    }

    return result;
  }

  static AttackSize? _sizeOfPart(String part) {
    var bestLength = 0;
    AttackSize? best;

    for (final entry in _sizesByName.entries) {
      final pattern = RegExp('(^|[^a-z0-9])${RegExp.escape(entry.key)}(e?s)?(?=[^a-z0-9]|\$)');

      if (!pattern.hasMatch(part)) continue;

      // Gana la coincidencia más larga: "espada corta" antes que "espada".
      final longer = entry.key.length > bestLength;
      final tieButBigger = entry.key.length == bestLength && best != null && entry.value.index > best.index;

      if (longer || tieButBigger) {
        bestLength = entry.key.length;
        best = entry.value;
      }
    }

    return best;
  }

  static AttackPlan? plan({
    required Weapon weapon,
    required CombatData combat,
    int declared = 1,
  }) {
    if (isProjection(weapon)) return null;

    final unarmed = isUnarmed(weapon);
    // Las artes marciales son estilos sin armas: Kempo no cambia nada con un
    // arma en la mano.
    final kempo = unarmed ? combat.kempoGrade : 0;
    final size = unarmed ? null : AttackSize.fromCode(weapon.attackSize) ?? suggestSize(weapon.name);
    final maxAttacks = maxAttacksFor(
      attackAbility: weapon.attack,
      kempoSupreme: kempo >= 3,
      additionalAttackTable: combat.additionalAttackTable,
    );

    return AttackPlan(
      maxAttacks: maxAttacks,
      declared: declared.clamp(1, maxAttacks),
      size: size,
      penaltySize: size == null ? null : chainedSize(size, chainAttackTable: combat.chainAttackTable),
      additionalAttackTable: combat.additionalAttackTable,
      kempoSupreme: kempo >= 3,
      unarmed: unarmed,
      penaltyPerAttack: penaltyPerAttack(size: size, unarmed: unarmed, kempoGrade: kempo, chainAttackTable: combat.chainAttackTable),
      penaltySource: penaltySource(size: size, unarmed: unarmed, kempoGrade: kempo, chainAttackTable: combat.chainAttackTable),
    );
  }

  static String _normalize(String text) {
    const accents = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n'};

    return text.toLowerCase().split('').map((char) => accents[char] ?? char).join().trim();
  }

  /// Tablas 29, 30 y 32 del Core, con el tamaño que da el tipo de arma (p. 76).
  /// Las mixtas toman el tamaño de la categoría más grande.
  static const _sizesByName = {
    // Tabla 29: armas comunes
    'alabarda': AttackSize.large,
    'arpon': AttackSize.large,
    'cadena': AttackSize.medium,
    'cestus': AttackSize.small,
    'cimitarra': AttackSize.medium,
    'daga de parada': AttackSize.small,
    'daga': AttackSize.small,
    'espada ancha': AttackSize.medium,
    'espada bastarda': AttackSize.large,
    'espada corta': AttackSize.small,
    'espada larga': AttackSize.medium,
    'estilete': AttackSize.small,
    'estoque': AttackSize.medium,
    'florete': AttackSize.medium,
    'garfio': AttackSize.small,
    'garrote': AttackSize.medium,
    'gran martillo de guerra': AttackSize.medium,
    'guadana': AttackSize.large,
    'hacha a dos manos': AttackSize.large,
    'hacha de guerra': AttackSize.medium,
    'hacha de mano': AttackSize.medium,
    'jabalina': AttackSize.large,
    'lanza de caballeria': AttackSize.large,
    'lanza': AttackSize.large,
    'latigo': AttackSize.medium,
    'lazo': AttackSize.medium,
    'mandoble': AttackSize.large,
    'mangual': AttackSize.large,
    'martillo de guerra': AttackSize.medium,
    'mayal': AttackSize.medium,
    'maza pesada de combate': AttackSize.large,
    'maza': AttackSize.medium,
    'red de gladiador': AttackSize.medium,
    'sable': AttackSize.medium,
    'tridente': AttackSize.large,
    'vara': AttackSize.large,
    // Tabla 30: armas exóticas o de diseño
    'katana de doble hoja': AttackSize.medium,
    'katana': AttackSize.medium,
    'katar': AttackSize.small,
    'garras': AttackSize.small,
    'nunchaku': AttackSize.medium,
    'bumeran': AttackSize.small,
    'quebradora': AttackSize.large,
    'shuriken': AttackSize.small,
    'cuervo': AttackSize.small,
    'anciano de primavera': AttackSize.large,
    'nodachi': AttackSize.large,
    'tanto': AttackSize.small,
    'tonfa': AttackSize.small,
    'abanico de combate': AttackSize.small,
    'sai': AttackSize.small,
    'kusari-gama': AttackSize.medium,
    'shuko': AttackSize.small,
    // Tabla 32: armas improvisadas
    'botella rota': AttackSize.small,
    'silla': AttackSize.large,
    'palo de madera': AttackSize.medium,
    'barra metalica': AttackSize.medium,
    'jarron': AttackSize.medium,
    'cuchillo de cocina': AttackSize.small,
    'martillo': AttackSize.medium,
    'hacha de lenador': AttackSize.medium,
    'azada': AttackSize.medium,
    'hoz': AttackSize.small,
    'pico': AttackSize.small,
    'antorcha': AttackSize.medium,
    // Categorías de arma, para nombres propios como "Espada de Kaito"
    'arma corta': AttackSize.small,
    'espada': AttackSize.medium,
    'hacha': AttackSize.medium,
    'cuerda': AttackSize.medium,
    'asta': AttackSize.large,
  };
}
