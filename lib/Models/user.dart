// lib/models/user.dart

class User {
  final String token;
  final String username;
  final String email;
  final String phone;

  User({
    required this.token,
    required this.username,
    required this.email,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      token: json["token"] ?? "",
      username: json["user_display_name"] ?? json["first_name"] ?? "",
      email: json["user_email"] ?? json["email"] ?? "",
      phone: json["phone"] ?? json["billing"]?["phone"] ?? "", // ✅ هذا السطر هو المفتاح
    );
  }

}
