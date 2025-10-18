import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import '../services/api_service.dart';
import '../models/order.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  await NotificationService().handleBackgroundMessage(message);
}

class NotificationService {
  NotificationService({
    FirebaseMessaging? firebaseMessaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    ApiService? apiService,
    Future<void> Function()? deleteTokenOverride,
  })  : _fcm = firebaseMessaging ?? FirebaseMessaging.instance,
        _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin(),
        _apiService = apiService ?? ApiService(),
        _deleteTokenOverride = deleteTokenOverride;

  final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final ApiService _apiService;
  final Future<void> Function()? _deleteTokenOverride;
  static final StreamController<int> _unreadCountController = StreamController<int>.broadcast();
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationsListKey = 'notifications';
  static const String _unreadCountKey = 'unread_notifications';
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Clears stored notification-related data from [SharedPreferences].
  static Future<void> clearStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    const keysToRemove = <String>[
      _notificationsListKey,
      _unreadCountKey,
      _notificationsEnabledKey,
      'order_statuses',
    ];

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final bool notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;

    if (notificationsEnabled) {
      await _requestPermission();
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _localNotifications.initialize(initializationSettings);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _tokenRefreshSubscription ??=
        _fcm.onTokenRefresh.listen((token) => unawaited(_handleTokenRefresh(token)));

    if (notificationsEnabled) {
      _startForegroundListener();
    } else {
      await _stopForegroundListener();
    }
  }

  void _startForegroundListener() {
    _foregroundSubscription ??=
        FirebaseMessaging.onMessage.listen((RemoteMessage message) => _handleForegroundMessage(message));
  }

  Future<void> _stopForegroundListener() async {
    await _foregroundSubscription?.cancel();
    _foregroundSubscription = null;
  }

  Future<void> logoutCleanup({String? email}) async {
    await _stopForegroundListener();
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await clearStoredData();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');

    try {
      if (_deleteTokenOverride != null) {
        await _deleteTokenOverride!.call();
      } else {
        await _fcm.deleteToken();
      }
    } catch (e) {
      print('Error deleting FCM token: $e');
    }

    if (email != null && email.isNotEmpty) {
      try {
        await _apiService.unregisterFcmToken(email);
      } catch (e) {
        print('Error unregistering FCM token: $e');
      }
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _fcm.getToken();
      if (token != null) {
        await _handleTokenRefresh(token);
      }
    }
  }

  Future<void> _handleTokenRefresh(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
    final email = prefs.getString('user_email');

    if (email == null || email.isEmpty) {
      return;
    }

    try {
      await _apiService.updateFcmToken(email, token);
    } catch (e) {
      print('Error updating FCM token on refresh: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (!await getNotificationsEnabled()) {
      return;
    }

    final title = message.notification?.title ?? 'تنبيه';
    final body = message.notification?.body ?? '';
    await _showNotification(title, body);
    await _saveNotification(message);
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    if (!await getNotificationsEnabled()) {
      return;
    }
    await _saveNotification(message);
  }

  Future<void> _showNotification(String title, String body) async {
    if (!await getNotificationsEnabled()) {
      return;
    }
    const androidDetails = AndroidNotificationDetails(
      'order_status_channel',
      'Order Status Updates',
      channelDescription: 'إشعارات تغير حالة الطلب',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> _saveNotification(RemoteMessage message) async {
    if (!await getNotificationsEnabled()) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList(_notificationsListKey) ?? [];
    final unreadCount = prefs.getInt(_unreadCountKey) ?? 0;

    final notification = {
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'time': DateTime.now().toIso8601String(),
      'type': message.data['type'] ?? 'general',
      'orderId': message.data['order_id'],
      'orderStatus': message.data['order_status'],
      'isRead': false,
    };

    notifications.insert(0, jsonEncode(notification));
    await prefs.setStringList(_notificationsListKey, notifications);
    final updatedCount = unreadCount + 1;
    await prefs.setInt(_unreadCountKey, updatedCount);
    _unreadCountController.add(updatedCount);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    if (enabled) {
      await _requestPermission();
      _startForegroundListener();
    } else {
      await _stopForegroundListener();
    }
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_notificationsListKey) ?? [];
    return rawList.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }

  Future<int> getUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_unreadCountKey) ?? 0;
  }

  Stream<int> get unreadCountStream => _unreadCountController.stream;

  Future<void> refreshUnreadCount() async {
    final count = await getUnreadCount();
    _unreadCountController.add(count);
  }

  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList(_notificationsListKey) ?? [];

    final updated = notifications.map((item) {
      final parsed = jsonDecode(item);
      parsed['isRead'] = true;
      return jsonEncode(parsed);
    }).toList();

    await prefs.setStringList(_notificationsListKey, updated);
    await prefs.setInt(_unreadCountKey, 0);
    _unreadCountController.add(0);
  }

  // 🆕 تتبع تغييرات الطلبات يدويًا
  Future<void> checkOrderStatusUpdates({
    required String userEmail,
    required String langCode,
  }) async {
    if (!await getNotificationsEnabled()) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final orders = await _apiService.getOrders(userEmail: userEmail);
    final storedStatuses = prefs.getString('order_statuses') ?? '{}';
    final Map<String, String> oldStatuses = Map<String, String>.from(json.decode(storedStatuses));
    final notifications = prefs.getStringList(_notificationsListKey) ?? [];
    int unreadCount = prefs.getInt(_unreadCountKey) ?? 0;

    for (final order in orders) {
      final orderId = order.id.toString();
      final currentStatus = order.status;
      final previousStatus = oldStatuses[orderId];

      if (previousStatus != null && previousStatus != currentStatus) {
        final previousText = _translateStatus(previousStatus, langCode);
        final currentText = _translateStatus(currentStatus, langCode);

        final title = langCode == 'ar' ? 'تحديث حالة الطلب' : 'Order Status Update';
        final body = langCode == 'ar'
            ? 'تم تغيير حالة طلبك رقم #$orderId من "$previousText" إلى "$currentText"'
            : 'Your order #$orderId status changed from "$previousText" to "$currentText"';

        await _showNotification(title, body);

        final notification = {
          'title': title,
          'body': body,
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

    await prefs.setStringList(_notificationsListKey, notifications);
    await prefs.setInt(_unreadCountKey, unreadCount);
    await prefs.setString('order_statuses', json.encode(oldStatuses));
    _unreadCountController.add(unreadCount);
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

    return (langCode == 'ar' ? ar : en)[status.toLowerCase()] ?? status;
  }
}
