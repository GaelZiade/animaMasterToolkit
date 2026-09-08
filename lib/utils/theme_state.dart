import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda y expone el modo de tema elegido por el usuario.
///
/// La preferencia se persiste para que la aplicación abra siempre en el modo
/// que el usuario dejó seleccionado.
class ThemeState extends ChangeNotifier {
  ThemeState() {
    _restore();
  }

  static const _key = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool isDark(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_key);

    if (stored == null) return;

    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;

    _themeMode = mode;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, mode.name);
  }

  /// Alterna entre claro y oscuro tomando como referencia lo que se ve ahora.
  Future<void> toggle(BuildContext context) {
    return setThemeMode(isDark(context) ? ThemeMode.light : ThemeMode.dark);
  }
}
