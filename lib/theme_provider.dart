// theme_provider.dart
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  double _fontSize = 16;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize > 0 ? _fontSize : 16;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void updateFontSize(double newSize) {
    _fontSize = newSize;
    notifyListeners();
  }
}
