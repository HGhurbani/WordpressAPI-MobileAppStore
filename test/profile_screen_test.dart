import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creditphoneqa/models/user.dart';
import 'package:creditphoneqa/providers/locale_provider.dart';
import 'package:creditphoneqa/providers/user_provider.dart';
import 'package:creditphoneqa/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
}
