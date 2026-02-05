import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('id');
  bool _notifPush = true;
  bool _notifEmail = false;

  SettingsProvider() {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get notifPush => _notifPush;
  bool get notifEmail => _notifEmail;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isEnglish => _locale.languageCode == 'en';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    final languageCode = prefs.getString('language_code') ?? 'id';

    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _locale = Locale(languageCode);
    _notifPush = prefs.getBool('notif_push') ?? true;
    _notifEmail = prefs.getBool('notif_email') ?? false;

    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
  }

  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }

  Future<void> setNotifPush(bool value) async {
    _notifPush = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_push', value);
  }

  Future<void> setNotifEmail(bool value) async {
    _notifEmail = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_email', value);
  }
}
