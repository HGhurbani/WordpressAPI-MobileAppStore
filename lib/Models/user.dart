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
      phone: json["phone"] ?? json["billing"]?["phone"] ?? "",
    );
  }

  User copyWith({
    int? id,
    String? token,
    String? username,
    String? email,
    String? phone,
  }) {
    return User(
      id: id ?? this.id,
      token: token ?? this.token,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

}
