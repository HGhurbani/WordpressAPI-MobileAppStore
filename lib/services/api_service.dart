import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../Models/order.dart';

class ApiService {
  final String baseUrl = AppConfig.baseUrl;
  final String ck = AppConfig.consumerKey;
  final String cs = AppConfig.consumerSecret;

  // جلب قائمة المنتجات مع دعم اللغة
  Future<List<Product>> getProducts({
    int? categoryId,
    String language = "ar",
    int perPage = 6,
    int page = 1, // ✅ أضف page هنا
  }) async {
    String url = "$baseUrl/products?consumer_key=$ck&consumer_secret=$cs&lang=$language&page=$page&per_page=$perPage";

    if (categoryId != null) {
      url += "&category=$categoryId";
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load products");
    }
  }




  // جلب التصنيفات مع دعم اللغة
  Future<List<Category>> getCategories({String language = "ar"}) async {
    String url = "$baseUrl/products/categories?consumer_key=$ck&consumer_secret=$cs&per_page=100&lang=$language";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Category.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load categories");
    }
  }

  // جلب منتج واحد عبر الـID مع دعم اللغة
  Future<Product> getProductById(int id, {String language = "ar"}) async {
    String url = "$baseUrl/products/$id?consumer_key=$ck&consumer_secret=$cs&lang=$language";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Product.fromJson(data);
    } else {
      throw Exception("Failed to load product");
    }
  }

  // إنشاء طلب جديد (Order)
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    String url = "$baseUrl/orders?consumer_key=$ck&consumer_secret=$cs";
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(orderData),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create order");
    }
  }
  Future<List<Order>> getOrders({
    required String userEmail,
    String language = "ar",
  }) async {
    final url = "$baseUrl/orders?consumer_key=$ck&consumer_secret=$cs&lang=$language";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final allOrders = data.map((item) => Order.fromJson(item)).toList();

      // تصفية الطلبات حسب البريد الإلكتروني للمستخدم
      return allOrders.where((order) => order.billingEmail == userEmail).toList();
    } else {
      throw Exception("فشل تحميل الطلبات");
    }
  }


}

