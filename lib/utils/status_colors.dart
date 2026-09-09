import 'package:flutter/material.dart';

/// Colores semánticos de estado (sorpresa, peligro, aviso) que se adaptan al
/// modo claro y oscuro.
///
/// Los tonos fijos de la paleta de Material (`Colors.green.shade100` y
/// similares) sólo funcionan sobre fondos claros: sobre un fondo oscuro
/// quedan ilegibles. Estas variantes eligen el tono según el brillo del tema.
extension StatusColors on ColorScheme {
  bool get _isDark => brightness == Brightness.dark;

  /// Ventaja: el personaje sorprende a otros.
  Color get advantage => _isDark ? const Color(0xFF7FD18B) : const Color(0xFF2E7D32);

  /// Fondo suave para la ventaja.
  Color get advantageContainer => _isDark ? const Color(0xFF1B3A21) : const Color(0xFFC8E6C9);

  /// Desventaja: el personaje es sorprendido.
  Color get danger => _isDark ? const Color(0xFFE8A362) : const Color(0xFFEF6C00);

  /// Fondo suave para la desventaja.
  Color get dangerContainer => _isDark ? const Color(0xFF3D2612) : const Color(0xFFFFE0B2);

  /// Situación mixta: sorprende y es sorprendido a la vez.
  Color get neutralContainer => _isDark ? const Color(0xFF2A2523) : const Color(0xFFEEEEEE);

  /// Marca de personajes fuera de escala (uróboros).
  Color get uroboros => _isDark ? const Color(0xFFEF6C6C) : const Color(0xFFD32F2F);

  /// Fondo de las barras de encabezado (barra superior y títulos de tarjetas).
  ///
  /// No se usa [primary] directamente: en modo oscuro Material genera un tono
  /// claro que resulta agresivo en una barra grande, y `ThemeData.primaryColor`
  /// devuelve el color de superficie, con lo que el título queda invisible.
  Color get header => _isDark ? const Color(0xFF4A2119) : primary;

  /// Color del texto y los iconos sobre [header].
  Color get onHeader => _isDark ? const Color(0xFFF7DCD4) : onPrimary;

  /// Variante del encabezado para distinguir al defensor del atacante.
  Color get headerAlt => _isDark ? const Color(0xFF3B2A46) : secondary;

  /// Color del texto y los iconos sobre [headerAlt].
  Color get onHeaderAlt => _isDark ? const Color(0xFFEBDCF2) : onSecondary;
}
