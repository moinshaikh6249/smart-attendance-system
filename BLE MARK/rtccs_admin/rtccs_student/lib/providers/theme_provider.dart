import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt('theme_mode') ?? 0; // 0 = system, 1 = light, 2 = dark
      
      switch (themeModeIndex) {
        case 1:
          _themeMode = ThemeMode.light;
          break;
        case 2:
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      int themeModeIndex = 0; // system
      
      if (mode == ThemeMode.light) {
        themeModeIndex = 1;
      } else if (mode == ThemeMode.dark) {
        themeModeIndex = 2;
      }
      
      await prefs.setInt('theme_mode', themeModeIndex);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }
}
