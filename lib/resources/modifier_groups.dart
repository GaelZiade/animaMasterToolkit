import 'package:amt/models/character_model/status_modifier.dart';

/// Conjunto de modificadores que se excluyen entre sí.
///
/// Un ataque no puede estar apuntado a dos zonas a la vez, ni un personaje
/// puede sufrir dos grados de ceguera al mismo tiempo. Agruparlos evita
/// combinaciones imposibles y acorta mucho la lista.
class ModifierGroup {
  const ModifierGroup({
    required this.label,
    this.prefix,
    this.names = const [],
  });

  /// Nombre visible del grupo.
  final String label;

  /// Todos los modificadores cuyo nombre empieza así pertenecen al grupo.
  final String? prefix;

  /// Modificadores del grupo indicados por nombre exacto.
  final List<String> names;

  bool contains(StatusModifier modifier) {
    if (prefix != null && modifier.name.startsWith(prefix!)) return true;
    return names.contains(modifier.name);
  }

  /// Texto que se muestra en el desplegable para cada opción.
  String optionLabel(StatusModifier modifier) {
    final name = prefix != null ? modifier.name.substring(prefix!.length) : modifier.name;
    return name.isEmpty ? modifier.name : name;
  }

  static const all = <ModifierGroup>[
    ModifierGroup(label: 'Zona apuntada', prefix: 'Apuntado: '),
    ModifierGroup(label: 'Actitud de combate', names: ['A la defensiva', 'A la ofensiva']),
    ModifierGroup(label: 'Acción total', names: ['Defensa total', 'Ataque total']),
    ModifierGroup(label: 'Posición relativa', names: ['Flanco', 'De espalda']),
    ModifierGroup(label: 'Tamaño del adversario', names: ['Adversario pequeño', 'Adversario diminuto']),
    ModifierGroup(label: 'Arma del adversario', names: ['Arma similar', 'Arma mixta', 'Arma distinta / Desarmado']),
    ModifierGroup(
      label: 'Cansancio',
      names: [
        '4 puntos restantes de cansancio',
        '3 puntos restantes de cansancio',
        '2 puntos restantes de cansancio',
        '1 puntos restantes de cansancio',
        '0 puntos restantes de cansancio',
      ],
    ),
    ModifierGroup(label: 'Ceguera', names: ['Ceguera parcial', 'Ceguera absoluta']),
    ModifierGroup(label: 'Parálisis', names: ['Parálisis menor', 'Parálisis parcial', 'Parálisis completa']),
    ModifierGroup(label: 'Dolor', names: ['Dolor', 'Dolor extremo']),
    ModifierGroup(label: 'Vuelo', names: ['Vuelo tipo 7 a 14', 'Vuelo 15 o superior']),
    ModifierGroup(label: 'Seraphite', names: ['Seraphite base', 'Seraphite arcano']),
    ModifierGroup(label: 'Shephon', names: ['Shephon base', 'Shephon arcano']),
    ModifierGroup(
      label: 'Proyectil recibido',
      names: [
        'Proyectil Lanzado',
        'Proyectil Disparado',
        'Proyectil Disparado (maestria en defensa)',
        'Proyectil Disparado (escudo)',
      ],
    ),
    ModifierGroup(
      label: 'Proyectil: turnos apuntando',
      names: [
        'Proyectil: Apuntar por 1 turno',
        'Proyectil: Apuntar por 2 turno',
        'Proyectil: Apuntar por 3 turno',
      ],
    ),
    ModifierGroup(
      label: 'Proyectil: velocidad del blanco',
      names: [
        'Proyectil: El blanco se mueve a Vel. 10',
        'Proyectil: El blanco se mueve a más de Vel. 8',
        'Proyectil: El blanco se mueve a más de Vel. +10',
      ],
    ),
  ];
}
