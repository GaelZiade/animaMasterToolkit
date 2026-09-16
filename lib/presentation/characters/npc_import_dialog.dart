import 'package:amt/models/character_model/character.dart';
import 'package:amt/models/combat_data.dart';
import 'package:amt/utils/npc_parser/npc_text_parser.dart';
import 'package:flutter/material.dart';

/// Crea PNJ a partir de perfiles copiados de los manuales.
class NpcImportDialog extends StatefulWidget {
  const NpcImportDialog({required this.onAdd, super.key});

  final void Function(Character character) onAdd;

  static Future<void> show(BuildContext context, void Function(Character character) onAdd) {
    return showDialog<void>(context: context, builder: (_) => NpcImportDialog(onAdd: onAdd));
  }

  @override
  State<NpcImportDialog> createState() => _NpcImportDialogState();
}

class _NpcImportDialogState extends State<NpcImportDialog> {
  List<NpcParseResult> _results = [];

  /// Copias a agregar de cada perfil; 0 lo deja afuera.
  List<int> _copies = [];

  void _parse(String text) {
    final results = NpcTextParser.parseAll(text);

    setState(() {
      _results = results;
      _copies = List.filled(results.length, 1);
    });
  }

  int get _total => _copies.fold(0, (sum, copies) => sum + copies);

  void _add() {
    for (var i = 0; i < _results.length; i++) {
      for (var copy = 0; copy < _copies[i]; copy++) {
        final character = Character.fromJson(_results[i].json);

        if (character != null) widget.onAdd(character);
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return AlertDialog(
      title: const Text('Pegar PNJ'),
      content: SizedBox(
        width: size.width < 720 ? size.width : 680,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Copiá el perfil de una criatura o PNJ del Core, el Bestiario o Gaïa y pegalo acá. Podés pegar varios seguidos.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              // Con perfiles reconocidos, el espacio es para la vista previa.
              minLines: _results.isEmpty ? 5 : 2,
              maxLines: _results.isEmpty ? 8 : 3,
              onChanged: _parse,
              style: theme.textTheme.bodySmall,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Pegá acá el perfil (Ctrl+V)',
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: _results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Todavía no se reconoce ningún perfil.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _NpcPreview(
                        result: _results[index],
                        copies: _copies[index],
                        onCopies: (copies) => setState(() => _copies[index] = copies),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: _total == 0 ? null : _add,
          icon: const Icon(Icons.person_add_alt_1),
          label: Text(_total == 0 ? 'Agregar' : 'Agregar $_total'),
        ),
      ],
    );
  }
}

class _NpcPreview extends StatelessWidget {
  const _NpcPreview({required this.result, required this.copies, required this.onCopies});

  final NpcParseResult result;
  final int copies;
  final void Function(int copies) onCopies;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = result.json['datosElementales'] as Map<String, dynamic>;
    final combat = CombatData.fromJson(result.json['Combate'] as Map<String, dynamic>)!;
    final armour = combat.armour.calculatedArmour;
    final accumulation = profile['acumDanio'] == 'Si';
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final weapons = combat.weapons.map((weapon) {
      final defense = accumulation ? '' : ' · ${weapon.defenseType.displayable} ${weapon.defense}';
      final reduction = (weapon.armourReduction ?? 0) > 0 ? ' · TA −${weapon.armourReduction}' : '';
      final critical = (weapon.criticalBonus ?? 0) > 0 ? ' · Crítico +${weapon.criticalBonus}' : '';
      final energy = (weapon.damagesEnergy ?? false) ? ' · Daña energía' : '';

      return '${weapon.name}: HA ${weapon.attack}$defense · Daño ${weapon.damage} ${weapon.principalDamage?.name.toUpperCase() ?? ''}$reduction$critical$energy';
    });

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.name, style: theme.textTheme.titleMedium),
                      Text(
                        [
                          if ('${profile['nivel']}'.isNotEmpty) 'Nivel ${profile['nivel']}',
                          'PV ${profile['puntosDeVida']}${accumulation ? ' (acumulación)' : ''}',
                          'Turno ${combat.weapons.first.turn}',
                          if (profile['barreraDanio'] != null) 'Barrera de daño ${profile['barreraDanio']}',
                        ].join(' · '),
                        style: muted,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Una copia menos',
                  onPressed: copies == 0 ? null : () => onCopies(copies - 1),
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 28,
                  child: Text('$copies', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: 'Una copia más',
                  onPressed: () => onCopies(copies + 1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final weapon in weapons) Text(weapon, style: theme.textTheme.bodySmall),
            Text(
              'TA ${armour.name ?? ''}: FIL ${armour.fil} CON ${armour.con} PEN ${armour.pen} CAL ${armour.cal} '
              'ELE ${armour.ele} FRI ${armour.fri} ENE ${armour.ene}',
              style: muted,
            ),
            for (final warning in result.warnings)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(warning, style: theme.textTheme.bodySmall)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
