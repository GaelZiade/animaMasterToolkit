import 'package:amt/models/character_model/consumable_state.dart';
import 'package:amt/models/enums.dart';
import 'package:amt/models/modifiers_state.dart';
import 'package:amt/models/roll.dart';
import 'package:amt/utils/json_utils.dart';
import 'package:hive/hive.dart';

part 'character_state.g.dart';

@HiveType(typeId: 3, adapterName: 'CharacterStateAdapter')
class CharacterState {
  CharacterState({
    required this.currentTurn,
    required this.consumables,
    required this.modifiers,
    this.selectedWeaponIndex = 0,
    this.hasAction = true,
    this.notes = '',
    this.defenseNumber = 1,
    this.turnModifier = '',
    this.isSurprised = 0,
  });
  @HiveField(0)
  int selectedWeaponIndex = 0;
  @HiveField(1)
  bool hasAction = true;
  @HiveField(2)
  List<ConsumableState> consumables = [];
  @HiveField(3)
  String notes = '';
  @HiveField(4)
  Roll currentTurn = Roll(description: '', roll: 0, rolls: []);
  @HiveField(5)
  String turnModifier = '';
  @HiveField(6)
  int defenseNumber = 1;
  @HiveField(7)
  ModifiersState modifiers = ModifiersState();
  @HiveField(8)
  int isSurprised;

  Map<String, dynamic> toJson() {
    return {
      'currentTurn': currentTurn.toJson(),
      'consumables': consumables.map((e) => e.toJson()).toList(),
      'modifiers': modifiers.toJson(),
      'selectedWeaponIndex': selectedWeaponIndex,
      'hasAction': hasAction,
      'notes': notes,
      'defenseNumber': defenseNumber,
      'turnModifier': turnModifier,
      'isSurprised': isSurprised,
    };
  }

  static CharacterState? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final consumables = _unifyKi(json.getList('consumables').map(ConsumableState.fromJson).nonNulls.toList());

    return CharacterState(
      currentTurn: Roll.fromJson(json.getMap('currentTurn')) ?? Roll(description: '', roll: 0, rolls: []),
      consumables: consumables,
      modifiers: ModifiersState.fromJson(json.getMap('modifiers')) ?? ModifiersState(),
      selectedWeaponIndex: JsonUtils.integer(json['selectedWeaponIndex'], 0),
      hasAction: JsonUtils.boolean(json['hasAction']),
      notes: JsonUtils.string(json['notes'], ''),
      defenseNumber: JsonUtils.integer(json['defenseNumber'], 1),
      turnModifier: JsonUtils.string(json['turnModifier'], ''),
      isSurprised: JsonUtils.integer(json['isSurprised'], 0),
    );
  }

  /// Une en una sola reserva los Ki repartidos por Caracteristica.
  ///
  /// Las partidas guardadas antes de adoptar la Reserva de Ki unificada traen
  /// un consumible por Caracteristica ("Ki/AGI", "Ki/VOL"...). Se suman al
  /// abrirlas para no tener que reimportar las fichas.
  static List<ConsumableState> _unifyKi(List<ConsumableState> consumables) {
    final perAttribute = consumables.where((element) => element.name.startsWith('Ki/')).toList();

    if (perAttribute.isEmpty) return consumables;

    final unified = ConsumableState(
      name: 'Ki',
      maxValue: perAttribute.fold(0, (total, element) => total + element.maxValue),
      actualValue: perAttribute.fold(0, (total, element) => total + element.actualValue),
      step: perAttribute.fold(0, (total, element) => total + element.step),
      description: 'Reserva de Ki unificada: suma de los puntos de todas las Características',
    );

    final result = consumables.where((element) => !element.name.startsWith('Ki/')).toList()
      ..insert(
        consumables.indexOf(perAttribute.first).clamp(0, consumables.length - perAttribute.length),
        unified,
      );

    return result;
  }

  ConsumableState? getConsumable(ConsumableType type) {
    try {
      return consumables.firstWhere((element) => element.type == type);
    } catch (e) {
      return ConsumableState(
        actualValue: 0,
        maxValue: 0,
        name: '',
        step: 1,
        description: '',
      );
    }
  }

  int getLifePointsPercentage() {
    final hitPoints = getConsumable(ConsumableType.hitPoints);

    if (hitPoints == null) return 100;
    if (hitPoints.maxValue == 0) return 100;

    return ((hitPoints.actualValue / hitPoints.maxValue) * 100).toInt();
  }

  int getOtherConsumablePercentage() {
    final other = getFirstOtherConsumable();

    if (other == null) return 100;

    try {
      return ((other.actualValue / other.maxValue) * 100).toInt();
    } catch (e) {
      return 100;
    }
  }

  /// Consumibles entre los que se puede elegir el que sigue la tabla.
  ///
  /// Todo menos la vida, que tiene su propia columna.
  List<ConsumableState> trackableConsumables() {
    return consumables.where(_isTrackable).toList();
  }

  static bool _isTrackable(ConsumableState consumable) {
    return consumable.type != ConsumableType.hitPoints && consumable.name.isNotEmpty;
  }

  /// Elige el consumible que se muestra en la tabla.
  ///
  /// No hace falta guardar la eleccion aparte: la tabla toma el primero de la
  /// lista, asi que basta con adelantarlo, y el orden ya se persiste.
  void trackConsumable(ConsumableState consumable) {
    final index = consumables.indexWhere((element) => element.name == consumable.name);

    if (index < 0) return;

    final tracked = consumables.removeAt(index);
    final first = consumables.indexWhere(_isTrackable);

    consumables.insert(first == -1 ? consumables.length : first, tracked);
  }

  /// Consumible que se muestra en la tabla: el primero que no sea la vida.
  ///
  /// Antes se filtraba por tipo "other" y solo se caia al Cansancio cuando no
  /// habia ninguno, asi que elegir el Cansancio a mano no tenia ningun efecto
  /// mientras el personaje tuviera Ki o Zeon.
  ConsumableState? getFirstOtherConsumable() {
    return consumables.where(_isTrackable).firstOrNull ?? getConsumable(ConsumableType.fatigue);
  }

  CharacterState copy() {
    return CharacterState(
      currentTurn: Roll(description: '', roll: 1, rolls: []),
      consumables: consumables.map((e) => e.copy()).toList(),
      modifiers: ModifiersState(),
    );
  }
}
