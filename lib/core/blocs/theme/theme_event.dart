import 'package:flutter/material.dart';

/// Theme Events
abstract class ThemeEvent {
  const ThemeEvent();
}

class ToggleThemeEvent extends ThemeEvent {
  const ToggleThemeEvent();
}

class SetThemeEvent extends ThemeEvent {
  final ThemeMode themeMode;

  const SetThemeEvent(this.themeMode);
}

class LoadThemeEvent extends ThemeEvent {
  const LoadThemeEvent();
}
