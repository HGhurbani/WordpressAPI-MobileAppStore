// lib/models/product.dart

class Product {
  final int id;
  final String name;
  final String description;
  final String shortDescription;
  final double price;
  final List<String> images;
  final int categoryId; // ✅ تم إضافته

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.shortDescription,
    required this.price,
    required this.images,
    required this.categoryId, // ✅ تم تضمينه في الكونستركتر
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["id"],
      name: json["name"],
      description: json["description"] ?? "",
      shortDescription: json["short_description"] ?? "",
      price: double.tryParse(json["price"]?.toString() ?? "0") ?? 0.0,
      images: (json["images"] as List<dynamic>)
          .map((img) => img["src"].toString())
          .toList(),
      categoryId: (json["categories"] != null && json["categories"].isNotEmpty)
          ? json["categories"][0]["id"]
          : 0, // ✅ استخراج أول تصنيف أو 0 في حال عدم وجوده
    );
  }
}
