import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar', '');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String? lang = prefs.getString('language_code');
    if (lang != null && lang.isNotEmpty) {
      _locale = Locale(lang, '');
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!['ar', 'en'].contains(locale.languageCode)) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    notifyListeners();
  }
}
