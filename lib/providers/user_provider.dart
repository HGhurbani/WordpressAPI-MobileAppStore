// lib/providers/user_provider.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_config.dart';
import '../models/user.dart';
import 'package:http/http.dart' as http;

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
  Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      debugPrint('No user ID found. Cannot delete.');
      return;
    }

    final url = Uri.parse('${AppConfig.baseUrl}/wp-json/wc/v3/customers/$userId'
        '?consumer_key=${AppConfig.consumerKey}&consumer_secret=${AppConfig.consumerSecret}');

    try {
      final response = await http.delete(url);

      if (response.statusCode != 200) {
        throw Exception('فشل حذف الحساب: ${response.body}');
      }
    } catch (e) {
      debugPrint('خطأ أثناء حذف الحساب: \$e');
    }

    await prefs.clear();
    _user = null;
    notifyListeners();
  }
}
