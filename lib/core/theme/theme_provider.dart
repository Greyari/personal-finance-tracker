import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemePreferenceKey = 'app_theme_mode_key';
const String _kWallpaperPreferenceKey = 'app_wallpaper_key';
const String _kCustomWallpaperPathKey = 'app_custom_wallpaper_path_key';

enum AppWallpaper {
  ghibliClassic('assets/images/backgrounds/bg_ghibli_photo1_classic.jpg', 'Ghibli Klasik'),
  custom(null, 'Foto Upload Sendiri'),
  none(null, 'Polos (Gradient)');

  final String? assetPath;
  final String label;

  const AppWallpaper(this.assetPath, this.label);
}

class WallpaperState {
  final AppWallpaper wallpaper;
  final String? customFilePath;

  const WallpaperState({
    required this.wallpaper,
    this.customFilePath,
  });

  String? get resolvedImagePath {
    if (wallpaper == AppWallpaper.custom) {
      return customFilePath;
    }
    return wallpaper.assetPath;
  }

  bool get isCustomFile => wallpaper == AppWallpaper.custom && customFilePath != null;
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

class WallpaperNotifier extends StateNotifier<WallpaperState> {
  final SharedPreferences? _prefs;

  WallpaperNotifier(this._prefs)
      : super(
          WallpaperState(
            wallpaper: _loadInitialWallpaper(_prefs),
            customFilePath: _prefs?.getString(_kCustomWallpaperPathKey),
          ),
        );

  static AppWallpaper _loadInitialWallpaper(SharedPreferences? prefs) {
    if (prefs == null) return AppWallpaper.ghibliClassic;
    final saved = prefs.getString(_kWallpaperPreferenceKey);
    for (final wp in AppWallpaper.values) {
      if (wp.name == saved) return wp;
    }
    return AppWallpaper.ghibliClassic; // Default to Ghibli Klasik
  }

  Future<void> setWallpaper(AppWallpaper wallpaper) async {
    state = WallpaperState(
      wallpaper: wallpaper,
      customFilePath: state.customFilePath,
    );
    await _prefs?.setString(_kWallpaperPreferenceKey, wallpaper.name);
  }

  Future<void> setCustomWallpaper(String filePath) async {
    state = WallpaperState(
      wallpaper: AppWallpaper.custom,
      customFilePath: filePath,
    );
    await _prefs?.setString(_kWallpaperPreferenceKey, AppWallpaper.custom.name);
    await _prefs?.setString(_kCustomWallpaperPathKey, filePath);
  }

  Future<void> clearCustomWallpaper() async {
    state = const WallpaperState(
      wallpaper: AppWallpaper.ghibliClassic,
      customFilePath: null,
    );
    await _prefs?.setString(_kWallpaperPreferenceKey, AppWallpaper.ghibliClassic.name);
    await _prefs?.remove(_kCustomWallpaperPathKey);
  }
}

final appWallpaperProvider = StateNotifierProvider<WallpaperNotifier, WallpaperState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WallpaperNotifier(prefs);
});
