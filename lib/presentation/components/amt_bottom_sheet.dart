import 'package:flutter/material.dart';

class AMTBottomSheet extends StatelessWidget {
  const AMTBottomSheet({
    required this.title,
    required this.children,
    super.key,
    this.bottomRow,
    this.scrollable = true,
  });

  final Widget title;
  final List<Widget> children;
  final List<Widget>? bottomRow;

  /// Si el contenido debe ir dentro de una lista con scroll propio.
  ///
  /// Se desactiva cuando quien lo usa ya provee su propia zona desplazable.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      // Antes la altura era fija a media pantalla, así que el contenido se
      // apretaba aunque sobrara espacio. Ahora crece con el contenido hasta
      // ocupar como mucho el 85% de la pantalla.
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            title,
            const SizedBox(height: 12),
            Flexible(
              child: scrollable ? ListView(shrinkWrap: true, children: children) : Column(children: children),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(),
                if (bottomRow != null)
                  ...bottomRow!
                else
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                const SizedBox(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
