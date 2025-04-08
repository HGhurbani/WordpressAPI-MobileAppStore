import 'package:creditphoneqa/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import 'providers/cart_provider.dart';
import 'providers/user_provider.dart';
import 'providers/locale_provider.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase

/// تعريف اللون الأساسي مع درجاته
const MaterialColor customPrimarySwatch = MaterialColor(
  0xFF1D0FE3,
  <int, Color>{
    50: Color(0xFFEAE6FE),
    100: Color(0xFFCBC2FE),
    200: Color(0xFFA898FD),
    300: Color(0xFF8570FD),
    400: Color(0xFF6A53FD),
    500: Color(0xFF1D0FE3),
    600: Color(0xFF190DCB),
    700: Color(0xFF150BB3),
    800: Color(0xFF11099B),
    900: Color(0xFF0A0676),
  },
);

class NotificationService {
  Future<void> initialize() async {
    // Placeholder:  Replace with actual Firebase Messaging initialization
    print('Notification service initialized (placeholder)');
  }

  // Add methods to send notifications here.  This requires FCM integration.
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp();

  final notificationService = NotificationService();
  await notificationService.initialize();

  final userProvider = UserProvider();
  await userProvider.loadUserFromPrefs(); // تحميل المستخدم من SharedPreferences

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          title: 'Credit Phone Qatar',
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('ar', ''),
            Locale('en', ''),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            fontFamily: 'Tajawal',
            scaffoldBackgroundColor: Colors.white,
            primarySwatch: customPrimarySwatch,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1d0fe3),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xff1d0fe3),
            ),
          ),
          initialRoute: '/',
          routes: AppRoutes.routes,
        );
      },
    );
  }
}