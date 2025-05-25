import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/locale_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

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
    final isArabic = languageCode == 'ar';

    final navLabels = isArabic
        ? ['الرئيسية', 'السلة', 'حسابي']
        : ['Home', 'Cart', 'Profile'];

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBody: true,
        drawer: _buildDrawer(context, languageCode),
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomNavigationBar(navLabels),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String languageCode) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isAr = languageCode == 'ar';
    final isLoggedIn = userProvider.isLoggedIn;

    return Drawer(
      backgroundColor: Colors.white,
      elevation: 8,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1A2543)),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 32, color: Color(0xFF6FE0DA)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isLoggedIn
                        ? (userProvider.user?.username ?? 'User')
                        : (isAr ? "مرحباً بك" : "Welcome"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoggedIn
                        ? (userProvider.user?.email ?? '')
                        : (isAr ? "يرجى تسجيل الدخول" : "Please login"),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _drawerItem(Icons.home_filled, isAr ? "الرئيسية" : "Home", () {
            Navigator.pushReplacementNamed(context, '/main');
          }),
          _drawerItem(Icons.dashboard_customize_rounded, isAr ? "التصنيفات" : "Categories", () {
            Navigator.pushNamed(context, '/categories');
          }),
          _drawerItem(Icons.shopping_bag_rounded, isAr ? "السلة" : "Cart", () {
            Navigator.pushNamed(context, '/cart');
          }),
          _drawerItem(Icons.receipt_long_rounded, isAr ? "طلباتي" : "Orders", () {
            Navigator.pushNamed(context, isLoggedIn ? '/orders' : '/login');
          }),
          _drawerItem(Icons.settings_rounded, isAr ? "الإعدادات / Settings" : "الإعدادات / Settings", () {
            Navigator.pushNamed(context, '/settings');
          }),
          const Divider(),
            _drawerItem(Icons.support_agent_rounded, isAr ? "تواصل معنا" : "Contact Us", () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: Text(isAr ? "اختر رقم للتواصل" : "Choose a number"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.circle, color: Colors.green),
                        title: const Text("50105685"),
                        onTap: () => _openWhatsApp("+97450105685"),
                      ),
                      ListTile(
                        leading: const Icon(Icons.circle, color: Colors.green),
                        title: const Text("77704313"),
                        onTap: () => _openWhatsApp("+97477704313"),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(isAr ? "إغلاق" : "Close"),
                    )
                  ],
                ),
              );
            }),
          _drawerItem(Icons.lock_person_rounded, isAr ? "سياسة الخصوصية" : "Privacy Policy", () {
            Navigator.pushNamed(context, '/privacy');
          }),
          _drawerItem(Icons.rule_folder_rounded, isAr ? "شروط الاستخدام" : "Terms of Use", () {
            Navigator.pushNamed(context, '/terms');
          }),
          _drawerItem(Icons.info_rounded, isAr ? "نبذة عنا" : "About Us", () {
            Navigator.pushNamed(context, '/about');
          }),
          _drawerItem(Icons.question_answer_rounded, isAr ? "الأسئلة الشائعة" : "FAQs", () {
            Navigator.pushNamed(context, '/faq');
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A2543)),
      title: Text(
        title,
        style: const TextStyle(color: Color(0xFF1A2543), fontSize: 15),
      ),
      onTap: onTap,
    );
  }

  void _openWhatsApp(String phoneNumber) async {
    final url = "https://wa.me/$phoneNumber";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildBottomNavigationBar(List<String> navLabels) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF6FE0DA),
          unselectedItemColor: Colors.grey[600],
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.home_filled, 0),
              label: navLabels[0],
            ),
            BottomNavigationBarItem(
              icon: Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  int count = cartProvider.items.fold(0, (sum, item) => sum + item.quantity);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildAnimatedIcon(Icons.shopping_bag_rounded, 1),
                      if (count > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              label: navLabels[1],
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.account_circle_rounded, 2),
              label: navLabels[2],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(IconData icon, int index) {
    return AnimatedScale(
      scale: _selectedIndex == index ? 1.2 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Icon(icon, size: 28),
    );
  }
}
