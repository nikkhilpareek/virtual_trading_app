import 'package:flutter/material.dart';

/// Theme State
class ThemeState {
  final ThemeMode themeMode;

  const ThemeState({this.themeMode = ThemeMode.system});

  bool get isDarkMode => themeMode == ThemeMode.dark;
  bool get isLightMode => themeMode == ThemeMode.light;
  bool get isSystemMode => themeMode == ThemeMode.system;

  ThemeState copyWith({ThemeMode? themeMode}) {
    return ThemeState(themeMode: themeMode ?? this.themeMode);
  }
}
