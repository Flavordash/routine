import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/language_service.dart';

// Provider for the LanguageService instance
final languageServiceProvider = Provider<LanguageService>((ref) {
  return LanguageService();
});

// StateNotifier for managing dark mode state
class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(true); // Default to dark mode

  void toggle() {
    state = !state;
  }

  void setDarkMode(bool isDark) {
    state = isDark;
  }
}

// Provider for dark mode state
final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier();
});

// StateNotifier for managing language state
class LanguageNotifier extends StateNotifier<Locale?> {
  LanguageNotifier(this._languageService) : super(null) {
    _initializeLanguage();
  }

  final LanguageService _languageService;

  Future<void> _initializeLanguage() async {
    await _languageService.loadSavedLanguage();
    state = _languageService.locale;
  }

  Future<void> setLanguage(String languageCode) async {
    final locale = Locale(languageCode);
    await _languageService.changeLanguage(locale);
    state = _languageService.locale;
  }

  String getCurrentLanguageName() {
    return _languageService.getCurrentLanguageName();
  }
}

// Provider for language state
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale?>((ref) {
  final languageService = ref.watch(languageServiceProvider);
  return LanguageNotifier(languageService);
});

// Provider for current language name
final currentLanguageNameProvider = Provider<String>((ref) {
  final languageNotifier = ref.read(languageProvider.notifier);
  return languageNotifier.getCurrentLanguageName();
});

// StateNotifier for managing app loading state
class AppLoadingNotifier extends StateNotifier<bool> {
  AppLoadingNotifier() : super(false);

  void setLoading(bool loading) {
    state = loading;
  }
}

// Provider for app loading state
final appLoadingProvider = StateNotifierProvider<AppLoadingNotifier, bool>((ref) {
  return AppLoadingNotifier();
});