import 'package:amt/models/character_model/status_modifier.dart';
import 'package:amt/models/enums.dart';
import 'package:amt/utils/list_extension.dart';
import 'package:amt/utils/string_extension.dart';

enum ModifiersType { attack, parry, dodge, turn, action }

extension ToModifiersType on DefenseType {
  ModifiersType toModifierType() {
    switch (this) {
      case DefenseType.parry:
        return ModifiersType.parry;
      case DefenseType.dodge:
        return ModifiersType.dodge;
    }
  }
}

class Modifiers {
  /// Ataques fuera del tope de ataques adicionales: segunda arma, patada de
  /// Tae Kwon Do, técnicas. Forman un grupo de selección única.
  static const extraAttackPrefix = 'Ataque extra: ';

  static List<StatusModifier> getSituationalModifiers(ModifiersType type, {bool includeAllDefense = false}) {
    final modifiers = <StatusModifier>[];

    for (final element in _valuesSituational.jsonList) {
      final modifier = StatusModifier.fromJson(element);

      if (modifier == null) continue;

      final value = switch (type) {
        ModifiersType.attack => modifier.attack,
        ModifiersType.parry => modifier.parry,
        ModifiersType.dodge => modifier.dodge,
        ModifiersType.turn => modifier.turn,
        ModifiersType.action => modifier.physicalAction,
      };
      // Una variante sin penalizador ("Presa sin penalizador") sigue siendo una
      // opción válida para ese tipo de tirada: se declara con "keepFor".
      final keepFor = (element['keepFor'] as List<dynamic>?)?.map((entry) => '$entry') ?? const <String>[];

      if (value != 0 || keepFor.contains(type.name)) modifiers.add(modifier);
    }

    return modifiers.map((e) => e.pruneOthers(type, includeAllDefense: includeAllDefense)).toList()
      ..sort((left, right) => left.name.compareTo(right.name));
  }

  static List<StatusModifier> getStatusModifiers() {
    final modifiers = <StatusModifier>[];

    for (final element in _values.jsonList) {
      modifiers.tryAdd(StatusModifier.fromJson(element));
    }

    modifiers.sort((left, right) => left.name.compareTo(right.name));

    return modifiers;
  }

  static const _valuesSituational = '''
[
    {
        "name": "Apuntado: Cuello",
        "attack": "-80"
    },
    {
        "name": "Apuntado: Cabeza",
        "attack": "-60"
    },
    {
        "name": "Apuntado: Codo",
        "attack": "-60"
    },
    {
        "name": "Apuntado: Corazón",
        "attack": "-60"
    },
    {
        "name": "Apuntado: Ingle",
        "attack": "-60"
    },
    {
        "name": "Apuntado: Pie",
        "attack": "-50"
    },
    {
        "name": "Apuntado: Mano",
        "attack": "-40"
    },
    {
        "name": "Apuntado: Rodilla",
        "attack": "-40"
    },
    {
        "name": "Apuntado: Abdomen",
        "attack": "-20"
    },
    {
        "name": "Apuntado: Brazo",
        "attack": "-20"
    },
    {
        "name": "Apuntado: Muslo",
        "attack": "-20"
    },
    {
        "name": "Apuntado: Pantorrilla",
        "attack": "-10"
    },
    {
        "name": "Apuntado: Torso",
        "attack": "-10"
    },
    {
        "name": "Apuntado: Ojo",
        "attack": "-100"
    },
    {
        "name": "Apuntado: Muñeca",
        "attack": "-40"
    },
    {
        "name": "Apuntado: Hombro",
        "attack": "-30"
    },
    {
        "name": "Flanco",
        "attack": -10,
        "parry": -30,
        "dodge": -30,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "De espalda",
        "attack": -30,
        "parry": -80,
        "dodge": -80,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Sorprendido",
        "attack": 0,
        "parry": -90,
        "dodge": -90,
        "turn": 0,
        "type": 2,
        "physicalAction": -90
    },
    {
        "name": "Posición superior",
        "attack": 20,
        "parry": "-",
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Cargando",
        "attack": 10,
        "parry": -10,
        "dodge": -20,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Desenfundar",
        "attack": -25,
        "parry": -25,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": -25
    },
    {
        "name": "Adversario pequeño",
        "attack": -10,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Adversario diminuto",
        "attack": -20,
        "parry": -10,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "A la defensiva",
        "attack": -30,
        "parry": 10,
        "dodge": 10,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "A la ofensiva",
        "attack": 10,
        "parry": -30,
        "dodge": -30,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil Lanzado",
        "attack": 0,
        "parry": -50,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil Disparado",
        "attack": 0,
        "parry": -80,
        "dodge": -30,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil Disparado (maestria en defensa)",
        "attack": 0,
        "parry": -20,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil Disparado (escudo)",
        "attack": 0,
        "parry": -30,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Seraphite arcano",
        "attack": 30,
        "parry": -50,
        "dodge": -50,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Seraphite base",
        "attack": 20,
        "parry": -30,
        "dodge": -30,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Presa",
        "attack": -40,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil: Bocajarro",
        "attack": 30,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil: Apuntar por 1 turno",
        "attack": 10,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil: Apuntar por 2 turno",
        "attack": 20,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil: Apuntar por 3 turno",
        "attack": 30,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil: Blanco grande",
        "attack": 30,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil: Cambiar blanco",
        "attack": -10,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil: Defendió en este asalto",
        "attack": -40,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil: Se desplazó más de 1 / 4 del movimiento",
        "attack": -10,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil: El blanco se mueve a Vel. 10",
        "attack": -40,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil: El blanco se mueve a más de Vel. +10",
        "attack": -60,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil: El blanco se mueve a más de Vel. 8",
        "attack": -20,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil: El blanco tiene cobertura",
        "attack": -40,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil: Escasa visibilidad",
        "attack": -20,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil: Moviendose al máximo de velocidad",
        "attack": -50,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Proyectil: Atacar por encima del alcance efectivo del arma",
        "attack": -30,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Ataque extra: Segunda arma",
        "attack": -40
    },
    {
        "name": "Ataque extra: Segunda arma con Ambidestría",
        "attack": -10
    },
    {
        "name": "Ataque extra: Patada de Tae Kwon Do (Base)",
        "attack": -30
    },
    {
        "name": "Ataque extra: Patada de Tae Kwon Do (Avanzado)",
        "attack": -20
    },
    {
        "name": "Ataque extra: Patada de Tae Kwon Do (Supremo)",
        "attack": 0,
        "keepFor": ["attack"]
    },
    {
        "name": "Ataque extra: Técnica de Ki sin penalizador",
        "attack": 0,
        "keepFor": ["attack"]
    },
    {"name": "Derribo", "attack": -30},
    {"name": "Derribo con arma corta", "attack": -60},
    {"name": "Derribo a mitad (Grappling, Sambo)", "attack": -15},
    {"name": "Derribo sin penalizador (Grappling avanzado, Aikido en contraataque)", "attack": 0, "keepFor": ["attack"]},
    {"name": "Presa a mitad (Pankration, Grappling, Sambo avanzado)", "attack": -20},
    {"name": "Presa sin penalizador (Grappling avanzado, Aikido en contraataque)", "attack": 0, "keepFor": ["attack"]},
    {"name": "Presa con arma sin regla de Presa (Tabla de Presa Inusual)", "attack": -60},
    {"name": "Desarmar", "attack": -40},
    {"name": "Desarmar a mitad (Tabla de Desarme, Sambo)", "attack": -20},
    {"name": "Desarmar sin penalizador (Emp, Malla-yuddha supremo en contraataque)", "attack": 0, "keepFor": ["attack"]},
    {"name": "Ataque en área", "attack": -50},
    {"name": "Ataque en área a mitad (Tabla de Área, Sambo avanzado)", "attack": -25},
    {"name": "Ataque en área con Capoeira supremo", "attack": -10},
    {"name": "Engatillar", "attack": -100},
    {"name": "Engatillar a mitad (Tabla de Precisión)", "attack": -50},
    {"name": "Crítico secundario", "attack": -10},
    {"name": "Crítico secundario sin penalizador (Tabla de Ataque Inusual)", "attack": 0, "keepFor": ["attack"]},
    {"name": "Dejar inconsciente sin arma contundente", "attack": -40},
    {"name": "Moverse más de 1/4 del movimiento", "attack": -25, "physicalAction": -25},
    {"name": "Desenfundar con Batto jutsu (arma a una mano)", "attack": 0, "parry": 0, "keepFor": ["attack", "parry"]},
    {"name": "Flanco con Soo Bahk", "attack": -10, "parry": -15, "dodge": -15},
    {"name": "Flanco con Soo Bahk avanzado", "keepFor": ["attack", "parry", "dodge"]},
    {"name": "De espalda con Hanja", "keepFor": ["attack", "parry", "dodge"]},
    {"name": "Proyectil Lanzado con Kuan", "parry": -25},
    {"name": "Proyectil Disparado con Kuan avanzado", "parry": -40, "dodge": -15},
    {"name": "Proyectil sin penalizador (Kuan supremo)", "keepFor": ["parry", "dodge"]},
    {"name": "Apartar a otro", "parry": -30, "dodge": -30},
    {"name": "Apartar a otro (Tabla de Guardaespaldas)", "parry": -10, "dodge": -10},
    {"name": "Resistir el golpe", "parry": -80, "dodge": -80},
    {"name": "Contraataque con Boxeo avanzado", "attack": 10},
    {"name": "Xing Quan: +10 contra su adversario", "attack": 10},
    {"name": "Xing Quan: +20 contra su adversario (avanzado)", "attack": 20},
    {"name": "Xing Quan: +30 contra su adversario (supremo)", "attack": 30}
]
''';

  static const _values = '''
[
    {
        "name": "4 puntos restantes de cansancio",
        "attack": "-10",
        "parry": -10,
        "dodge": -10,
        "turn": -10,
        "physicalAction": -10
    },
    {
        "name": "3 puntos restantes de cansancio",
        "attack": "-20",
        "parry": -20,
        "dodge": -20,
        "turn": -20,
        "physicalAction": -20
    },
    {
        "name": "2 puntos restantes de cansancio",
        "attack": "-40",
        "parry": -40,
        "dodge": -40,
        "turn": -40,
        "physicalAction": -40
    },
    {
        "name": "1 puntos restantes de cansancio",
        "attack": "-80",
        "parry": -80,
        "dodge": -80,
        "turn": -80,
        "physicalAction": -80
    },
    {
        "name": "0 puntos restantes de cansancio",
        "attack": "-120",
        "parry": -120,
        "dodge": -120,
        "turn": -120,
        "physicalAction": -120
    },
    {
        "name": "Ceguera parcial",
        "attack": -30,
        "parry": -30,
        "dodge": -15,
        "turn": 0,
        "type": 2,
        "physicalAction": -30
    },
    {
        "name": "Ceguera absoluta",
        "attack": -100,
        "parry": -80,
        "dodge": -80,
        "turn": 0,
        "type": 2,
        "physicalAction": -90
    },
    {
        "name": "Derribado",
        "attack": -30,
        "parry": -30,
        "dodge": -30,
        "turn": -10,
        "type": 2,
        "physicalAction": -30
    },
    {
        "name": "Parálisis menor",
        "attack": -20,
        "parry": -20,
        "dodge": -40,
        "turn": -20,
        "type": 2,
        "physicalAction": -40
    },
    {
        "name": "Parálisis parcial",
        "attack": -80,
        "parry": -80,
        "dodge": -80,
        "turn": -30,
        "type": 2,
        "physicalAction": -60
    },
    {
        "name": "Parálisis completa",
        "attack": -200,
        "parry": -200,
        "dodge": -200,
        "turn": -100,
        "type": 2,
        "physicalAction": -200
    },
    {
        "name": "Amenazado",
        "attack": -20,
        "parry": -120,
        "dodge": -120,
        "turn": -50,
        "type": 2,
        "physicalAction": -100
    },
    {
        "name": "Levitando",
        "attack": -20,
        "parry": -20,
        "dodge": -40,
        "turn": 0,
        "type": 2,
        "physicalAction": -60
    },
    {
        "name": "Vuelo tipo 7 a 14",
        "attack": 10,
        "parry": 10,
        "dodge": 10,
        "turn": 10,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Vuelo 15 o superior",
        "attack": 15,
        "parry": 10,
        "dodge": 20,
        "turn": 10,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Espacio reducido",
        "attack": -40,
        "parry": -40,
        "dodge": -40,
        "turn": 0,
        "type": 2,
        "physicalAction": -20
    },
    {
        "name": "Escasa visibilidad",
        "attack": -20,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 0,
        "physicalAction": 0
    },
    {
        "name": "Defensa total",
        "attack": -200,
        "parry": 30,
        "dodge": 30,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Ataque total",
        "attack": 30,
        "parry": -200,
        "dodge": -200,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Arma distinta / Desarmado",
        "attack": -60,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Arma mixta",
        "attack": -40,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {
        "name": "Arma similar",
        "attack": -20,
        "parry": 0,
        "dodge": 0,
        "turn": 0,
        "type": 2,
        "physicalAction": 0
    },
    {"name": "Dolor leve", "attack": -20, "parry": -20, "dodge": -20, "turn": -10, "physicalAction": -20},
    {"name": "Dolor", "attack": -40, "parry": -40, "dodge": -40, "turn": -20, "physicalAction": -40},
    {"name": "Dolor extremo", "attack": -80, "parry": -80, "dodge": -80, "turn": -40, "physicalAction": -80},
    {"name": "Miedo", "attack": -60, "parry": -60, "dodge": -60, "turn": -30, "physicalAction": -60},
    {"name": "Fascinación", "parry": -20, "dodge": -20, "physicalAction": -20},
    {"name": "Incapacitado (coma o inconsciente)", "attack": -200, "parry": -200, "dodge": -200, "turn": -100, "physicalAction": -200},
    {"name": "Recién estabilizado tras estar entre la vida y la muerte", "attack": -60, "parry": -60, "dodge": -60, "turn": -30, "physicalAction": -60},
    {"name": "Defensa total con Shephon", "attack": -200, "parry": 60, "dodge": 60},
    {"name": "Defensa total con Shephon arcano", "attack": -200, "parry": 100, "dodge": 100},
    {"name": "Derribado con Soo Bahk supremo", "turn": -10, "physicalAction": -30},
    {"name": "Espacio reducido (Tabla de Movimiento en Espacios Reducidos)", "attack": -20, "parry": -20, "dodge": -20, "physicalAction": -10},
    {"name": "Espacio reducido con Hanja", "attack": -40, "physicalAction": -20},
    {"name": "Parálisis menor con Hanja arcano", "attack": -20, "turn": -20, "physicalAction": -40},
    {"name": "Parálisis parcial con Hanja arcano", "attack": -80, "turn": -30, "physicalAction": -60},
    {"name": "Amenazado con Hanja arcano", "attack": -20, "turn": -50, "physicalAction": -100},
    {"name": "Kung Fu: +10 al ataque", "attack": 10},
    {"name": "Kung Fu: +10 a la parada", "parry": 10},
    {"name": "Kung Fu: +10 a la esquiva", "dodge": 10},
    {"name": "Kung Fu: +10 al turno", "turn": 10},
    {"name": "Kung Fu: +20 al ataque (supremo)", "attack": 20},
    {"name": "Kung Fu: +20 a la parada (supremo)", "parry": 20},
    {"name": "Kung Fu: +20 a la esquiva (supremo)", "dodge": 20},
    {"name": "Kung Fu: +20 al turno (supremo)", "turn": 20},
    {"name": "Kung Fu: +40 al ataque (Asakusen arcano)", "attack": 40},
    {"name": "Kung Fu: +40 a la parada (Asakusen arcano)", "parry": 40},
    {"name": "Kung Fu: +40 a la esquiva (Asakusen arcano)", "dodge": 40},
    {"name": "Kung Fu: +40 al turno (Asakusen arcano)", "turn": 40},
    {"name": "Asakusen", "attack": 10, "parry": 10, "dodge": 10, "turn": 10}
]
''';
}
