import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  final List<Locale> supportedLocales = [
    const Locale('en'), // English
    const Locale('es'), // Spanish
    const Locale('zh'), // Chinese
    const Locale('ko'), // Korean
  ];

  final Map<String, String> languageNames = {
    'en': 'English',
    'es': 'Español',
    'zh': '中文',
    'ko': '한국어',
  };

  final Map<String, String> nativeNames = {
    'en': 'English',
    'es': 'Español', 
    'zh': '中文',
    'ko': '한국어',
  };

  Future<void> loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'en';
      _locale = Locale(languageCode);
      print('Language loaded: $languageCode'); // Debug log
      notifyListeners();
    } catch (e) {
      print('Error loading saved language: $e');
      _locale = const Locale('en'); // Fallback to English
    }
  }

  Future<void> changeLanguage(Locale locale) async {
    if (supportedLocales.contains(locale)) {
      print('Changing language to: ${locale.languageCode}'); // Debug log
      _locale = locale;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_languageKey, locale.languageCode);
        print('Language saved: ${locale.languageCode}'); // Debug log
      } catch (e) {
        print('Error saving language: $e');
      }
      notifyListeners();
    }
  }

  String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? 'Unknown';
  }

  String getNativeName(String languageCode) {
    return nativeNames[languageCode] ?? 'Unknown';
  }

  String getCurrentLanguageName() {
    print('getCurrentLanguageName called, current locale: ${_locale.languageCode}'); // Debug log
    final name = getLanguageName(_locale.languageCode);
    print('Language name returned: $name'); // Debug log
    return name;
  }
}