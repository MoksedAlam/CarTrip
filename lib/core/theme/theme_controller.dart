import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_prefs.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main()');
});

final localPrefsProvider = Provider<LocalPrefs>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalPrefs(prefs);
});

class ThemeController extends Notifier<ThemeMode> {
  late final LocalPrefs _localPrefs;

  @override
  ThemeMode build() {
    _localPrefs = ref.watch(localPrefsProvider);
    return _localPrefs.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _localPrefs.setThemeMode(mode);
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);
