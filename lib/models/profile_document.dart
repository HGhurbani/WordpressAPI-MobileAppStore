class ProfileDocument {
  final String id;
  final String url;
  final String name;
  final String type;

  const ProfileDocument({
    required this.id,
    required this.url,
    required this.name,
    required this.type,
  });

  factory ProfileDocument.fromJson(Map<String, dynamic> json) {
    return ProfileDocument(
      id: (json['id'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'name': name,
      'type': type,
    };
  }
}
