import 'package:creditphoneqa/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import '../providers/locale_provider.dart';
import '../providers/cart_provider.dart';
import '../services/notification_service.dart'; // Import the NotificationService

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final languageCode = localeProvider.locale.languageCode;

    final navLabels = languageCode == "ar"
        ? ['الرئيسية', 'السلة', 'حسابي']
        : ['Home', 'Cart', 'Profile'];

    return Directionality(
      textDirection:
          languageCode == "ar" ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBody: true, 
        
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: const Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: Text(
                  languageCode == "ar" ? 'التصنيفات' : 'Categories',
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/categories');
                },
              ),
              // Add more drawer items here
            ],
          ),
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.transparent, 
              elevation: 0,
              selectedItemColor: const Color(0xff1d0fe3),
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: AnimatedScale(
                    scale: _selectedIndex == 0 ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.home_rounded, size: 28),
                  ),
                  label: navLabels[0],
                ),
                BottomNavigationBarItem(
                  icon: Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      int count = cartProvider.items
                          .fold(0, (prev, item) => prev + item.quantity);
                      return AnimatedScale(
                        scale: _selectedIndex == 1 ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.shopping_cart_rounded, size: 28),
                            if (count > 0)
                              Positioned(
                                right: -6,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  label: navLabels[1],
                ),
                BottomNavigationBarItem(
                  icon: AnimatedScale(
                    scale: _selectedIndex == 2 ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.person_rounded, size: 28),
                  ),
                  label: navLabels[2],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}