import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

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
      Logger.instance.info('Language loaded: $languageCode');
      notifyListeners();
    } catch (e) {
      Logger.instance.error('Error loading saved language: $e');
      _locale = const Locale('en'); // Fallback to English
    }
  }

  Future<void> changeLanguage(Locale locale) async {
    if (supportedLocales.contains(locale)) {
      Logger.instance.info('Changing language to: ${locale.languageCode}');
      _locale = locale;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_languageKey, locale.languageCode);
        Logger.instance.info('Language saved: ${locale.languageCode}');
      } catch (e) {
        Logger.instance.error('Error saving language: $e');
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
    Logger.instance.debug('getCurrentLanguageName called, current locale: ${_locale.languageCode}');
    final name = getLanguageName(_locale.languageCode);
    Logger.instance.debug('Language name returned: $name');
    return name;
  }
}