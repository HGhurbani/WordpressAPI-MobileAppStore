import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../providers/user_provider.dart';

// --- Constants (Best practice: place in a separate file like `app_constants.dart`) ---
class AppColors {
  static const Color primaryColor = Color(0xFF1A2543); // Dark Blue
  static const Color backgroundColor = Color(0xFFF1F3F6); // Light Grey/Off-white
  static const Color accentColor = Color(0xFF00C853); // Example: A nice green for success or new notifications
  static const Color warningColor = Colors.orangeAccent; // Example: For pending or on-hold
}

class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
    color: Colors.white,
  );
  static const TextStyle notificationTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 17,
    color: AppColors.primaryColor,
  );
  static const TextStyle notificationBody = TextStyle(
    fontSize: 15,
    color: Colors.black87,
  );
  static const TextStyle notificationTime = TextStyle(
    fontSize: 13,
    color: Colors.grey, // Slightly darker grey for better readability
  );
  static const TextStyle emptyStateText = TextStyle(
    fontSize: 18,
    color: Colors.grey,
  );
}
// --- End Constants ---

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool _isLoading = false; // To show a loading indicator

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadNotifications();
    });
  }

  Future<void> _checkAndLoadNotifications() async {
    if (_isLoading) return; // Prevent multiple simultaneous calls
    setState(() {
      _isLoading = true;
    });

    final user = Provider.of<UserProvider>(context, listen: false).user;
    final langCode = Localizations.localeOf(context).languageCode;

    if (user != null && user.email != null) {
      // In a real app, you might want to show specific loading for this update check
      await NotificationService().checkOrderStatusUpdates(
        userEmail: user.email!,
        langCode: langCode,
      );
    }
    await _loadNotifications();
    // Decide when to mark all as read: immediately on load, or when user interacts
    // For a better UX, marking all as read might happen after the user
    // sees the notifications for a while, or you implement individual marking.
    // For now, keeping it here as per original logic.
    await NotificationService().markAllAsRead();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsList = prefs.getStringList('notifications') ?? [];

    setState(() {
      notifications = notificationsList
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList()
        ..sort((a, b) {
          // Sort by time, newest first
          final timeA = DateTime.tryParse(a['time'] ?? '') ?? DateTime(0);
          final timeB = DateTime.tryParse(b['time'] ?? '') ?? DateTime(0);
          return timeB.compareTo(timeA);
        });
    });
  }

  String formatTime(String isoTime, String langCode) {
    try {
      final dateTime = DateTime.parse(isoTime).toLocal();
      // Adjust format for Arabic if needed, or use a package for locale-aware formatting
      return DateFormat('yyyy/MM/dd – HH:mm', langCode).format(dateTime);
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

  // --- Widget for individual Notification Card ---
  Widget _buildNotificationCard(
      Map<String, dynamic> notification, String langCode) {
    String title = notification['title'] ?? '';
    String body = notification['body'] ?? '';
    IconData icon = Icons.notifications_active;
    Color iconColor = AppColors.primaryColor;

    if (notification['type'] == 'order_update') {
      final to = translateStatus(notification['orderStatus'] ?? '', langCode);
      final orderId = notification['orderId'] ?? '';
      title = langCode == 'ar' ? 'تحديث حالة الطلب' : 'Order Status Update';
      body = langCode == 'ar'
          ? 'تم تغيير حالة طلبك رقم #$orderId إلى "$to"'
          : 'Your order #$orderId status changed to "$to"';

      // Customize icon/color based on order status for better visual cue
      switch (notification['orderStatus']) {
        case 'completed':
          icon = Icons.check_circle;
          iconColor = AppColors.accentColor;
          break;
        case 'cancelled':
        case 'failed':
          icon = Icons.cancel;
          iconColor = Colors.redAccent;
          break;
        case 'pending':
        case 'on-hold':
          icon = Icons.access_time;
          iconColor = AppColors.warningColor;
          break;
        case 'processing':
          icon = Icons.sync;
          iconColor = Colors.blueAccent;
          break;
        default:
          icon = Icons.notifications_active;
          iconColor = AppColors.primaryColor;
      }
    } else if (notification['type'] == 'promotion') {
      icon = Icons.local_offer;
      iconColor = AppColors.accentColor;
    }
    // Add more conditions for different notification types

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // More rounded corners
      ),
      child: Material(
        // Use Material for InkWell splash effect
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Handle notification tap, e.g., navigate to order details
            debugPrint('Notification tapped: ${notification['title']}');
            // Implement logic to mark as read if not using markAllAsRead
          },
          child: Padding(
            padding: const EdgeInsets.all(18), // Slightly more padding
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 30), // Larger icon
                const SizedBox(width: 16), // More space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.notificationTitle,
                      ),
                      const SizedBox(height: 8), // More space
                      Text(
                        body,
                        style: AppTextStyles.notificationBody,
                      ),
                      const SizedBox(height: 10), // More space
                      Align(
                        alignment: langCode == 'ar'
                            ? Alignment.bottomLeft
                            : Alignment.bottomRight,
                        child: Text(
                          formatTime(notification['time'] ?? '', langCode),
                          style: AppTextStyles.notificationTime,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // --- End Notification Card Widget ---

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          langCode == 'ar' ? 'الإشعارات' : 'Notifications',
          style: AppTextStyles.appBarTitle,
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 6.0, // Increased elevation for a more prominent app bar
        actions: [
          _isLoading
              ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: langCode == 'ar' ? 'تحديث' : 'Refresh',
            onPressed: _checkAndLoadNotifications,
          ),
          const SizedBox(width: 8), // Spacing for action icons
        ],
      ),
      body: _isLoading && notifications.isEmpty
          ? Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      )
          : notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined, // A clear "no notifications" icon
              size: 100, // Larger icon
              color: Colors.grey[300], // Lighter grey for a softer look
            ),
            const SizedBox(height: 24), // More spacing
            Text(
              langCode == 'ar' ? 'لا توجد إشعارات بعد' : 'No notifications yet',
              style: AppTextStyles.emptyStateText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Optional: A button to manually refresh or go to a help screen
            ElevatedButton.icon(
              onPressed: _checkAndLoadNotifications,
              icon: Icon(Icons.cached, color: Colors.white),
              label: Text(
                langCode == 'ar' ? 'تحديث الإشعارات' : 'Refresh Notifications',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _checkAndLoadNotifications,
        color: AppColors.primaryColor,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14), // More space between cards
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationCard(notification, langCode);
          },
        ),
      ),
    );
  }
}