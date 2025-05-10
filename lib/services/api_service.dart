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

  // جلب قائمة المنتجات مع دعم اللغة وفلترة السعر
  Future<List<Product>> getProducts({
    int? categoryId,
    String language = "ar",
    int perPage = 6,
    int page = 1, // ✅ أضف page هنا
    double? minPrice, // فلترة السعر الأدنى
    double? maxPrice, // فلترة السعر الأعلى
  }) async {
    String url = "$baseUrl/products?consumer_key=$ck&consumer_secret=$cs&lang=$language&page=$page&per_page=$perPage";

    // إضافة الفلاتر للصنف والسعر إذا كانت موجودة
    if (categoryId != null) {
      url += "&category=$categoryId";
    }
    if (minPrice != null) {
      url += "&min_price=$minPrice";
    }
    if (maxPrice != null) {
      url += "&max_price=$maxPrice";
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
  Future<Map<String, dynamic>> createOrder({
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required List<Map<String, dynamic>> lineItems,
    required String installmentType,
    Map<String, dynamic>? customInstallment,
    required bool isNewCustomer,
    String? customerNote,
  }) async {
    String url = "$baseUrl/orders?consumer_key=$ck&consumer_secret=$cs";

    String orderNotes = "Installment Type: $installmentType\n";
    if (customInstallment != null) {
      orderNotes += """
Down Payment: ${customInstallment['downPayment']} QAR
Remaining Amount: ${customInstallment['remainingAmount']} QAR
Monthly Installments (4 months): ${customInstallment['monthlyPayment']} QAR each
""";
    }
    orderNotes += "\nNew Customer: ${isNewCustomer ? 'Yes' : 'No'}";
    if (customerNote?.isNotEmpty ?? false) {
      orderNotes += "\n\nCustomer Note: $customerNote";
    }

    final orderData = {
      'status': 'pending',
      'customer_note': orderNotes,
      'billing': {
        'first_name': customerName,
        'email': customerEmail,
        'phone': customerPhone,
      },
      'line_items': lineItems,
      'meta_data': [
        {'key': 'installment_type', 'value': installmentType},
        {'key': 'is_new_customer', 'value': isNewCustomer},
        if (customInstallment != null)
          {'key': 'custom_installment', 'value': json.encode(customInstallment)},
      ],
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(orderData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create order: ${response.body}");
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

  Future<bool> cancelOrder(int orderId) async {
    final url = "$baseUrl/orders/$orderId?consumer_key=$ck&consumer_secret=$cs&status=cancelled";

    final response = await http.put(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
    );

    return response.statusCode == 200;
  }

  Future<bool> updateFcmToken(String email, String token) async {
    final url = "$baseUrl/wp-json/custom/v1/update-fcm-token";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "fcm_token": token,
          "consumer_key": ck,
          "consumer_secret": cs,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating FCM token: $e');
      return false;
    }
  }
}
