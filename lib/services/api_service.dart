import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_config.dart';
import '../models/finance_profile.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/order.dart';

class ApiService {
  static const String _appApiBaseUrl = 'https://creditphoneqatar.com/wp-json/app/v1';

  Uri _uri(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return AppConfig.buildBackendUri(
      path,
      queryParameters: queryParameters,
    );
  }

  Uri _appUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_appApiBaseUrl$normalizedPath');
  }

  Map<String, String> _defaultHeaders({
    Map<String, String>? additional,
    bool includeJson = false,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
      ...AppConfig.wooCommerceAuthHeaders,
    };

    if (includeJson) {
      headers['Content-Type'] = 'application/json';
    }

    if (additional != null) {
      headers.addAll(additional);
    }

    return headers;
  }

  Future<int?> _storedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  Future<String?> _storedUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token');
  }

  Future<Map<String, String>> _jwtHeaders({
    bool includeJson = false,
  }) async {
    final token = await _storedUserToken();
    if (token == null || token.isEmpty) {
      throw Exception('missing_user_token');
    }

    return {
      'Accept': 'application/json',
      if (includeJson) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  List<dynamic> _ensureList(
    dynamic payload, {
    String? fallbackKey,
  }) {
    if (payload is List) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      if (fallbackKey != null && payload[fallbackKey] is List) {
        return List<dynamic>.from(payload[fallbackKey] as List);
      }
      for (final entry in payload.entries) {
        if (entry.value is List) {
          return List<dynamic>.from(entry.value as List);
        }
      }
    }

    throw Exception('Unexpected response format from backend: $payload');
  }

  // جلب قائمة المنتجات مع دعم اللغة وفلترة السعر
  Future<List<Product>> getProducts({
    int? categoryId,
    String language = "ar",
    int perPage = 6,
    int page = 1,
    double? minPrice,
    double? maxPrice,
  }) async {
    final response = await http.get(
      _uri(
        '/products',
        queryParameters: {
          'lang': language,
          'per_page': perPage,
          'page': page,
          'category': categoryId,
          'min_price': minPrice,
          'max_price': maxPrice,
        },
      ),
      headers: _defaultHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final productsJson = _ensureList(data, fallbackKey: 'products');
      return productsJson.map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load products: ${response.body}");
    }
  }

  // جلب التصنيفات مع دعم اللغة (per_page=100 لجلب كل التصنيفات بدل الافتراضي 10)
  Future<List<Category>> getCategories({String language = "ar"}) async {
    final response = await http.get(
      _uri(
        '/products/categories',
        queryParameters: {
          'lang': language,
          'per_page': 100,
        },
      ),
      headers: _defaultHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final categoriesJson = _ensureList(data, fallbackKey: 'categories');
      return categoriesJson.map((item) => Category.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load categories: ${response.body}");
    }
  }

  Future<List<Product>> getProductsByIds(
    List<int> ids, {
    String language = "ar",
  }) async {
    if (ids.isEmpty) {
      return [];
    }

    try {
      final response = await http.get(
        AppConfig.buildBackendUri(
          '/products',
          queryParameters: {
            'include': ids.join(','),
            'lang': language,
          },
        ),
        headers: _defaultHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final productsJson = _ensureList(data, fallbackKey: 'products');

        return productsJson
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw Exception(
        'Failed to fetch products by ids: ${response.statusCode} ${response.body}',
      );
    } catch (error) {
      print('Batch fetch failed, falling back to individual requests: $error');
    }

    final products = <Product>[];

    for (final id in ids) {
      try {
        final product = await getProductById(id, language: language);
        products.add(product);
      } catch (e) {
        print("Failed to fetch product with ID $id: $e");
      }
    }

    return products;
  }

  // جلب منتج واحد عبر الـID مع دعم اللغة
  Future<Product> getProductById(int id, {String language = "ar"}) async {
    final response = await http.get(
      _uri(
        '/products/$id',
        queryParameters: {'lang': language},
      ),
      headers: _defaultHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return Product.fromJson(data);
      }
      if (data is List && data.isNotEmpty) {
        return Product.fromJson(data.first as Map<String, dynamic>);
      }
      throw Exception('Unexpected product payload: $data');
    } else {
      throw Exception("Failed to load product: ${response.body}");
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
    int? customerId,
  }) async {
    final isCashOrder = installmentType == 'cash';

    String orderNotes = "Installment Type: $installmentType\n";
    if (!isCashOrder && customInstallment != null) {
      final months = customInstallment['numberOfInstallments'];
      orderNotes += """
Down Payment: ${customInstallment['downPayment']} QAR
Remaining Amount: ${customInstallment['remainingAmount']} QAR
Monthly Installments ($months months): ${customInstallment['monthlyPayment']} QAR each
""";
    }
    orderNotes += "\nNew Customer: ${isNewCustomer ? 'Yes' : 'No'}";
    if (customerNote?.isNotEmpty ?? false) {
      orderNotes += "\n\nCustomer Note: $customerNote";
    }

    Map<String, dynamic>? schedulePayload;
    if (!isCashOrder && customInstallment != null) {
      final now = DateTime.now();
      final baseDue = DateTime(now.year, now.month, now.day);
      final int months = (customInstallment['numberOfInstallments'] is int)
          ? customInstallment['numberOfInstallments'] as int
          : int.tryParse('${customInstallment['numberOfInstallments']}') ?? 0;
      final double downPayment = (customInstallment['downPayment'] is num)
          ? (customInstallment['downPayment'] as num).toDouble()
          : double.tryParse('${customInstallment['downPayment']}') ?? 0.0;
      final double monthlyPayment = (customInstallment['monthlyPayment'] is num)
          ? (customInstallment['monthlyPayment'] as num).toDouble()
          : double.tryParse('${customInstallment['monthlyPayment']}') ?? 0.0;

      String fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final items = <Map<String, dynamic>>[
        {
          'no': 0,
          'dueDate': fmt(baseDue),
          'amount': downPayment,
          'paidAt': null,
        },
      ];
      for (var i = 1; i <= months; i++) {
        final due = DateTime(baseDue.year, baseDue.month + i, baseDue.day);
        items.add({
          'no': i,
          'dueDate': fmt(due),
          'amount': monthlyPayment,
          'paidAt': null,
        });
      }
      schedulePayload = {
        'version': 1,
        'items': items,
      };
    }

    final metaData = [
      {'key': 'installment_type', 'value': installmentType},
      {'key': 'is_new_customer', 'value': isNewCustomer},
      if (customerId != null) {'key': 'finance_profile_customer_id', 'value': customerId},
      if (!isCashOrder) {'key': 'finance_profile_linked', 'value': true},
      if (!isCashOrder && customInstallment != null)
        {'key': 'custom_installment', 'value': json.encode(customInstallment)},
      if (!isCashOrder && schedulePayload != null)
        {'key': 'installment_schedule', 'value': json.encode(schedulePayload)},
    ];

    final orderData = {
      'status': 'pending',
      'customer_note': orderNotes,
      if (customerId != null) 'customer_id': customerId,
      'billing': {
        'first_name': customerName,
        'email': customerEmail,
        'phone': customerPhone,
      },
      'line_items': lineItems,
      'meta_data': metaData,
    };

    final response = await http.post(
      _uri('/orders'),
      headers: _defaultHeaders(includeJson: true),
      body: jsonEncode(orderData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw Exception('Unexpected order response format: $data');
    } else {
      throw Exception("Failed to create order: ${response.body}");
    }
  }

  Future<List<Order>> getOrders({
    required String userEmail,
    String language = "ar",
  }) async {
    final response = await http.get(
      _uri(
        '/orders',
        queryParameters: {
          'search': userEmail,
          'lang': language,
        },
      ),
      headers: _defaultHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final ordersJson = _ensureList(data, fallbackKey: 'orders');
      final orders = ordersJson
          .map((item) => Order.fromJson(item as Map<String, dynamic>))
          .toList();

      return orders
          .where((order) => order.billingEmail == userEmail)
          .toList();
    } else {
      throw Exception("فشل تحميل الطلبات: ${response.body}");
    }
  }

  Future<bool> updateUserInfo({
    required String name,
    required String email,
    required String phone,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null || userId == 0) {
      throw Exception('user_id_missing');
    }

    final url = _uri('/customers/$userId');

    final body = {
      'email': email,
      'first_name': name,
      'billing': {
        'first_name': name,
        'email': email,
        'phone': phone,
      },
    };

    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    try {
      final response = await http.put(
        url,
        headers: _defaultHeaders(includeJson: true),
        body: jsonEncode(body),
      );

      print("Update Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        throw Exception('expired_token');
      } else {
        return false;
      }
    } catch (e) {
      print("Update Error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCustomerById(int customerId) async {
    final response = await http.get(
      _uri('/customers/$customerId'),
      headers: _defaultHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch customer: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw Exception('Unexpected customer payload: $data');
  }

  Future<FinanceProfile> getFinanceProfile() async {
    final userId = await _storedUserId();
    if (userId == null || userId == 0) {
      return const FinanceProfile();
    }

    final customer = await getCustomerById(userId);
    final metaData = customer['meta_data'];
    if (metaData is List) {
      return FinanceProfile.fromCustomerMeta(metaData);
    }
    return const FinanceProfile();
  }

  Future<bool> updateFinanceProfileAnswers({
    required String residencyInQatar,
    required String haveBankChecks,
    String? canGetBankChecks,
  }) async {
    final userId = await _storedUserId();
    if (userId == null || userId == 0) {
      throw Exception('user_id_missing');
    }

    final customer = await getCustomerById(userId);
    final existingMetaData = customer['meta_data'] is List
        ? List<dynamic>.from(customer['meta_data'] as List)
        : const <dynamic>[];

    Map<String, dynamic> buildFinanceMetaEntry(String key, String value) {
      final existingId = _latestMetaIdForKey(existingMetaData, key);
      return {
        if (existingId != null) 'id': existingId,
        'key': key,
        'value': value,
      };
    }

    final body = {
      'meta_data': [
        buildFinanceMetaEntry(
          'finance_residency_in_qatar',
          residencyInQatar,
        ),
        buildFinanceMetaEntry(
          'finance_have_bank_checks',
          haveBankChecks,
        ),
        buildFinanceMetaEntry(
          'finance_can_get_bank_checks',
          haveBankChecks == 'No' ? (canGetBankChecks ?? '') : '',
        ),
      ],
    };

    final response = await http.put(
      _uri('/customers/$userId'),
      headers: _defaultHeaders(includeJson: true),
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  int? _latestMetaIdForKey(List<dynamic> metaData, String key) {
    int? latestId;
    for (final item in metaData) {
      if (item is! Map) continue;
      final entry = Map<String, dynamic>.from(item);
      if (entry['key']?.toString() != key) continue;

      final rawId = entry['id'];
      final int? parsedId;
      if (rawId is int) {
        parsedId = rawId;
      } else if (rawId is String) {
        parsedId = int.tryParse(rawId);
      } else if (rawId is double) {
        parsedId = rawId.toInt();
      } else {
        parsedId = null;
      }

      if (parsedId == null) continue;
      if (latestId == null || parsedId > latestId) {
        latestId = parsedId;
      }
    }
    return latestId;
  }

  Future<void> uploadFinanceDocument({
    required String category,
    required PlatformFile file,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _appUri('/profile-documents/upload'),
    );
    request.headers.addAll(await _jwtHeaders());
    request.fields['category'] = category;

    if (file.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ),
      );
    } else if (file.path != null && file.path!.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ),
      );
    } else {
      throw Exception('invalid_file');
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to upload document: $responseBody');
    }
  }

  Future<void> deleteFinanceDocument({
    required String category,
    required String documentId,
  }) async {
    final response = await http.delete(
      _appUri('/profile-documents'),
      headers: await _jwtHeaders(includeJson: true),
      body: jsonEncode({
        'category': category,
        'document_id': documentId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to delete document: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    final response = await http.put(
      _uri('/orders/$orderId'),
      headers: _defaultHeaders(includeJson: true),
      body: jsonEncode({'status': 'cancelled'}),
    );

    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<bool> deleteAccount(int userId) async {
    try {
      final uri = _uri(
        '/customers/$userId',
        queryParameters: {'force': 'true'},
      );
      final response = await http.delete(uri, headers: _defaultHeaders());

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      print(
        'Delete account failed: status=${response.statusCode} body=${response.body}',
      );
      return false;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }

  Future<int?> fetchCustomerIdByEmail(String email) async {
    final response = await http.get(
      _uri(
        '/customers',
        queryParameters: {
          'email': email,
          'per_page': '1',
        },
      ),
      headers: _defaultHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch customer by email: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final customers = _ensureList(data, fallbackKey: 'customers');
    if (customers.isEmpty) {
      return null;
    }

    final dynamic firstCustomer = customers.first;
    if (firstCustomer is! Map) {
      throw Exception('Unexpected customer payload: $firstCustomer');
    }

    final customer = Map<String, dynamic>.from(firstCustomer);
    final dynamic idSource = customer['id'] ?? customer['ID'];
    if (idSource is int) return idSource;
    if (idSource is String) return int.tryParse(idSource);
    if (idSource is double) return idSource.toInt();
    return null;
  }

  Future<bool> updateFcmToken(String email, String token) async {
    try {
      final response = await http.post(
        Uri.parse('https://creditphoneqatar.com/wp-json/app/v1/notifications/fcm'),
        headers: const {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "fcm_token": token,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating FCM token: $e');
      return false;
    }
  }

  Future<bool> unregisterFcmToken(String email) async {
    try {
      final response = await http.delete(
        Uri.parse('https://creditphoneqatar.com/wp-json/app/v1/notifications/fcm'),
        headers: const {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error unregistering FCM token: $e');
      return false;
    }
  }
}
