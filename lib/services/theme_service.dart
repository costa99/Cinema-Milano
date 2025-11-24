import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme {
  system,
  light,
  dark,
  neon,
}

class ThemeController with ChangeNotifier {
  static const String _themeKey = 'app_theme';
  AppTheme _appTheme = AppTheme.system;

  AppTheme get appTheme => _appTheme;

  ThemeMode get themeMode {
    switch (_appTheme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
      case AppTheme.neon:
        return ThemeMode.dark; // Neon is a dark theme
      case AppTheme.system:
      default:
        return ThemeMode.system;
    }
  }

  ThemeController() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme != null) {
      _appTheme = AppTheme.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => AppTheme.system,
      );
      notifyListeners();
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    _appTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.toString());
  }
}
