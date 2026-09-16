import 'package:amt/models/combat_data.dart';
import 'package:amt/models/rules/additional_attack_rules.dart';
import 'package:amt/models/weapon.dart';

/// Una fuente de barrera de daño y su valor.
class DamageBarrierSource {
  const DamageBarrierSource(this.label, this.value);

  final String label;
  final int value;
}

/// Barrera de daño (Core, Estados y Accidentes): un ataque cuyo daño base no la
/// alcanza no quita PV, salvo que dañe energía.
abstract class DamageBarrierRules {
  /// Hanja (Dominus Exxet): Barrera 60 en grado Base y 200 en Arcano.
  static const hanjaBase = 60;
  static const hanjaArcane = 200;

  /// Las barreras que tiene el defensor: la cargada a mano, la del Hanja y la
  /// del Escudo físico del Ki (igual a su Presencia base).
  static List<DamageBarrierSource> sources({
    required int? manual,
    required CombatData combat,
    required int presence,
  }) {
    final hanja = combat.martialArtGrade('Hanja');

    return [
      if ((manual ?? 0) > 0) DamageBarrierSource('Barrera de daño', manual!),
      if (hanja > 0) DamageBarrierSource('Hanja', hanja >= 3 ? hanjaArcane : hanjaBase),
      if (presence > 0 && CombatData.hasTrait(combat.kiAbilities, 'escudo fisico')) DamageBarrierSource('Escudo físico', presence),
    ];
  }

  /// Barreras que, contra la regla general, también frenan a los ataques que
  /// dañan energía: la Comunión con la Tierra del Behemoth (80) o el Escudo
  /// telequinético por encima de Imposible. Se cargan a mano.
  static List<DamageBarrierSource> energySources({required int? manual}) {
    return [
      if ((manual ?? 0) > 0) DamageBarrierSource('Barrera contra energía', manual!),
    ];
  }

  /// La barrera que frena este ataque: la física si no daña energía, y si la
  /// daña solo una barrera contra energía.
  static DamageBarrierSource? applicable({
    required List<DamageBarrierSource> physical,
    required List<DamageBarrierSource> energy,
    required String? energyDamageSource,
  }) {
    return strongest(energyDamageSource == null ? physical : energy);
  }

  /// Los manuales no dicen que se sumen: vale la más alta.
  static DamageBarrierSource? strongest(List<DamageBarrierSource> sources) {
    return sources.isEmpty ? null : sources.reduce((best, source) => source.value > best.value ? source : best);
  }

  /// Por qué el ataque daña energía e ignora la barrera, o null si no lo hace.
  ///
  /// Atacar sobre la TA de Energía no alcanza: el Core distingue los ataques
  /// basados en energía de los capaces de dañarla. Sí la dañan un arma mística
  /// o un poder marcado en el arma, la Extrusión de presencia peleando con el
  /// cuerpo y la Extensión del aura al arma con lo que se empuñe (Core, Los
  /// dominios del Ki). Los conjuros y poderes psíquicos que se lanzan con la
  /// Proyección son ataques sobrenaturales.
  static String? energyDamageSource({required Weapon? weapon, required CombatData? combat}) {
    if (weapon == null) return null;
    if (weapon.damagesEnergy ?? false) return 'el arma daña energía';

    final name = CombatData.normalizeTrait('${weapon.name} ${weapon.type ?? ''}');
    if (name.contains('proyeccion')) return 'ataque sobrenatural';

    // Planillas: la característica o lo especial del arma lo dicen.
    final description = CombatData.normalizeTrait('${weapon.characteristic ?? ''} ${weapon.special ?? ''}');
    if (description.contains('dana energia') || description.contains('mistic')) return 'arma mística';
    if (combat == null) return null;
    if (CombatData.hasTrait(combat.kiAbilities, 'extension del aura')) return 'Extensión del aura al arma';

    if (AdditionalAttackRules.isUnarmed(weapon) && CombatData.hasTrait(combat.kiAbilities, 'extrusion de presencia')) {
      return 'Extrusión de presencia';
    }

    return null;
  }

  static bool blocks({required int barrier, required int baseDamage}) {
    return barrier > 0 && baseDamage < barrier;
  }
}
