// lib/models/product.dart

class Product {
  final int id;
  final String name;
  final String description;
  final String shortDescription;
  final double price;
  final List<String> images;
  final int categoryId; // ✅ تم إضافته
  final String stockStatus; // instock | outofstock | onbackorder | ...
  final int? stockQuantity;
  final bool manageStock;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.shortDescription,
    required this.price,
    required this.images,
    required this.categoryId, // ✅ تم تضمينه في الكونستركتر
    required this.stockStatus,
    required this.stockQuantity,
    required this.manageStock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final dynamic stockQtyRaw = json['stock_quantity'];
    final rawPrice = json["price"]?.toString();
    final parsedPrice = double.tryParse(rawPrice ?? '');
    final safePrice =
        (parsedPrice == null || !parsedPrice.isFinite) ? 0.0 : parsedPrice;
    return Product(
      id: json["id"],
      name: json["name"],
      description: json["description"] ?? "",
      shortDescription: json["short_description"] ?? "",
      price: safePrice,
      images: (json["images"] as List<dynamic>)
          .map((img) => img["src"].toString())
          .toList(),
      categoryId: (json["categories"] != null && json["categories"].isNotEmpty)
          ? json["categories"][0]["id"]
          : 0, // ✅ استخراج أول تصنيف أو 0 في حال عدم وجوده
      stockStatus: (json['stock_status'] ?? '').toString(),
      manageStock: json['manage_stock'] == true,
      stockQuantity: stockQtyRaw == null
          ? null
          : (stockQtyRaw is int
              ? stockQtyRaw
              : int.tryParse(stockQtyRaw.toString())),
    );
  }

  static const int lowStockThreshold = 5;

  /// Returns: 'in' | 'low' | 'out'
  String availabilityKey() {
    // If quantity is known, it is the most accurate.
    if (stockQuantity != null) {
      final qty = stockQuantity!;
      if (qty <= 0) return 'out';
      if (qty <= lowStockThreshold) return 'low';
      return 'in';
    }

    // Fallback to WooCommerce stock_status.
    final status = stockStatus.toLowerCase();
    if (status == 'outofstock') return 'out';
    return 'in';
  }

  String availabilityLabel(bool isArabic) {
    switch (availabilityKey()) {
      case 'out':
        return isArabic ? 'نفاذ' : 'Out of stock';
      case 'low':
        return isArabic ? 'قيد النفاذ' : 'Low stock';
      default:
        return isArabic ? 'متوفر' : 'In stock';
    }
  }
}
