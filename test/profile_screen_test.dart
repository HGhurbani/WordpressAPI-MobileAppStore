import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creditphoneqa/models/user.dart';
import 'package:creditphoneqa/providers/locale_provider.dart';
import 'package:creditphoneqa/providers/user_provider.dart';
import 'package:creditphoneqa/screens/profile_screen.dart';
import 'package:creditphoneqa/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('User.fromJson prefers trimmed first name and persists via UserProvider', () async {
    SharedPreferences.setMockInitialValues({});

    final jwtResponse = {
      'token': 'jwt-token',
      'first_name': '  Preferred  ',
      'user_display_name': 'Display Name',
      'username': 'display.name',
      'email': 'user@example.com',
    };

    final user = User.fromJson(jwtResponse);
    expect(user.username, 'Preferred');

    final provider = UserProvider();
    provider.setUser(user);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final restoredProvider = UserProvider();
    await restoredProvider.loadUserFromPrefs();

    expect(restoredProvider.user?.username, 'Preferred');
  });

  testWidgets('ProfileScreen shows fallback initial for empty username', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final userProvider = UserProvider();
    final localeProvider = LocaleProvider();

    await localeProvider.setLocale(const Locale('en'));

    userProvider.setUser(
      User(
        id: 1,
        token: 'token',
        username: '',
        email: 'tester@example.com',
        phone: '',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('T'), findsOneWidget);
    expect(find.text('Hello, tester@example.com!'), findsOneWidget);
  });

  testWidgets('SettingsScreen pre-fills phone from nested billing sections',
      (WidgetTester tester) async {
    Future<void> verifyScenario({
      required Map<String, dynamic> jwtResponse,
      required String expectedPhone,
    }) async {
      SharedPreferences.setMockInitialValues({});

      final localeProvider = LocaleProvider();
      await tester.runAsync(() async {
        await localeProvider.setLocale(const Locale('en'));
      });

      final user = User.fromJson(jwtResponse);
      expect(user.phone, expectedPhone);

      final initialProvider = UserProvider();
      await tester.runAsync(() async {
        initialProvider.setUser(user);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });

      final restoredProvider = UserProvider();
      await tester.runAsync(() async {
        await restoredProvider.loadUserFromPrefs();
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });

      expect(restoredProvider.user?.phone, expectedPhone);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: restoredProvider),
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final phoneFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.hintText == 'Phone Number',
      );

      expect(phoneFieldFinder, findsOneWidget);
      final phoneField = tester.widget<TextField>(phoneFieldFinder);
      expect(phoneField.controller?.text, expectedPhone);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }

    await verifyScenario(
      jwtResponse: {
        'token': 'jwt-token',
        'username': 'billing.user',
        'email': 'user@example.com',
        'data': {
          'billing': {'phone': '50012345'},
        },
      },
      expectedPhone: '50012345',
    );

    await verifyScenario(
      jwtResponse: {
        'token': 'jwt-token',
        'username': 'billing.user',
        'email': 'user@example.com',
        'customer': {
          'billing': {'phone': '70098765'},
        },
      },
      expectedPhone: '70098765',
    );
  });
}
