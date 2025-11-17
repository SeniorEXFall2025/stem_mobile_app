import 'package:flutter/material.dart';

/// simple global theme controller the app can listen to
class ThemeController {
  // start by following the system setting
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
  }
}
