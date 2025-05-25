class Order {
  final int id;
  final String status;
  final String dateCreated;
  final String total;
  final String billingEmail;
  final String customerNote;
  final Map<String, dynamic> metaData;

  Order({
    required this.id,
    required this.status,
    required this.dateCreated,
    required this.total,
    required this.billingEmail,
    required this.customerNote,
    required this.metaData,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // استخراج meta_data كـ Map
    Map<String, dynamic> meta = {};
    if (json['meta_data'] != null && json['meta_data'] is List) {
      for (var item in json['meta_data']) {
        final key = item['key'];
        final value = item['value'];
        if (key != null) {
          meta[key] = value;
        }
      }
    }

    return Order(
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      dateCreated: json['date_created'] ?? '',
      total: json['total'] ?? '0',
      billingEmail: json['billing']?['email'] ?? '',
      customerNote: json['customer_note'] ?? '',
      metaData: meta,
    );
  }

  bool get canBeCancelled {
    final lowerStatus = status.toLowerCase();
    return lowerStatus == 'pending' || lowerStatus == 'processing';
  }
}
