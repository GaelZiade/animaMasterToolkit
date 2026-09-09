import 'package:amt/models/enums.dart';
import 'package:amt/models/roll.dart';
import 'package:amt/presentation/bottom_sheet_modifiers.dart';
import 'package:amt/presentation/characters/modifiers_card.dart';
import 'package:amt/presentation/combat/custom_combat_card.dart';
import 'package:amt/presentation/components/components.dart';
import 'package:amt/presentation/states/characters_page_state.dart';
import 'package:amt/resources/modifiers.dart';
import 'package:amt/utils/assets.dart';
import 'package:amt/utils/status_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CombatAttackCard extends StatelessWidget {
  const CombatAttackCard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CharactersPageState>();
    final theme = Theme.of(context);
    final attackState = appState.combatState.attack;
    final character = attackState.character;
    final weapon = character?.selectedWeapon();
    final isVariableDamage = weapon?.variableDamage ?? false;

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
                      onPressed: () {
                        BottomSheetModifiers.show(
                          context,
                          attackState.modifiers,
                          Modifiers.getSituationalModifiers(ModifiersType.attack),
                          appState.updateAttackingModifiers,
                        );
                      },
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
              'Cubre al menos la mitad del cuerpo: dobla el daño',
              style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
