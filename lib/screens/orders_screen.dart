import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../Models/order.dart';
import '../providers/user_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    final userEmail = Provider.of<UserProvider>(context, listen: false).user?.email ?? "";
    _ordersFuture = ApiService().getOrders(userEmail: userEmail); // تعديل هنا
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("طلباتي"),
        backgroundColor: const Color(0xff1d0fe3),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("حدث خطأ: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("لا يوجد طلبات حالياً"));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: Text("طلب رقم: #${order.id}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("الحالة: ${order.status}"),
                      Text("التاريخ: ${order.dateCreated.substring(0, 10)}"),
                      Text("الإجمالي: ${order.total} ر.س"),
                    ],
                  ),
                  trailing: order.canBeCancelled ? 
                    TextButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('تأكيد إلغاء الطلب'),
                            content: const Text('هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('لا'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('نعم'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            final success = await ApiService().cancelOrder(order.id);
                            if (success) {
                              setState(() {
                                _ordersFuture = ApiService().getOrders(
                                  userEmail: Provider.of<UserProvider>(context, listen: false).user?.email ?? ""
                                );
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم إلغاء الطلب بنجاح')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('حدث خطأ أثناء إلغاء الطلب')),
                            );
                          }
                        }
                      },
                      child: const Text('إلغاء الطلب', style: TextStyle(color: Colors.red)),
                    )
                    : const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text("تفاصيل الطلب #${order.id}"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("الحالة: ${order.status}"),
                            const SizedBox(height: 8),
                            Text("تاريخ الإنشاء: ${order.dateCreated.substring(0, 10)}"),
                            const SizedBox(height: 8),
                            Text("الإجمالي: ${order.total} ر.س"),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("إغلاق"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
