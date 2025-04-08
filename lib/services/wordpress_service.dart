// lib/services/wordpress_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class WordPressService {
  final String baseUrl = "https://creditphoneqatar.com/wp-json/wp/v2";

  // مثال: جلب صفحة عبر ID
  Future<Map<String, dynamic>> getPageById(int pageId) async {
    final url = "$baseUrl/pages/$pageId";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load page");
    }
  }
}
