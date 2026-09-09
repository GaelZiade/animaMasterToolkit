import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Iconos de la aplicación.
///
/// Todos reciben el color con el que deben pintarse. Los SVG traen su relleno
/// original en negro, así que sin filtro desaparecen sobre un fondo oscuro; el
/// color tiene que venir del tema y no del archivo.
class Assets {
  static Widget anatomy(Color color) => _svg('anatomy', 'status icon', color);

  static Widget attack(Color color) => _svg('attack', 'attack icon', color);

  static Widget dodging(Color color) => _svg('dodging', 'dodge icon', color);

  static Widget parry(Color color) => _svg('parry', 'parry icon', color);

  static Widget diceRoll(Color color) => _svg('d100_dice', 'dice rolling icon', color);

  static Widget shield(Color color) => _svg('shield', 'shield icon', color);

  static Widget knife(Color color) => _svg('knife', 'knife icon', color);

  static Widget uprising(Color color) => _svg('uprising', 'uprising icon', color);

  static Widget faceToFace(Color color) => _svg('face-to-face', 'face-to-face icon', color);

  static Widget github(Color color) => _svg('github', 'github icon', color);

  static Widget _svg(String name, String label, Color color) => SvgPicture.asset(
        'assets/$name.svg',
        semanticsLabel: label,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );

  static Widget excelConvert(Color color) => Image.asset(
        'assets/convert.png',
        color: color,
      );

  static Image surprised(Color color) => Image.asset(
        'assets/surprised.png',
        color: color,
      );
}
