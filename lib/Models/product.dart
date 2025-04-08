// lib/models/product.dart

class Product {
  final int id;
  final String name;
  final String description;
  final String shortDescription; // ✅ تمت إضافته
  final double price;
  final List<String> images;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.shortDescription, // ✅ تمت إضافته
    required this.price,
    required this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["id"],
      name: json["name"],
      description: json["description"] ?? "",
      shortDescription: json["short_description"] ?? "", // ✅ تم إضافته بشكل صحيح
      price: double.tryParse(json["price"] ?? "0") ?? 0.0,
      images: (json["images"] as List<dynamic>)
          .map((img) => img["src"].toString())
          .toList(),
    );
  }
}
