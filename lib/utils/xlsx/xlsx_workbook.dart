import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

/// Lector mínimo de libros de Excel (.xlsx / .xlsm).
///
/// El paquete `excel` no sirve para las planillas de Ánima por dos motivos:
/// tarda minutos en decodificar el libro entero y no expone el resultado de las
/// fórmulas, que es justamente lo que tiene la ficha. Este lector resuelve las
/// dos cosas: sólo abre las hojas que se le piden y toma el valor cacheado que
/// Excel deja guardado junto a cada fórmula.
class XlsxWorkbook {
  XlsxWorkbook._(this._archive, this._sheetPaths, this._sharedStrings);

  final Archive _archive;

  /// Nombre de hoja normalizado -> ruta del XML dentro del paquete.
  final Map<String, String> _sheetPaths;

  final List<String> _sharedStrings;

  /// Hojas ya leídas, indexadas por referencia A1.
  final _cache = <String, Map<String, String>>{};

  static XlsxWorkbook decode(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    final relations = <String, String>{};
    final relationsXml = _readXml(archive, 'xl/_rels/workbook.xml.rels');

    if (relationsXml != null) {
      for (final node in relationsXml.findAllElements('Relationship')) {
        final id = node.getAttribute('Id');
        final target = node.getAttribute('Target');
        if (id != null && target != null) {
          relations[id] = target.startsWith('/') ? target.substring(1) : 'xl/$target';
        }
      }
    }

    final sheetPaths = <String, String>{};
    final workbookXml = _readXml(archive, 'xl/workbook.xml');

    if (workbookXml != null) {
      for (final node in workbookXml.findAllElements('sheet')) {
        final name = node.getAttribute('name');
        final id = node.getAttribute('r:id') ?? node.getAttribute('id');
        final path = relations[id];
        if (name != null && path != null) {
          sheetPaths[normalizeName(name)] = path;
        }
      }
    }

    return XlsxWorkbook._(archive, sheetPaths, _readSharedStrings(archive));
  }

  /// Los nombres de hoja se comparan sin acentos ni mayúsculas: la macro
  /// original los escribe de varias maneras según el bloque.
  static String normalizeName(String name) => stripAccents(name).toLowerCase().trim();

  static const _accented = 'ÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇáàäâãéèëêíìïîóòöôõúùüûñç';
  static const _plain = 'AAAAAEEEEIIIIOOOOOUUUUNCaaaaaeeeeiiiiooooouuuunc';

  /// Reproduce `stripAccent` de la macro: el JSON usa claves sin acentos.
  static String stripAccents(String text) {
    final buffer = StringBuffer();

    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final index = _accented.indexOf(char);
      buffer.write(index == -1 ? char : _plain[index]);
    }

    return buffer.toString();
  }

  bool hasSheet(String sheet) => _sheetPaths.containsKey(normalizeName(sheet));

  /// Valor mostrado de una celda, o null si está vacía.
  String? cell(String sheet, String reference) => _sheet(sheet)[reference.toUpperCase()];

  /// Recorre las filas de un rango A1 y devuelve, por fila, el valor de las
  /// columnas indicadas por desplazamiento (1 = primera columna del rango).
  List<List<String?>> rows(String sheet, String range, List<int> columnOffsets) {
    final values = _sheet(sheet);
    final bounds = _parseRange(range);
    final result = <List<String?>>[];

    for (var row = bounds.firstRow; row <= bounds.lastRow; row++) {
      result.add([
        for (final offset in columnOffsets) values[_reference(bounds.firstColumn + offset - 1, row)],
      ]);
    }

    return result;
  }

  /// Valor de una celda expresada como desplazamiento dentro de un bloque.
  ///
  /// La macro direcciona asi los bloques de armas: `Range("G3")` sobre un
  /// bloque significa tercera fila, septima columna contando desde su esquina.
  String? blockCell(String sheet, String block, String relative) {
    final bounds = _parseRange(block);
    final offset = _parseReference(relative);

    return cell(sheet, _reference(bounds.firstColumn + offset.column - 1, bounds.firstRow + offset.row - 1));
  }

  /// Busca la fila cuya celda en [column] contiene [text].
  ///
  /// Las variantes de la planilla (por ejemplo la Akuma Exxet) corren las filas
  /// de la hoja de PDs, asi que buscar por etiqueta es mas seguro que fijar el
  /// numero de fila.
  int? findRow(String sheet, String column, String text, {int from = 1, int to = 200}) {
    final needle = normalizeName(text);

    for (var row = from; row <= to; row++) {
      final value = cell(sheet, '$column$row');

      if (value != null && normalizeName(value).contains(needle)) return row;
    }

    return null;
  }

  Map<String, String> _sheet(String sheet) {
    final key = normalizeName(sheet);
    final cached = _cache[key];

    if (cached != null) return cached;

    final path = _sheetPaths[key];
    final values = path == null ? <String, String>{} : _parseSheet(path);

    _cache[key] = values;

    return values;
  }

  /// Lee la hoja con un parser por eventos: construir el árbol completo de una
  /// hoja de la ficha cuesta bastante más memoria y tiempo.
  Map<String, String> _parseSheet(String path) {
    final content = _readString(_archive, path);

    if (content == null) return {};

    final values = <String, String>{};

    String? reference;
    String? type;
    var insideValue = false;
    var insideInlineText = false;
    final buffer = StringBuffer();

    for (final event in parseEvents(content)) {
      if (event is XmlStartElementEvent) {
        switch (event.localName) {
          case 'c':
            reference = event.attributes.where((a) => a.localName == 'r').firstOrNull?.value;
            type = event.attributes.where((a) => a.localName == 't').firstOrNull?.value;
          case 'v':
            insideValue = !event.isSelfClosing;
            buffer.clear();
          case 't':
            insideInlineText = !event.isSelfClosing;
            buffer.clear();
        }
      } else if (event is XmlTextEvent) {
        if (insideValue || insideInlineText) buffer.write(event.value);
      } else if (event is XmlEndElementEvent) {
        switch (event.localName) {
          case 'v':
            if (insideValue && reference != null) {
              values[reference] = _resolve(buffer.toString(), type);
            }
            insideValue = false;
          case 't':
            if (insideInlineText && reference != null && type == 'inlineStr') {
              values[reference] = buffer.toString();
            }
            insideInlineText = false;
          case 'c':
            reference = null;
            type = null;
        }
      }
    }

    _applyMerges(content, values);

    return values;
  }

  /// Excel guarda el valor de un bloque combinado solo en su celda ancla; el
  /// resto del bloque queda vacio en el XML. La macro original, corriendo
  /// dentro de Excel, ve el valor desde cualquier celda del bloque, asi que hay
  /// que replicarlo para que las referencias del mapeo coincidan.
  void _applyMerges(String content, Map<String, String> values) {
    for (final match in RegExp(r'<mergeCell ref="([^"]+)"').allMatches(content)) {
      final range = _parseRange(match.group(1)!);
      final anchor = values[_reference(range.firstColumn, range.firstRow)];

      if (anchor == null) continue;

      for (var row = range.firstRow; row <= range.lastRow; row++) {
        for (var column = range.firstColumn; column <= range.lastColumn; column++) {
          values.putIfAbsent(_reference(column, row), () => anchor);
        }
      }
    }
  }

  /// `t="s"` indexa la tabla de cadenas compartidas; el resto ya viene literal.
  String _resolve(String raw, String? type) {
    if (type != 's') return raw;

    final index = int.tryParse(raw);

    return index != null && index < _sharedStrings.length ? _sharedStrings[index] : raw;
  }

  static List<String> _readSharedStrings(Archive archive) {
    final document = _readXml(archive, 'xl/sharedStrings.xml');

    if (document == null) return [];

    return [
      for (final item in document.findAllElements('si')) item.findAllElements('t').map((node) => node.innerText).join(),
    ];
  }

  static String? _readString(Archive archive, String path) {
    final file = archive.files.where((file) => file.name == path).firstOrNull;

    // El paquete OOXML es UTF-8. Leerlo byte a byte rompe cualquier acento,
    // empezando por el nombre de la hoja "Místicos".
    return file == null ? null : utf8.decode(file.content as List<int>, allowMalformed: true);
  }

  static XmlDocument? _readXml(Archive archive, String path) {
    final content = _readString(archive, path);

    return content == null ? null : XmlDocument.parse(content);
  }

  static _Range _parseRange(String range) {
    final parts = range.toUpperCase().split(':');
    final start = _parseReference(parts.first);
    final end = _parseReference(parts.length > 1 ? parts[1] : parts.first);

    return _Range(start.column, start.row, end.column, end.row);
  }

  static ({int column, int row}) _parseReference(String reference) {
    final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(reference);

    if (match == null) return (column: 1, row: 1);

    var column = 0;
    for (final code in match.group(1)!.codeUnits) {
      column = column * 26 + (code - 64);
    }

    return (column: column, row: int.parse(match.group(2)!));
  }

  static String _reference(int column, int row) {
    final letters = StringBuffer();
    var remaining = column;

    while (remaining > 0) {
      final rest = (remaining - 1) % 26;
      letters.write(String.fromCharCode(65 + rest));
      remaining = (remaining - 1) ~/ 26;
    }

    return '${letters.toString().split('').reversed.join()}$row';
  }
}

class _Range {
  const _Range(this.firstColumn, this.firstRow, this.lastColumn, this.lastRow);

  final int firstColumn;
  final int firstRow;
  final int lastColumn;
  final int lastRow;
}
