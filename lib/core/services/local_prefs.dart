import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalPrefs {
  static const String _keyThemeMode = 'theme_mode';

  final SharedPreferences _prefs;

  LocalPrefs(this._prefs);

  ThemeMode getThemeMode() {
    final value = _prefs.getString(_keyThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    switch (mode) {
      case ThemeMode.light:
        await _prefs.setString(_keyThemeMode, 'light');
        break;
      case ThemeMode.dark:
        await _prefs.setString(_keyThemeMode, 'dark');
        break;
      case ThemeMode.system:
        await _prefs.setString(_keyThemeMode, 'system');
        break;
    }
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
