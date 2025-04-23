// theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 16;
  MaterialColor _primaryColor = Colors.green;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  MaterialColor get primaryColor => _primaryColor;

  ThemeProvider() {
    _loadPrefs();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _savePrefs();
    notifyListeners();
  }

  void updateFontSize(double value) {
    _fontSize = value;
    _savePrefs();
    notifyListeners();
  }

  void updatePrimaryColor(MaterialColor color) {
    _primaryColor = color;
    _savePrefs();
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    prefs.setDouble('fontSize', _fontSize);
    prefs.setInt('primaryColorIndex', Colors.primaries.indexOf(_primaryColor));
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = prefs.getBool('isDarkMode') ?? false ? ThemeMode.dark : ThemeMode.light;
    _fontSize = prefs.getDouble('fontSize') ?? 16;
    int colorIndex = prefs.getInt('primaryColorIndex') ?? Colors.primaries.indexOf(Colors.green);
    _primaryColor = Colors.primaries[colorIndex];
    notifyListeners();
  }
}
