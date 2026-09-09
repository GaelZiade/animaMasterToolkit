import 'dart:io';

import 'package:amt/models/character_model/character.dart';
import 'package:amt/utils/excel_parser.dart';
import 'package:amt/utils/xlsx/sheet_to_json.dart';
import 'package:amt/utils/xlsx/xlsx_workbook.dart';

/// Error de conversión con un mensaje pensado para mostrarle al usuario.
class SheetParseException implements Exception {
  SheetParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Lee una planilla de personaje sin salir de la aplicación.
///
/// Reemplaza al conversor en la nube, que sólo acepta pedidos desde el dominio
/// publicado y por lo tanto falla al ejecutar la aplicación en local.
class XlsxCharacterParser implements ExcelParser {
  XlsxCharacterParser.fromFile(this.file);
  XlsxCharacterParser.fromBytes(this.bytes);

  @override
  File? file;

  @override
  List<int>? bytes;

  @override
  Future<Character?> parse() async {
    final content = bytes ?? await file?.readAsBytes();

    if (content == null) {
      throw SheetParseException('No se pudo leer el archivo de la planilla.');
    }

    final XlsxWorkbook book;

    try {
      book = XlsxWorkbook.decode(content);
    } catch (error) {
      throw SheetParseException(
        'El archivo no es una planilla de Excel válida (.xlsx o .xlsm).',
      );
    }

    if (!book.hasSheet('Principal') || !book.hasSheet('Combate')) {
      throw SheetParseException(
        'La planilla no tiene las hojas "Principal" y "Combate". '
        '¿Es una ficha de personaje de Ánima?',
      );
    }

    final Character? character;

    try {
      character = Character.fromJson(SheetToJson.convert(book));
    } catch (error) {
      throw SheetParseException('No se pudo interpretar la ficha: $error');
    }

    if (character == null) {
      throw SheetParseException('La planilla no contiene datos de personaje.');
    }

    return character;
  }
}
