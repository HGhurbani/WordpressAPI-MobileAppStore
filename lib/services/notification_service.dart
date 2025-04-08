import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static const String NOTIFICATIONS_ENABLED_KEY = 'notifications_enabled';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final bool notificationsEnabled = prefs.getBool(NOTIFICATIONS_ENABLED_KEY) ?? false;

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

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message.notification?.title ?? '', message.notification?.body ?? '');
      _saveNotification(message);
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
      print('FCM Token: $token');
    }
  }

  Future<void> _showNotification(String title, String body) async {
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

  Future<void> _saveNotification(RemoteMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('notifications') ?? [];

    final newNotification = {
      'title': message.notification?.title,
      'body': message.notification?.body,
      'time': DateTime.now().toIso8601String(),
    };

    notifications.insert(0, jsonEncode(newNotification));
    await prefs.setStringList('notifications', notifications);
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
    return prefs.getBool(NOTIFICATIONS_ENABLED_KEY) ?? false;
  }
}