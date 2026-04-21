import 'package:flutter/material.dart';

class ThemeService {
  // 單例模式 (Singleton)
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  // 預設為跟隨系統，或是直接指定為亮色模式 ThemeMode.light
  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  void toggleTheme() {
    if (themeNotifier.value == ThemeMode.dark) {
      themeNotifier.value = ThemeMode.light;
    } else {
      themeNotifier.value = ThemeMode.dark;
    }
  }
}