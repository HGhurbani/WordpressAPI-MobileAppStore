import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const AuthException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}

class AuthService {
  // تسجيل الدخول
  Future<User> login(String username, String password) async {
    final url = AppConfig.jwtLoginUrl;

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      var user = User.fromJson(data);

      String? email = data['email'] ?? data['user_email'];
      final String? normalizedEmail =
          email ?? (user.email.isNotEmpty ? user.email : null);

      final bool isIdMissing = user.id == null || user.id == 0;
      if (isIdMissing && normalizedEmail != null) {
        final fetchedId =
            await ApiService().fetchCustomerIdByEmail(normalizedEmail);
        if (fetchedId != null) {
          user = user.copyWith(id: fetchedId);
        }
      }

      if (user.id != null) {
        await prefs.setInt('user_id', user.id!);
      } else {
        await prefs.remove('user_id');
      }

      // Get and update FCM token
      String? fcmToken = prefs.getString('fcm_token');
      if (fcmToken != null && normalizedEmail != null) {
        await ApiService().updateFcmToken(normalizedEmail, fcmToken);
      }
      return user;
    } else {
      final dynamic errorData = jsonDecode(response.body);
      final Map<String, dynamic> map =
          (errorData is Map<String, dynamic>) ? errorData : <String, dynamic>{};
      final String code = (map['code'] is String && (map['code'] as String).isNotEmpty)
          ? map['code'] as String
          : 'login_failed';
      final String message =
          (map['message'] is String && (map['message'] as String).trim().isNotEmpty)
              ? (map['message'] as String).trim()
              : 'Login failed';
      throw AuthException(code: code, message: message, statusCode: response.statusCode);
    }
  }

  // التسجيل (إنشاء حساب جديد)
  Future<User> register(
      String username, String email, String password, String phone) async {
    final response = await http.post(
      AppConfig.buildBackendUri('/customers'),
      headers: {
        "Content-Type": "application/json",
        'Accept': 'application/json',
        ...AppConfig.wooCommerceAuthHeaders,
      },
      body: jsonEncode({
        "email": email,
        "username": username,
        "password": password,
        "billing": {
          "phone": phone,
        }
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      Map<String, dynamic> customerData;
      if (data is Map<String, dynamic>) {
        if (data['customer'] is Map<String, dynamic>) {
          customerData = Map<String, dynamic>.from(data['customer']);
        } else {
          customerData = data;
        }
      } else {
        throw Exception('Unexpected registration response format: $data');
      }

      return User.fromJson({
        "id": customerData["id"],
        "token": "",
        "user_display_name":
            customerData["username"] ?? customerData["name"] ?? "",
        "user_email": customerData["email"] ?? "",
        "phone": customerData["billing"]?["phone"] ?? "",
      });
    } else {
      final dynamic errorData = jsonDecode(response.body);
      final Map<String, dynamic> map =
          (errorData is Map<String, dynamic>) ? errorData : <String, dynamic>{};
      final String code = (map['code'] is String && (map['code'] as String).isNotEmpty)
          ? map['code'] as String
          : 'register_failed';
      final String message =
          (map['message'] is String && (map['message'] as String).trim().isNotEmpty)
              ? (map['message'] as String).trim()
              : 'Register failed';
      throw AuthException(code: code, message: message, statusCode: response.statusCode);
    }
  }
}