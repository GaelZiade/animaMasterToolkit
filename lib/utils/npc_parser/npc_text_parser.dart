import 'dart:math';

import 'package:amt/utils/npc_parser/npc_reference_tables.dart';

/// Un PNJ leído de texto: el JSON que consume [Character.fromJson] y los
/// avisos de lo que no se pudo leer o se completó por deducción.
class NpcParseResult {
  NpcParseResult({required this.name, required this.json, required this.warnings});

  final String name;
  final Map<String, dynamic> json;
  final List<String> warnings;

  /// Descarta bloques que empiezan como un perfil pero no lo son, como las
  /// técnicas o conjuros con «Nivel:».
  bool get looksLikeProfile {
    final profile = json['datosElementales'] as Map<String, dynamic>;
    final signals = [
      profile['puntosDeVida'] != '0',
      !warnings.contains(NpcTextParser.noAttack),
      (json['Atributos'] as Map).length >= 4,
      (json['Resistencias'] as Map).length >= 3,
    ];

    return signals.where((signal) => signal).length >= 3;
  }
}

/// Lee perfiles de criaturas y PNJ copiados de los manuales.
///
/// Entiende los dos formatos canon:
/// - el largo del Bestiario, Gaïa y Los que Caminaron con Nosotros
///   (`Nivel: 7`, `Habilidad de ataque: 190 Garras…`);
/// - el compacto de los personajes comunes
///   (`Categoría Guerrero; Nivel 1`, `Turno 55/25; Pv 110; HA 80…`).
///
/// Un mismo texto puede traer varios perfiles seguidos.
abstract class NpcTextParser {
  static const noAttack = 'No se encontró ningún ataque';
  static const unarmed = 'Desarmado';

  static List<NpcParseResult> parseAll(String raw) {
    final lines = _cleanLines(raw);

    return [
      for (final block in _splitBlocks(lines))
        if (_parseBlock(block) case final result when result.looksLikeProfile) result,
    ];
  }

  // ---------------------------------------------------------------------------
  // Texto

  static List<String> _cleanLines(String raw) {
    return raw
        .replaceAll('\r', '')
        .replaceAll(' ', ' ')
        // Marcas de Markdown y tablas de los manuales digitalizados.
        .replaceAll(RegExp('[*#|_]'), ' ')
        // Referencias de página de los manuales digitalizados: «{p.64}».
        .replaceAll(RegExp(r'\{[^}]*\}'), ' ')
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        // Restos de maquetación: números sueltos y créditos de ilustración.
        .where((line) => !RegExp(r'^[\d\s.,/]+$').hasMatch(line))
        .where((line) => !RegExp('ilustrad[oa] por|©', caseSensitive: false).hasMatch(line))
        .toList();
  }

  static final _longAnchor = RegExp(r'^Nivel\s*:', caseSensitive: false);
  static final _compactAnchor = RegExp(r'^Categor[ií]a\s*:?\s*[^;:]+;\s*Nivel', caseSensitive: false);

  static bool _isAnchor(String line) => _longAnchor.hasMatch(line) || _compactAnchor.hasMatch(line);

  /// Nombre y subtítulos: renglones cortos sin números ni etiquetas.
  static bool _isHeader(String line) {
    return RegExp('[A-Za-zÁÉÍÓÚáéíóúñÑ]').hasMatch(line) && !line.contains(':') && !RegExp(r'\d').hasMatch(line) && !line.endsWith(',') && line.split(' ').length <= 7;
  }

  static List<List<String>> _splitBlocks(List<String> lines) {
    final anchors = [
      for (var i = 0; i < lines.length; i++)
        if (_isAnchor(lines[i])) i,
    ];

    if (anchors.isEmpty) return lines.isEmpty ? [] : [lines];

    final starts = <int>[];

    for (var k = 0; k < anchors.length; k++) {
      final previous = k == 0 ? -1 : anchors[k - 1];
      var start = anchors[k];

      while (start - 1 > previous && anchors[k] - (start - 1) <= 4 && _isHeader(lines[start - 1])) {
        start--;
      }

      starts.add(start);
    }

    return [
      for (var k = 0; k < starts.length; k++) lines.sublist(starts[k], k + 1 < starts.length ? starts[k + 1] : lines.length),
    ];
  }

  /// Quita tildes sin cambiar la longitud, para buscar sobre una copia.
  static String _fold(String text) {
    const from = 'áéíóúüñÁÉÍÓÚÜÑ';
    const to = 'aeiouunAEIOUUN';
    final buffer = StringBuffer();

    for (final char in text.split('')) {
      final index = from.indexOf(char);
      buffer.write(index < 0 ? char : to[index]);
    }

    return buffer.toString();
  }

  static String _key(String text) => _fold(text).toLowerCase().trim();

  static String _joinLines(List<String> lines) {
    final buffer = StringBuffer();

    for (final line in lines) {
      if (buffer.isEmpty) {
        buffer.write(line);
      } else if (buffer.toString().endsWith('-') && RegExp('^[a-zñáéíóú]').hasMatch(line)) {
        // Palabra partida al final del renglón.
        final text = buffer.toString();
        buffer
          ..clear()
          ..write(text.substring(0, text.length - 1))
          ..write(line);
      } else {
        buffer.write(' $line');
      }
    }

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Etiquetas

  static const _longLabels = [
    'Nivel de Via',
    'Nivel',
    'Clase',
    'Puntos de Vida',
    'Categoria',
    'Fue',
    'Des',
    'Agi',
    'Con',
    'Pod',
    'Int',
    'Vol',
    'Per',
    'Turno',
    'Habilidad de ataque',
    'Habilidad de defensa',
    'Dano',
    'TA',
    'Habilidades esenciales',
    'Habilidades naturales',
    'Habilidades Secundarias',
    'Habilidades',
    'Poderes',
    'Tamano',
    'Tipo de movimiento',
    'Regeneracion',
    'Cansancio',
    'Especial',
    'ACT',
    'Zeon',
    'Proyeccion magica',
    'Proyeccion psiquica',
    'Resistencias',
  ];

  static const _compactLabels = [
    'Categoria',
    'Nivel',
    'Turno',
    'Pv',
    'TA',
    'HA',
    'HP',
    'HE',
    'Armas',
    'Dano',
    'Habilidades',
    'Especial',
    'Resistencias',
    'Poderes',
    'Zeon',
    'ACT',
    'Proyeccion magica',
    'Proyeccion psiquica',
    'Proyeccion Magica',
    'Proyeccion Psiquica',
    'Nivel en Via',
    'AGI',
    'DES',
    'CON',
    'FUE',
    'PER',
    'INT',
    'VOL',
    'POD',
  ];

  static RegExp _labelPattern(List<String> labels, {required bool compact}) {
    final sorted = [...labels]..sort((a, b) => b.length.compareTo(a.length));
    final alternation = sorted.map(RegExp.escape).join('|');

    // Formato largo: siempre con dos puntos. Compacto: los dos puntos son
    // opcionales, así que distingue mayúsculas para no confundir «CON» con
    // «con».
    return compact
        // En el compacto una etiqueta nunca sigue a una preposición o un
        // artículo: «Maestro de Armas» es una categoría, no el campo Armas.
        ? RegExp('(?<![A-Za-z(/])(?<!\\b(?:de|del|la|las|los|el|y|o|e|a|en|con|sin) )($alternation)(?![A-Za-z])\\s*:?')
        : RegExp('(?<![A-Za-z])($alternation)\\s*:', caseSensitive: false);
  }

  /// Etiquetas no previstas del formato largo: «Algo:» tras un punto.
  static final _genericLabel = RegExp(r'(?<=[.;]\s)([A-Z][a-z]+(?: [a-z]+){0,3})\s*:');

  static Map<String, String> _fields(String text, {required bool compact}) {
    final folded = _fold(text);
    final matches = [
      ..._labelPattern(compact ? _compactLabels : _longLabels, compact: compact).allMatches(folded),
      if (!compact) ..._genericLabel.allMatches(folded),
    ]..sort((a, b) => a.start.compareTo(b.start));

    // Una etiqueta genérica puede solaparse con una conocida.
    final unique = <RegExpMatch>[];
    for (final match in matches) {
      if (unique.isNotEmpty && match.start < unique.last.end) continue;
      unique.add(match);
    }

    final fields = <String, String>{};

    for (var i = 0; i < unique.length; i++) {
      final match = unique[i];
      final end = i + 1 < unique.length ? unique[i + 1].start : text.length;
      final key = match.group(1)!.toLowerCase().replaceFirst('nivel en via', 'nivel de via');
      final value = text.substring(match.end, end).trim().replaceAll(RegExp(r'^[:\s]+|[;,.\s]+$'), '');

      fields.putIfAbsent(key, () => value);
    }

    return fields;
  }

  // ---------------------------------------------------------------------------
  // Valores

  /// Primer número, aceptando el punto de miles («3.005»).
  static int? _firstInt(String? text) {
    if (text == null) return null;

    final match = RegExp(r'-?\d{1,3}(?:\.\d{3})+(?!\d)|-?\d+').firstMatch(text);

    return match == null ? null : int.parse(match.group(0)!.replaceAll('.', ''));
  }

  static List<String> _splitTopLevel(String text, Pattern separator) {
    final parts = <String>[];
    var depth = 0;
    var current = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final char = text[i];

      if (char == '(') depth++;
      if (char == ')') depth = max(0, depth - 1);

      if (depth == 0 && separator.matchAsPrefix(text, i) != null) {
        parts.add(current.toString());
        current = StringBuffer();
        i += separator.matchAsPrefix(text, i)!.end - i - 1;
        continue;
      }

      current.write(char);
    }

    parts.add(current.toString());

    return parts.map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
  }

  static const _stopWords = {'de', 'del', 'la', 'las', 'los', 'el', 'y', 'e', 'o', 'u', 'a', 'en', 'con', 'como', 'arma', 'armas'};

  static Set<String> _stems(String text) {
    return _key(text)
        .split(RegExp('[^a-z0-9]+'))
        .where((word) => word.length >= 4 && !_stopWords.contains(word))
        .map((word) => word.substring(0, min(5, word.length)))
        .toSet();
  }

  static bool _sharesWord(String a, String b) => _stems(a).intersection(_stems(b)).isNotEmpty;

  static String _capitalize(String word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1);

  static String _formatName(String raw) {
    final tokens = raw.split(' ').where((token) => token.isNotEmpty).toList();

    // Versalitas pegadas como «z ombI».
    if (tokens.length > 1 && tokens[0].length == 1 && RegExp('^[a-zñ]').hasMatch(tokens[1]) && !_stopWords.contains(tokens[1].toLowerCase())) {
      tokens
        ..[1] = tokens[0] + tokens[1]
        ..removeAt(0);
    }

    return [
      for (var i = 0; i < tokens.length; i++)
        if (RegExp(r'^[IVX]+$').hasMatch(tokens[i]) && i > 0)
          tokens[i]
        else if (i > 0 && _stopWords.contains(tokens[i].toLowerCase()) && tokens[i].toLowerCase() != 'arma')
          tokens[i].toLowerCase()
        else
          _capitalize(tokens[i].toLowerCase()),
    ].join(' ');
  }

  /// Orden de la Tabla 38 y de [NpcReferenceTables.armours].
  static const _armourTypes = ['FIL', 'CON', 'PEN', 'CAL', 'ELE', 'FRI', 'ENE'];

  static List<String> _criticalsIn(String text) {
    // «FIL», «(Fil)», «(Filo)» o «(Penetrante / Calor)».
    final pattern = RegExp(r'\b(FIL|PEN|CON|CAL|ELE|FRI|ENE)\b|(?<=[(/,]\s*)(Fil|Pen|Con|Cal|Ele|Fri|Ene)[a-z]*(?=\s*[)/,])');

    return [for (final match in pattern.allMatches(_fold(text))) (match.group(1) ?? match.group(2)!).toUpperCase()];
  }

  // ---------------------------------------------------------------------------
  // Perfil

  static NpcParseResult _parseBlock(List<String> block) {
    final anchor = block.indexWhere(_isAnchor);
    final header = anchor <= 0 ? <String>[] : block.sublist(0, anchor);
    final body = _joinLines(anchor < 0 ? block : block.sublist(anchor));
    final compact = anchor >= 0 && _compactAnchor.hasMatch(block[anchor]);
    final fields = _fields(body, compact: compact);
    final warnings = <String>[];

    String? field(String label) => fields[label.toLowerCase()];

    var name = header.isEmpty ? 'PNJ' : _formatName(header.first);
    if (header.length >= 3) name = '$name (${_formatName(header.last)})';

    // Vida y acumulación.
    final hitPointsText = compact ? field('Pv') : field('Puntos de Vida');
    final defenseText = compact ? null : field('Habilidad de defensa');
    final accumulation = RegExp('acumulaci', caseSensitive: false).hasMatch('${hitPointsText ?? ''} ${defenseText ?? ''} ${field('Especial') ?? ''}');
    final hitPoints = _firstInt(hitPointsText);
    if (hitPoints == null) warnings.add('No se encontraron los Puntos de Vida');

    final fatigueText = field('Cansancio');
    var fatigue = _firstInt(fatigueText);
    if (fatigue == null && RegExp('incansable', caseSensitive: false).hasMatch(fatigueText ?? '')) {
      // Incansable: con 0 de máximo nunca aplica el penalizador de la Tabla 27.
      fatigue = 0;
    }

    const attributeKeys = {'fue': 'FUE', 'des': 'DES', 'agi': 'AGI', 'con': 'CON', 'pod': 'POD', 'int': 'INT', 'vol': 'VOL', 'per': 'PER'};
    final attributes = <String, String>{
      for (final entry in attributeKeys.entries)
        if (field(entry.key)?.startsWith('-') ?? false)
          entry.value: '0'
        else if (_firstInt(field(entry.key)) case final value?)
          entry.value: '$value',
    };
    if (attributes.length < 8) warnings.add('Faltan características: se leyeron ${attributes.length} de 8');

    final resistances = <String, String>{};
    for (final match in RegExp(r'\bR([FMPVE])\s*:?\s*(\d+)').allMatches(body)) {
      resistances.putIfAbsent('R${match.group(1)}', () => match.group(2)!);
    }
    if (resistances.length < 5) warnings.add('Faltan resistencias: se leyeron ${resistances.length} de 5');

    final weapons = _weapons(fields, compact: compact, accumulation: accumulation, warnings: warnings);
    final armour = _armour(field('TA'), warnings);

    final skills = <String, String>{
      for (final item in _splitTopLevel(field(compact ? 'Habilidades' : 'Habilidades Secundarias') ?? '', ','))
        if (RegExp(r'^(.*?)\s*(-?\d+)').firstMatch(item) case final match? when match.group(1)!.trim().isNotEmpty)
          match.group(1)!.trim(): match.group(2)!,
    };

    final special = field('Especial') ?? '';
    final tables = {
      for (final item in _splitTopLevel(special, RegExp(',|;')))
        if (RegExp('^tabla', caseSensitive: false).hasMatch(_key(item))) item: '',
    };

    final zeon = _firstInt(field('Zeon'));

    return NpcParseResult(
      name: name,
      warnings: warnings,
      json: {
        'datosElementales': {
          'nombre': name,
          'categoria': field('Categoria') ?? '',
          'nivel': '${_firstInt(field('Nivel')) ?? ''}',
          'clase': field('Clase') ?? '',
          'puntosDeVida': '${hitPoints ?? 0}',
          // El formato compacto no los trae: salen de las características
          // (Core: Cansancio = CON, Tipo de movimiento = AGI, Tabla 23).
          'cansancio': '${fatigue ?? int.tryParse(attributes['CON'] ?? '') ?? 6}',
          'regeneracion': '${_firstInt(field('Regeneracion')) ?? _regenerationFor(int.tryParse(attributes['CON'] ?? ''))}',
          'movimiento': '${_firstInt(field('Tipo de movimiento')) ?? int.tryParse(attributes['AGI'] ?? '') ?? 6}',
          'acumDanio': accumulation ? 'Si' : 'No',
        },
        'Atributos': attributes,
        'Resistencias': resistances,
        'Habilidades': skills,
        'Combate': {
          'armas': weapons,
          'armadura': armour,
          'TablasDeArmas': tables,
        },
        if (zeon != null && zeon > 0)
          'Misticos': {
            'zeon': '$zeon',
            'act': '${_firstInt(field('ACT')) ?? 0}',
            'regen': '0',
          },
      },
    );
  }

  /// Tabla 23: índice de regeneración según la Constitución.
  static int _regenerationFor(int? constitution) {
    if (constitution == null) return 1;
    if (constitution <= 2) return 0;
    if (constitution <= 7) return 1;
    if (constitution <= 9) return 2;

    return min(constitution - 7, 12);
  }

  static List<Map<String, dynamic>> _weapons(
    Map<String, String> fields, {
    required bool compact,
    required bool accumulation,
    required List<String> warnings,
  }) {
    String? field(String label) => fields[label.toLowerCase()];

    // Ataques: nombre y habilidad.
    final attacks = <(String, int)>[];

    if (compact) {
      final attack = _firstInt(field('HA'));
      var names = (field('Armas') ?? 'Arma').replaceAll(RegExp(r'\bEsp\.\s*', caseSensitive: false), 'Espada ');

      if (RegExp(r'^(no|ninguna)$', caseSensitive: false).hasMatch(names)) names = unarmed;

      // «Armas Natural» con el detalle en Especial: «Arma natural: Coz (CON)».
      final natural = RegExp(r'Arma natural\s*[:;]\s*([^(,.;]+)', caseSensitive: false).firstMatch(field('Especial') ?? '');
      if (_key(names) == 'natural' && natural != null) names = natural.group(1)!.trim();

      // «Espada Larga / Lanza de Caballería»: una por cada una, y el daño
      // «55/85» en el mismo orden.
      if (attack != null) {
        for (final name in names.split(RegExp(r'\s*/\s*'))) {
          attacks.add((_capitalize(name), attack));
        }
      }
    } else {
      for (var segment in _splitTopLevel(field('Habilidad de ataque') ?? '', RegExp(r';|\s\+\s'))) {
        segment = segment.replaceFirst(RegExp(r'^o\s+'), '');
        final match = RegExp(r'^(\d+)\s*(.*)$').firstMatch(segment);

        if (match == null) continue;

        final value = int.parse(match.group(1)!);
        final names = match.group(2)!.replaceAll(RegExp(r'[.,;\s]+$'), '');

        if (names.isEmpty) {
          attacks.add(('Ataque', value));
          continue;
        }

        // «120 Espada larga, Garras o Armas de cazador»: la misma habilidad con
        // cada una. «Arma» o «Armas de…» son las que lleve, que no vienen en
        // el perfil.
        final parts = _splitTopLevel(names, RegExp(r',|\so\s'));
        final concrete = parts.where((part) => !_key(part).startsWith('arma')).toList();

        if (concrete.length < parts.length) {
          warnings.add('${concrete.isEmpty ? names : parts.where((part) => !concrete.contains(part)).join(', ')}: '
              'usa armas que el perfil no detalla, agregalas a mano');
        }

        for (final part in concrete.isEmpty ? [names] : concrete) {
          // «200 Garras, 190 Arrollar»: la parte trae su propia habilidad.
          final own = RegExp(r'^(\d+)\s+(.+)$').firstMatch(part);

          attacks.add(own == null ? (_capitalize(part), value) : (_capitalize(own.group(2)!), int.parse(own.group(1)!)));
        }
      }
    }

    // Defensa.
    var defense = 0;
    var defenseType = 'Par';

    if (compact) {
      final parry = _firstInt(field('HP'));
      final dodge = _firstInt(field('HE'));

      if ((dodge ?? -1) > (parry ?? -1)) {
        defense = dodge!;
        defenseType = 'Esq';
      } else {
        defense = parry ?? 0;
      }
    } else {
      final text = field('Habilidad de defensa') ?? '';

      if (!RegExp('acumulaci', caseSensitive: false).hasMatch(text)) {
        defense = _firstInt(text) ?? 0;
        if (RegExp('esquiva', caseSensitive: false).hasMatch(text)) defenseType = 'Esq';
      }
    }

    final hasProjection = [field('Proyeccion magica'), field('Proyeccion psiquica')].any((text) => (_firstInt(text) ?? 0) > 0);
    if (!accumulation && defense == 0 && !hasProjection) warnings.add('No se encontró la habilidad de defensa');

    // Turno, con valores por arma si los hay («75 Natural, 55 Espada larga»).
    final turnText = field('Turno') ?? '';
    final baseTurn = _firstInt(turnText) ?? 0;
    final turns = <(String, int)>[
      for (final segment in _splitTopLevel(turnText, RegExp(r',|;|\so\s')))
        if (RegExp(r'^(\d+)\s*(.*)$').firstMatch(segment) case final match?) (match.group(2)!, int.parse(match.group(1)!)),
    ];

    // Daño: «130 Garras FIL, 150 Mordisco PEN» o «80/90».
    final damages = <({String name, int value, List<String> criticals, bool variable})>[];

    final damageText = field('Dano') ?? '';
    final damageSegments = compact && RegExp(r'^\d+(\s*/\s*\d+)+$').hasMatch(damageText)
        ? damageText.split('/').map((value) => value.trim()).toList()
        : _splitTopLevel(damageText, RegExp('[,;]'));

    for (var segment in damageSegments) {
      segment = segment.replaceFirst(RegExp(r'^o\s+'), '');
      final match = RegExp(r'^(\d+)\s*(.*)$').firstMatch(segment);

      if (match == null) continue;

      final rest = match.group(2)!;
      damages.add((
        name: rest.replaceAll(RegExp(r'\([^)]*\)|\b(FIL|PEN|CON|CAL|ELE|FRI|ENE)\b|/'), ' ').trim(),
        value: int.parse(match.group(1)!),
        criticals: _criticalsIn(rest),
        variable: RegExp('variable', caseSensitive: false).hasMatch(rest),
      ));
    }

    if (damages.isEmpty && attacks.isNotEmpty) warnings.add('No se encontró el daño');

    final weapons = <Map<String, dynamic>>[];

    for (var i = 0; i < attacks.length; i++) {
      final (name, attack) = attacks[i];

      final damage = damages.where((damage) => damage.name.isNotEmpty && _sharesWord(damage.name, name)).firstOrNull ??
          (damages.length == 1 ? damages.first : (i < damages.length ? damages[i] : damages.firstOrNull));

      final turn = turns.where((turn) => turn.$1.isNotEmpty && _sharesWord(turn.$1, name)).firstOrNull?.$2 ?? baseTurn;

      var criticals = damage?.criticals ?? const <String>[];

      if (criticals.isEmpty && compact) {
        final special = RegExp('${RegExp.escape(name)}\\s*\\(([^)]*)\\)', caseSensitive: false).firstMatch(field('Especial') ?? '');
        if (special != null) criticals = _criticalsIn(special.group(1)!.toUpperCase());
      }

      if (criticals.isEmpty && name == unarmed) criticals = const ['CON'];

      if (criticals.isEmpty) {
        final key = _key(name);
        final known = NpcReferenceTables.weaponCriticals.entries.where((entry) => key.contains(entry.key)).fold<MapEntry<String, (String, String)>?>(
              null,
              (best, entry) => best == null || entry.key.length > best.key.length ? entry : best,
            );

        if (known != null) {
          criticals = [known.value.$1, if (known.value.$2.isNotEmpty) known.value.$2];
        } else {
          warnings.add('$name: sin tipo de crítico, queda en FIL');
        }
      }

      if (damage?.variable ?? false) warnings.add('$name: el daño es variable, revisalo al atacar');

      weapons.add({
        'nombre': name,
        'tipo': name == unarmed ? 'desarmado' : '',
        'conocimiento': 'Conocida',
        'tamanio': 'Normal',
        'critPrincipal': criticals.firstOrNull ?? 'FIL',
        'critSecundario': criticals.length > 1 ? criticals[1] : (criticals.firstOrNull ?? 'FIL'),
        'turno': '$turn',
        'ataque': '$attack',
        'defensa': '$defense',
        'defensaTipo': defenseType,
        'danio': '${damage?.value ?? 0}',
        'calidad': '0',
        'reduccionTA': '${_armourReductionFor(name, field('Poderes') ?? '')}',
      });
    }

    // Proyecciones como un arma más, igual que al importar la planilla.
    for (final (label, weaponName) in [('Proyeccion magica', 'Proyección Mágica'), ('Proyeccion psiquica', 'Proyección Psíquica')]) {
      final text = field(label);
      final value = _firstInt(text);

      if (value == null || value <= 0) continue;

      final offensiveOnly = RegExp('ofensiva', caseSensitive: false).hasMatch(text!);
      final defensiveOnly = RegExp('defensiva', caseSensitive: false).hasMatch(text);

      weapons.add({
        'nombre': weaponName,
        'tipo': weaponName,
        'conocimiento': 'Conocida',
        'tamanio': 'Normal',
        'critPrincipal': 'ENE',
        'critSecundario': 'ENE',
        'turno': '$baseTurn',
        'ataque': defensiveOnly ? '0' : '$value',
        'defensa': offensiveOnly ? '0' : '$value',
        'defensaTipo': 'Par',
        'danio': '0',
        'variable': true,
      });
    }

    if (weapons.isEmpty) {
      warnings.add(NpcTextParser.noAttack);
      weapons.add({
        'nombre': 'Sin ataque',
        'turno': '$baseTurn',
        'ataque': '0',
        'defensa': '$defense',
        'defensaTipo': defenseType,
        'danio': '0',
      });
    }

    return weapons;
  }

  /// «Garras, Mordisco (…, Armadura -1)» o «Cuchilla (…, -2 a la TA Defensora)».
  static int _armourReductionFor(String weapon, String powers) {
    for (final match in RegExp(r'([^():;]*)\(([^()]*)\)').allMatches(powers)) {
      final inner = match.group(2)!;
      final value = RegExp(r'Armadura\s*-\s*(\d+)', caseSensitive: false).firstMatch(inner)?.group(1) ??
          RegExp(r'-\s*(\d+)\s*a la TA', caseSensitive: false).firstMatch(inner)?.group(1);

      if (value != null && _sharesWord(match.group(1)!, weapon)) return int.parse(value);
    }

    return 0;
  }

  static Map<String, dynamic> _armour(String? text, List<String> warnings) {
    Map<String, dynamic> build(String name, List<int> values) {
      return {
        'armaduraTotal': {
          'nombre': name,
          for (var i = 0; i < _armourTypes.length; i++) _armourTypes[i]: '${values[i]}',
        },
        'armaduras': [
          {'nombre': name},
        ],
      };
    }

    if (text == null || text.isEmpty) {
      warnings.add('No se encontró la TA: queda en 0');
      return build('Sin armadura', List.filled(7, 0));
    }

    if (RegExp(r'^(no|na|n/a|-)$|ninguna|sin armadura', caseSensitive: false).hasMatch(text.trim())) return build('Sin armadura', List.filled(7, 0));

    // Por tipo: «Fil 7 Con 7 Pen 7…».
    final perType = <String, int>{
      for (final match in RegExp(r'\b(Fil|Con|Pen|Cal|Ele|Fri|Ene)\s*:?\s*(\d+)', caseSensitive: false).allMatches(text))
        match.group(1)!.toUpperCase(): int.parse(match.group(2)!),
    };

    final name = text.split(RegExp(r':|\b(Fil|Con|Pen|Cal|Ele|Fri|Ene)\b\s*\d|\d')).first.trim();

    if (perType.isNotEmpty) {
      return build(name.isEmpty ? 'Armadura' : _capitalize(name), [for (final type in _armourTypes) perType[type] ?? 0]);
    }

    // Por nombre, con la Tabla 38.
    final key = _key(text);
    final known = NpcReferenceTables.armours.keys.where(key.contains).fold<String?>(null, (best, entry) => best == null || entry.length > best.length ? entry : best);

    if (known != null) return build(_capitalize(text), NpcReferenceTables.armours[known]!);

    // Natural: «TA X» protege contra todo menos Energía (Core, Poderes).
    final value = _firstInt(text);

    if (value != null) return build(name.isEmpty ? 'Natural' : _capitalize(name), [...List.filled(6, value), 0]);

    warnings.add('TA «$text» no reconocida: queda en 0');
    return build(_capitalize(text), List.filled(7, 0));
  }
}
