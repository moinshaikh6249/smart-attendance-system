import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // Theme preferences
  ThemeMode _themeMode = ThemeMode.system;
  
  // Notification preferences
  bool _notifyOnNewApproval = true;
  bool _notifyOnBLESession = true;
  bool _notifyOnDailySummary = true;
  
  // Security preferences
  bool _requirePinOnReopen = false;
  
  bool _isLoading = false;
  
  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get notifyOnNewApproval => _notifyOnNewApproval;
  bool get notifyOnBLESession => _notifyOnBLESession;
  bool get notifyOnDailySummary => _notifyOnDailySummary;
  bool get requirePinOnReopen => _requirePinOnReopen;
  bool get isLoading => _isLoading;
  
  // Initialize settings from local storage
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme preference
      final themeModeString = prefs.getString('theme_mode') ?? 'system';
      _themeMode = _parseThemeMode(themeModeString);
      
      // Load notification preferences
      _notifyOnNewApproval = prefs.getBool('notify_new_approval') ?? true;
      _notifyOnBLESession = prefs.getBool('notify_ble_session') ?? true;
      _notifyOnDailySummary = prefs.getBool('notify_daily_summary') ?? true;
      
      // Load security preferences
      _requirePinOnReopen = prefs.getBool('require_pin_reopen') ?? false;
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', _themeModeName(mode));
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }
  
  // Update notification preferences
  Future<void> setNotifyOnNewApproval(bool value) async {
    _notifyOnNewApproval = value;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notify_new_approval', value);
    } catch (e) {
      print('Error saving notification preference: $e');
    }
  }
  
  Future<void> setNotifyOnBLESession(bool value) async {
    _notifyOnBLESession = value;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notify_ble_session', value);
    } catch (e) {
      print('Error saving notification preference: $e');
    }
  }
  
  Future<void> setNotifyOnDailySummary(bool value) async {
    _notifyOnDailySummary = value;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notify_daily_summary', value);
    } catch (e) {
      print('Error saving notification preference: $e');
    }
  }
  
  // Update security preferences
  Future<void> setRequirePinOnReopen(bool value) async {
    _requirePinOnReopen = value;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('require_pin_reopen', value);
    } catch (e) {
      print('Error saving security preference: $e');
    }
  }
  
  // Clear local cache (non-destructive)
  Future<bool> clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Only clear specific cache keys, preserve settings
      final keysToRemove = <String>[];
      final allKeys = prefs.getKeys();
      
      for (final key in allKeys) {
        // Clear cache data but keep settings
        if (key.startsWith('cache_') || 
            key.startsWith('temp_') ||
            key.startsWith('filter_')) {
          keysToRemove.add(key);
        }
      }
      
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
      
      return true;
    } catch (e) {
      print('Error clearing cache: $e');
      return false;
    }
  }
  
  // Helper methods
  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  
  String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
  
  String get themeModeDisplayName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'System Default';
    }
  }
}
