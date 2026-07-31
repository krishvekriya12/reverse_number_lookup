import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController();
  static const String _prefKeyTheme = 'app_theme_mode';

  ThemeMode themeMode = ThemeMode.light;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKeyTheme);
    if (saved == 'dark') {
      themeMode = ThemeMode.dark;
    } else {
      themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyTheme, themeMode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> toggleTheme() async {
    if (themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  bool get isDark => themeMode == ThemeMode.dark;

  bool isDarkMode(BuildContext context) => isDark;

  String get currentThemeName => isDark ? 'Dark' : 'Light';
}
