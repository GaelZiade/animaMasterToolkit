import 'package:amt/models/combat_data.dart';
import 'package:amt/models/enums.dart';
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

  /// Los manuales no dicen que se sumen: vale la más alta.
  static DamageBarrierSource? strongest(List<DamageBarrierSource> sources) {
    return sources.isEmpty ? null : sources.reduce((best, source) => source.value > best.value ? source : best);
  }

  /// Un ataque que daña energía ignora la barrera: el arma lo tiene marcado o
  /// el ataque va sobre la TA de Energía.
  static bool ignores({required Weapon? weapon, required DamageTypes damageType}) {
    return (weapon?.damagesEnergy ?? false) || damageType == DamageTypes.ene;
  }

  static bool blocks({required int barrier, required int baseDamage, required bool ignored}) {
    return !ignored && barrier > 0 && baseDamage < barrier;
  }
}
