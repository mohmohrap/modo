import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ValueNotifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  ThemeProvider() : super(ThemeMode.light);

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme == 'dark') {
      value = ThemeMode.dark;
    } else {
      value = ThemeMode.light;
    }
  }

  Future<void> toggleTheme() async {
    value = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _themeKey,
      value == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

ThemeData lightTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.brown,
    brightness: Brightness.light,
  );
}

ThemeData darkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.brown,
    brightness: Brightness.dark,
  );
}
