// lib/providers/user_provider.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  bool get isLoggedIn => _user != null;

  void setUser(User newUser) async {
    _user = newUser;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_token', newUser.token);
    await prefs.setString('user_name', newUser.username);
    await prefs.setString('user_email', newUser.email);
    await prefs.setString('user_phone', newUser.phone); // ✅ احفظ رقم الهاتف
  }

  Future<void> loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');
    final username = prefs.getString('user_name');
    final email = prefs.getString('user_email');
    final phone = prefs.getString('user_phone');

    if (token != null && username != null && email != null) {
      setUser(User(
        token: token,
        username: username,
        email: email,
        phone: phone ?? '',
      ));
    }
  }
  void logout() {
    _user = null;
    notifyListeners();
  }
}
