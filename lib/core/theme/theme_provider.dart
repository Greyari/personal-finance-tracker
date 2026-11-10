import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemePreferenceKey = 'app_theme_mode_key';

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) {
  return null;
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences? _prefs;

  ThemeNotifier(this._prefs) : super(_loadInitialTheme(_prefs));

  static ThemeMode _loadInitialTheme(SharedPreferences? prefs) {
    if (prefs == null) return ThemeMode.dark;
    final saved = prefs.getString(_kThemePreferenceKey);
    if (saved == 'light') return ThemeMode.light;
    if (saved == 'system') return ThemeMode.system;
    return ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final value = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await _prefs?.setString(_kThemePreferenceKey, value);
  }
}

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});
