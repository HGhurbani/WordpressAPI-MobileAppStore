import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadNotifications();
    });
  }


  Future<void> _checkAndLoadNotifications() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final langCode = Localizations.localeOf(context).languageCode;

    if (user != null && user.email != null) {
      await NotificationService().checkOrderStatusUpdates(
        userEmail: user.email!,
        langCode: langCode,
      );
    }

    await _loadNotifications();
    await NotificationService().markAllAsRead();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsList = prefs.getStringList('notifications') ?? [];

    setState(() {
      notifications = notificationsList
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList();
    });
  }

  String formatTime(String isoTime) {
    try {
      final dateTime = DateTime.parse(isoTime).toLocal();
      return DateFormat('yyyy/MM/dd – HH:mm').format(dateTime);
    } catch (_) {
      return isoTime;
    }
  }

  String translateStatus(String status, String langCode) {
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
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        centerTitle: true,
        title: Text(langCode == 'ar' ? 'الإشعارات' : 'Notifications'),
        backgroundColor: const Color(0xFF1A2543),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: langCode == 'ar' ? 'تحديث' : 'Refresh',
            onPressed: _checkAndLoadNotifications,
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
        child: Text(
          langCode == 'ar' ? 'لا توجد إشعارات بعد' : 'No notifications yet',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = notifications[index];

          // إذا الإشعار مرتبط بحالة طلب - ترجم النص
          String title = notification['title'] ?? '';
          String body = notification['body'] ?? '';

          if (notification['type'] == 'order_update') {
            final to = translateStatus(notification['orderStatus'] ?? '', langCode);
            final orderId = notification['orderId'] ?? '';
            title = langCode == 'ar' ? 'تحديث حالة الطلب' : 'Order Status Update';
            body = langCode == 'ar'
                ? 'تم تغيير حالة طلبك رقم #$orderId إلى "$to"'
                : 'Your order #$orderId status changed to "$to"';
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notifications_active, color: Color(0xFF1A2543)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatTime(notification['time'] ?? ''),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
