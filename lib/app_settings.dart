import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static final ValueNotifier<bool> notifications =
      ValueNotifier<bool>(true);

  static final ValueNotifier<bool> autoPlayVideos =
      ValueNotifier<bool>(true);

  static final ValueNotifier<bool> videoSound =
      ValueNotifier<bool>(true);

  static final ValueNotifier<bool> vibration =
      ValueNotifier<bool>(true);

  static final ValueNotifier<bool> dataSaver =
      ValueNotifier<bool>(false);

  static final ValueNotifier<String> videoQuality =
      ValueNotifier<String>('Auto');

  static final ValueNotifier<bool> reduceMotion =
      ValueNotifier<bool>(false);

  static final ValueNotifier<String> language =
      ValueNotifier<String>('English');

  static final ValueNotifier<String> currency =
      ValueNotifier<String>('KRW');

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark = prefs.getBool('darkMode') ?? false;

    themeMode.value =
        isDark ? ThemeMode.dark : ThemeMode.light;

    notifications.value =
        prefs.getBool('notifications') ?? true;

    autoPlayVideos.value =
        prefs.getBool('autoPlayVideos') ?? true;

    videoSound.value =
        prefs.getBool('videoSound') ?? true;

    vibration.value =
        prefs.getBool('vibration') ?? true;

    dataSaver.value =
        prefs.getBool('dataSaver') ?? false;

    videoQuality.value =
        prefs.getString('videoQuality') ?? 'Auto';

    reduceMotion.value =
        prefs.getBool('reduceMotion') ?? false;

    language.value =
        prefs.getString('language') ?? 'English';

    currency.value =
        prefs.getString('currency') ?? 'KRW';
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('darkMode', value);

    themeMode.value =
        value ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notifications', value);

    notifications.value = value;
  }

  static Future<void> setAutoPlayVideos(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('autoPlayVideos', value);

    autoPlayVideos.value = value;
  }

  static Future<void> setVideoSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('videoSound', value);

    videoSound.value = value;
  }

  static Future<void> setVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('vibration', value);

    vibration.value = value;
  }

  static Future<void> setDataSaver(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('dataSaver', value);

    dataSaver.value = value;
  }

  static Future<void> setVideoQuality(String value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('videoQuality', value);

    videoQuality.value = value;
  }

  static Future<void> setReduceMotion(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('reduceMotion', value);

    reduceMotion.value = value;
  }

  static Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('language', value);

    language.value = value;
  }

  static Future<void> setCurrency(String value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('currency', value);

    currency.value = value;
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('videoQuality');
    await prefs.remove('reduceMotion');

    videoQuality.value = 'Auto';
    reduceMotion.value = false;
  }
}
