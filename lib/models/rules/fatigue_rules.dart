import 'dart:math';

import 'package:amt/models/character_model/status_modifier.dart';

/// Agotamiento: el penalizador que produce el Cansancio bajo (Core, Tabla 27).
abstract class FatigueRules {
  /// Negativo a toda acción según los puntos de Cansancio que quedan.
  static const _penalties = [-120, -80, -40, -20, -10];

  /// Penalizador para [actual] puntos de Cansancio sobre [maximum].
  ///
  /// Con 4 puntos o menos aplica a toda acción, y a la iniciativa la mitad
  /// (Estados y Accidentes). Quien tiene naturalmente menos de 5 no lo sufre de
  /// entrada: empieza a notarlo cuando pierde el primer punto. Un Cansancio
  /// negativo cuenta como 0.
  static StatusModifier? modifierFor({required int maximum, required int actual}) {
    final remaining = max(0, actual);

    if (remaining > 4 || remaining >= maximum) return null;

    final value = _penalties[remaining];

    return StatusModifier(
      name: 'Cansancio $remaining (automático)',
      attack: value,
      parry: value,
      dodge: value,
      turn: value ~/ 2,
      physicalAction: value,
    );
  }

  /// Estados que afectan al personaje: los elegidos más el cansancio.
  ///
  /// Cuando el cansancio se calcula solo, se ignoran los grados de cansancio
  /// elegidos a mano para no contarlo dos veces.
  static List<StatusModifier> activeModifiers(List<StatusModifier> chosen, StatusModifier? fatigue) {
    return [
      for (final modifier in chosen)
        if (fatigue == null || !modifier.name.endsWith('restantes de cansancio')) modifier,
      if (fatigue != null) fatigue,
    ];
  }
}
