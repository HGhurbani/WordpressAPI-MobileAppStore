
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static const String NOTIFICATIONS_ENABLED_KEY = 'notifications_enabled';

  Future<void> initialize() async {
    // Check if notifications are enabled
    final prefs = await SharedPreferences.getInstance();
    final bool notificationsEnabled = prefs.getBool(NOTIFICATIONS_ENABLED_KEY) ?? true;

    if (notificationsEnabled) {
      await _requestPermission();
    }
    
    // Initialize local notifications
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    
    await _localNotifications.initialize(initializationSettings);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message.notification?.title ?? '', message.notification?.body ?? '');
    });
  }

  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();
      print('FCM Token: $token'); // Store this token in your backend
    }
  }

  Future<void> _showNotification(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final bool notificationsEnabled = prefs.getBool(NOTIFICATIONS_ENABLED_KEY) ?? true;
    
    if (!notificationsEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      'order_status_channel',
      'Order Status Updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NOTIFICATIONS_ENABLED_KEY, enabled);
    
    if (enabled) {
      await _requestPermission();
    }
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(NOTIFICATIONS_ENABLED_KEY) ?? true;
  }
}
