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

    String? _normalizedString(dynamic value) {
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
      return null;
    }

    String? _lookupFirstName() {
      final billingSection = json['billing'] is Map
          ? Map<String, dynamic>.from(json['billing'])
          : null;
      final dataBillingSection = dataSection?['billing'] is Map
          ? Map<String, dynamic>.from(dataSection!['billing'])
          : null;
      final customerBillingSection = customerSection?['billing'] is Map
          ? Map<String, dynamic>.from(customerSection!['billing'])
          : null;

      final firstNameSources = [
        json['first_name'],
        dataSection?['first_name'],
        customerSection?['first_name'],
        billingSection?['first_name'],
        dataBillingSection?['first_name'],
        customerBillingSection?['first_name'],
      ];

      for (final source in firstNameSources) {
        final normalized = _normalizedString(source);
        if (normalized != null) {
          return normalized;
        }
      }
      return null;
    }

    String? _lookupDisplayOrUsername() {
      final displaySources = [
        json['user_display_name'],
        dataSection?['user_display_name'],
        customerSection?['user_display_name'],
      ];

      for (final source in displaySources) {
        final normalized = _normalizedString(source);
        if (normalized != null) {
          return normalized;
        }
      }

      final usernameSources = [
        json['username'],
        dataSection?['username'],
        customerSection?['username'],
        json['user_nicename'],
        json['user_login'],
      ];

      for (final source in usernameSources) {
        final normalized = _normalizedString(source);
        if (normalized != null) {
          return normalized;
        }
      }

      return null;
    }

    final resolvedName =
        _lookupFirstName() ?? _lookupDisplayOrUsername() ?? '';

    String? _lookupPhone() {
      final billingSection = json['billing'] is Map
          ? Map<String, dynamic>.from(json['billing'])
          : null;
      final dataBillingSection = dataSection?['billing'] is Map
          ? Map<String, dynamic>.from(dataSection!['billing'])
          : null;
      final customerBillingSection = customerSection?['billing'] is Map
          ? Map<String, dynamic>.from(customerSection!['billing'])
          : null;

      final phoneSources = [
        json['phone'],
        json['user_phone'],
        dataSection?['phone'],
        customerSection?['phone'],
        billingSection?['phone'],
        dataBillingSection?['phone'],
        customerBillingSection?['phone'],
      ];

      for (final source in phoneSources) {
        final normalized = _normalizedString(source);
        if (normalized != null) {
          return normalized;
        }
      }

      return null;
    }

    return User(
      id: _parseId(idSource),
      token: json["token"] ?? "",
      username: resolvedName,
      email: json["user_email"] ?? json["email"] ?? "",
      phone: _lookupPhone() ?? '',
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
