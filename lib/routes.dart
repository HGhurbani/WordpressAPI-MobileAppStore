import 'package:creditphoneqa/screens/categories_screen.dart';
import 'package:creditphoneqa/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'screens/about_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/installment_options_screen.dart';
import 'screens/installment_store_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart'; // تأكد من وجود هذا الملف
import 'screens/main_screen.dart';
import 'screens/home_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String main = '/main';
  static const String login = '/login';

  static const Set<String> _restorableRoutes = {
    main,
    '/home',
    '/cart',
    '/profile',
    '/orders',
    '/settings',
    '/privacy',
    '/terms',
    '/notifications',
    '/categories',
    '/about',
    '/faq',
    '/installment-options',
    '/installment-store',
  };

  static const Set<String> _authRequiredRoutes = {
    '/orders',
  };

  static bool canRestore(String? routeName) {
    return routeName != null && _restorableRoutes.contains(routeName);
  }

  static String resolveStartupRoute({
    required String? lastRoute,
    required bool isLoggedIn,
  }) {
    if (!canRestore(lastRoute)) {
      return main;
    }

    if (_authRequiredRoutes.contains(lastRoute) && !isLoggedIn) {
      return login;
    }

    return lastRoute!;
  }

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => SplashScreen(),
    login: (context) => LoginScreen(),
    '/register': (context) => RegisterScreen(),
    main: (context) => MainScreen(),
    '/home': (context) => HomeScreen(),
    '/product_list': (context) => ProductListScreen(),
    // لاحظ أن صفحة تفاصيل المنتج تحتاج إلى معلمة، فيُفضل تمريرها باستخدام Navigator مع arguments
    // '/product_detail': (context) => ProductDetailScreen(productId: 0),
    '/cart': (context) => CartScreen(),
    // '/checkout': (context) => CheckoutScreen(),
    '/profile': (context) => ProfileScreen(),
    '/orders': (context) => OrdersScreen(),
    '/settings': (context) => SettingsScreen(),
    '/privacy': (context) =>  PrivacyPolicyScreen(),
    '/terms': (context) =>  TermsScreen(),
    '/notifications': (context) =>  NotificationsScreen(),
    '/categories': (context) => const CategoriesScreen(),
    '/about': (context) => const AboutUsScreen(),
    '/faq': (context) => const FaqScreen(),
    '/installment-options': (context) => const InstallmentOptionsScreen(),
    '/installment-store': (context) => const InstallmentStoreScreen(),


  };
}
