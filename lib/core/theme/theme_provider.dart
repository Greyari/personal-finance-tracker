import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemePreferenceKey = 'app_theme_mode_key';
const String _kWallpaperPreferenceKey = 'app_wallpaper_key';

enum AppWallpaper {
  fluidGlass('assets/images/backgrounds/bg_fluid_glass.jpg', 'Fluid Glass (Opsi 1)'),
  architectural('assets/images/backgrounds/bg_architectural_topography.jpg', 'Topography (Opsi 2)'),
  auroraMesh('assets/images/backgrounds/bg_aurora_mesh.jpg', 'Aurora Mesh (Opsi 3)'),
  none(null, 'Polos (Gradient)');

  final String? assetPath;
  final String label;

  const AppWallpaper(this.assetPath, this.label);
}

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

class WallpaperNotifier extends StateNotifier<AppWallpaper> {
  final SharedPreferences? _prefs;

  WallpaperNotifier(this._prefs) : super(_loadInitialWallpaper(_prefs));

  static AppWallpaper _loadInitialWallpaper(SharedPreferences? prefs) {
    if (prefs == null) return AppWallpaper.fluidGlass;
    final saved = prefs.getString(_kWallpaperPreferenceKey);
    if (saved == 'architectural') return AppWallpaper.architectural;
    if (saved == 'auroraMesh') return AppWallpaper.auroraMesh;
    if (saved == 'none') return AppWallpaper.none;
    return AppWallpaper.fluidGlass; // Default to Option 1
  }

  Future<void> setWallpaper(AppWallpaper wallpaper) async {
    state = wallpaper;
    await _prefs?.setString(_kWallpaperPreferenceKey, wallpaper.name);
  }
}

final appWallpaperProvider = StateNotifierProvider<WallpaperNotifier, AppWallpaper>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WallpaperNotifier(prefs);
});
