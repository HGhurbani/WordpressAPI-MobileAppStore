import 'package:creditphoneqa/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart'; // تأكد من وجود هذا الملف
import 'screens/main_screen.dart';
import 'screens/home_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => SplashScreen(),
    '/login': (context) => LoginScreen(),
    '/register': (context) => RegisterScreen(),
    '/main': (context) => MainScreen(),
    '/home': (context) => HomeScreen(),
    '/product_list': (context) => ProductListScreen(),
    // لاحظ أن صفحة تفاصيل المنتج تحتاج إلى معلمة، فيُفضل تمريرها باستخدام Navigator مع arguments
    // '/product_detail': (context) => ProductDetailScreen(productId: 0),
    '/cart': (context) => CartScreen(),
    '/checkout': (context) => CheckoutScreen(),
    '/profile': (context) => ProfileScreen(),
    '/orders': (context) => OrdersScreen(),
    '/settings': (context) => SettingsScreen(),
    '/privacy': (context) =>  PrivacyPolicyScreen(),
    '/terms': (context) =>  TermsScreen(),
    '/notifications': (context) =>  NotificationsScreen(),

  };
}
