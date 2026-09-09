import 'package:amt/models/character_model/consumable_state.dart';
import 'package:amt/models/enums.dart';
import 'package:amt/presentation/components/components.dart';
import 'package:flutter/material.dart';

class ConsumableCard extends StatelessWidget {
  const ConsumableCard(
    this.consumable, {
    required this.onChangedMax,
    required this.onChangedActual,
    required this.onDelete,
    super.key,
  });
  final ConsumableState consumable;
  final void Function(String) onChangedMax;
  final void Function(String) onChangedActual;
  final void Function(ConsumableState) onDelete;

  /// Los contadores van sin relleno ni recuadro.
  ///
  /// `border: InputBorder.none` no alcanza: mientras el campo esta habilitado
  /// manda `enabledBorder`, que viene del tema con esquinas redondeadas, y a la
  /// altura de estos campos eso los dibuja como burbujas.
  static const _counterDecoration = InputDecoration(
    isDense: true,
    filled: false,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    contentPadding: EdgeInsets.symmetric(vertical: 4),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Cifras tabulares para que los contadores no se muevan al cambiar.
    const tabular = [FontFeature.tabularFigures()];
    final styleS = theme.textTheme.bodySmall!.copyWith(fontFeatures: tabular);
    final styleM = theme.textTheme.bodyMedium!.copyWith(fontFeatures: tabular);

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (consumable.type == ConsumableType.other)
            InkWell(
              child: Icon(
                Icons.delete,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Borrar consumible'),
                      content: Text('Seguro que desea borrar ${consumable.name}?'),
                      actions: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete(consumable);
                          },
                          child: const Text('Borrar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancelar'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          Expanded(
            child: Text(
              consumable.name,
              style: styleM,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (consumable.step > 0 || consumable.description.isNotEmpty)
            const Icon(
              Icons.info,
              size: 16,
            )
          else
            const SizedBox.square(dimension: 16),
        ],
      ),
    );

    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Column(
        children: [
          if (consumable.step > 0 || consumable.description.isNotEmpty)
            Tooltip(
              textAlign: TextAlign.center,
              message:
                  '${consumable.step > 0 ? 'incremento: ${consumable.step}\n' : ''}${consumable.description.isNotEmpty ? consumable.description : ''}',
              child: header,
            )
          else
            header,
          Row(
            children: [
              IconButton(
                // Compactos: con el tamano por defecto se comian el ancho y
                // los contadores quedaban recortados.
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Restar ${consumable.step} a ${consumable.name}',
                onPressed: () {
                  onChangedActual((consumable.actualValue - consumable.step).toString());
                },
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: AMTTextFormField(
                  align: TextAlign.center,
                  decoration: _counterDecoration,
                  style: consumable.actualValue > 999 ? styleS : styleM,
                  text: consumable.actualValue.toString(),
                  onChanged: onChangedActual,
                ),
              ),
              Text('/', style: styleM.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Expanded(
                child: AMTTextFormField(
                  align: TextAlign.center,
                  decoration: _counterDecoration,
                  style: consumable.maxValue > 999 ? styleS : styleM,
                  text: consumable.maxValue.toString(),
                  onChanged: onChangedMax,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Sumar ${consumable.step} a ${consumable.name}',
                onPressed: () {
                  onChangedActual((consumable.actualValue + consumable.step).toString());
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
