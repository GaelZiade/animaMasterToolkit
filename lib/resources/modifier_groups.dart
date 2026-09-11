import 'package:amt/models/character_model/status_modifier.dart';
import 'package:amt/resources/modifiers.dart';

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
    ModifierGroup(label: 'Ataque extra', prefix: Modifiers.extraAttackPrefix),
    // Maniobras (Core, "Ataques específicos" y "Defensas especiales"). Cada
    // grupo reúne la maniobra y sus variantes por tabla o arte marcial; las
    // maniobras distintas sí se pueden combinar entre sí. Una variante que deja
    // el penalizador en 0 no está: equivale a no elegir nada.
    ModifierGroup(
      label: 'Derribo',
      names: ['Derribo', 'Derribo con arma corta', 'Derribo a mitad (Grappling, Sambo)'],
    ),
    ModifierGroup(
      label: 'Presa',
      names: [
        'Presa',
        'Presa a mitad (Pankration, Grappling, Sambo avanzado)',
        'Presa con arma sin regla de Presa (Tabla de Presa Inusual)',
      ],
    ),
    ModifierGroup(label: 'Desarmar', names: ['Desarmar', 'Desarmar a mitad (Tabla de Desarme, Sambo)']),
    ModifierGroup(
      label: 'Ataque en área',
      names: [
        'Ataque en área',
        'Ataque en área a mitad (Tabla de Área, Sambo avanzado)',
        'Ataque en área con Capoeira supremo',
      ],
    ),
    ModifierGroup(label: 'Engatillar', names: ['Engatillar', 'Engatillar a mitad (Tabla de Precisión)']),
    ModifierGroup(label: 'Apartar a otro', names: ['Apartar a otro', 'Apartar a otro (Tabla de Guardaespaldas)']),
    ModifierGroup(label: 'Xing Quan', prefix: 'Xing Quan: '),
    ModifierGroup(label: 'Kung Fu: bono variable', prefix: 'Kung Fu: '),
    ModifierGroup(label: 'Defensa total', names: ['Defensa total', 'Defensa total con Shephon', 'Defensa total con Shephon arcano']),
    ModifierGroup(label: 'Posición relativa', names: ['Flanco', 'De espalda', 'Flanco con Soo Bahk']),
    ModifierGroup(label: 'Tamaño del adversario', names: ['Adversario pequeño', 'Adversario diminuto']),
    // Tabla 29: penalizador por usar un arma distinta de la que se domina.
    ModifierGroup(label: 'Arma que no domina', names: ['Arma similar', 'Arma mixta', 'Arma distinta / Desarmado']),
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
    ModifierGroup(
      label: 'Parálisis',
      names: [
        'Parálisis menor',
        'Parálisis parcial',
        'Parálisis completa',
        'Parálisis menor con Hanja arcano',
        'Parálisis parcial con Hanja arcano',
      ],
    ),
    ModifierGroup(label: 'Derribado', names: ['Derribado', 'Derribado con Soo Bahk supremo']),
    ModifierGroup(
      label: 'Espacio reducido',
      names: ['Espacio reducido', 'Espacio reducido (Tabla de Movimiento en Espacios Reducidos)', 'Espacio reducido con Hanja'],
    ),
    ModifierGroup(label: 'Amenazado', names: ['Amenazado', 'Amenazado con Hanja arcano']),
    ModifierGroup(label: 'Dolor', names: ['Dolor leve', 'Dolor', 'Dolor extremo']),
    ModifierGroup(label: 'Vuelo', names: ['Vuelo tipo 7 a 14', 'Vuelo 15 o superior']),
    ModifierGroup(label: 'Seraphite', names: ['Seraphite base', 'Seraphite arcano']),
    ModifierGroup(
      label: 'Proyectil recibido',
      names: [
        'Proyectil Lanzado',
        'Proyectil Disparado',
        'Proyectil Disparado (maestria en defensa)',
        'Proyectil Disparado (escudo)',
        'Proyectil Lanzado con Kuan',
        'Proyectil Disparado con Kuan avanzado',
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
