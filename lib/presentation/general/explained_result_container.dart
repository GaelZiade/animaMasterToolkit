import 'package:amt/utils/explained_text.dart';
import 'package:flutter/material.dart';

/// Muestra un resultado de combate y, al desplegarlo, cómo se calculó.
class ExplainedTextContainer extends StatelessWidget {
  const ExplainedTextContainer({
    required this.info,
    required this.explanationsExpanded,
    required this.onExpanded,
    super.key,
    this.parent = '',
    this.hierarchy = 1,
  });

  final ExplainedText info;
  final int hierarchy;
  final Map<String, bool> explanationsExpanded;
  final void Function(String) onExpanded;
  final String parent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final titleForStatus = parent + info.title;
    final isExpanded = explanationsExpanded[titleForStatus] ?? false;
    final canExpand = info.explanation.isNotEmpty || info.explanations.isNotEmpty || info.terms.isNotEmpty;

    // Los niveles anidados se distinguen con una línea lateral y sangría en
    // lugar de rellenos de color alternos, que competían con el contenido.
    final isNested = hierarchy > 1;

    final header = InkWell(
      onTap: canExpand ? () => onExpanded(titleForStatus) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            if (info.specialRule != null) ...[
              _Badge(label: info.specialRule!.name, scheme: scheme),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                info.text,
                style: theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (canExpand)
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info.terms.isNotEmpty) _TermsTable(terms: info.terms, theme: theme),
          if (info.explanation.trim().isNotEmpty) ...[
            if (info.terms.isNotEmpty) const SizedBox(height: 8),
            Text(
              info.explanation.trim(),
              style: theme.textTheme.bodySmall!.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
          for (final explanation in info.explanations)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ExplainedTextContainer(
                onExpanded: onExpanded,
                explanationsExpanded: explanationsExpanded,
                info: explanation,
                hierarchy: hierarchy + 1,
                parent: info.title,
              ),
            ),
          if (info.references.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final reference in info.references) _Badge(label: '${reference.book.name} · p. ${reference.page}', scheme: scheme),
                ],
              ),
            ),
        ],
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (isExpanded) body,
      ],
    );

    if (isNested) {
      return Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: scheme.outlineVariant, width: 2)),
        ),
        child: content,
      );
    }

    return Card(
      clipBehavior: Clip.hardEdge,
      color: scheme.surface,
      child: content,
    );
  }
}

/// Desglose de la operación: un sumando por fila, con el total separado.
class _TermsTable extends StatelessWidget {
  const _TermsTable({required this.terms, required this.theme});

  final List<ExplainedTerm> terms;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;

    return Column(
      children: [
        for (final term in terms) ...[
          if (term.isTotal) Divider(color: scheme.outlineVariant, height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    term.label,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: term.isTotal ? scheme.onSurface : scheme.onSurfaceVariant,
                      fontWeight: term.isTotal ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  // El signo explícito deja claro de un vistazo si el término
                  // suma o resta.
                  term.isTotal ? '${term.value}' : (term.value > 0 ? '+${term.value}' : '${term.value}'),
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: term.isTotal ? FontWeight.w700 : FontWeight.w600,
                    color: term.isTotal
                        ? scheme.onSurface
                        : term.value > 0
                            ? scheme.tertiary
                            : scheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Etiqueta compacta: referencia de manual o regla especial.
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.scheme});

  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
