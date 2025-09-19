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
    final Map<String, dynamic>? dataSection =
        json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null;

    final Map<String, dynamic>? customerSection = json['customer'] is Map
        ? Map<String, dynamic>.from(json['customer'])
        : null;

    final dynamic idSource = json['id'] ??
        json['user_id'] ??
        json['ID'] ??
        (dataSection?['id']) ??
        (dataSection?['user_id']) ??
        (customerSection?['id']);

    return User(
      id: _parseId(idSource),
      token: json["token"] ?? "",
      username: json["user_display_name"] ?? json["first_name"] ?? "",
      email: json["user_email"] ?? json["email"] ?? "",
      phone: json["phone"] ?? json["billing"]?["phone"] ?? "",
    );
  }

  static int? _parseId(dynamic id) {
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    if (id is double) return id.toInt();
    return null;
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
