/* provider to manage app language */

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colours_of_wine/utils/app_constants.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('de', '');

  Locale get locale => _locale;

  Future<void> loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(AppConstants.appLanguageKey);
      if (languageCode != null) {
        _locale = Locale(languageCode, '');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved language: $e');
    }
  }

  Future<void> setLanguage(Locale locale) async {
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.appLanguageKey, locale.languageCode);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }
}
