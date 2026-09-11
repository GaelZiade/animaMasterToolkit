import 'package:amt/models/character_model/character.dart';
import 'package:amt/models/enums.dart';
import 'package:amt/models/roll.dart';
import 'package:amt/models/rules/additional_attack_rules.dart';
import 'package:amt/models/rules/combat_traits.dart';
import 'package:amt/presentation/bottom_sheet_modifiers.dart';
import 'package:amt/presentation/characters/modifiers_card.dart';
import 'package:amt/presentation/combat/custom_combat_card.dart';
import 'package:amt/presentation/components/components.dart';
import 'package:amt/presentation/states/characters_page_state.dart';
import 'package:amt/resources/modifiers.dart';
import 'package:amt/utils/assets.dart';
import 'package:amt/utils/status_colors.dart';
import 'package:flutter/material.dart';
import 'package:function_tree/function_tree.dart';
import 'package:provider/provider.dart';

class CombatAttackCard extends StatelessWidget {
  const CombatAttackCard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CharactersPageState>();
    final theme = Theme.of(context);
    final attackState = appState.combatState.attack;
    final defenderIsMass = appState.combatState.defense.character?.profile.isMass ?? false;
    final character = attackState.character;
    final weapon = character?.selectedWeapon();
    final isVariableDamage = weapon?.variableDamage ?? false;
    final attackPlan = appState.combatState.attackPlan;

    // Los ataques extra que corresponden por la ficha aparecen primero.
    void openAttackModifiers() {
      BottomSheetModifiers.show(
        context,
        attackState.modifiers,
        Modifiers.getSituationalModifiers(ModifiersType.attack),
        appState.updateAttackingModifiers,
        suggested: character == null
            ? const []
            : [
                ...AdditionalAttackRules.suggestedExtraAttacks(weapon: character.selectedWeapon(), combat: character.combat),
                ...CombatTraits.suggestedModifiers(character.combat),
              ],
      );
    }

    return CustomCombatCard(
      title: "${character?.profile.name ?? ""} Ataca (Total: ${appState.combatState.finalAttackValue.result})",
      actionTitle: character == null
          ? null
          : IconButton(
              tooltip: 'Quitar atacante',
              icon: Icon(
                Icons.close,
                color: theme.colorScheme.onHeader,
              ),
              onPressed: appState.removeAttacker,
            ),
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Flexible(
                flex: 2,
                child: AMTTextFormField(
                  text: attackState.roll,
                  label: 'Tirada de ataque',
                  onChanged: (value) => {appState.updateCombatState(attackRoll: value)},
                  suffixIcon: IconButton(
                    tooltip: 'Tirar dados de ataque',
                    onPressed: () {
                      appState.updateCombatState(attackRoll: (character?.roll() ?? Roll.roll()).getRollsAsString());
                    },
                    icon: SizedBox.square(
                      dimension: 24,
                      child: Assets.diceRoll(theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (character != null && !isVariableDamage)
                Flexible(
                  child: AMTTextFormField(
                    enabled: false,
                    label: 'Daño base',
                    text: weapon?.damage.toString(),
                    onChanged: (newText) {
                      final newValue = int.tryParse(newText);

                      if (newValue != null) {
                        weapon?.damage = newValue;
                        appState.updateCharacter(character);
                      }
                    },
                  ),
                ),
              if (character != null) const SizedBox(width: 4),
              Flexible(
                flex: 2,
                child: AMTTextFormField(
                  onChanged: (value) {
                    appState.updateCombatState(damageModifier: value);
                  },
                  text: attackState.damage,
                  label: isVariableDamage || character == null ? 'Daño' : 'Modificador',
                  suffixIcon: IconButton(
                    tooltip: 'Borrar modificador de dano',
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      appState.updateCombatState(damageModifier: '');
                    },
                  ),
                ),
              ),
              if (character != null) const SizedBox(width: 12),
              if (character != null)
                isVariableDamage
                    ? ToggleButtons(
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 40),
                        isSelected: [
                          attackState.damageType == DamageTypes.fil,
                          attackState.damageType == DamageTypes.pen,
                          attackState.damageType == DamageTypes.con,
                          attackState.damageType == DamageTypes.fri,
                          attackState.damageType == DamageTypes.cal,
                          attackState.damageType == DamageTypes.ele,
                          attackState.damageType == DamageTypes.ene,
                        ],
                        onPressed: (index) => {appState.updateCombatState(damageType: DamageTypes.values[index])},
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        children: [
                          Text('fil', style: theme.textTheme.bodySmall),
                          Text('pen', style: theme.textTheme.bodySmall),
                          Text('con', style: theme.textTheme.bodySmall),
                          Text('fri', style: theme.textTheme.bodySmall),
                          Text('cal', style: theme.textTheme.bodySmall),
                          Text('ele', style: theme.textTheme.bodySmall),
                          Text('ene', style: theme.textTheme.bodySmall),
                        ],
                      )
                    : Padding(
                        padding: EdgeInsets.zero,
                        child: ToggleButtons(
                          isSelected: [
                            weapon?.principalDamage == attackState.damageType,
                            weapon?.secondaryDamage == attackState.damageType,
                          ],
                          onPressed: (index) =>
                              {appState.updateCombatState(damageType: index == 0 ? weapon?.principalDamage : weapon?.secondaryDamage)},
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                          children: [
                            Text(
                              weapon?.principalDamage?.name ?? 'con',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              weapon?.secondaryDamage?.name ?? 'con',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
            ],
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (character != null)
                          Flexible(
                            child: Tooltip(
                              message: character.calculateAttack(),
                              child: AMTTextFormField(
                                enabled: false,
                                label: 'Ataque',
                                text: character.calculateAttack(),
                              ),
                            ),
                          ),
                        if (character != null) const SizedBox(width: 4),
                        Flexible(
                          flex: 2,
                          child: AMTTextFormField(
                            label: character != null ? 'Modificador' : 'Ataque',
                            suffixIcon: TextButton(
                              child: const Text('+Can'),
                              onPressed: () {
                                character?.removeFrom(
                                  1,
                                  ConsumableType.fatigue,
                                );
                                appState
                                  ..updateCombatState(baseAttackModifiers: '${attackState.attack}+15')
                                  ..updateCharacter(character);
                              },
                            ),
                            text: attackState.attack,
                            onChanged: (value) => appState.updateCombatState(baseAttackModifiers: value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Flexible(
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: TextButton(
                      onPressed: openAttackModifiers,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Situacionales',
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            attackState.modifiers.totalAttackingDescription(),
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (character != null && attackPlan != null) ...[
          const SizedBox(height: 16),
          _AdditionalAttacks(plan: attackPlan, character: character, onOpenModifiers: openAttackModifiers),
          const SizedBox(height: 8),
        ],
        // Solo tiene efecto contra criaturas con acumulacion de dano, asi que
        // no se muestra en el resto de los combates.
        if (appState.combatState.defense.character?.profile.damageAccumulation ?? false)
          CheckboxListTile(
            value: attackState.areaAttack,
            onChanged: (value) => appState.updateCombatState(areaAttack: value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('Ataque en área', style: theme.textTheme.bodyMedium),
            subtitle: Text(
              defenderIsMass
                  ? 'Contra una masa: multiplica el daño según a cuántos alcanza (Tabla 2)'
                  : 'Cubre al menos la mitad del cuerpo: dobla el daño',
              style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        // Contra una masa el multiplicador depende de cuántos miembros alcanza.
        if (defenderIsMass && attackState.areaAttack)
          SizedBox(
            height: 40,
            child: AMTTextFormField(
              label: 'Enemigos alcanzados',
              text: attackState.areaTargets > 0 ? '${attackState.areaTargets}' : '',
              inputType: TextInputType.number,
              onChanged: (value) => appState.updateCombatState(areaTargets: int.tryParse(value.trim()) ?? 0),
            ),
          ),
        const SizedBox(
          height: 10,
        ),
        SizedBox(
          width: 8000,
          child: ModifiersCard(
            modifiers: attackState.modifiers.getAll(),
            onSelected: (selected) {
              attackState.modifiers.removeModifier(selected);
              appState.updateCombatState(attackingModifiers: attackState.modifiers);
            },
          ),
        ),
      ],
    );
  }
}

/// Ataques del asalto: cuántos se declaran con el arma y el tamaño que fija su
/// penalizador. Los ataques extra (segunda arma, patada, técnicas) son
/// modificadores situacionales; acá se ve el que esté activo.
class _AdditionalAttacks extends StatelessWidget {
  const _AdditionalAttacks({required this.plan, required this.character, required this.onOpenModifiers});

  final AttackPlan plan;
  final Character character;
  final VoidCallback onOpenModifiers;

  static String _signed(int value) => value < 0 ? '−${-value}' : '+$value';

  /// Habilidad de la ficha con los estados del personaje, sin tirada.
  int get _ability {
    try {
      return character.calculateAttack().interpret().toInt();
    } catch (_) {
      return character.selectedWeapon().attack;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<CharactersPageState>();
    final theme = Theme.of(context);
    final weapon = character.selectedWeapon();
    final muted = theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final number = theme.textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final attackState = appState.combatState.attack;
    final activeExtra = attackState.modifiers.getAll().where((modifier) => modifier.name.startsWith(Modifiers.extraAttackPrefix)).firstOrNull;

    final penalty = plan.penaltyPerAttack;
    final sizeText = plan.unarmed
        ? '${plan.penaltySource[0].toUpperCase()}${plan.penaltySource.substring(1)} · ${_signed(penalty ?? 0)} c/u'
        : plan.size == null
            ? 'Elegir tamaño'
            : plan.penaltySize != plan.size
                ? 'Arma ${plan.size!.code} como ${plan.penaltySize!.code} · ${_signed(penalty ?? 0)} c/u'
                : 'Arma ${plan.size!.code} · ${_signed(penalty ?? 0)} c/u';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 12),
        // Título del bloque y tamaño del arma, que fija el penalizador.
        Row(
          children: [
            Expanded(
              child: Text(
                'Ataques del asalto',
                style: theme.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            if (plan.unarmed)
              Tooltip(
                message: 'Desarmado no admite un arma adicional',
                child: Chip(label: Text(sizeText), visualDensity: VisualDensity.compact),
              )
            else
              PopupMenuButton<String>(
                tooltip: 'Tamaño del arma para los ataques adicionales',
                initialValue: weapon.attackSize ?? '',
                onSelected: (code) {
                  weapon.attackSize = code.isEmpty ? null : code;
                  appState.updateCharacter(character);
                },
                itemBuilder: (context) => [
                  for (final size in AttackSize.values) PopupMenuItem(value: size.code, child: Text('${size.label} (${size.code})')),
                  const PopupMenuItem(value: '', child: Text('Deducir del nombre')),
                ],
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(
                    plan.size == null ? Icons.help_outline : Icons.expand_more,
                    size: 18,
                    color: plan.size == null ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                  ),
                  label: Text(sizeText),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Contador de ataques con el arma, con el desglose del tope a la vista.
        Row(
          children: [
            IconButton.outlined(
              tooltip: 'Declarar un ataque menos',
              onPressed: plan.declared > 1 ? () => appState.updateCombatState(declaredAttacks: plan.declared - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 40,
              child: Text('${plan.declared}', style: number, textAlign: TextAlign.center),
            ),
            IconButton.outlined(
              tooltip: 'Declarar un ataque más',
              onPressed: plan.declared < plan.maxAttacks ? () => appState.updateCombatState(declaredAttacks: plan.declared + 1) : null,
              icon: const Icon(Icons.add),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('de ${plan.maxAttacks} posibles con el arma', style: theme.textTheme.bodyMedium),
                  Text(plan.maxAttacksBreakdown, style: muted),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // El ataque extra es un modificador que queda marcado hasta quitarlo:
        // se muestra acá para que no pase desapercibido.
        Align(
          alignment: Alignment.centerLeft,
          child: activeExtra == null
              ? TextButton.icon(
                  onPressed: onOpenModifiers,
                  icon: const Icon(Icons.add),
                  label: const Text('Ataque extra (segunda arma, patada…)'),
                )
              : InputChip(
                  selected: true,
                  showCheckmark: false,
                  avatar: const Icon(Icons.bolt, size: 18),
                  label: Text(
                    'Ataque extra activo: ${activeExtra.name.substring(Modifiers.extraAttackPrefix.length)}'
                    ' · ${activeExtra.attack == 0 ? 'sin penalizador' : _signed(activeExtra.attack)}',
                  ),
                  tooltip: 'Cambiar el ataque extra',
                  onPressed: onOpenModifiers,
                  deleteButtonTooltipMessage: 'Quitar el ataque extra',
                  onDeleted: () {
                    attackState.modifiers.removeModifier(activeExtra);
                    appState.updateAttackingModifiers(attackState.modifiers);
                  },
                ),
        ),
        if (plan.needsSize)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Falta el tamaño del arma: el penalizador por ataques adicionales no se está aplicando.',
              style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.error),
            ),
          ),
        if (plan.additionalAttacks > 0) ...[
          const SizedBox(height: 8),
          Text(
            'HA en cada uno de los ${plan.declared} ataques: ${_ability + plan.sharedPenalty}, sin tirada ni situacionales.',
            style: muted,
          ),
        ],
      ],
    );
  }
}
