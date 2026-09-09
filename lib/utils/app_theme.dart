import 'package:amt/utils/status_colors.dart';
import 'package:flutter/material.dart';

/// Tema visual de la aplicación.
///
/// Define una variante clara y una oscura a partir de la misma semilla de
/// color, para que la identidad visual se mantenga en ambos modos.
abstract class AppTheme {
  /// Color base del que se derivan ambos esquemas.
  static const seed = Color(0xFFB1442A);

  /// Radio de esquina de diálogos y campos.
  static const radius = 12.0;

  /// Radio de los campos de texto.
  ///
  /// Mas chico que [radius] por el mismo motivo que [cardRadius]: muchos campos
  /// de la ficha son bajos y con 12 px se redondean del todo.
  static const inputRadius = 8.0;

  /// Radio de las tarjetas.
  ///
  /// Mas chico que [radius] a proposito: muchas tarjetas de la aplicacion miden
  /// dos decenas de pixeles de alto, y con un radio grande se redondean por
  /// completo y quedan con forma de pastilla.
  static const cardRadius = 6.0;

  static ThemeData light({bool reduceMotion = false}) => _build(Brightness.light, reduceMotion: reduceMotion);

  static ThemeData dark({bool reduceMotion = false}) => _build(Brightness.dark, reduceMotion: reduceMotion);

  static ThemeData _build(Brightness brightness, {required bool reduceMotion}) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    // En claro se evita el blanco puro y en oscuro el negro puro: ambos
    // extremos cansan la vista en sesiones largas.
    final scaffold = isDark ? const Color(0xFF14100F) : const Color(0xFFF6F1EC);
    final surface = isDark ? const Color(0xFF1E1917) : const Color(0xFFFDFAF7);

    final scheme = colorScheme.copyWith(surface: surface);

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSans',
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      // Respeta la preferencia de reducir movimiento del sistema operativo.
      pageTransitionsTheme: reduceMotion
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _NoTransitionBuilder(),
                TargetPlatform.iOS: _NoTransitionBuilder(),
                TargetPlatform.linux: _NoTransitionBuilder(),
                TargetPlatform.macOS: _NoTransitionBuilder(),
                TargetPlatform.windows: _NoTransitionBuilder(),
              },
            )
          : const PageTransitionsTheme(),
      canvasColor: scaffold,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: isDark ? 0 : 1,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.header,
        foregroundColor: scheme.onHeader,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: shape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.4 : 0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: shape,
        collapsedShape: shape,
        iconColor: scheme.primary,
        collapsedIconColor: scheme.onSurfaceVariant,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: shape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: shape),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: shape),
      ),
    );
  }
}

/// Transicion de pagina sin animacion, para `prefers-reduced-motion`.
class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
