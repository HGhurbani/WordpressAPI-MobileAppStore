import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../Models/order.dart';
import '../providers/user_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Future<List<Order>>? _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrdersAndTrackChanges();
  }


  Future<List<Order>> _loadOrdersAndTrackChanges() async {
    final userEmail = Provider.of<UserProvider>(context, listen: false).user?.email ?? "";
    final orders = await ApiService().getOrders(userEmail: userEmail);
    await _trackOrderStatusChanges(orders);
    return orders;
  }


  Future<void> _trackOrderStatusChanges(List<Order> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final storedStatuses = prefs.getString('order_statuses') ?? '{}';
    final Map<String, String> oldStatuses = Map<String, String>.from(json.decode(storedStatuses));
    final notifications = prefs.getStringList('notifications') ?? [];
    int unreadCount = prefs.getInt('unread_notifications') ?? 0;

    final langCode = Localizations.localeOf(context).languageCode;

    for (final order in orders) {
      final orderId = order.id.toString();
      final currentStatus = order.status;
      final previousStatus = oldStatuses[orderId];

      if (previousStatus != null && previousStatus != currentStatus) {
        final previousText = _translateStatus(previousStatus, langCode);
        final currentText = _translateStatus(currentStatus, langCode);

        final notification = {
          'title': langCode == 'ar' ? 'تحديث حالة الطلب' : 'Order Status Update',
          'body': langCode == 'ar'
              ? 'تم تغيير حالة طلبك رقم #$orderId من "$previousText" إلى "$currentText"'
              : 'Your order #$orderId status changed from "$previousText" to "$currentText"',
          'time': DateTime.now().toIso8601String(),
          'type': 'order_update',
          'orderId': orderId,
          'orderStatus': currentStatus,
          'isRead': false,
        };

        notifications.insert(0, jsonEncode(notification));
        unreadCount++;
      }

      oldStatuses[orderId] = currentStatus;
    }

    await prefs.setStringList('notifications', notifications);
    await prefs.setInt('unread_notifications', unreadCount);
    await prefs.setString('order_statuses', json.encode(oldStatuses));
  }

  String _translateStatus(String status, String langCode) {
    final ar = {
      'pending': 'قيد المعالجة',
      'processing': 'قيد التنفيذ',
      'completed': 'مكتمل',
      'cancelled': 'ملغي',
      'on-hold': 'قيد الانتظار',
      'refunded': 'مسترد',
      'failed': 'فشل',
    };

    final en = {
      'pending': 'Pending',
      'processing': 'Processing',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'on-hold': 'On Hold',
      'refunded': 'Refunded',
      'failed': 'Failed',
    };

    final map = langCode == 'ar' ? ar : en;
    return map[status.toLowerCase()] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text("طلباتي"),
        backgroundColor: const Color(0xFF1A2543),
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: _ordersFuture == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6FE0DA)))
          : FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6FE0DA)));
          } else if (snapshot.hasError) {
            return Center(child: Text("حدث خطأ: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("لا توجد طلبات حتى الآن."));
          }

          final orders = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              final langCode = Localizations.localeOf(context).languageCode;

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, const Color(0xFFF9FBFC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF6FE0DA),
                    child: const Icon(Icons.shopping_bag, color: Colors.white),
                  ),
                  title: Text("طلب رقم: #${order.id}", style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text("الحالة: ${_translateStatus(order.status, langCode)}"),
                      Text("التاريخ: ${order.dateCreated.substring(0, 10)}"),
                      Text("الإجمالي: ${order.total} ر.ق"),
                    ],
                  ),
                  trailing: order.canBeCancelled
                      ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    onPressed: () => _confirmCancelOrder(order.id),
                    child: const Text('إلغاء', style: TextStyle(fontSize: 12)),
                  )
                      : const Icon(Icons.chevron_right, color: Color(0xFF1A2543)),
                  onTap: () => _showOrderDetails(order, langCode),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmCancelOrder(int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الإلغاء'),
        content: const Text('هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await ApiService().cancelOrder(orderId);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الطلب بنجاح')));
          _loadOrdersAndTrackChanges();
        } else {
          throw Exception();
        }
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل إلغاء الطلب')));
      }
    }
  }

  void _showOrderDetails(Order order, String langCode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final Color primaryColor = const Color(0xFF1A2543);
        final Color accentColor = const Color(0xFF6FE0DA);

        final List<Widget> rows = [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Text("تفاصيل الطلب #${order.id}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 16),

          _buildIconInfoRow(Icons.info_outline, "الحالة", _translateStatus(order.status, langCode), primaryColor, accentColor),
          _buildIconInfoRow(Icons.calendar_today_outlined, "تاريخ الإنشاء", order.dateCreated.substring(0, 10), primaryColor, accentColor),
          _buildIconInfoRow(Icons.attach_money, "المقدم", "${order.total} ر.ق", primaryColor, accentColor),

          const Divider(height: 32),
        ];

        if (order.metaData.containsKey('custom_installment')) {
          final plan = jsonDecode(order.metaData['custom_installment']);
          rows.addAll([
            Text("خطة التقسيط", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 12),

            _buildIconInfoRow(Icons.payment, "الدفعة الأولى", "${(double.tryParse(plan['downPayment'].toString()) ?? 0).toInt()} ر.ق", primaryColor, accentColor),
            _buildIconInfoRow(Icons.account_balance_wallet, "المبلغ المتبقي", "${(double.tryParse(plan['remainingAmount'].toString()) ?? 0).toInt()} ر.ق", primaryColor, accentColor),
            _buildIconInfoRow(Icons.calendar_view_month, "قيمة القسط الشهري", "${(double.tryParse(plan['monthlyPayment'].toString()) ?? 0).toInt()} ر.ق", primaryColor, accentColor),
            _buildIconInfoRow(Icons.timelapse, "عدد الأشهر", "${plan['numberOfInstallments']}", primaryColor, accentColor),

            const Divider(height: 32),
          ]);
        }

        rows.add(
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("إغلاق", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          ),
        );

        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows,
            ),
          ),
        );
      },
    );
  }
  Widget _buildIconInfoRow(IconData icon, String label, String value, Color primaryColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: primaryColor)),
          ),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
        ],
      ),
    );
  }


}
