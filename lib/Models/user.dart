// lib/models/user.dart

class User {
  final int? id;
  final String token;
  final String username;
  final String email;
  final String phone;

  User({
    this.id,
    required this.token,
    required this.username,
    required this.email,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      token: json["token"] ?? "",
      username: json["user_display_name"] ?? json["first_name"] ?? "",
      email: json["user_email"] ?? json["email"] ?? "",
      phone: json["phone"] ?? json["billing"]?["phone"] ?? "", // ✅ هذا السطر هو المفتاح
    );
  }

}
