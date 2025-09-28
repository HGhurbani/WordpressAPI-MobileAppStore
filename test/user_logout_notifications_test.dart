import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creditphoneqa/models/user.dart';
import 'package:creditphoneqa/providers/user_provider.dart';
import 'package:creditphoneqa/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logout clears notification data for next user session', () async {
    SharedPreferences.setMockInitialValues({
      'notifications': <String>['{"title":"old"}'],
      'unread_notifications': 3,
      'order_statuses': '{"1":"pending"}',
      'notifications_enabled': false,
      'fcm_token': 'old-token',
      'user_token': 'token-a',
      'user_name': 'user-a',
      'user_email': 'a@example.com',
      'user_phone': '123456',
    });

    final provider = UserProvider();
    provider.setUser(
      User(
        id: 1,
        token: 'token-a',
        username: 'user-a',
        email: 'a@example.com',
        phone: '123456',
      ),
    );

    await provider.logout();

    final prefs = await SharedPreferences.getInstance();
    final notifications = await NotificationService().getAllNotifications();

    expect(provider.user, isNull);
    expect(notifications, isEmpty);
    expect(prefs.containsKey('notifications'), isFalse);
    expect(prefs.containsKey('unread_notifications'), isFalse);
    expect(prefs.containsKey('order_statuses'), isFalse);
    expect(prefs.containsKey('notifications_enabled'), isFalse);
    expect(prefs.containsKey('fcm_token'), isFalse);
  });
}
