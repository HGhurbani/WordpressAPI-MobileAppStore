class Order {
  final int id;
  final String status;
  final String dateCreated;
  final String total;
  final String billingEmail;

  Order({
    required this.id,
    required this.status,
    required this.dateCreated,
    required this.total,
    required this.billingEmail,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      status: json['status'],
      dateCreated: json['date_created'],
      total: json['total'],
      billingEmail: json['billing']?['email'] ?? '',
    );
  }
}
