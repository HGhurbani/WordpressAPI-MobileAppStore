// lib/providers/user_provider.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService();

  final NotificationService _notificationService;
  User? _user;

  User? get user => _user;

  bool get isLoggedIn => _user != null;

  void setUser(User newUser) async {
    _user = newUser;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (newUser.id != null) {
      await prefs.setInt('user_id', newUser.id!);
    } else {
      await prefs.remove('user_id');
    }
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
    final userId = prefs.getInt('user_id');


    if (token != null && username != null && email != null) {
      setUser(User(
        id: userId,
        token: token,
        username: username,
        email: email,
        phone: phone ?? '',
      ));
    }
  }
  Future<void> logout() async {
    final email = _user?.email;
    await _notificationService.logoutCleanup(email: email);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    await prefs.remove('saved_username');
    await prefs.remove('remember_me');

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

    final success = await ApiService().deleteAccount(userId);
    if (!success) {
      debugPrint('خطأ أثناء حذف الحساب');
    }

    await prefs.clear();
    _user = null;
    notifyListeners();
  }

  Future<void> updateUser({
    String? username,
    String? email,
    String? phone,
  }) async {
    if (_user != null) {
      _user = _user!.copyWith(
        username: username ?? _user!.username,
        email: email ?? _user!.email,
        phone: phone ?? _user!.phone,
      );

      final prefs = await SharedPreferences.getInstance();
      if (username != null) await prefs.setString('user_name', _user!.username);
      if (email != null) await prefs.setString('user_email', _user!.email);
      if (phone != null) await prefs.setString('user_phone', _user!.phone);

      notifyListeners();
    }
  }

}
