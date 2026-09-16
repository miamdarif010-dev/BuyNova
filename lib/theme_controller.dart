import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global controller for the app's theme mode (light/dark).
/// Settings page's "Dark Mode" toggle calls [toggleTheme] on this.
/// [MyApp] listens to [themeMode] and rebuilds automatically.
class ThemeController {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.light);

  static const String _prefsKey = 'isDarkMode';

  /// Call once at app startup, before runApp().
  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_prefsKey) ?? false;
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static bool get isDarkMode => themeMode.value == ThemeMode.dark;

  static Future<void> toggleTheme(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, isDark);
  }
}
