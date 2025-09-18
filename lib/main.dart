import 'package:creditphoneqa/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'routes.dart';
import 'providers/cart_provider.dart';
import 'providers/user_provider.dart';
import 'providers/locale_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme.dart';

Future<void> _loadEnvironment() async {
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
  WidgetsFlutterBinding.ensureInitialized();
  await _loadEnvironment();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService().initialize();

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

class MyApp extends StatefulWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();

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
          theme: AppTheme.lightTheme,
          initialRoute: widget.initialRoute,
          navigatorObservers: [routeObserver],
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
