import 'package:amt/models/character_model/character.dart';
import 'package:amt/models/enums.dart';
import 'package:amt/models/rules/additional_attack_rules.dart';
import 'package:amt/utils/app_theme.dart';
import 'package:amt/utils/key_value.dart';
import 'package:amt/utils/status_colors.dart';
import 'package:amt/utils/xlsx/xlsx_workbook.dart';
import 'package:flutter/material.dart';
import 'package:function_tree/function_tree.dart';

/// Ficha de consulta de un personaje.
///
/// Sigue la lógica de un bloque de estadísticas del bestiario: lo que se mira
/// en cada turno arriba y a la vista, y el detalle debajo. Antes era una tabla
/// ancha con diez columnas de dificultad por fila que ocupaba toda la pantalla;
/// esa escalera ahora aparece solo al tocar una habilidad.
class ShowCharacterInfo {
  static Future<void> call(BuildContext context, Character character, {required void Function(Character) onEdit}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CharacterSheet(character: character, onEdit: onEdit),
    );
  }
}

class _CharacterSheet extends StatefulWidget {
  const _CharacterSheet({required this.character, required this.onEdit});

  final Character character;
  final void Function(Character) onEdit;

  @override
  State<_CharacterSheet> createState() => _CharacterSheetState();
}

class _CharacterSheetState extends State<_CharacterSheet> {
  String _search = '';

  /// Habilidad cuya escalera de dificultades está desplegada.
  String? _expandedSkill;

  Character get _character => widget.character;

  void _commit(VoidCallback change) {
    setState(change);
    widget.onEdit(_character);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.9;

    return SizedBox(
      height: height,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            children: [
              _Header(character: _character),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _vitals(theme),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 720;
                        final left = [_attributes(theme), const SizedBox(height: 16), _resistances(theme)];
                        final right = [
                          _combat(theme),
                          if (_hasSupernatural) ...[const SizedBox(height: 16), _supernatural(theme)]
                        ];

                        if (!wide)
                          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...left, const SizedBox(height: 16), ...right]);

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: left)),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _skills(theme),
                    ..._lists(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Vitales

  Widget _vitals(ThemeData theme) {
    final profile = _character.profile;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatTile(label: 'Puntos de vida', value: '${profile.hitPoints}', emphasis: true),
        _StatTile(label: 'Cansancio', value: '${profile.fatigue}'),
        _StatTile(label: 'Regeneración', value: '${profile.regeneration}'),
        _StatTile(label: 'Movimiento', value: '${profile.speed}'),
        _StatTile(label: 'Turno', value: '${_character.calculateTurnBase()}'),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Características y resistencias

  Widget _attributes(ThemeData theme) {
    final values = _character.attributes.toKeyValue();
    final short = _character.attributes.toKeyValue(abbreviated: true);

    return _Section(
      title: 'Características',
      child: _EditableGrid(
        columns: 4,
        items: [
          for (var i = 0; i < values.length; i++)
            _EditableItem(
              label: short[i].key,
              tooltip: values[i].key,
              value: values[i].value,
              onChanged: (value) => _commit(() => _character.attributes.edit(KeyValue(key: values[i].key, value: value))),
            ),
        ],
      ),
    );
  }

  Widget _resistances(ThemeData theme) {
    final resistances = _character.resistances;

    if (resistances == null) return const SizedBox.shrink();

    const names = {
      'Pres': 'Presencia',
      'RF': 'Resistencia física',
      'RE': 'Resistencia a enfermedades',
      'RV': 'Resistencia a venenos',
      'RM': 'Resistencia mágica',
      'RP': 'Resistencia psíquica',
    };

    return _Section(
      title: 'Resistencias',
      child: _EditableGrid(
        columns: 6,
        items: [
          for (final item in resistances.toKeyValue())
            _EditableItem(
              label: item.key,
              tooltip: names[item.key],
              value: item.value,
              onChanged: (value) => _commit(() => resistances.editResistance(KeyValue(key: item.key, value: value))),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Combate

  Widget _combat(ThemeData theme) {
    final weapon = _character.selectedWeapon();
    final armour = _character.combat.armour.calculatedArmour;
    final defenseLabel = weapon.defenseType == DefenseType.parry ? 'Parada' : 'Esquiva';
    // Si el critico secundario coincide con el principal no aporta nada.
    final critical = {weapon.principalDamage?.name, weapon.secondaryDamage?.name}.whereType<String>().map((e) => e.toUpperCase()).join(' / ');

    return _Section(
      title: 'Combate',
      trailing: Text(weapon.name, style: theme.textTheme.labelMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatTile(label: 'Ataque', value: _evaluate(_character.calculateAttack()), emphasis: true),
              _StatTile(label: defenseLabel, value: _evaluate(_character.calculateDefense(weapon.defenseType)), emphasis: true),
              _StatTile(label: 'Daño', value: '${weapon.damage}', caption: critical.isEmpty ? null : critical),
            ],
          ),
          const SizedBox(height: 12),
          Text('Tipo de armadura', style: theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          _ReadOnlyGrid(
            columns: 7,
            items: {
              'FIL': armour.fil,
              'CON': armour.con,
              'PEN': armour.pen,
              'CAL': armour.cal,
              'ELE': armour.ele,
              'FRI': armour.fri,
              'ENE': armour.ene,
            },
          ),
          const SizedBox(height: 12),
          Text('Ataques adicionales', style: theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: const Text('Ambidestría'),
                tooltip: 'El ataque con un arma adicional aplica −10 en vez de −40',
                selected: _character.combat.ambidextrous,
                onSelected: (value) => _commit(() => _character.combat.ambidextrous = value),
              ),
              FilterChip(
                label: const Text('Tabla de Ataque Encadenado'),
                tooltip: 'Armas grandes como medias y medias como pequeñas',
                selected: _character.combat.chainAttackTable,
                onSelected: (value) => _commit(() => _character.combat.chainAttackTable = value),
              ),
              _GradeMenu(
                label: 'Kempo',
                grade: _character.combat.kempoGrade,
                onSelected: (grade) => _commit(() => _character.combat.kempoGrade = grade),
              ),
              _GradeMenu(
                label: 'Tae Kwon Do',
                grade: _character.combat.taeKwonDoGrade,
                onSelected: (grade) => _commit(() => _character.combat.taeKwonDoGrade = grade),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Las fórmulas de ataque y defensa llegan como expresión ("120-30").
  String _evaluate(String expression) {
    try {
      return expression.interpret().toInt().toString();
    } catch (_) {
      return expression;
    }
  }

  // ---------------------------------------------------------------------------
  // Sobrenatural

  bool get _hasSupernatural => _kiTotal > 0 || (_character.mystical?.zeon ?? 0) > 0 || (_character.psychic?.freeCvs ?? 0) > 0;

  int get _kiTotal {
    final ki = _character.ki;
    if (ki == null) return 0;

    final perAttribute = ki.maximumPerAttribute.orderedList().fold(0, (total, value) => total + (value > 0 ? value : 0));
    return perAttribute > 0 ? perAttribute : ki.maximumAccumulation;
  }

  Widget _supernatural(ThemeData theme) {
    final mystical = _character.mystical;
    final psychic = _character.psychic;
    final ki = _character.ki;

    return _Section(
      title: 'Sobrenatural',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_kiTotal > 0)
            _StatTile(label: 'Ki', value: '$_kiTotal', caption: ki != null && ki.genericAccumulation > 0 ? 'Acum. ${ki.genericAccumulation}' : null),
          if ((mystical?.zeon ?? 0) > 0) _StatTile(label: 'Zeon', value: '${mystical!.zeon}', caption: 'ACT ${mystical.act}'),
          if ((mystical?.zeonRegeneration ?? 0) > 0) _StatTile(label: 'Regen. Zeon', value: '${mystical!.zeonRegeneration}'),
          if ((psychic?.freeCvs ?? 0) > 0) _StatTile(label: 'CV libres', value: '${psychic!.freeCvs}'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Habilidades secundarias

  Widget _skills(ThemeData theme) {
    final query = XlsxWorkbook.normalizeName(_search);
    final grouped = <String, List<KeyValue>>{};

    for (final skill in _character.skills.list()) {
      if (query.isNotEmpty && !XlsxWorkbook.normalizeName(skill.key).contains(query)) continue;
      grouped.putIfAbsent(_SkillCategories.of(skill.key), () => []).add(skill);
    }

    final categories = _SkillCategories.order.where(grouped.containsKey).toList();

    return _Section(
      title: 'Habilidades secundarias',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar habilidad, vía, disciplina…',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
            onChanged: (value) => setState(() => _search = value),
          ),
          const SizedBox(height: 4),
          Text(
            'Tocá una habilidad para ver qué tirada necesita cada dificultad.',
            style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              // Sin busqueda, que no haya nada significa que la ficha no trae
              // habilidades, no que el filtro las haya descartado.
              child: Text(
                query.isEmpty ? 'Este personaje no tiene habilidades cargadas' : 'Ninguna habilidad coincide con "$_search"',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          for (final category in categories) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(category, style: theme.textTheme.labelLarge!.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / 240).floor().clamp(1, 4);
                final width = (constraints.maxWidth - 8 * (columns - 1)) / columns;

                return Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    for (final skill in grouped[category]!)
                      SizedBox(
                        width: _expandedSkill == skill.key ? constraints.maxWidth : width,
                        child: _SkillRow(
                          skill: skill,
                          expanded: _expandedSkill == skill.key,
                          onToggle: () => setState(() => _expandedSkill = _expandedSkill == skill.key ? null : skill.key),
                          onChanged: (value) => _commit(() => _character.skills[skill.key] = value),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Listas: vías, conjuros, disciplinas, habilidades de Ki

  List<Widget> _lists(ThemeData theme) {
    final mystical = _character.mystical;
    final psychic = _character.psychic;

    final sections = <String, List<KeyValue>?>{
      'Vías de magia': mystical?.paths.list(),
      'Subvías': mystical?.subPaths.list(),
      'Metamagia': mystical?.metamagic.list(),
      'Conjuros mantenidos': mystical?.spellsMaintained.list(),
      'Conjuros libres': mystical?.spellsPurchased.list(interchange: true),
      'Habilidades de Ki': _character.ki?.skills.list(),
      'Disciplinas psíquicas': psychic?.disciplines.list(),
      'Poderes psíquicos': psychic?.powers.list(),
      'Patrones mentales': psychic?.patterns.list(),
      'Innatos': psychic?.innate.list(),
    };

    final query = XlsxWorkbook.normalizeName(_search);
    final widgets = <Widget>[];

    for (final entry in sections.entries) {
      final items = (entry.value ?? [])
          .where((item) => item.key.trim().isNotEmpty && item.key != '-')
          .where((item) => query.isEmpty || XlsxWorkbook.normalizeName(item.key).contains(query))
          .toList();

      if (items.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Card(
            margin: EdgeInsets.zero,
            child: ExpansionTile(
              // Con una búsqueda activa se abren solas para mostrar lo encontrado.
              key: ValueKey('${entry.key}-${query.isNotEmpty}'),
              initiallyExpanded: query.isNotEmpty,
              title: Text(entry.key, style: theme.textTheme.titleSmall),
              trailing: _CountBadge(count: items.length),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.key, style: theme.textTheme.bodyMedium)),
                        if (item.value.trim().isNotEmpty && item.value != '-') Text(item.value, style: _numberStyle(theme)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

// -----------------------------------------------------------------------------
// Categorías de habilidades

abstract class _SkillCategories {
  static const order = ['Atléticas', 'Vigor', 'Perceptivas', 'Intelectuales', 'Sociales', 'Subterfugio', 'Creativas', 'Otras'];

  /// Agrupación del capítulo de Habilidades Secundarias del Core Exxet, más las
  /// que agrega la planilla. Lo que no figura cae en "Otras" en lugar de
  /// perderse, así también aparecen habilidades de otros manuales o caseras.
  static const _byName = {
    'acrobacias': 'Atléticas',
    'atletismo': 'Atléticas',
    'montar': 'Atléticas',
    'nadar': 'Atléticas',
    'saltar': 'Atléticas',
    'trepar': 'Atléticas',
    'pilotar': 'Atléticas',
    'frialdad': 'Vigor',
    'proezas de fuerza': 'Vigor',
    'resistir el dolor': 'Vigor',
    'advertir': 'Perceptivas',
    'buscar': 'Perceptivas',
    'rastrear': 'Perceptivas',
    'animales': 'Intelectuales',
    'ciencia': 'Intelectuales',
    'herbolaria': 'Intelectuales',
    'historia': 'Intelectuales',
    'medicina': 'Intelectuales',
    'memorizar': 'Intelectuales',
    'navegacion': 'Intelectuales',
    'ocultismo': 'Intelectuales',
    'tasacion': 'Intelectuales',
    'valoracion magica': 'Intelectuales',
    'tactica': 'Intelectuales',
    'ley': 'Intelectuales',
    'estilo': 'Sociales',
    'intimidar': 'Sociales',
    'liderazgo': 'Sociales',
    'persuasion': 'Sociales',
    'comercio': 'Sociales',
    'callejeo': 'Sociales',
    'etiqueta': 'Sociales',
    'cerrajeria': 'Subterfugio',
    'disfraz': 'Subterfugio',
    'ocultarse': 'Subterfugio',
    'robo': 'Subterfugio',
    'sigilo': 'Subterfugio',
    'tramperia': 'Subterfugio',
    'venenos': 'Subterfugio',
    'arte': 'Creativas',
    'baile': 'Creativas',
    'forja': 'Creativas',
    'musica': 'Creativas',
    'trucos de manos': 'Creativas',
    'runas': 'Creativas',
    'alquimia': 'Creativas',
    'animismo': 'Creativas',
    'caligrafia': 'Creativas',
  };

  static String of(String skill) => _byName[XlsxWorkbook.normalizeName(skill)] ?? 'Otras';
}

// -----------------------------------------------------------------------------
// Piezas visuales

TextStyle _numberStyle(ThemeData theme, {bool strong = false}) {
  return (strong ? theme.textTheme.titleLarge! : theme.textTheme.bodyMedium!).copyWith(
    fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: theme.colorScheme.onSurface,
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = character.profile;
    final subtitle = [
      profile.category,
      if (profile.level.trim().isNotEmpty) 'Nivel ${profile.level}',
      profile.kind,
    ].where((part) => part.trim().isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.trim().isEmpty ? 'Sin nombre' : profile.name,
                  style: theme.textTheme.headlineSmall!.copyWith(fontFamily: 'Metamorphous', fontWeight: FontWeight.w700),
                ),
                if (subtitle.isNotEmpty) Text(subtitle, style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                if ((profile.damageAccumulation ?? false) || (profile.uroboros ?? false) || profile.isMass)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (profile.isMass) _RuleChip(label: 'Masa de ${profile.massSize}', color: theme.colorScheme.primary),
                        if (profile.damageAccumulation ?? false) _RuleChip(label: 'Acumulación de daño', color: theme.colorScheme.danger),
                        if (profile.uroboros ?? false) _RuleChip(label: 'Uróboros', color: theme.colorScheme.uroboros),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

/// Grado en un arte marcial, elegido de un menú.
class _GradeMenu extends StatelessWidget {
  const _GradeMenu({required this.label, required this.grade, required this.onSelected});

  final String label;
  final int grade;
  final void Function(int) onSelected;

  @override
  Widget build(BuildContext context) {
    final grades = AdditionalAttackRules.martialArtGrades;
    final known = grade > 0;

    return PopupMenuButton<int>(
      tooltip: 'Grado en $label',
      initialValue: grade,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (var i = 0; i < grades.length; i++) PopupMenuItem(value: i, child: Text(i == 0 ? 'No lo domina' : grades[i])),
      ],
      child: Chip(
        avatar: Icon(known ? Icons.check : Icons.expand_more, size: 18),
        label: Text(known ? '$label: ${grades[grade]}' : label),
      ),
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: color),
      ),
      child: Text(label, style: theme.textTheme.labelSmall!.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 4),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant))),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: theme.textTheme.labelMedium!.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        child,
      ],
    );
  }
}

/// Valor destacado con su etiqueta, para lo que se consulta en cada turno.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.caption, this.emphasis = false});

  final String label;
  final String value;
  final String? caption;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: emphasis ? theme.colorScheme.secondaryContainer : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: _numberStyle(theme, strong: true)),
          if (caption != null) Text(caption!, style: theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _EditableItem {
  const _EditableItem({required this.label, required this.value, required this.onChanged, this.tooltip});

  final String label;
  final String value;
  final String? tooltip;
  final void Function(String) onChanged;
}

/// Grilla de valores cortos editables en el lugar (características, resistencias).
class _EditableGrid extends StatelessWidget {
  const _EditableGrid({required this.columns, required this.items});

  final int columns;
  final List<_EditableItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // En pantallas angostas las seis resistencias pasan a dos filas de tres.
        final fit = (constraints.maxWidth / 64).floor().clamp(1, columns);
        final width = (constraints.maxWidth - 6 * (fit - 1)) / fit;

        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: Tooltip(
                  message: item.tooltip ?? item.label,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    ),
                    child: Column(
                      children: [
                        Text(item.label,
                            style: theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                        _InlineNumberField(value: item.value, onChanged: item.onChanged, style: _numberStyle(theme, strong: true)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ReadOnlyGrid extends StatelessWidget {
  const _ReadOnlyGrid({required this.columns, required this.items});

  final int columns;
  final Map<String, int> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final fit = (constraints.maxWidth / 48).floor().clamp(1, columns);
        final width = (constraints.maxWidth - 4 * (fit - 1)) / fit;

        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final entry in items.entries)
              Container(
                width: width,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                child: Column(
                  children: [
                    Text(entry.key, style: theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text('${entry.value}', style: _numberStyle(theme)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Número editable sin recuadro, que se ve como texto hasta que se lo toca.
class _InlineNumberField extends StatefulWidget {
  const _InlineNumberField({required this.value, required this.onChanged, required this.style, this.textAlign = TextAlign.center});

  final String value;
  final void Function(String) onChanged;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  State<_InlineNumberField> createState() => _InlineNumberFieldState();
}

class _InlineNumberFieldState extends State<_InlineNumberField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _InlineNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text && !_controller.selection.isValid) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textAlign: widget.textAlign,
      style: widget.style,
      keyboardType: const TextInputType.numberWithOptions(signed: true),
      decoration: const InputDecoration(
        isDense: true,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 2),
      ),
      onChanged: widget.onChanged,
    );
  }
}

/// Fila de habilidad: nombre, valor editable y, al tocarla, la escalera de
/// dificultades con la tirada que hace falta para cada una.
class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill, required this.expanded, required this.onToggle, required this.onChanged});

  final KeyValue skill;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = int.tryParse(skill.value.trim()) ??
        (() {
          try {
            return skill.value.interpret().toInt();
          } catch (_) {
            return null;
          }
        })();

    // Los negativos son información (penalizador por no tener la habilidad),
    // así que se atenúan pero no se ocultan.
    final muted = value != null && value <= 0;

    return Material(
      color: expanded ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.6) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 4, 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      skill.key,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium!.copyWith(color: muted ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: _InlineNumberField(
                      value: skill.value,
                      onChanged: onChanged,
                      textAlign: TextAlign.right,
                      style: _numberStyle(theme).copyWith(color: muted ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded && value != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final difficulty in SecondaryDifficulties.values) _DifficultyChip(difficulty: difficulty, skill: value),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.difficulty, required this.skill});

  final SecondaryDifficulties difficulty;
  final int skill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final needed = difficulty.difficulty - skill;
    final automatic = needed <= 0;

    return Tooltip(
      message: automatic
          ? '${difficulty.displayable} (${difficulty.difficulty}): se supera sin tirar'
          : '${difficulty.displayable} (${difficulty.difficulty}): hace falta sacar $needed o más',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: automatic ? theme.colorScheme.advantageContainer : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(difficulty.abbreviated, style: theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(automatic ? '✓' : '$needed', style: _numberStyle(theme)),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Text('$count', style: theme.textTheme.labelSmall!.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
    );
  }
}
