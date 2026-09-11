import 'package:amt/models/combat_data.dart';
import 'package:amt/models/rules/additional_attack_rules.dart';
import 'package:amt/models/weapon.dart';

/// Condición para sugerir un modificador: dominar una tabla o un arte marcial,
/// opcionalmente dentro de un rango de grados (1 base, 2 avanzado, 3 supremo o
/// arcano).
class TraitRequirement {
  /// Tabla cuyo nombre contiene [name], en minúsculas y sin acentos.
  const TraitRequirement.table(this.name)
      : category = TraitCategory.table,
        minGrade = 0,
        maxGrade = 3;

  /// Arte marcial llamada exactamente [name], en minúsculas y sin acentos.
  const TraitRequirement.art(this.name, {this.minGrade = 1, this.maxGrade = 3}) : category = TraitCategory.martialArt;

  /// Ars Magnus cuyo nombre contiene [name].
  const TraitRequirement.arsMagnus(this.name)
      : category = TraitCategory.arsMagnus,
        minGrade = 0,
        maxGrade = 3;

  final TraitCategory category;
  final String name;
  final int minGrade;
  final int maxGrade;

  bool matches(CombatData combat) {
    if (category != TraitCategory.martialArt) return CombatData.hasTrait(CombatTraits.entriesOf(combat, category), name);

    final grade = combat.martialArtGrade(name);

    return grade > 0 && grade >= minGrade && grade <= maxGrade;
  }
}

/// Lo que se puede anotar en la ficha de un personaje.
enum TraitCategory {
  table('Tabla'),
  martialArt('Arte marcial'),
  advantage('Ventaja'),
  disadvantage('Desventaja'),
  ki('Habilidad de Ki'),
  arsMagnus('Ars Magnus');

  const TraitCategory(this.label);

  final String label;
}

/// Tablas y artes marciales: el catálogo de los manuales y los modificadores
/// que cada una cambia.
///
/// Fuentes: Core Exxet (tablas de estilos y artes marciales, cap. 6; maniobras
/// y situaciones de combate, cap. 9), Dominus Exxet (Tablas de Estilo y Artes
/// Marciales, que como regla específica mandan sobre el Core).
abstract class CombatTraits {
  static const styleTableCatalog = [
    // Core Exxet
    'Batto jutsu / Iai jutsu',
    'Tabla de Área',
    'Tabla de Precisión',
    'Tabla de Desarme',
    'Tabla de Ataque Encadenado',
    // Dominus Exxet
    'Tabla de Acumulación de Proyectiles',
    'Tabla de 2ª Arma: Estilo Defensivo',
    'Tabla de Crítico Incrementado',
    'Tabla de Ataque Inusual',
    'Tabla de Presa Inusual',
    'Tabla de Guardaespaldas',
    'Tabla de Movimiento en Espacios Reducidos',
    'Tabla de Esquiva con Escudo',
    'Tabla de Sujeción',
    // Figuran en la planilla, no en los manuales digitalizados
    'Tabla de Ataque Adicional',
    'Tabla de Desvío',
    'Tabla de Reducción de Armadura',
    'Tabla de Combate a Ciegas',
    'Tabla de Disparo en Movimiento',
    'Tabla de Blanco en Movimiento',
    'Tabla de Varios Blancos',
    'Tabla de Defensa contra Proyectiles',
  ];

  /// Artes Marciales Básicas del Dominus: grados Base, Avanzado y Supremo.
  static const basicMartialArts = [
    'Aikido',
    'Boxeo',
    'Capoeira',
    'Grappling',
    'Kardad',
    'Kempo',
    'Kuan',
    'Kung Fu',
    'Lama',
    'Malla-yuddha',
    'Moai Thai',
    'Pankration',
    'Sambo',
    'Shotokan',
    'Soo Bahk',
    'Tae Kwon Do',
    'Tai Chi',
    'Xing Quan',
  ];

  /// Artes Marciales Avanzadas del Dominus: grados Base y Arcano.
  static const advancedMartialArts = [
    'Asakusen',
    'Dumah',
    'Emp',
    'Enuth',
    'Exelion',
    'Godhand',
    'Hakyoukuken',
    'Hanja',
    'Lama Tsu',
    'Melkaiah',
    'Mushin',
    'Rex Frame',
    'Selene',
    'Seraphite',
    'Shephon',
    'Suyanta',
    'Velez',
  ];

  static List<String> get martialArtCatalog => [
        for (final art in basicMartialArts)
          for (final grade in const ['Base', 'Avanzado', 'Supremo']) '$art ($grade)',
        for (final art in advancedMartialArts)
          for (final grade in const ['Base', 'Arcano']) '$art ($grade)',
      ];

  static List<String> get catalog => [...styleTableCatalog, ...martialArtCatalog];

  /// Ventajas y desventajas de creación que cambian algún cálculo.
  static const advantageCatalog = ['Ambidestría', 'Inmunidad al dolor y al cansancio'];
  static const disadvantageCatalog = ['Exhausto'];

  /// Dominios del Ki (Core) y habilidades del Némesis (Dominus).
  static const kiAbilityCatalog = [
    'Uso del Ki',
    'Control del Ki',
    'Detección del Ki',
    'Erudición',
    'Aura de combate',
    'Dominio físico',
    'Cambio físico',
    'Cambio superior',
    'Multiplicación de cuerpos',
    'Multiplicación mayor',
    'Multiplicación arcana',
    'Magnitud',
    'Magnitud arcana',
    'Control de la edad',
    'Imitación de técnicas',
    'Forzar técnicas',
    'Eliminación de peso',
    'Levitación',
    'Movimiento de objetos',
    'Movimiento de masas',
    'Vuelo',
    'Extrusión de presencia',
    'Armadura de energía',
    'Armadura mayor',
    'Armadura arcana',
    'Extensión del aura al arma',
    'Ataque elemental',
    'Daño incrementado',
    'Alcance incrementado',
    'Velocidad incrementada',
    'Destrucción por Ki',
    'Absorción de energía',
    'Escudo físico',
    'Transmisión del Ki',
    'Curación por Ki',
    'Curación superior',
    'Estabilizar',
    'Sacrificio vital',
    'Uso de la energía necesaria',
    'Ocultación del Ki',
    'Aura de ocultación',
    'Falsa muerte',
    'Eliminación de necesidades',
    'Inmunidad elemental al fuego',
    'Inmunidad elemental al frío',
    'Inmunidad elemental a la electricidad',
    'Eliminación de penalizadores',
    'Recuperación',
    'Restituir a otros',
    'Aumento de características',
    'Incremento superior',
    'Técnicas de combate improvisadas',
    'Inhumanidad',
    'Zen',
    'Armadura de vacío',
    'Noht',
    'Anulación de Ki',
    'Anulación de Ki mayor',
    'Anulación de Magia',
    'Anulación de Magia mayor',
    'Anulación de Matrices',
    'Anulación de Matrices mayor',
    'Anulación de Lazos',
    'Extrusión de Vacío',
    'Forma de Vacío',
    'Cuerpo de Vacío',
    'Sin necesidades',
    'Movimiento de Vacío',
    'Esencia de Vacío',
    'Uno con la nada',
    'Aura de Vacío',
    'Indetección',
  ];

  static const arsMagnusCatalog = ['Berserker'];

  static List<String> catalogFor(TraitCategory category) {
    return switch (category) {
      TraitCategory.table => styleTableCatalog,
      TraitCategory.martialArt => martialArtCatalog,
      TraitCategory.advantage => advantageCatalog,
      TraitCategory.disadvantage => disadvantageCatalog,
      TraitCategory.ki => kiAbilityCatalog,
      TraitCategory.arsMagnus => arsMagnusCatalog,
    };
  }

  /// Lista de la ficha donde se guarda cada categoría.
  static List<String> entriesOf(CombatData combat, TraitCategory category) {
    return switch (category) {
      TraitCategory.table => combat.styleTables,
      TraitCategory.martialArt => combat.martialArts,
      TraitCategory.advantage => combat.advantages,
      TraitCategory.disadvantage => combat.disadvantages,
      TraitCategory.ki => combat.kiAbilities,
      TraitCategory.arsMagnus => combat.arsMagnus,
    };
  }

  /// Distingue un arte marcial de una tabla al añadirla a mano.
  static bool isMartialArt(String value) {
    final name = CombatData.traitName(value);

    return [...basicMartialArts, ...advancedMartialArts].any((art) => CombatData.normalizeTrait(art) == name) ||
        RegExp(r'\((base|avanzado|supremo|arcano)\)', caseSensitive: false).hasMatch(value);
  }

  /// Modificadores que corresponden a quien domina ciertas tablas o artes.
  static const _suggestions = <String, List<TraitRequirement>>{
    'Derribo a mitad (Grappling, Sambo)': [TraitRequirement.art('grappling', maxGrade: 1), TraitRequirement.art('sambo')],
    'Presa a mitad (Pankration, Grappling, Sambo avanzado)': [
      TraitRequirement.art('pankration'),
      TraitRequirement.art('grappling', maxGrade: 1),
      TraitRequirement.art('sambo', minGrade: 2),
    ],
    'Presa con arma sin regla de Presa (Tabla de Presa Inusual)': [TraitRequirement.table('presa inusual')],
    'Desarmar a mitad (Tabla de Desarme, Sambo)': [TraitRequirement.table('tabla de desarme'), TraitRequirement.art('sambo')],
    'Ataque en área a mitad (Tabla de Área, Sambo avanzado)': [TraitRequirement.table('tabla de area'), TraitRequirement.art('sambo', minGrade: 2)],
    'Ataque en área con Capoeira supremo': [TraitRequirement.art('capoeira', minGrade: 3)],
    'Engatillar a mitad (Tabla de Precisión)': [TraitRequirement.table('tabla de precision')],
    'Flanco con Soo Bahk': [TraitRequirement.art('soo bahk', maxGrade: 1)],
    'Proyectil Lanzado con Kuan': [TraitRequirement.art('kuan', maxGrade: 1)],
    'Proyectil Disparado con Kuan avanzado': [TraitRequirement.art('kuan', minGrade: 2, maxGrade: 2)],
    'Proyectil Disparado (escudo)': [TraitRequirement.table('defensa contra proyectiles')],
    'Apartar a otro (Tabla de Guardaespaldas)': [TraitRequirement.table('guardaespaldas')],
    'Contraataque con Boxeo avanzado': [TraitRequirement.art('boxeo', minGrade: 2)],
    'Xing Quan: +10 contra su adversario': [TraitRequirement.art('xing quan', maxGrade: 1)],
    'Xing Quan: +20 contra su adversario (avanzado)': [TraitRequirement.art('xing quan', minGrade: 2, maxGrade: 2)],
    'Xing Quan: +30 contra su adversario (supremo)': [TraitRequirement.art('xing quan', minGrade: 3)],
    'Seraphite base': [TraitRequirement.art('seraphite', maxGrade: 2)],
    'Seraphite arcano': [TraitRequirement.art('seraphite', minGrade: 3)],
    'Defensa total con Shephon': [TraitRequirement.art('shephon', maxGrade: 2)],
    'Defensa total con Shephon arcano': [TraitRequirement.art('shephon', minGrade: 3)],
    'Derribado con Soo Bahk supremo': [TraitRequirement.art('soo bahk', minGrade: 3)],
    'Espacio reducido (Tabla de Movimiento en Espacios Reducidos)': [TraitRequirement.table('espacios reducidos')],
    'Espacio reducido con Hanja': [TraitRequirement.art('hanja')],
    'Parálisis menor con Hanja arcano': [TraitRequirement.art('hanja', minGrade: 3)],
    'Parálisis parcial con Hanja arcano': [TraitRequirement.art('hanja', minGrade: 3)],
    'Amenazado con Hanja arcano': [TraitRequirement.art('hanja', minGrade: 3)],
    'Asakusen': [TraitRequirement.art('asakusen')],
    'Berserker (Ars Magnus)': [TraitRequirement.arsMagnus('berserker')],
    'Kung Fu: +10 al ataque': [TraitRequirement.art('kung fu', minGrade: 2, maxGrade: 2)],
    'Kung Fu: +10 a la parada': [TraitRequirement.art('kung fu', minGrade: 2, maxGrade: 2)],
    'Kung Fu: +10 a la esquiva': [TraitRequirement.art('kung fu', minGrade: 2, maxGrade: 2)],
    'Kung Fu: +10 al turno': [TraitRequirement.art('kung fu', minGrade: 2, maxGrade: 2)],
    'Kung Fu: +20 al ataque (supremo)': [TraitRequirement.art('kung fu', minGrade: 3)],
    'Kung Fu: +20 a la parada (supremo)': [TraitRequirement.art('kung fu', minGrade: 3)],
    'Kung Fu: +20 a la esquiva (supremo)': [TraitRequirement.art('kung fu', minGrade: 3)],
    'Kung Fu: +20 al turno (supremo)': [TraitRequirement.art('kung fu', minGrade: 3)],
    'Kung Fu: +40 al ataque (Asakusen arcano)': [TraitRequirement.art('asakusen', minGrade: 3)],
    'Kung Fu: +40 a la parada (Asakusen arcano)': [TraitRequirement.art('asakusen', minGrade: 3)],
    'Kung Fu: +40 a la esquiva (Asakusen arcano)': [TraitRequirement.art('asakusen', minGrade: 3)],
    'Kung Fu: +40 al turno (Asakusen arcano)': [TraitRequirement.art('asakusen', minGrade: 3)],
  };

  /// Nombres con sugerencia, para comprobar que existen como modificadores.
  static Iterable<String> get suggestedModifierNames => _suggestions.keys;

  /// Modificadores que corresponden al personaje: se muestran primero y
  /// marcados, sin ocultar el resto.
  static List<String> suggestedModifiers(CombatData combat) {
    return [
      for (final entry in _suggestions.entries)
        if (entry.value.any((requirement) => requirement.matches(combat))) entry.key,
    ];
  }

  /// Defensas por asalto que no aplican el penalizador por defensas
  /// adicionales (Tabla 44). -1 significa que ninguna lo aplica.
  ///
  /// Lama da una en grado Avanzado y dos en Supremo, y Lama Tsu suma dos más
  /// (o todas en Arcano); como artes marciales, solo peleando sin armas. La
  /// Tabla de 2ª Arma: Estilo Defensivo da una con un arma en cada mano.
  static int suggestedFreeDefenses({required Weapon weapon, required CombatData combat}) {
    var free = 0;

    if (AdditionalAttackRules.isUnarmed(weapon)) {
      if (combat.martialArtGrade('Lama Tsu') >= 3) return -1;

      final lama = combat.martialArtGrade('Lama');

      if (lama >= 3) {
        free += 2;
      } else if (lama == 2) {
        free += 1;
      }

      if (combat.martialArtGrade('Lama Tsu') >= 1) free += 2;
    } else if (AdditionalAttackRules.wieldsTwoWeapons(weapon) && combat.hasStyleTable('estilo defensivo')) {
      free += 1;
    }

    return free;
  }
}
