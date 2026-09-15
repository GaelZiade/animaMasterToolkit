import 'dart:math';

import 'package:amt/models/combat_data.dart';
import 'package:amt/models/rules/additional_attack_rules.dart';
import 'package:amt/models/weapon.dart';

/// Una fuente de reducción del Tipo de Armadura del defensor.
class ArmourReductionSource {
  const ArmourReductionSource(this.label, this.value);

  final String label;
  final int value;
}

/// Reducción de la TA del defensor por el ataque.
///
/// Fuentes: Core Exxet, "Armas especiales" (cada +5 de calidad resta un tipo);
/// Dominus Exxet, Dumah y "Destruir armadura" (las reducciones se acumulan
/// entre sí). La Tabla de Reducción de Armadura resta 1 por cada vez que se
/// compra; figura en la planilla, no en los manuales digitalizados.
///
/// Lo que depende de algo puntual (técnicas de Ki, conjuros, flecha de mella,
/// el poder de criatura Modificador de armadura) se carga en el arma a mano.
abstract class ArmourReductionRules {
  static List<ArmourReductionSource> sources({required Weapon weapon, required CombatData combat}) {
    final quality = max(0, weapon.quality ?? 0);
    final unarmed = AdditionalAttackRules.isUnarmed(weapon);
    final dumah = unarmed ? combat.martialArtGrade('Dumah') : 0;

    return [
      if (quality >= 5) ArmourReductionSource('Calidad +$quality', quality ~/ 5),
      for (final table in combat.styleTables)
        if (CombatData.normalizeTrait(table).contains('reduccion de armadura')) ArmourReductionSource(table, _timesBought(table)),
      if (dumah > 0) ArmourReductionSource(dumah >= 3 ? 'Dumah (Arcano)' : 'Dumah', dumah >= 3 ? 6 : 2),
      if ((weapon.armourReduction ?? 0) != 0) ArmourReductionSource('Del arma', weapon.armourReduction!),
    ];
  }

  static int total({required Weapon weapon, required CombatData combat}) {
    return sources(weapon: weapon, combat: combat).fold(0, (sum, source) => sum + source.value);
  }

  /// TA efectiva. Los archivos no fijan un mínimo explícito, pero "Sin
  /// armadura" (Destruir armadura) ignora la TA por completo: no se baja de 0.
  static int effectiveArmourType({required int base, int modifier = 0, int reduction = 0}) {
    return max(0, base + modifier - reduction);
  }

  /// "Tabla de Reducción de Armadura (2)" se compró dos veces.
  static int _timesBought(String entry) {
    final match = RegExp(r'\((\d+)\)').firstMatch(entry);

    return max(1, int.tryParse(match?.group(1) ?? '') ?? 1);
  }
}
