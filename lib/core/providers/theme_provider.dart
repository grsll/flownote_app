import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

const _kThemeKey = 'flownote_dark_mode';

/// Provide SharedPreferences secara sinkron (di-override di main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider did not get initialized.');
});

// ── Persisted Theme Provider ──────────────────────────────────────────────────

class ThemeModeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(_prefs.getBool(_kThemeKey) ?? false);

  void toggle() {
    final next = !state;
    state = next;
    _prefs.setBool(_kThemeKey, next);
  }

  void setDark(bool value) {
    state = value;
    _prefs.setBool(_kThemeKey, value);
  }
}

/// Provider sinkron untuk status tema, bisa digunakan secara real-time tanpa async flickering
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

/// Alias sinkron untuk theme mode (dikembalikan ke bool biasa)
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeModeProvider);
});

/// Provide ThemeMode untuk MaterialApp.router
final themeModeEnumProvider = Provider<ThemeMode>((ref) {
  final isDark = ref.watch(themeModeProvider);
  return isDark ? ThemeMode.dark : ThemeMode.light;
});
