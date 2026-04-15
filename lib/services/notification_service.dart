import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import '../services/api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  await NotificationService.instance.handleBackgroundMessage(message);
}

class NotificationService {
  NotificationService._internal({
    FirebaseMessaging? firebaseMessaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    ApiService? apiService,
    Future<void> Function()? deleteTokenOverride,
  })  : _fcm = firebaseMessaging ?? FirebaseMessaging.instance,
        _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin(),
        _apiService = apiService ?? ApiService(),
        _deleteTokenOverride = deleteTokenOverride;

  static NotificationService? _instance;

  static NotificationService get instance =>
      _instance ??= NotificationService._internal();

  factory NotificationService({
    FirebaseMessaging? firebaseMessaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    ApiService? apiService,
    Future<void> Function()? deleteTokenOverride,
  }) {
    if (_instance == null) {
      _instance = NotificationService._internal(
        firebaseMessaging: firebaseMessaging,
        localNotifications: localNotifications,
        apiService: apiService,
        deleteTokenOverride: deleteTokenOverride,
      );
    } else if (firebaseMessaging != null ||
        localNotifications != null ||
        apiService != null ||
        deleteTokenOverride != null) {
      print(
        'NotificationService is already initialized; duplicate configuration was ignored.',
      );
    }
    return instance;
  }

  /// Resets the singleton instance. Intended for testing to inject mocks.
  static void resetForTesting({
    FirebaseMessaging? firebaseMessaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    ApiService? apiService,
    Future<void> Function()? deleteTokenOverride,
  }) {
    _instance = NotificationService._internal(
      firebaseMessaging: firebaseMessaging,
      localNotifications: localNotifications,
      apiService: apiService,
      deleteTokenOverride: deleteTokenOverride,
    );
  }

  final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final ApiService _apiService;
  final Future<void> Function()? _deleteTokenOverride;
  static final StreamController<int> _unreadCountController = StreamController<int>.broadcast();
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationsListKey = 'notifications';
  static const String _unreadCountKey = 'unread_notifications';
  static const String _notificationsTruncatedKey = 'notifications_truncated';
  static const int _maxStoredNotifications = 50;
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
      _notificationsTruncatedKey,
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

    // Background handler is registered once in main.dart (must be top-level).

    if (_tokenRefreshSubscription == null) {
      _tokenRefreshSubscription =
          _fcm.onTokenRefresh.listen((token) => unawaited(_handleTokenRefresh(token)));
      print('NotificationService: Token refresh listener registered.');
    } else {
      print('NotificationService: Token refresh listener already registered; skipping.');
    }

    if (notificationsEnabled) {
      _startForegroundListener();
    } else {
      await _stopForegroundListener();
    }
  }

  void _startForegroundListener() {
    if (_foregroundSubscription == null) {
      _foregroundSubscription = FirebaseMessaging.onMessage
          .listen((RemoteMessage message) => _handleForegroundMessage(message));
      print('NotificationService: Foreground listener registered.');
    } else {
      print('NotificationService: Foreground listener already active; skipping.');
    }
  }

  Future<void> _stopForegroundListener() async {
    if (_foregroundSubscription != null) {
      await _foregroundSubscription?.cancel();
      _foregroundSubscription = null;
      print('NotificationService: Foreground listener cancelled.');
    }
  }

  Future<void> logoutCleanup({String? email}) async {
    await _stopForegroundListener();
    if (_tokenRefreshSubscription != null) {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
      print('NotificationService: Token refresh listener cancelled.');
    }
    await clearStoredData();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');

    try {
      if (_deleteTokenOverride != null) {
        await _deleteTokenOverride.call();
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

  /// On iOS, FCM needs the APNs device token before [FirebaseMessaging.getToken] works.
  static const Duration _apnsPollDelay = Duration(milliseconds: 400);
  static const int _apnsMaxAttempts = 25;

  Future<void> _waitForApnsTokenIfNeeded() async {
    if (kIsWeb) {
      return;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
      default:
        return;
    }
    for (var i = 0; i < _apnsMaxAttempts; i++) {
      final apns = await _fcm.getAPNSToken();
      if (apns != null) {
        return;
      }
      await Future<void>.delayed(_apnsPollDelay);
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(alert: true, badge: true, sound: true);
    final ok = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!ok) {
      return;
    }
    await _waitForApnsTokenIfNeeded();
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _handleTokenRefresh(token);
      }
    } catch (e, st) {
      // iOS may still race; [onTokenRefresh] will deliver the FCM token when ready.
      print('NotificationService: getToken failed (will retry on refresh if needed): $e');
      print('$st');
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
    final bool wasTruncated = prefs.getBool(_notificationsTruncatedKey) ?? false;
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

    bool isTruncated = wasTruncated;
    if (notifications.length > _maxStoredNotifications) {
      notifications.removeRange(
        _maxStoredNotifications,
        notifications.length,
      );
      isTruncated = true;
    }

    await prefs.setStringList(_notificationsListKey, notifications);
    final updatedCount = unreadCount + 1;
    await prefs.setInt(_unreadCountKey, updatedCount);
    await prefs.setBool(_notificationsTruncatedKey, isTruncated);
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
    bool wasTruncated = prefs.getBool(_notificationsTruncatedKey) ?? false;
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

    if (notifications.length > _maxStoredNotifications) {
      notifications.removeRange(
        _maxStoredNotifications,
        notifications.length,
      );
      wasTruncated = true;
    }

    await prefs.setStringList(_notificationsListKey, notifications);
    await prefs.setInt(_unreadCountKey, unreadCount);
    await prefs.setString('order_statuses', json.encode(oldStatuses));
    await prefs.setBool(_notificationsTruncatedKey, wasTruncated);
    _unreadCountController.add(unreadCount);
  }

  String _translateStatus(String status, String langCode) {
    final ar = {
      'pending': 'قيد المعالجة',
      'in-installments': 'جاري التقسيط',
      'processing': 'قيد التنفيذ',
      'completed': 'مكتمل',
      'cancelled': 'ملغي',
      'on-hold': 'قيد الانتظار',
      'refunded': 'مسترد',
      'failed': 'فشل',
    };

    final en = {
      'pending': 'Pending',
      'in-installments': 'In Installments',
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
