import 'package:amt/lib.dart';
import 'package:amt/models/rules/mass_rules.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ShowCharacterOptions {
  static Future<void> call(
    BuildContext context,
    Character character, {
    required void Function(Character) onRemove,
    required void Function(Character) onEdit,
    required void Function(Character) onAddCharacter,
  }) {
    final theme = Theme.of(context);

    return showModalBottomSheet(
      context: context,
      constraints: BoxConstraints.tight(const Size(750, 500)),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(character.profile.name),
                          IconButton(
                            tooltip: 'Cerrar',
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AMTTextFormField(
                              label: 'Nombre',
                              text: character.profile.name,
                              onChanged: (value) {
                                character.profile.name = value;
                                onEdit(character);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Acumulación de daño',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      '(Seres que no se defienden activamente)',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Switch(
                                  value: character.profile.damageAccumulation ?? false,
                                  onChanged: (value) {
                                    setState(() {
                                      character.profile.damageAccumulation = value;
                                      onEdit(character);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'La Sangre de Uroboros',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      '(Aplica sorpresa con 100 en vez de 150)',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Switch(
                                  value: character.profile.uroboros ?? false,
                                  onChanged: (value) {
                                    setState(() {
                                      character.profile.uroboros = value;
                                      onEdit(character);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AMTTextFormField(
                              label: 'Nivel de pifia',
                              text: (character.profile.fumbleLevel ?? 3).toString(),
                              onChanged: (value) {
                                final fumble = int.tryParse(value);
                                if (fumble != null) {
                                  character.profile.fumbleLevel = fumble;
                                }

                                onEdit(character);
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: AMTTextFormField(
                              label: 'Nivel de crítico',
                              text: (character.profile.critLevel ?? 90).toString(),
                              onChanged: (value) {
                                final crit = int.tryParse(value);
                                if (crit != null) {
                                  character.profile.critLevel = crit;
                                }
                                onEdit(character);
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: AMTTextFormField(
                              label: 'Natura',
                              text: (character.profile.nature ?? 5).toString(),
                              onChanged: (value) {
                                final nature = int.tryParse(value);
                                if (nature != null) {
                                  character.profile.nature = nature;
                                }
                                onEdit(character);
                              },
                              suffixIcon: const Tooltip(
                                message: 'menor de 5 no permite más de un crítico '
                                    '\nEntre 5 y 14 usan el sistema normal de criticos'
                                    "\nSuperior a 15 tienen 'Tirada abierta adicional'",
                                child: Icon(Icons.info),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Valores menores se consideran pifia',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Text(
                              'Valores mayores o iguales se consideran crítico',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Text(
                              'Indica el tipo de tirada critica',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 32,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                // No se arma una masa a partir de otra masa.
                                if (character.profile.isMass) return;

                                final controller = TextEditingController(text: '10');
                                final members = await showDialog<int>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Crear masa de enemigos'),
                                    content: TextField(
                                      controller: controller,
                                      autofocus: true,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Cantidad de miembros',
                                        helperText: 'Suma la vida de todos, gana bono de ataque y se defiende sin tirar',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
                                      FilledButton(
                                        onPressed: () {
                                          final value = int.tryParse(controller.text.trim());
                                          Navigator.pop(dialogContext, value != null && value >= 2 ? value : null);
                                        },
                                        child: const Text('Crear'),
                                      ),
                                    ],
                                  ),
                                );

                                if (members == null || !context.mounted) return;

                                Navigator.pop(context);
                                onAddCharacter(MassRules.create(character, members));
                              },
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: Assets.uprising(Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                  const Text('Crear masa de enemigos'),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                onAddCharacter(character.copyWith(uuid: const Uuid().v4()));
                              },
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: Assets.faceToFace(Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                  const Text('Duplicar personaje'),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);

                                showDialog<void>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Borrar personaje'),
                                      content: Text('Seguro que desea borrar ${character.profile.name}?'),
                                      actions: [
                                        OutlinedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            onRemove(character);
                                          },
                                          child: const Text('Borrar'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Cancelar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 36,
                                  ),
                                  const Text('Borrar personaje'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 48,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
