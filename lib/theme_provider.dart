import 'package:flutter/material.dart';

class ThemeProvider extends ValueNotifier<ThemeMode> {
  ThemeProvider() : super(ThemeMode.light);

  void toggleTheme() {
    value = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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
