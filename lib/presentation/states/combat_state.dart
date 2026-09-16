import 'dart:math';

import 'package:amt/models/character_model/character.dart';
import 'package:amt/models/enums.dart';
import 'package:amt/models/modifiers_state.dart';
import 'package:amt/models/rules/additional_attack_rules.dart';
import 'package:amt/models/rules/armour_reduction_rules.dart';
import 'package:amt/models/rules/counter_attack_rules.dart';
import 'package:amt/models/rules/damage_barrier_rules.dart';
import 'package:amt/models/rules/mass_rules.dart';
import 'package:amt/models/rules/rules.dart';
import 'package:amt/resources/modifiers.dart';
import 'package:amt/utils/explained_text.dart';

class ScreenCombatStateAttack {
  String roll = '';
  String damage = '';
  String attack = '';

  DamageTypes damageType = DamageTypes.ene;

  /// Ataque cuya area cubre al menos la mitad del cuerpo del defensor.
  ///
  /// Solo cambia algo contra criaturas con acumulacion de dano, que en ese caso
  /// reciben el doble.
  bool areaAttack = false;

  /// Miembros de una masa que alcanza el ataque en área (Tabla 2).
  int areaTargets = 0;

  /// Ataques declarados con el arma principal, contando el primero.
  int declaredAttacks = 1;

  Character? character;

  ModifiersState modifiers = ModifiersState();
}

class ScreenCombatStateDefense {
  String roll = '';
  String armour = '';
  String defense = '';

  DefenseType defenseType = DefenseType.parry;

  /// El defensor con acumulación se protege con un escudo mágico o psíquico.
  bool supernaturalShield = false;

  /// Defensas del asalto que no aplican el penalizador por defensas
  /// adicionales (Lama, Tabla de 2ª Arma: Estilo Defensivo…). -1: ninguna.
  int freeDefenses = 0;

  /// La fila de defensas sin penalizador solo se muestra cuando corresponde
  /// por la ficha o si se activa a mano.
  bool showFreeDefenses = false;

  Character? character;

  ModifiersState modifiers = ModifiersState();
}

class ScreenCombatStateCritical {
  String criticalRoll = '';
  String localizationRoll = '';
  String physicalResistanceBase = '';
  String physicalResistanceRoll = '';
  String damageDone = '';
  String modifierReduction = '';
}

class ScreenCombatState {
  ScreenCombatStateAttack attack = ScreenCombatStateAttack();
  ScreenCombatStateDefense defense = ScreenCombatStateDefense();
  ScreenCombatStateCritical critical = ScreenCombatStateCritical();
  SurpriseType surpriseType = SurpriseType.none;

  /// Mejor Proyección disponible para levantar un escudo sobrenatural.
  ///
  /// La planilla importa la Proyección Mágica y la Psíquica como armas, así que
  /// se toma la defensa de la que sea más alta.
  static int shieldProjectionOf(Character? character) {
    final projections =
        (character?.combat.weapons ?? const []).where((weapon) => weapon.name.toLowerCase().contains('proyecci')).map((weapon) => weapon.defense);

    return projections.isEmpty ? 0 : projections.reduce(max);
  }

  String get criticalLocalization {
    return CombatRules.getCriticalLocalization(critical.localizationRoll);
  }

  /// Ataques adicionales del atacante: tope, penalizadores y ataque en curso.
  AttackPlan? get attackPlan {
    final character = attack.character;

    if (character == null) return null;

    return AdditionalAttackRules.plan(
      weapon: character.selectedWeapon(),
      combat: character.combat,
      declared: attack.declaredAttacks,
    );
  }

  ExplainedText get finalAttackValue {
    final plan = attackPlan;

    return CombatRules.finalAttackValue(
      roll: attack.roll,
      baseAttack: attack.character?.calculateAttack(),
      modifier: attack.attack,
      surpriseType: surpriseType,
      modifiers: attack.modifiers,
      characterStateModifiers: attack.character?.activeModifiers.getAllModifiersForType(ModifiersType.attack) ?? 0,
      massBonus: (attack.character?.profile.isMass ?? false) ? MassRules.attackBonus(MassRules.membersAlive(attack.character!)) : 0,
      additionalAttacksPenalty: plan?.sharedPenalty ?? 0,
      additionalAttacksLabel: plan?.sharedLabel ?? '',
    );
  }

  /// Número de la defensa que cuenta para el penalizador, descontando las que
  /// no lo aplican: con una libre, la tercera defensa penaliza como segunda.
  int? get effectiveDefenseNumber {
    final number = defense.character?.state.defenseNumber;

    if (number == null) return null;
    if (defense.freeDefenses < 0) return 1;

    return max(1, number - defense.freeDefenses);
  }

  ExplainedText get finalDefenseValue {
    return CombatRules.finalDefenseValue(
      roll: defense.roll,
      baseDefense: defense.character?.calculateDefense(defense.defenseType),
      modifier: defense.defense,
      surpriseType: surpriseType,
      modifiers: defense.modifiers,
      defenseType: defense.defenseType.toModifierType(),
      defensesNumber: effectiveDefenseNumber,
      defender: defense.character,
      characterStateModifiers: defense.character?.activeModifiers.getAllModifiersForType(defense.defenseType.toModifierType()) ?? 0,
      supernaturalShield: defense.supernaturalShield,
      shieldProjection: shieldProjectionOf(defense.character),
    );
  }

  /// Bono con el que el defensor puede contraatacar, o null si no puede.
  int? get counterAttackBonus {
    if (attack.character == null || defense.character == null) return null;

    return CounterAttackRules.bonus(
      attack: finalAttackValue.result ?? 0,
      defense: finalDefenseValue.result ?? 0,
      damageAccumulation: defense.character?.profile.damageAccumulation ?? false,
      selene: counterWithSelene,
      sacraAegis: counterWithSacraAegis,
    );
  }

  /// El defensor domina Selene y contraataca sin armas, es decir, con el arte.
  bool get counterWithSelene {
    final defender = defense.character;

    if (defender == null) return false;

    return defender.combat.martialArtGrade('Selene') > 0 && AdditionalAttackRules.isUnarmed(defender.selectedWeapon());
  }

  bool get counterWithSacraAegis => defense.modifiers.getAll().any((modifier) => modifier.name == CounterAttackRules.sacraAegis);

  ExplainedText get calculateFinalAbsorption {
    final attacker = attack.character;
    final reductions = attacker == null
        ? const <ArmourReductionSource>[]
        : ArmourReductionRules.sources(weapon: attacker.selectedWeapon(), combat: attacker.combat);

    return CombatRules.calculateFinalAbsorption(
      armour: defense.character?.combat.armour.calculatedArmour,
      damageType: attack.damageType,
      armourTypeModifier: defense.armour,
      defender: defense.character,
      surpriseType: surpriseType,
      armourReduction: reductions.fold(0, (sum, source) => sum + source.value),
      armourReductionDetail: reductions.map((source) => '${source.label} −${source.value}').join(', '),
    );
  }

  ExplainedText? calculateDamage() {
    return CombatRules.calculateDamage(
      attackValue: finalAttackValue,
      defenseValue: finalDefenseValue,
      finalAbsorption: calculateFinalAbsorption,
      areaAttack: attack.areaAttack,
      massAreaMultiplier: (defense.character?.profile.isMass ?? false)
          ? MassRules.areaDamageMultiplier(targets: attack.areaTargets, members: MassRules.membersAlive(defense.character!))
          : 1,
      baseDamage: CombatRules.calculateBaseDamage(
        weapon: attack.character?.selectedWeapon(),
        damageModifier: attack.damage,
      ),
      defender: defense.character,
      damageBarrier: DamageBarrierRules.strongest(damageBarrierSources),
      ignoresBarrier: DamageBarrierRules.ignores(weapon: attack.character?.selectedWeapon(), damageType: attack.damageType),
    );
  }

  /// Barreras de daño del defensor: la cargada a mano, el Hanja y el Escudo
  /// físico.
  List<DamageBarrierSource> get damageBarrierSources {
    final defender = defense.character;

    if (defender == null) return const [];

    return DamageBarrierRules.sources(
      manual: defender.profile.damageBarrier,
      combat: defender.combat,
      presence: defender.resistances?.presence ?? 0,
    );
  }

  List<ExplainedText> attackResult() {
    final result = <ExplainedText>[];

    final damage = calculateDamage();

    if (damage != null) result.add(damage);

    final additionalRules = ExplainedText(
      title: 'Reglas a tener en cuenta',
      text: 'Reglas a tener en cuenta',
      explanation: 'Algunas reglas que se utilizaron para este cálculo',
    );

    if (defense.character?.profile.damageAccumulation ?? false) {
      additionalRules.explanations
        ..add(
          ExplainedText(
            title: 'Doble daño según área de ataque',
            text: 'Doble daño según área de ataque',
            explanation:
                'Si una criatura con acumulación recibe un Ataque con un área que cubra por lo menos la mitad de su cuerpo, recibirá el doble de daño de lo que indique el resultado',
            reference: BookReference(
              page: 97,
              book: Books.coreExxet,
            ),
            specialRule: SpecialRule.damageAccumulation,
          ),
        )
        ..add(
          ExplainedText(
            title: 'Sorpresa en el ataque',
            text: 'Sorpresa en el ataque',
            explanation:
                'Si la sorpresa ha sido provocada por no saber dónde se encuentra su adversario no puede realizar una devolución ese asalto en contra de dicho individuo.',
            reference: BookReference(
              page: 97,
              book: Books.coreExxet,
            ),
            specialRule: SpecialRule.damageAccumulation,
          ),
        );
    }

    if ((attack.character?.profile.uroboros ?? false) || (defense.character?.profile.uroboros ?? false)) {
      additionalRules.explanations.add(
        ExplainedText(
          title: 'La Sangre de Uroboros',
          text: 'La Sangre de Uroboros',
          explanation:
              'Legado de Uroboros obtiene Sorpresa contra cualquier adversario, superándolo simplemente por un resultado de 100 puntos en lugar de necesitar 150. '
              'Ademas, cuando declara que desea retirarse de un combate, no aplica el penalizador de Flanco a su habilidad de defensa',
          reference: BookReference(
            page: 77,
            book: Books.prometheus,
          ),
          specialRule: SpecialRule.uruboros,
        ),
      );
    }

    if (additionalRules.explanations.isNotEmpty) {
      result.add(additionalRules);
    }

    final critical = CombatRules.criticalDamage(
      defender: defense.character,
      damage: damage?.result ?? 0,
    );

    if (critical != null) result.add(critical);

    final counter = CombatRules.calculateCounterBonus(
      attackValue: finalAttackValue,
      defenseValue: finalDefenseValue,
      defender: defense.character,
    );

    if (counter != null) {
      if (counterWithSelene) {
        counter.add(
          text: 'Selene: el bono se dobla',
          explanation: 'Una maestra de Selene dobla el bono del contraataque si la Acción Respuesta usa este arte marcial (Core, Artes marciales avanzadas)',
        );
      }

      if (counterWithSacraAegis) {
        counter.add(
          text: 'Sacra Aegis: +${CounterAttackRules.sacraAegisBonus} al contraataque',
          explanation: 'La técnica del Alius incrementa en +75 la habilidad del Contraataque',
        );
      }

      if (counterWithSelene || counterWithSacraAegis) counter.add(text: 'Bono total del contraataque: +${counterAttackBonus ?? 0}');

      result.add(counter);
    }

    // Logger().d('counter ${counter?.text}');

    final breakage = CombatRules.calculateBreakage(
      attacker: attack.character,
      defender: defense.character,
      defenseType: defense.defenseType,
    );

    result.add(breakage);

    return result;
  }

  int criticalResultWithReduction({
    required int? criticalResult,
  }) {
    return CombatRules.criticalResultWithReduction(
      reduction: critical.modifierReduction,
      criticalResult: criticalResult,
    );
  }

  ExplainedText criticalResult() {
    return CombatRules.criticalResult(
      damageDone: critical.damageDone,
      criticalRoll: critical.criticalRoll,
      physicalResistanceBase: critical.physicalResistanceBase,
      physicalResistanceRoll: critical.physicalResistanceRoll,
      defender: defense.character,
      criticalBonus: attack.character?.selectedWeapon().criticalBonus ?? 0,
    );
  }

  List<ExplainedText> criticalEffects(ExplainedText criticalResult) {
    return CombatRules.criticalDescription(
      defender: defense.character,
      criticalResult: criticalResult,
    );
  }
}
