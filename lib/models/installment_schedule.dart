import 'dart:convert';

class InstallmentSchedule {
  final int version;
  final List<InstallmentItem> items;

  const InstallmentSchedule({
    required this.version,
    required this.items,
  });

  factory InstallmentSchedule.fromDynamic(dynamic raw) {
    if (raw is String) {
      final decoded = jsonDecode(raw);
      return InstallmentSchedule.fromDynamic(decoded);
    }

    if (raw is List) {
      return InstallmentSchedule(
        version: 1,
        items: raw
            .whereType<Map>()
            .map((e) => InstallmentItem.fromMap(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => a.no.compareTo(b.no)),
      );
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final dynamic itemsRaw = map['items'];
      final items = <InstallmentItem>[];
      if (itemsRaw is List) {
        for (final entry in itemsRaw) {
          if (entry is Map) {
            items.add(
              InstallmentItem.fromMap(Map<String, dynamic>.from(entry)),
            );
          }
        }
      }
      items.sort((a, b) => a.no.compareTo(b.no));
      return InstallmentSchedule(
        version: (map['version'] is int) ? map['version'] as int : 1,
        items: items,
      );
    }

    throw FormatException('Unsupported installment schedule payload: $raw');
  }

  int get totalCount => items.length;

  int get paidCount => items.where((e) => e.isPaid).length;

  double get paidTotal => items
      .where((e) => e.isPaid)
      .fold<double>(0.0, (sum, e) => sum + e.amount);

  /// Actual remaining amount based on tracked payments.
  /// This equals the sum of unpaid installment amounts (including installment 0 if unpaid).
  double get remainingTotal => items
      .where((e) => !e.isPaid)
      .fold<double>(0.0, (sum, e) => sum + e.amount);

  InstallmentItem? nextUnpaid() {
    for (final item in items) {
      if (!item.isPaid) return item;
    }
    return null;
  }
}

class InstallmentItem {
  final int no; // 0 = down payment
  final String dueDate; // yyyy-mm-dd
  final double amount;
  final String? paidAt; // yyyy-mm-dd

  const InstallmentItem({
    required this.no,
    required this.dueDate,
    required this.amount,
    required this.paidAt,
  });

  factory InstallmentItem.fromMap(Map<String, dynamic> map) {
    final dynamic noRaw = map['no'];
    final int no = (noRaw is int) ? noRaw : int.tryParse('$noRaw') ?? 0;
    final dueDate = (map['dueDate'] ?? '').toString();
    final dynamic amountRaw = map['amount'];
    final double amount = (amountRaw is num)
        ? amountRaw.toDouble()
        : double.tryParse('$amountRaw') ?? 0.0;
    final paidAtRaw = map['paidAt'];
    final String? paidAt = (paidAtRaw == null || '$paidAtRaw'.trim().isEmpty)
        ? null
        : paidAtRaw.toString();

    return InstallmentItem(
      no: no,
      dueDate: dueDate,
      amount: amount,
      paidAt: paidAt,
    );
  }

  bool get isPaid => paidAt != null && paidAt!.trim().isNotEmpty;

  bool isLate(DateTime now) {
    if (isPaid) return false;
    if (dueDate.trim().isEmpty) return false;
    final parsed = DateTime.tryParse('${dueDate}T23:59:59Z') ??
        DateTime.tryParse(dueDate);
    if (parsed == null) return false;
    return now.toUtc().isAfter(parsed.toUtc());
  }
}

