import 'dart:math';

import 'package:amt/utils/xlsx/xlsx_workbook.dart';

/// Convierte una planilla de personaje de Ánima al JSON que consume
/// [Character.fromJson].
///
/// Es la traducción de `assets/ExportJson.bas`, la macro que la propia planilla
/// usa para exportarse. Las referencias de celda salen de ahí, así que el
/// resultado es el mismo que produce la macro o el conversor en la nube.
abstract class SheetToJson {
  static const _principal = 'Principal';
  static const _combate = 'Combate';
  static const _ki = 'Ki';
  static const _misticos = 'Místicos';
  static const _psiquicos = 'Psíquicos';

  static Map<String, dynamic> convert(XlsxWorkbook book) {
    return {
      'Atributos': _rangeToMap(book, _principal, 'D11:H18', 1, 4),
      'Habilidades': _rangeToMap(book, _principal, 'M22:Q77', 1, 5),
      'datosElementales': _basicData(book),
      'Resistencias': _rangeToMap(book, _principal, 'D57:J62', 1, 7),
      'PoderesDeCriatura': _rangeToMap(book, _principal, 'AB12:AH23', 1, 5),
      'HabilidadesElementales': _rangeToMap(book, _principal, 'AD12:AH69', 1, 4),
      'Combate': _combatData(book),
      'Ki': _kiData(book),
      'Elan': _rangeToMap(book, 'Elan', 'C29:G49', 4, 5),
      // El bloque místico y el psíquico se emiten siempre: el modelo los ignora
      // cuando el Zeon o los CVs son cero, y la celda que la macro usaba de
      // compuerta (PDs!M101) viene vacía en las planillas reales.
      'Misticos': _mysticData(book),
      'Psiquicos': _psychicData(book),
    };
  }

  /// Equivalente de `RangeToJson`: recorre las filas del rango tomando una
  /// columna como clave y otra como valor, sin repetir claves ni acentos.
  static Map<String, String> _rangeToMap(
    XlsxWorkbook book,
    String sheet,
    String range,
    int keyColumn,
    int valueColumn,
  ) {
    final result = <String, String>{};

    for (final row in book.rows(sheet, range, [keyColumn, valueColumn])) {
      final key = XlsxWorkbook.stripAccents(row[0] ?? '').trim();

      if (key.isEmpty || result.containsKey(key)) continue;

      result[key] = XlsxWorkbook.stripAccents(row[1] ?? '').trim();
    }

    return result;
  }

  static String _text(XlsxWorkbook book, String sheet, String reference) {
    return XlsxWorkbook.stripAccents(book.cell(sheet, reference) ?? '').trim();
  }

  static Map<String, String> _basicData(XlsxWorkbook book) {
    return {
      'cansancio': _text(book, _principal, 'N16'),
      'puntosDeVida': _text(book, _principal, 'N11'),
      'regeneracion': _text(book, _principal, 'J11'),
      'nombre': _text(book, _principal, 'K4'),
      'categoria': _text(book, _principal, 'K5'),
      'nivel': _text(book, _principal, 'O6'),
      'clase': _text(book, _principal, 'K7'),
      'acumDanio': _text(book, _principal, 'Y13'),
      'creadoConMagia': _text(book, _principal, 'Y14'),
      'gnosis': _text(book, _principal, 'AB13'),
      'natura': _text(book, _principal, 'AB14'),
      'movimiento': _text(book, _principal, 'J16'),
    };
  }

  static Map<String, dynamic> _kiData(XlsxWorkbook book) {
    return {
      'Acumulaciones': _rangeToMap(book, _ki, 'C12:D23', 1, 2),
      'Habilidades': _rangeToMap(book, _ki, 'C35:F36', 1, 4),
      'Maximos': _rangeToMap(book, _ki, 'C12:F23', 1, 6),
      'acumulacionMax': _text(book, _ki, 'F24'),
      'acumulacionGenerica': _text(book, _ki, 'D24'),
    };
  }

  static Map<String, dynamic> _mysticData(XlsxWorkbook book) {
    return {
      'regen': _text(book, _misticos, 'J12'),
      'act': _text(book, _misticos, 'L12'),
      'zeon': _text(book, _misticos, 'K18'),
      'Vias': _rangeToMap(book, _misticos, 'C15:H25', 1, 6),
      'SubVias': _rangeToMap(book, _misticos, 'C15:H25', 1, 3),
      'Metamagia': _rangeToMap(book, _misticos, 'W53:AB73', 1, 6),
      'Conjuros': _rangeToMap(book, _misticos, 'Y12:AC50', 5, 1),
      'Libres': _rangeToMap(book, _misticos, 'AG12:AK50', 5, 1),
    };
  }

  static Map<String, dynamic> _psychicData(XlsxWorkbook book) {
    return {
      // CVs libres. La macro nunca los exportaba, asi que el consumible de CV
      // no se creaba ni siquiera con el conversor en la nube.
      'cvsLibres': _text(book, _psiquicos, 'M10'),
      'Disciplinas': _rangeToMap(book, _psiquicos, 'C25:Q36', 1, 4),
      'Patrones': _rangeToMap(book, _psiquicos, 'C39:Q50', 1, 4),
      'Poderes': _rangeToMap(book, _psiquicos, 'V11:AB64', 1, 7),
      'Innatos': _rangeToMap(book, _psiquicos, 'AD17:AK62', 1, 8),
    };
  }

  static Map<String, dynamic> _combatData(XlsxWorkbook book) {
    return {
      'TablasDeArmas': _rangeToMap(book, _combate, 'AH11:AL16', 1, 5),
      'EstilosDeCombate': _rangeToMap(book, _combate, 'AB19:AQ28', 1, 7),
      'ArsMagnus': _rangeToMap(book, _combate, 'AB55:AQ64', 1, 7),
      'ArtesMarciales': _rangeToMap(book, _combate, 'AB31:AQ49', 1, 5),
      'armas': _weapons(book),
      'armadura': _armourData(book),
      // La macro no exporta las ventajas; la ambidestría cambia el ataque con
      // un arma adicional.
      'ambidestria': _hasAdvantage(book, 'ambidestr'),
    };
  }

  static const _baseWeaponBlocks = [
    'C27:L32',
    'C34:L39',
    'C41:L46',
    'N27:W32',
    'N34:W39',
    'N41:W46',
  ];

  static const _rangedWeaponBlocks = [
    'C49:L55',
    'C58:L64',
    'N49:W55',
    'N58:W64',
  ];

  static List<Map<String, String>> _weapons(XlsxWorkbook book) {
    final weapons = <Map<String, String>>[_unarmed(book)];

    if (_hasInvestedIn(book, 'Proyeccion Magica')) {
      final projection = _projection(book, sheet: _misticos, name: 'Proyeccion Magica', type: 'Mistico');
      if (projection != null) weapons.add(projection);
    }

    if (_hasInvestedIn(book, 'Proyeccion psiquica')) {
      final projection = _projection(book, sheet: _psiquicos, name: 'Proyeccion Psiquica', type: 'Psiquica');
      if (projection != null) weapons.add(projection);
    }

    for (final block in _baseWeaponBlocks) {
      final weapon = _baseWeapon(book, block);
      if (weapon != null) weapons.add(weapon);
    }

    for (final block in _rangedWeaponBlocks) {
      final weapon = _rangedWeapon(book, block);
      if (weapon != null) weapons.add(weapon);
    }

    return weapons;
  }

  /// Indica si el personaje puso PDs en la habilidad indicada.
  ///
  /// Sin inversion la planilla igual muestra un valor de proyeccion, que es el
  /// que sale solo de las caracteristicas; agregar esa arma llenaria la lista
  /// de armas inutiles a cualquier personaje.
  static bool _hasInvestedIn(XlsxWorkbook book, String label) {
    final row = book.findRow('PDs', 'K', label, from: 80, to: 140);

    if (row == null) return false;

    final invested = double.tryParse(book.cell('PDs', 'M' + row.toString()) ?? '');

    return invested != null && invested > 0;
  }

  /// Busca una ventaja en la lista de la hoja Principal, que empieza bajo
  /// "Puntos de Creación" y termina en "Desventajas". Algunas versiones además
  /// las resumen en D55.
  static bool _hasAdvantage(XlsxWorkbook book, String name) {
    final needle = name.toLowerCase();

    for (var row = 33; row <= 55; row++) {
      final value = _text(book, _principal, 'C$row').toLowerCase();

      if (value.startsWith('desventajas')) break;
      if (value.contains(needle)) return true;
    }

    return _text(book, _principal, 'D55').toLowerCase().contains(needle);
  }

  /// Tamaño del arma de un bloque para los ataques adicionales: 'P', 'M' o 'G'.
  ///
  /// Si el bloque es la mano hábil de un combate con dos armas (Combate!R22 y
  /// U22), manda la más grande de las dos (Core, p. 91).
  static String? _weaponSize(XlsxWorkbook book, String block) {
    final sizes = [_sizeOfBaseWeapon(book, _block(book, _combate, block, 'C2'))];

    final slot = _block(book, _combate, block, 'A1');
    final mainHand = _text(book, _combate, 'R22');
    final offHand = _text(book, _combate, 'U22');

    if (slot.isNotEmpty && offHand.isNotEmpty && mainHand.startsWith('$slot ')) {
      final offSlot = offHand.split(' ').first;

      for (final other in _baseWeaponBlocks) {
        if (_block(book, _combate, other, 'A1') == offSlot) {
          sizes.add(_sizeOfBaseWeapon(book, _block(book, _combate, other, 'C2')));
        }
      }
    }

    final known = sizes.whereType<int>();

    return known.isEmpty ? null : const ['P', 'M', 'G'][known.reduce(max)];
  }

  /// Columna Tamaño de la "Tabla de Armas y Escudos" de la hoja Tablas, para
  /// el arma base de un bloque: 0 pequeña, 1 mediana, 2 grande.
  static int? _sizeOfBaseWeapon(XlsxWorkbook book, String name) {
    if (name.isEmpty || !book.hasSheet('Tablas')) return null;

    final header = book.findRow('Tablas', 'X', 'Tama', from: 600, to: 700);

    if (header == null) return null;

    final wanted = name.toLowerCase();

    for (var row = header + 1; row <= header + 500; row++) {
      final weapon = book.cell('Tablas', 'D$row');

      if (weapon == null || XlsxWorkbook.stripAccents(weapon).trim().toLowerCase() != wanted) continue;

      final size = XlsxWorkbook.stripAccents(book.cell('Tablas', 'X$row') ?? '').toLowerCase();

      if (size.startsWith('peque')) return 0;
      if (size.startsWith('median')) return 1;
      if (size.startsWith('grande')) return 2;

      return null;
    }

    return null;
  }

  static String _block(XlsxWorkbook book, String sheet, String block, String relative) {
    return XlsxWorkbook.stripAccents(book.blockCell(sheet, block, relative) ?? '').trim();
  }

  static Map<String, String> _unarmed(XlsxWorkbook book) {
    const block = 'C20:L25';

    return {
      'nombre': _block(book, _combate, block, 'A1'),
      'tipo': 'desarmado',
      'conocimiento': _block(book, _combate, block, 'A2'),
      'tamanio': 'Normal',
      'critPrincipal': _block(book, _combate, block, 'A4'),
      'critSecundario': _block(book, _combate, block, 'B4'),
      'entereza': _block(book, _combate, block, 'C4'),
      'rotura': _block(book, _combate, block, 'D4'),
      'presencia': _block(book, _combate, block, 'E4'),
      'turno': _block(book, _combate, block, 'F2'),
      'ataque': _block(book, _combate, block, 'G2'),
      'defensa': _block(book, _combate, block, 'H2'),
      'defensaTipo': _block(book, _combate, block, 'I2'),
      'danio': _block(book, _combate, block, 'J2'),
      'calidad': '-',
      'caracteristica': '-',
      'advertencia': '-',
      'municion': '-',
      'especial': '-',
    };
  }

  /// La proyección mágica y la psíquica se exponen como un arma más.
  static Map<String, String>? _projection(
    XlsxWorkbook book, {
    required String sheet,
    required String name,
    required String type,
  }) {
    const block = 'O12:Q13';

    final attack = _block(book, sheet, block, 'B1');

    // Sin proyección no hay arma que agregar.
    if (attack.isEmpty || attack == '0') return null;

    return {
      'nombre': name,
      'tipo': type,
      'conocimiento': 'Conocida',
      'tamanio': 'Normal',
      'critPrincipal': 'Ene',
      'critSecundario': 'Pen',
      'entereza': '999',
      'rotura': '0',
      'presencia': '0',
      'turno': _block(book, sheet, block, 'A1'),
      'ataque': attack,
      'defensa': _block(book, sheet, block, 'C1'),
      'defensaTipo': 'Par',
      'danio': '100',
      'calidad': '-',
      'caracteristica': '-',
      'advertencia': '-',
      'municion': '-',
      'especial': '-',
    };
  }

  static Map<String, String>? _baseWeapon(XlsxWorkbook book, String block) {
    final name = _block(book, _combate, block, 'B1');

    if (name.isEmpty) return null;

    return {
      'nombre': name,
      'tipo': _block(book, _combate, block, 'A2'),
      'conocimiento': _block(book, _combate, block, 'A3'),
      'tamanio': _block(book, _combate, block, 'D3'),
      'critPrincipal': _block(book, _combate, block, 'A5'),
      'critSecundario': _block(book, _combate, block, 'B5'),
      'entereza': _block(book, _combate, block, 'C5'),
      'rotura': _block(book, _combate, block, 'D5'),
      'presencia': _block(book, _combate, block, 'E5'),
      'turno': _block(book, _combate, block, 'F3'),
      'ataque': _block(book, _combate, block, 'G3'),
      'defensa': _block(book, _combate, block, 'H3'),
      'defensaTipo': _block(book, _combate, block, 'I3'),
      'danio': _block(book, _combate, block, 'J3'),
      'calidad': _block(book, _combate, block, 'H5'),
      'caracteristica': _block(book, _combate, block, 'A6'),
      'advertencia': _block(book, _combate, block, 'I6'),
      'municion': '-',
      'especial': _block(book, _combate, block, 'H6'),
      if (_weaponSize(book, block) case final size?) 'tamanoAtaque': size,
    };
  }

  static Map<String, String>? _rangedWeapon(XlsxWorkbook book, String block) {
    final name = _block(book, _combate, block, 'C1');

    if (name.isEmpty) return null;

    return {
      'nombre': name,
      'tipo': _block(book, _combate, block, 'A1'),
      'conocimiento': _block(book, _combate, block, 'A3'),
      'tamanio': _block(book, _combate, block, 'D3'),
      'critPrincipal': _block(book, _combate, block, 'A5'),
      'critSecundario': _block(book, _combate, block, 'B5'),
      'entereza': _block(book, _combate, block, 'C5'),
      'rotura': _block(book, _combate, block, 'D5'),
      'presencia': _block(book, _combate, block, 'E5'),
      'turno': _block(book, _combate, block, 'F2'),
      'ataque': _block(book, _combate, block, 'G2'),
      'defensa': _block(book, _combate, block, 'H2'),
      'defensaTipo': _block(book, _combate, block, 'I2'),
      'danio': _block(book, _combate, block, 'J2'),
      'calidad': _block(book, _combate, block, 'H5'),
      'caracteristica': _block(book, _combate, block, 'A6'),
      'advertencia': _block(book, _combate, block, 'I6'),
      'municion': _block(book, _combate, block, 'C2'),
      'especial': _block(book, _combate, block, 'H6'),
    };
  }

  static Map<String, dynamic> _armourData(XlsxWorkbook book) {
    return {
      'restriccionMov': _text(book, _combate, 'E16'),
      'penNatural': _text(book, _combate, 'H17'),
      'requisito': _text(book, _combate, 'H16'),
      'penAccionFisica': _text(book, _combate, 'S16'),
      'penNaturalFinal': _text(book, _combate, 'S17'),
      'armaduraTotal': {
        'FIL': _text(book, _combate, 'I16'),
        'CON': _text(book, _combate, 'J16'),
        'PEN': _text(book, _combate, 'K16'),
        'CAL': _text(book, _combate, 'L16'),
        'ELE': _text(book, _combate, 'M16'),
        'FRI': _text(book, _combate, 'N16'),
        'ENE': _text(book, _combate, 'O16'),
      },
      'armaduras': _armours(book),
    };
  }

  static List<Map<String, String>> _armours(XlsxWorkbook book) {
    const columns = [1, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];
    const keys = [
      'nombre',
      'Localizacion',
      'calidad',
      'FIL',
      'CON',
      'PEN',
      'CAL',
      'ELE',
      'FRI',
      'ENE',
      'Entereza',
      'Presencia',
      'RestMov',
      'Enc',
    ];

    final armours = <Map<String, String>>[];

    for (final row in book.rows(_combate, 'C12:S15', columns)) {
      if ((row.first ?? '').trim().isEmpty) continue;

      armours.add({
        for (var i = 0; i < keys.length; i++) keys[i]: XlsxWorkbook.stripAccents(row[i] ?? '').trim(),
      });
    }

    return armours;
  }
}
