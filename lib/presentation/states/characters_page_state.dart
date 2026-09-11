import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:amt/models/character_model/character.dart';
import 'package:amt/models/enums.dart';
import 'package:amt/models/modifiers_state.dart';
import 'package:amt/models/rules/combat_traits.dart';
import 'package:amt/models/rules/rules.dart';
import 'package:amt/presentation/states/combat_state.dart';
import 'package:amt/utils/xlsx/xlsx_character_parser.dart';
import 'package:amt/utils/string_extension.dart';
import 'package:enough_convert/windows.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class SafeBox {
  SafeBox() {
    openBox('characters');
  }

  Box<Character>? _box;

  Future<void> openBox(String name) async {
    try {
      _box = await Hive.openBox(name);
    } catch (e) {
      await Hive.deleteBoxFromDisk(name);
      _box = await Hive.openBox(name);
    }
  }

  void add(Character character) async {
    try {
      await _box?.add(character);
    } catch (e) {
      print(e);
    }
  }

  Iterable<Character> get values {
    return _box?.values.cast<Character>() ?? [];
  }
}

class CharactersPageState extends ChangeNotifier {
  CharactersPageState() {
    initAsync();
  }

  List<Character> characters = [];
  ScreenCombatState combatState = ScreenCombatState();
  String? errorMessage = '';
  int pageSelected = 0;
  bool isLoading = false;
  String? message;
  String? campaignName;
  int? campaignIndex = 1;

  double sheetsLoadingPercentage = -1;

  Map<String, bool> explanationsExpanded = {};

  late SafeBox _box = SafeBox();

  void stepSheetLoading() {
    if (sheetsLoadingPercentage > 0.9) {
      sheetsLoadingPercentage = sheetsLoadingPercentage + 0.0010;
    } else if (sheetsLoadingPercentage > 0.75) {
      sheetsLoadingPercentage = sheetsLoadingPercentage + 0.0025;
    } else if (sheetsLoadingPercentage > 0.5) {
      sheetsLoadingPercentage = sheetsLoadingPercentage + 0.0050;
    } else {
      sheetsLoadingPercentage = sheetsLoadingPercentage + 0.0100;
    }
    notifyListeners();
  }

  void changeCampaignName(String name) {
    campaignName = name;
    notifyListeners();
  }

  void changeCampaign(int index) {
    campaignIndex = index;
    notifyListeners();
  }

  void updateSheetLoading(double value) {
    sheetsLoadingPercentage = value;
    notifyListeners();
  }

  Map<String, dynamic> getJsonSnapshot() {
    final charactersJson = characters.map((e) => e.toJson()).toList();

    return {
      'characters': charactersJson,
      'name': campaignName,
    };
  }

  Future<void> loadJsonSnapshot(Map<String, dynamic> json) async {
    final charactersJson = (json['characters'] as List).map((e) => Character.fromJson(e as Map<String, dynamic>)).whereType<Character>().toList();

    characters = charactersJson;
    this.campaignName = json['name'] as String?;

    for (final element in characters) {
      _box.add(element);
      notifyListeners();
    }
  }

  void showLoading({String? message}) {
    this.message = message;
    isLoading = true;
    notifyListeners();
  }

  void hideLoading({String? message}) {
    this.message = null;
    isLoading = false;
    notifyListeners();
  }

  Future<void> initAsync() async {
    characters.addAll(_box.values.toList());
    notifyListeners();
  }

  void toggleExplanationStatus(String name) {
    if (explanationsExpanded.containsKey(name)) {
      explanationsExpanded[name] = !explanationsExpanded[name]!;
    } else {
      explanationsExpanded[name] = true;
    }
    notifyListeners();
  }

  void addCharacter(Character character, {bool isNpc = false}) {
    // Numbering, get all characters with # in the name:
    var maxValue = characters.where((element) => element.nameNormalized() == character.nameNormalized()).length;
    for (final element in characters.where(
      (element) => element.nameNormalized() == character.nameNormalized(),
    )) {
      final split = element.profile.name.split('#');
      final value = int.tryParse(split.last);
      maxValue = max(value ?? 0, maxValue);
    }

    if (isNpc) {
      final newChar = character.copyWith(
        uuid: const Uuid().v4(),
        isNpc: isNpc,
        number: maxValue + 1,
      );
      characters.add(newChar);
      _box.add(newChar);
    } else {
      if (maxValue > 0) {
        // Se numera sobre el nombre base: sin esto, duplicar "PJ #2" daba
        // "PJ #2 #3", y cada copia sucesiva sumaba otro sufijo.
        final baseName = character.profile.name.split('#').first.trim();
        character.profile.name = '$baseName #${maxValue + 1}';
      }

      characters.add(character);
      _box.add(character);
    }

    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }

  void removeAllNPC() {
    for (final char in characters) {
      if (char.profile.isNpc ?? false) {
        char.delete();
      }
    }
    characters.removeWhere((element) => element.profile.isNpc ?? false);
    notifyListeners();
  }

  /// Deja la mesa vacía: quita todos los personajes y el combate en curso.
  ///
  /// Devuelve los personajes quitados para poder deshacerlo.
  List<Character> clearTable() {
    final removed = [...characters];

    for (final character in removed) {
      try {
        character.delete();
      } catch (e) {
        print(e);
      }
    }

    characters.clear();
    combatState = ScreenCombatState();
    notifyListeners();

    return removed;
  }

  /// Vuelve a poner en la mesa los personajes quitados al limpiarla, con su
  /// estado. Se reconstruyen desde su JSON, igual que al importar una partida,
  /// porque un objeto ya borrado del almacenamiento no se puede volver a
  /// guardar tal cual.
  void restoreCharacters(List<Character> removed) {
    for (final character in removed) {
      final restored = Character.fromJson(character.toJson());

      if (restored == null) continue;

      characters.add(restored);
      _box.add(restored);
    }

    notifyListeners();
  }

  void updatePageSelected(int index) {
    pageSelected = index;
    notifyListeners();
  }

  void updateAttackingModifiers(ModifiersState modifiers) {
    combatState.attack.modifiers = modifiers;
    notifyListeners();
  }

  void updateDefenderModifiers(ModifiersState modifiers) {
    combatState.defense.modifiers = modifiers;
    notifyListeners();
  }

  void removeDefendant() {
    combatState.defense.character = null;

    notifyListeners();
  }

  void removeAttacker() {
    combatState.attack.character = null;
    notifyListeners();
  }

  void updateCombatState({
    String? attackRoll,
    String? damageModifier,
    Character? attacking,
    Character? defendant,
    ModifiersState? attackingModifiers,
    ModifiersState? defenderModifiers,
    String? defenseRoll,
    String? armourModifier,
    DefenseType? defenseType,
    DamageTypes? damageType,
    String? criticalRoll,
    String? physicalResistanceBase,
    String? physicalResistanceRoll,
    String? damageDone,
    String? localizationRoll,
    String? modifierReduction,
    String? baseAttackModifiers,
    String? baseDefenseModifiers,
    SurpriseType? surprise,
    bool? areaAttack,
    int? areaTargets,
    bool? supernaturalShield,
    int? declaredAttacks,
    int? freeDefenses,
    bool? showFreeDefenses,
  }) {
    // Los ataques declarados son de ese atacante: al cambiarlo vuelven a uno.
    if (attacking != null) combatState.attack.declaredAttacks = 1;

    combatState.attack.declaredAttacks = declaredAttacks ?? combatState.attack.declaredAttacks;
    combatState.defense.freeDefenses = freeDefenses ?? combatState.defense.freeDefenses;
    combatState.defense.showFreeDefenses = showFreeDefenses ?? combatState.defense.showFreeDefenses;

    combatState.attack.areaAttack = areaAttack ?? combatState.attack.areaAttack;
    combatState.attack.areaTargets = areaTargets ?? combatState.attack.areaTargets;
    combatState.defense.supernaturalShield = supernaturalShield ?? combatState.defense.supernaturalShield;

    combatState.attack.attack = baseAttackModifiers ?? combatState.attack.attack;
    combatState.defense.defense = baseDefenseModifiers ?? combatState.defense.defense;

    combatState.critical.modifierReduction = modifierReduction ?? combatState.critical.modifierReduction;
    combatState.critical.localizationRoll = localizationRoll ?? combatState.critical.localizationRoll;

    combatState.critical.damageDone = damageDone ?? combatState.critical.damageDone;
    combatState.critical.physicalResistanceBase = physicalResistanceBase ?? combatState.critical.physicalResistanceBase;
    combatState.critical.criticalRoll = criticalRoll ?? combatState.critical.criticalRoll;
    combatState.critical.physicalResistanceRoll = physicalResistanceRoll ?? combatState.critical.physicalResistanceRoll;

    combatState.attack.roll = attackRoll ?? combatState.attack.roll;
    combatState.attack.damage = damageModifier ?? combatState.attack.damage;

    combatState.defense.roll = defenseRoll ?? combatState.defense.roll;
    combatState.defense.armour = armourModifier ?? combatState.defense.armour;

    combatState.defense.defenseType = defenseType ?? combatState.defense.defenseType;

    combatState.attack.damageType = damageType ?? combatState.attack.damageType;

    combatState.attack.character = attacking ?? combatState.attack.character;

    // Al elegir atacante se preselecciona el critico principal de su arma, que
    // es el que se usa salvo que se decida lo contrario. Un damageType explicito
    // manda: es el usuario cambiando el tipo a mano.
    if (attacking != null && damageType == null) {
      syncDamageTypeWithWeapon();
    }
    combatState.defense.character = defendant ?? combatState.defense.character;

    // El escudo es una decisión de ese defensor: al cambiarlo se apaga.
    if (defendant != null && supernaturalShield == null) {
      combatState.defense.supernaturalShield = false;
    }

    // Las defensas sin penalizador dependen de la ficha del nuevo defensor.
    if (defendant != null && freeDefenses == null) {
      combatState.defense.freeDefenses = CombatTraits.suggestedFreeDefenses(weapon: defendant.selectedWeapon(), combat: defendant.combat);
    }

    if (defendant != null && showFreeDefenses == null) {
      combatState.defense.showFreeDefenses = combatState.defense.freeDefenses != 0;
    }

    combatState.attack.modifiers = attackingModifiers ?? combatState.attack.modifiers;
    combatState.defense.modifiers = defenderModifiers ?? combatState.defense.modifiers;

    combatState.surpriseType = surprise ?? combatState.surpriseType;

    notifyListeners();
  }

  /// Ajusta el tipo de dano al critico principal del arma seleccionada.
  void syncDamageTypeWithWeapon() {
    final principal = combatState.attack.character?.selectedWeapon().principalDamage;

    if (principal == null) return;

    combatState.attack.damageType = principal;
    notifyListeners();
  }

  void removeCharacter(Character character) {
    characters.remove(character);
    character.delete();
    notifyListeners();
  }

  void rollTurns() {
    for (final character in characters) {
      final allModifiers = character.state.modifiers.getAll();

      for (final element in allModifiers) {
        if (element.isOfCritical ?? false) {
          element
            ..attack = min(element.attack + 5, element.midValue ?? 0)
            ..dodge = min(element.dodge + 5, element.midValue ?? 0)
            ..parry = min(element.parry + 5, element.midValue ?? 0)
            ..physicalAction = min(element.physicalAction + 5, element.midValue ?? 0)
            ..turn = min(element.turn + 5, element.midValue ?? 0);
        }
      }

      // character.state.modifiers.clear();
      character.state.modifiers.setAll(allModifiers);

      character.rollInitiative();
      character.state.hasAction = true;
      character.state.defenseNumber = 1;
    }
    characters.sort(Character.initiativeSort);
    notifyListeners();
  }

  void resetConsumables() {
    for (final character in characters) {
      for (final consumable in character.state.consumables) {
        consumable.actualValue = consumable.maxValue;
      }
      try {
        character.save();
      } catch (e) {
        print(e);
      }
    }
    notifyListeners();
  }

  void updateCharacter(Character? character) {
    if (character == null) return;

    final index = characters.indexWhere((element) => element.uuid == character.uuid);

    characters[index] = character;

    notifyListeners();
    try {
      character.save();
    } catch (e) {
      print(e);
    }
  }

  Future<void> parseCharacters(FilePickerResult? filesPicked, void Function(double) onUpdated) async {
    print(e);

    final failures = <String>[];

    try {
      if (filesPicked != null) {
        var counter = 0;
        final total = filesPicked.files.length;

        if (filesPicked.files.first.bytes != null) {
          // For web
          for (final element in filesPicked.files) {
            onUpdated(counter / total);

            // Un archivo que falla no debe cortar la carga de los demas.
            try {
              if (element.extension == 'json') {
                final jsonFile = const Windows1252Codec().decode(element.bytes!.toList());
                final character = Character.fromJson(jsonFile.jsonMap);
                if (character != null) addCharacter(character);
              } else {
                final parser = XlsxCharacterParser.fromBytes(element.bytes!.toList());
                final characterDecoded = await parser.parse();

                if (characterDecoded != null) addCharacter(characterDecoded);
              }
            } catch (error) {
              failures.add('${element.name}: $error');
            }

            counter = counter + 1;
          }
        } else {
          // For desktop
          final files = filesPicked.paths.map((path) => File(path ?? '')).toList();

          for (final file in files) {
            onUpdated(counter / total);
            print('Progress: $counter / $total');

            try {
              final extension = file.path.split('.').last;
              if (extension == 'json') {
                final json = await file.readAsString(encoding: const Windows1252Codec());
                final character = Character.fromJson(json.jsonMap);
                if (character != null) addCharacter(character);
              } else {
                final parser = XlsxCharacterParser.fromFile(file);
                final characterDecoded = await parser.parse();

                if (characterDecoded != null) addCharacter(characterDecoded);
              }
            } catch (error) {
              failures.add('${file.path.split(RegExp(r'[\/]')).last}: $error');
            }
            counter = counter + 1;
          }
        }
      } else {
        failures.add('No se pudo leer ningun archivo');
      }
    } catch (e) {
      print(e);
      failures.add(e.toString());
    }

    errorMessage = failures.isEmpty ? null : failures.join('\n');

    onUpdated(-1);
  }

  Future<FilePickerResult?> getCharacters() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'xlsm', 'xlsx'],
      allowMultiple: true,
    );

    if (result?.files.isEmpty ?? true) {
      errorMessage = '$errorMessage Sin archivos encontrados';
    }

    return result;
  }
}
