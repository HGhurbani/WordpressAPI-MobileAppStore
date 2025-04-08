import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added import

class ApiService { // Added ApiService class
  Future<void> updateFcmToken(String email, String fcmToken) async {
    //  Replace with your actual WordPress webhook update logic.  This is a placeholder.
    final url = "${AppConfig.baseUrl}/update_fcm_token/$email"; //Example URL, adjust as needed.
    final response = await http.post(Uri.parse(url), body: {"fcm_token": fcmToken});
    if (response.statusCode != 200) {
      print("Error updating FCM token: ${response.statusCode}");
      // Handle error appropriately
    }
  }
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
      final prefs = await SharedPreferences.getInstance(); //moved here

      String? email = data['email']; // Assuming email is part of the response

      // Get and update FCM token
      String? fcmToken = await prefs.getString('fcm_token');
      if (fcmToken != null && email != null) { //added email check to avoid null error
        await ApiService().updateFcmToken(email, fcmToken);
      }
      return User.fromJson(data);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? "Login failed with status ${response.statusCode}");
    }
  }

  // التسجيل (إنشاء حساب جديد)
  Future<User> register(String username, String email, String password, String phone) async {
    final url = "${AppConfig.baseUrl}/customers"
        "?consumer_key=${AppConfig.consumerKey}&consumer_secret=${AppConfig.consumerSecret}";

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
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

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return User.fromJson({
        "token": "",
        "user_display_name": data["username"],
        "user_email": data["email"],
        "phone": data["billing"]?["phone"] ?? "",
      });
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error["message"] ?? "فشل إنشاء الحساب");
    }
  }
}