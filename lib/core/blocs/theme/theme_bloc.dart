import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_event.dart';
import 'theme_state.dart';

/// Theme BLoC
/// Manages theme state with SharedPreferences persistence
///
/// Why BLoC over Provider/Riverpod:
/// 1. Already using BLoC pattern throughout the app (UserBloc, CryptoBloc, etc.)
/// 2. Better separation of concerns with Events/States
/// 3. Built-in state management with stream-based architecture
/// 4. Easier to test and debug
/// 5. Consistent with existing codebase architecture
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themePreferenceKey = 'theme_mode';

  ThemeBloc() : super(const ThemeState()) {
    on<LoadThemeEvent>(_onLoadTheme);
    on<ToggleThemeEvent>(_onToggleTheme);
    on<SetThemeEvent>(_onSetTheme);
  }

  /// Load saved theme preference on app start
  Future<void> _onLoadTheme(
    LoadThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themePreferenceKey);

      if (themeModeString != null) {
        final themeMode = _stringToThemeMode(themeModeString);
        emit(state.copyWith(themeMode: themeMode));
      }
    } catch (e) {
      // If loading fails, keep default (system) theme
      debugPrint('Error loading theme preference: $e');
    }
  }

  /// Toggle between light and dark mode
  Future<void> _onToggleTheme(
    ToggleThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    final newThemeMode = state.isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await _saveThemePreference(newThemeMode);
    emit(state.copyWith(themeMode: newThemeMode));
  }

  /// Set specific theme mode
  Future<void> _onSetTheme(
    SetThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    await _saveThemePreference(event.themeMode);
    emit(state.copyWith(themeMode: event.themeMode));
  }

  /// Save theme preference to SharedPreferences
  Future<void> _saveThemePreference(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, _themeModeToString(themeMode));
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Convert ThemeMode to String for storage
  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Convert String to ThemeMode from storage
  ThemeMode _stringToThemeMode(String themeModeString) {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
