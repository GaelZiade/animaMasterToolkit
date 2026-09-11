import 'dart:math';

import 'package:amt/models/character_model/status_modifier.dart';

/// Rasgos del personaje que cambian los negativos por dolor, cansancio y
/// críticos.
class PenaltyTraits {
  const PenaltyTraits({
    this.painAndFatigueImmunity = false,
    this.exhausted = false,
    this.penaltyElimination = false,
    this.voidEssence = false,
  });

  /// Ventaja Inmunidad al dolor y al cansancio: ambos a la mitad (Core).
  final bool painAndFatigueImmunity;

  /// Desventaja Exhausto: dobla los penalizadores por fatiga (Core).
  final bool exhausted;

  /// Habilidad del Ki Eliminación de penalizadores: cansancio y críticos a la
  /// mitad (Core, Dominios del Ki).
  final bool penaltyElimination;

  /// Habilidad del Némesis Esencia de vacío: sin negativos por dolor,
  /// cansancio ni críticos que no dejen carencias físicas (Dominus).
  final bool voidEssence;
}

/// Negativos por dolor, cansancio y críticos, y lo que los reduce.
///
/// No se modifican los estados elegidos: se añaden ajustes con el nombre de su
/// origen, para que el desglose muestre por qué cambia el total.
///
/// Los archivos no dicen cómo combinar varias reducciones. Se aplican en este
/// orden: Esencia de vacío (anula todo), Exhausto, una sola mitad aunque haya
/// dos fuentes, Berserker y por último la tirada de Resistir el dolor.
abstract class PenaltyRules {
  static const painNames = {'Dolor leve', 'Dolor', 'Dolor extremo'};

  /// Estado del Ars Magnus Berserker (Dominus): ignora dolor y cansancio en
  /// las acciones físicas.
  static const berserker = 'Berserker (Ars Magnus)';

  /// Tabla 15: resultado de Resistir el dolor y negativo que anula.
  static const _painResistance = [(80, 10), (120, 20), (140, 30), (180, 40), (240, 50), (280, 60), (320, 70), (440, 80)];

  /// Negativo que anula una tirada de Resistir el dolor.
  static int painResistanceFor(int roll) {
    var cancelled = 0;

    for (final (minimum, value) in _painResistance) {
      if (roll >= minimum) cancelled = value;
    }

    return cancelled;
  }

  static bool isFatigue(StatusModifier modifier) {
    return modifier.name.endsWith('restantes de cansancio') || (modifier.name.startsWith('Cansancio ') && modifier.name.endsWith('(automático)'));
  }

  static bool isPain(StatusModifier modifier) => painNames.contains(modifier.name);

  static bool isCritical(StatusModifier modifier) => modifier.isOfCritical ?? false;

  /// Hay algo que Resistir el dolor podría reducir.
  static bool hasReduciblePenalties(List<StatusModifier> active) => active.any((modifier) => isFatigue(modifier) || isPain(modifier) || isCritical(modifier));

  /// Ajustes que se suman a los estados [active] del personaje.
  static List<StatusModifier> adjustments({
    required List<StatusModifier> active,
    required PenaltyTraits traits,
    int painResistanceRoll = 0,
  }) {
    final fatigue = _sum(active.where(isFatigue));
    final pain = _sum(active.where(isPain));
    // De un crítico solo cuenta la parte de dolor: pasado 50, la otra mitad es
    // deterioro físico y persiste.
    final critical = active.where(isCritical).fold(const _Penalty.zero(), (total, modifier) => total + _Penalty.painOf(modifier));

    if (traits.voidEssence) {
      final total = fatigue + pain + critical;

      return total.isZero ? const [] : [(-total).toModifier('Esencia de vacío')];
    }

    final offsets = <String, _Penalty>{};

    void offset(String name, _Penalty value) {
      if (value.isZero) return;
      offsets[name] = (offsets[name] ?? const _Penalty.zero()) + value;
    }

    var remainingFatigue = fatigue;

    if (traits.exhausted) {
      offset('Exhausto', fatigue);
      remainingFatigue = fatigue + fatigue;
    }

    if (traits.painAndFatigueImmunity || traits.penaltyElimination) {
      final halved = -remainingFatigue.half;

      offset(traits.painAndFatigueImmunity ? 'Inmunidad al dolor y al cansancio' : 'Eliminación de penalizadores', halved);
      remainingFatigue = remainingFatigue + halved;
    }

    var remainingPain = pain;

    if (traits.painAndFatigueImmunity) {
      final halved = -pain.half;

      offset('Inmunidad al dolor y al cansancio', halved);
      remainingPain = pain + halved;
    }

    var remainingCritical = critical;

    if (traits.penaltyElimination) {
      final halved = -critical.half;

      offset('Eliminación de penalizadores', halved);
      remainingCritical = critical + halved;
    }

    var reducible = remainingFatigue + remainingPain + remainingCritical;

    if (active.any((modifier) => modifier.name == berserker)) {
      // Solo dolor y cansancio, y solo en las acciones físicas.
      final physical = (remainingFatigue + remainingPain).action;
      final ignored = _Penalty(0, 0, 0, 0, -physical);

      offset('Berserker: sin dolor ni cansancio en acciones físicas', ignored);
      reducible = reducible + ignored;
    }

    final cancelled = painResistanceFor(painResistanceRoll);

    if (cancelled > 0) {
      int cap(int remaining, int amount) => remaining < 0 ? min(amount, -remaining) : 0;

      offset(
        'Resistir el dolor (anula hasta $cancelled)',
        _Penalty(
          cap(reducible.attack, cancelled),
          cap(reducible.parry, cancelled),
          cap(reducible.dodge, cancelled),
          cap(reducible.turn, cancelled ~/ 2),
          cap(reducible.action, cancelled),
        ),
      );
    }

    return [
      for (final entry in offsets.entries)
        if (!entry.value.isZero) entry.value.toModifier(entry.key),
    ];
  }

  static _Penalty _sum(Iterable<StatusModifier> modifiers) {
    return modifiers.fold(const _Penalty.zero(), (total, modifier) => total + _Penalty.of(modifier));
  }
}

/// Valores de un modificador por tipo de tirada.
class _Penalty {
  const _Penalty(this.attack, this.parry, this.dodge, this.turn, this.action);

  const _Penalty.zero() : this(0, 0, 0, 0, 0);

  factory _Penalty.of(StatusModifier modifier) {
    return _Penalty(modifier.attack, modifier.parry, modifier.dodge, modifier.turn, modifier.physicalAction);
  }

  /// Parte de dolor de un crítico: lo que excede al deterioro físico.
  factory _Penalty.painOf(StatusModifier modifier) {
    final physical = modifier.midValue ?? 0;

    int pain(int value) => min(0, value - physical);

    return _Penalty(pain(modifier.attack), pain(modifier.parry), pain(modifier.dodge), pain(modifier.turn), pain(modifier.physicalAction));
  }

  final int attack;
  final int parry;
  final int dodge;
  final int turn;
  final int action;

  _Penalty operator +(_Penalty other) {
    return _Penalty(attack + other.attack, parry + other.parry, dodge + other.dodge, turn + other.turn, action + other.action);
  }

  _Penalty operator -() => _Penalty(-attack, -parry, -dodge, -turn, -action);

  /// La mitad, truncada hacia cero.
  _Penalty get half => _Penalty(attack ~/ 2, parry ~/ 2, dodge ~/ 2, turn ~/ 2, action ~/ 2);

  bool get isZero => attack == 0 && parry == 0 && dodge == 0 && turn == 0 && action == 0;

  StatusModifier toModifier(String name) {
    return StatusModifier(name: name, attack: attack, parry: parry, dodge: dodge, turn: turn, physicalAction: action);
  }
}
