import 'package:amt/models/models.dart';
import 'package:amt/presentation/presentation.dart';
import 'package:amt/utils/assets.dart';
import 'package:amt/utils/int_extension.dart';
import 'package:amt/utils/app_theme.dart';
import 'package:amt/utils/status_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CharactersTable extends StatelessWidget {
  const CharactersTable({super.key});

  SizedBox get spacer => const SizedBox(height: 8, width: 8);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CharactersPageState>();
    final theme = Theme.of(context);

    return Column(
      children: [
        spacer,
        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: TextButton.icon(
                onPressed: appState.rollTurns,
                icon: const Icon(Icons.repeat),
                label: const Text(
                  'Iniciativas',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            Flexible(
              child: TextButton.icon(
                onPressed: appState.sheetsLoadingPercentage == -1
                    ? () async {
                        appState.showLoading(
                          message: 'Selecciona las planillas que deseas cargar#Si quieres convertir planillas excel, haz click en el ícono de arriba',
                        );
                        final files = await appState.getCharacters();
                        appState.hideLoading();

                        // El progreso lo reporta parseCharacters al terminar
                        // cada archivo. Antes lo simulaba un temporizador de
                        // 250 ms por archivo, que ni reflejaba el avance real
                        // ni dejaba terminar antes.
                        await appState.parseCharacters(files, appState.updateSheetLoading);

                        // Hasta ahora un fallo de importacion no se veia: el
                        // mensaje se guardaba en el estado y nadie lo mostraba.
                        final error = appState.errorMessage;

                        if (error != null && error.trim().isNotEmpty && context.mounted) {
                          appState.errorMessage = null;

                          await showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('No se pudieron cargar todas las fichas'),
                              content: SingleChildScrollView(child: Text(error)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cerrar'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.upload_file),
                label: const Text(
                  'Cargar Personaje',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            Flexible(
              child: TextButton.icon(
                onPressed: () {
                  CreateCharacter.show(context, appState.addCharacter);
                },
                icon: const Icon(Icons.edit_document),
                label: const Text(
                  'Crear Personaje',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            Flexible(
              child: TextButton.icon(
                onPressed: appState.resetConsumables,
                icon: const Icon(Icons.restore),
                label: const Text(
                  'Restaurar consumibles',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Limpiar mesa',
              // Mismo color que los botones de texto de esta fila.
              color: theme.colorScheme.primary,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: appState.characters.isEmpty
                  ? null
                  : () async {
                      final count = appState.characters.length;
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Limpiar mesa'),
                          content: Text(
                            'Se quitan los $count personajes cargados y el combate en curso. '
                            'Con la sesión iniciada, la partida guardada en la nube también queda vacía.',
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
                            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Limpiar')),
                          ],
                        ),
                      );

                      if (confirmed != true || !context.mounted) return;

                      final removed = appState.clearTable();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Mesa limpia: se quitaron $count personajes'),
                          duration: const Duration(seconds: 8),
                          action: SnackBarAction(
                            label: 'Deshacer',
                            onPressed: () => appState.restoreCharacters(removed),
                          ),
                        ),
                      );
                    },
            ),
          ],
        ),
        spacer,
        // Cabecera de la tabla.
        //
        // Cada titulo era una tarjeta propia, y a esa altura el radio de
        // esquina las convertia en pastillas. Ahora es una franja con una linea
        // debajo, que es como se lee una cabecera de tabla.
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _header(theme, 1, ''),
                _header(theme, 2, 'Nombre'),
                _header(theme, 1, 'HP'),
                _header(theme, 2, 'Turno'),
                Expanded(
                  child: Tooltip(
                    message: 'Aqui se visualiza el primer consumible que tenga el personaje sin ser la vida, puede ser Zeon, Ki o Fatiga por ejemplo',
                    child: _headerText(theme, '?'),
                  ),
                ),
                _header(theme, 5, 'Acciones'),
              ],
            ),
          ),
        ),

        Expanded(
          // ListView.builder solo construye las filas visibles; antes se
          // construian todas las fichas de la partida en cada repintado.
          child: appState.characters.isEmpty
              ? _emptyState(theme)
              : ListView.builder(
                  itemCount: appState.characters.length,
                  itemBuilder: (context, index) {
                    final character = appState.characters[index];

                    return Card(
                      shape: _characterShape(character, appState, theme),
                      child: Row(
                        children: [
                          _cell(
                            size: 1,
                            child: Checkbox(
                              value: character.state.hasAction,
                              onChanged: (value) {
                                character.state.hasAction = value ?? true;
                                appState.updateCharacter(character);
                              },
                            ),
                          ),
                          _cell(
                            size: 2,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Tooltip(
                                    message: character.profile.name,
                                    child: Text(
                                      character.profile.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _cell(
                            size: 1,
                            child: _percentageBar(
                              theme,
                              label: '${character.state.getLifePointsPercentage()}%',
                              percentage: character.state.getLifePointsPercentage(),
                              tooltip: 'Puntos de vida',
                            ),
                          ),
                          _cell(
                            size: 2,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Tooltip(
                                    message: character.state.currentTurn.description,
                                    child: Card(
                                      color: theme.colorScheme.header,
                                      child: Text(
                                        character.state.currentTurn.roll.toString(),
                                        // Cifras tabulares: la columna no baila
                                        // cuando cambian los digitos.
                                        style: theme.textTheme.bodyMedium!.copyWith(
                                          color: theme.colorScheme.onHeader,
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                _surpriseDesc(appState.characters, character, appState, theme),
                              ],
                            ),
                          ),
                          _cell(
                            size: 1,
                            child: _trackedConsumable(context, appState, character, theme),
                          ),
                          _cell(
                            size: 5,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Tooltip(
                                    message: 'Info',
                                    child: IconButton(
                                      icon: const Icon(Icons.info),
                                      onPressed: () {
                                        ShowCharacterInfo.call(context, character, onEdit: appState.updateCharacter);
                                      },
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Atacar',
                                    child: IconButton(
                                      icon: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Assets.knife(theme.colorScheme.onSurfaceVariant),
                                      ),
                                      onPressed: () {
                                        final surprise = SurpriseType.calculate(
                                          attacker: character,
                                          defendant: appState.combatState.defense.character,
                                        );

                                        appState.updateCombatState(
                                          attacking: character,
                                          attackRoll: '',
                                          attackingModifiers: ModifiersState(),
                                          damageModifier: '',
                                          baseAttackModifiers: '',
                                          surprise: surprise,
                                        );
                                      },
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Parada',
                                    child: IconButton(
                                      icon: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Assets.shield(theme.colorScheme.onSurfaceVariant),
                                      ),
                                      onPressed: () {
                                        _updateDefense(
                                          appState,
                                          character,
                                          DefenseType.parry,
                                        );
                                      },
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Esquiva',
                                    child: IconButton(
                                      icon: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Assets.dodging(theme.colorScheme.onSurfaceVariant),
                                      ),
                                      iconSize: 12,
                                      onPressed: () {
                                        _updateDefense(
                                          appState,
                                          character,
                                          DefenseType.dodge,
                                        );
                                      },
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Opciones',
                                    child: IconButton(
                                      icon: const Icon(Icons.settings),
                                      onPressed: () {
                                        ShowCharacterOptions.call(
                                          context,
                                          character,
                                          onRemove: (character) => {appState.removeCharacter(character)},
                                          onEdit: appState.updateCharacter,
                                          onAddCharacter: (character) {
                                            appState.addCharacter(character, isNpc: character.profile.isNpc ?? false);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Sin personajes la tabla quedaba en blanco, sin explicar que hacer.
  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'Todavia no hay personajes en la partida',
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Usa "Cargar Personaje" para importar una planilla de Excel '
              'o un .json, o "Crear Personaje" para armar uno a mano.',
              style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  ShapeBorder? _characterShape(Character character, CharactersPageState appState, ThemeData theme) {
    if (character.state.isSurprised > 0) {
      return _border(theme.colorScheme.danger, width: 2);
    } else if (character.state.isSurprised < 0) {
      return _border(theme.colorScheme.advantage, width: 2);
    }

    return appState.combatState.attack.character?.uuid == character.uuid
        ? _border(theme.colorScheme.primary)
        : appState.combatState.defense.character?.uuid == character.uuid
            ? _border(theme.colorScheme.secondary)
            : _border(Colors.transparent);
  }

  Widget _surpriseDesc(List<Character> characters, Character character, CharactersPageState appState, ThemeData theme) {
    final surprisesTo = <Character>[];
    final getsSurprisedFrom = <Character>[];

    for (final element in characters) {
      final surprise = SurpriseType.calculate(
        attacker: element,
        defendant: character,
      );

      if (surprise == SurpriseType.attacker) {
        getsSurprisedFrom.add(element);
      } else if (surprise == SurpriseType.defender) {
        surprisesTo.add(element);
      }
    }

    var background = Colors.transparent;

    if (surprisesTo.isNotEmpty && getsSurprisedFrom.isNotEmpty) {
      background = theme.colorScheme.neutralContainer;
    } else if (surprisesTo.isNotEmpty) {
      background = theme.colorScheme.advantageContainer;
    } else if (getsSurprisedFrom.isNotEmpty) {
      background = theme.colorScheme.dangerContainer;
    }

    final surprisesToMessage = surprisesTo.isNotEmpty
        ? <InlineSpan>[
            const TextSpan(
              text: 'Sorprende a:\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: surprisesTo.map((e) => e.profile.name).join('\n'),
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ]
        : <InlineSpan>[];

    final surprisesFromMessage = getsSurprisedFrom.isNotEmpty
        ? <InlineSpan>[
            if (surprisesTo.isNotEmpty) const TextSpan(text: '\n'),
            const TextSpan(
              text: 'Es sorprendido por:\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: getsSurprisedFrom.map((e) => e.profile.name).join('\n'),
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ]
        : <InlineSpan>[];

    return MouseRegion(
      onEnter: (e) {
        for (final element in surprisesTo) {
          element.state.isSurprised = -1;
        }
        for (final element in getsSurprisedFrom) {
          element.state.isSurprised = 1;
        }
        appState.notify();
      },
      onExit: (e) {
        for (final element in characters) {
          element.state.isSurprised = 0;
        }
        appState.notify();
      },
      child: Tooltip(
        richMessage: TextSpan(
          text: '',
          children: <InlineSpan>[...surprisesToMessage, ...surprisesFromMessage],
        ),
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
            border: Border.all(
              color: character.profile.uroboros ?? false ? theme.colorScheme.uroboros : theme.colorScheme.outlineVariant,
              width: character.profile.uroboros ?? false ? 1 : 0,
            ),
          ),
          child: SizedBox(
            width: 24,
            height: 24,
            child: Assets.surprised(
              surprisesTo.isEmpty && getsSurprisedFrom.isEmpty ? theme.colorScheme.outlineVariant : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  ShapeBorder _border(Color color, {double width = 1}) {
    // Rectangulo redondeado y no StadiumBorder: la fila es baja y con el borde
    // de estadio quedaba completamente ovalada.
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      side: BorderSide(color: color, width: width),
    );
  }

  /// Indicador del recurso que se sigue para este personaje.
  ///
  /// Se elige solo al importar, pero no siempre se puede acertar, asi que al
  /// pulsarlo se puede cambiar entre las reservas que tenga el personaje.
  Widget _trackedConsumable(
    BuildContext context,
    CharactersPageState appState,
    Character character,
    ThemeData theme,
  ) {
    final tracked = character.state.getFirstOtherConsumable();
    final options = character.state.trackableConsumables();
    final percentage = character.state.getOtherConsumablePercentage();

    final indicator = _percentageBar(
      theme,
      label: tracked?.actualValue.toString() ?? '',
      percentage: percentage,
    );

    if (options.length < 2) {
      return Tooltip(
        message: '${tracked?.name ?? ''}: ${tracked?.description ?? ''}',
        child: indicator,
      );
    }

    return PopupMenuButton<ConsumableState>(
      tooltip: 'Recurso seguido: ${tracked?.name ?? '-'}. Pulsa para cambiarlo.',
      padding: EdgeInsets.zero,
      onSelected: (consumable) {
        character.state.trackConsumable(consumable);
        appState.updateCharacter(character);
      },
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<ConsumableState>(
            value: option,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(option.name),
                const SizedBox(width: 16),
                Text(
                  '${option.actualValue}/${option.maxValue}',
                  style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
      ],
      child: indicator,
    );
  }

  /// Barra de proporcion con su cifra encima.
  ///
  /// Reemplaza al indicador circular: la cifra iba centrada dentro del circulo
  /// y en cuanto pasaba de dos caracteres se salia del trazo. Una barra ademas
  /// se lee mejor en una fila de tabla, donde sobra ancho y falta alto.
  Widget _percentageBar(
    ThemeData theme, {
    required String label,
    required int percentage,
    String? tooltip,
  }) {
    final clamped = (percentage.clamp(0, 100)) / 100;

    final bar = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 5,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(percentage.percentageColor(lastTransparent: false)),
            ),
          ),
        ],
      ),
    );

    return tooltip == null ? bar : Tooltip(message: tooltip, child: bar);
  }

  Widget _header(ThemeData theme, int size, String text) {
    return Expanded(flex: size, child: _headerText(theme, text));
  }

  Widget _headerText(ThemeData theme, String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelMedium!.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _cell({required int size, required Widget child}) {
    return Expanded(flex: size, child: child);
  }

  void _updateDefense(
    CharactersPageState appState,
    Character character,
    DefenseType type,
  ) {
    final physicalResistance = character.resistances?.physicalResistance;
    final surprise = SurpriseType.calculate(
      attacker: appState.combatState.attack.character,
      defendant: character,
    );

    appState.updateCombatState(
      defendant: character,
      defenseRoll: '0',
      defenderModifiers: ModifiersState(),
      armourModifier: '',
      defenseType: type,
      physicalResistanceBase: physicalResistance.toString(),
      baseDefenseModifiers: '',
      surprise: surprise,
    );
  }
}
