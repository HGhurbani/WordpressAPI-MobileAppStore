import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    // Prefer the current key used by the splash language selector.
    // Keep backward compatibility with older saved key.
    String? lang = prefs.getString('app_lang') ?? prefs.getString('language_code');
    if (lang != null && lang.isNotEmpty) {
      _locale = Locale(lang);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!['ar', 'en'].contains(locale.languageCode)) return;
    _locale = Locale(locale.languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', locale.languageCode);
    notifyListeners();
  }
}
