import 'package:creditphoneqa/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:creditphoneqa/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'routes.dart';
import 'providers/cart_provider.dart';
import 'providers/user_provider.dart';
import 'providers/locale_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme.dart';

Future<void> _loadEnvironment() async {
  if (kReleaseMode || kIsWeb) {
    return;
  }
  try {
    await dotenv.load(fileName: '.env');
  } on FlutterError catch (error) {
    debugPrint('dotenv: ${error.message}');
  } catch (error, stackTrace) {
    debugPrint('Failed to load .env file: $error');
    debugPrint('$stackTrace');
  }
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    if (kIsWeb) {
      // تهيئة مبسطة للويب
      await _initializeWebApp();
    } else {
      // التهيئة الكاملة للأندرويد/iOS
      await _initializeMobileApp();
    }
  } catch (e) {
    debugPrint('Error initializing app: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

Future<void> _initializeWebApp() async {
  // تجاهل جميع التهيئات للويب - استخدام dart-define بدلاً منها
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
      ],
      child: MyApp(initialRoute: '/'), // استخدام route ثابت
    ),
  );
}

Future<void> _initializeMobileApp() async {
  await _loadEnvironment();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.initialize();

  final userProvider = UserProvider();
  await userProvider.loadUserFromPrefs();

  final prefs = await SharedPreferences.getInstance();
  final lastRoute = prefs.getString('last_route') ?? '/';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
      ],
      child: MyApp(initialRoute: lastRoute),
    ),
  );
}

/// Route Observer لحفظ آخر صفحة تمت زيارتها
class RouteObserverService extends RouteObserver<PageRoute<dynamic>> {
  void _saveLastRoute(Route<dynamic>? route) {
    if (route is PageRoute) {
      final routeName = route.settings.name;
      if (routeName != null) {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('last_route', routeName);
        });
      }
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _saveLastRoute(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _saveLastRoute(previousRoute);
    super.didPop(route, previousRoute);
  }
}

final RouteObserverService routeObserver = RouteObserverService();

// إضافة شاشة خطأ
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({Key? key, required this.error}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0175C2),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'حدث خطأ في تحميل التطبيق',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // إعادة تحميل الصفحة
                    if (kIsWeb) {
                      // إعادة تحميل الصفحة في المتصفح
                      // يمكن استخدام JavaScript هنا
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0175C2),
                  ),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationService _notificationService = NotificationService.instance;

  @override
  void initState() {
    super.initState();

    // تجاهل Firebase للويب
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
        final user = userProvider.user;

        if (user != null && user.email != null) {
          await _notificationService.checkOrderStatusUpdates(
            userEmail: user.email!,
            langCode: localeProvider.locale.languageCode,
          );
        }
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
        final user = userProvider.user;

        if (user != null && user.email != null) {
          await _notificationService.checkOrderStatusUpdates(
            userEmail: user.email!,
            langCode: localeProvider.locale.languageCode,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          title: 'Credit Phone Qatar',
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.lightTheme,
          initialRoute: widget.initialRoute,
          navigatorObservers: kIsWeb ? [] : [routeObserver], // تجاهل routeObserver للويب
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
