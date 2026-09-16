import 'dart:math';

import 'package:amt/utils/int_extension.dart';

/// Contraataque (Core p.87): si la defensa supera al ataque, el defensor puede
/// devolver el golpe con la mitad de la diferencia, redondeada a 5 y con un
/// máximo de 150. Las criaturas con acumulación de daño no pueden (Core p.97).
class CounterAttackRules {
  static const maxBonus = 150;

  /// Bono del contraataque, o null si no hay contraataque posible.
  static int? bonus({
    required int attack,
    required int defense,
    bool damageAccumulation = false,
  }) {
    final difference = defense - attack;

    if (difference <= 0 || damageAccumulation) return null;

    return min((difference ~/ 2).roundToFives, maxBonus);
  }
}
