import 'package:amt/models/character_model/status_modifier.dart';
import 'package:amt/models/modifiers_state.dart';
import 'package:amt/presentation/components/components.dart';
import 'package:amt/resources/modifier_groups.dart';
import 'package:flutter/material.dart';
import 'package:function_tree/function_tree.dart';
import 'package:logger/web.dart';

class BottomSheetModifiers {
  static Future<void> show(
    BuildContext context,
    ModifiersState state,
    List<StatusModifier> allModifiersBase,
    void Function(ModifiersState) onModifiersChanged,
  ) {
    void toggleModifier(StateSetter setState, StatusModifier modifier) {
      setState(
        () {
          if (state.containsModifier(modifier)) {
            state.removeModifier(modifier);
          } else {
            state.add(modifier);
          }
          onModifiersChanged(state);
        },
      );
    }

    /// Aplica la opción elegida de un grupo excluyente, quitando las demás.
    void selectInGroup(StateSetter setState, List<StatusModifier> options, StatusModifier? selection) {
      setState(
        () {
          for (final option in options) {
            state.removeModifier(option);
          }
          if (selection != null) {
            state.add(selection);
          }
          onModifiersChanged(state);
        },
      );
    }

    final theme = Theme.of(context);
    final subtitleButton = theme.textTheme.bodySmall;
    final allModifiers = allModifiersBase;
    final searchController = TextEditingController();

    return showModalBottomSheet<void>(
      context: context,
      // Sin esto el panel queda limitado a poco más de media pantalla y la
      // lista de penalizadores obliga a desplazarse todo el tiempo.
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final query = searchController.text.trim().toLowerCase();

            bool matches(StatusModifier modifier) => query.isEmpty || modifier.name.toLowerCase().contains(query);

            // Se reparten los modificadores entre los grupos excluyentes y el
            // resto, que sigue mostrandose como interruptores sueltos.
            final grouped = <ModifierGroup, List<StatusModifier>>{};
            final loose = <StatusModifier>[];

            for (final modifier in allModifiers) {
              final group = ModifierGroup.all.where((group) => group.contains(modifier)).firstOrNull;

              if (group == null) {
                loose.add(modifier);
              } else {
                grouped.putIfAbsent(group, () => []).add(modifier);
              }
            }

            // Un grupo se muestra si su nombre coincide con la búsqueda o si
            // alguna de sus opciones coincide.
            final visibleGroups =
                grouped.entries.where((entry) => query.isEmpty || entry.key.label.toLowerCase().contains(query) || entry.value.any(matches)).toList();
            final visibleLoose = loose.where(matches).toList();
            final isEmpty = visibleGroups.isEmpty && visibleLoose.isEmpty;

            return AMTBottomSheet(
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modificadores afectando al personaje',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              state.totalModifierDescription(),
                              style: subtitleButton,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Crear modificador',
                        onPressed: () {
                          final modifier = StatusModifier(name: '');
                          state.add(modifier);
                          Navigator.pop(context);

                          _showModifierCreator(
                            context,
                            modifier: modifier,
                            onEdit: (modifier) {
                              Logger().d(modifier);
                              state
                                ..removeModifier(modifier)
                                ..add(modifier);
                              onModifiersChanged(state);
                            },
                          );
                        },
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        tooltip: 'Quitar todos',
                        onPressed: () {
                          setState(() => state.clear());
                          onModifiersChanged(state);
                        },
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Buscar penalizador…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () => setState(searchController.clear),
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
              children: [
                if (isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('Sin resultados para "$query"', style: subtitleButton),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // En pantallas anchas se reparte en columnas para que
                      // entren muchos más modificadores sin desplazarse.
                      const spacing = 8.0;
                      const minColumnWidth = 300.0;
                      final columns = (constraints.maxWidth / minColumnWidth).floor().clamp(1, 4);
                      final itemWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;

                      return Wrap(
                        spacing: spacing,
                        // Más aire entre filas: cada grupo lleva su etiqueta
                        // encima del campo.
                        runSpacing: 14,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          for (final entry in visibleGroups)
                            SizedBox(
                              width: itemWidth,
                              child: _groupDropdown(
                                theme: theme,
                                group: entry.key,
                                options: entry.value,
                                state: state,
                                onSelected: (selection) => selectInGroup(setState, entry.value, selection),
                              ),
                            ),
                          for (final modifier in visibleLoose)
                            SizedBox(
                              width: itemWidth,
                              child: _modifierTile(
                                theme: theme,
                                modifier: modifier,
                                subtitleStyle: subtitleButton,
                                selected: state.containsModifier(modifier),
                                onToggle: () => toggleModifier(setState, modifier),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Desplegable de selección única para un grupo de modificadores
  /// mutuamente excluyentes.
  static Widget _groupDropdown({
    required ThemeData theme,
    required ModifierGroup group,
    required List<StatusModifier> options,
    required ModifiersState state,
    required void Function(StatusModifier?) onSelected,
  }) {
    final selected = options.where(state.containsModifier).firstOrNull;
    final isActive = selected != null;

    // La etiqueta va encima del campo y no flotando sobre el borde: en una
    // grilla apretada el label flotante se recorta contra la fila de arriba.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            group.label,
            style: theme.textTheme.labelMedium!.copyWith(
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        DropdownButtonFormField<StatusModifier?>(
          initialValue: selected,
          isExpanded: true,
          style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            fillColor: isActive ? theme.colorScheme.secondaryContainer : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: [
            DropdownMenuItem<StatusModifier?>(
              child: Text('Ninguno', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ),
            for (final option in options)
              DropdownMenuItem<StatusModifier?>(
                value: option,
                child: Text(
                  '${group.optionLabel(option)}  ·  ${option.description()}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onSelected,
        ),
      ],
    );
  }

  /// Fila compacta de un modificador, con su estado de activación.
  static Widget _modifierTile({
    required ThemeData theme,
    required StatusModifier modifier,
    required TextStyle? subtitleStyle,
    required bool selected,
    required VoidCallback onToggle,
  }) {
    return Material(
      color: selected ? theme.colorScheme.secondaryContainer : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      modifier.name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      modifier.description(),
                      overflow: TextOverflow.ellipsis,
                      style: subtitleStyle,
                    ),
                  ],
                ),
              ),
              Switch(
                value: selected,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showModifierCreator(BuildContext context, {required StatusModifier modifier, required void Function(StatusModifier) onEdit}) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return AMTBottomSheet(
          title: const Text('Añadir modificador'),
          children: [
            AMTTextFormField(
              label: 'Nombre',
              text: modifier.name,
              onChanged: (value) {
                modifier.name = value;
                onEdit(modifier);
              },
            ),
            const SizedBox(
              height: 16,
            ),
            AMTTextFormField(
              label: 'Ataque',
              text: modifier.attack.toString(),
              onChanged: (value) {
                modifier.attack = _parseInput(value);
                onEdit(modifier);
              },
            ),
            const SizedBox(
              height: 16,
            ),
            AMTTextFormField(
              label: 'Esquiva',
              text: modifier.dodge.toString(),
              onChanged: (value) {
                modifier.dodge = _parseInput(value);
                onEdit(modifier);
              },
            ),
            const SizedBox(
              height: 16,
            ),
            AMTTextFormField(
              label: 'Parada',
              text: modifier.parry.toString(),
              onChanged: (value) {
                modifier.parry = _parseInput(value);
                onEdit(modifier);
              },
            ),
            const SizedBox(
              height: 16,
            ),
            AMTTextFormField(
              label: 'Turno',
              text: modifier.turn.toString(),
              onChanged: (value) {
                modifier.turn = _parseInput(value);
                onEdit(modifier);
              },
            ),
            const SizedBox(
              height: 16,
            ),
            AMTTextFormField(
              label: 'Acciones',
              text: modifier.physicalAction.toString(),
              onChanged: (value) {
                modifier.physicalAction = _parseInput(value);
                onEdit(modifier);
              },
            ),
            const SizedBox(
              height: 16,
            ),
          ],
        );
      },
    );
  }

  static int _parseInput(String value) {
    try {
      return value.interpret().toInt();
    } catch (e) {
      return 0;
    }
  }
}
