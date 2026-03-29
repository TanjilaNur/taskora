import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences key for persisting the chosen theme mode.
const _kThemeKey = 'app_theme_mode';

/// Riverpod provider for the current [ThemeMode].
/// Survives app restarts — reads from SharedPreferences on init.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
      (ref) => ThemeModeNotifier(),
);

/// Manages light / dark / system theme and persists the choice locally.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  // Default to system theme until the saved preference is loaded.
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadFromPrefs();
  }

  // Read the previously saved theme from disk and update state.
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);
    state = switch (saved) {
      'light' => ThemeMode.light,
      'dark'  => ThemeMode.dark,
      _       => ThemeMode.system,
    };
  }

  /// Flip between light and dark. Ignores system mode.
  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }

  /// Set a specific mode and save it so it persists after restart.
  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark  => 'dark',
      _               => 'system',
    });
  }
}