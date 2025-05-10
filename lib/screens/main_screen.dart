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

    final navLabels = languageCode == "ar"
        ? ['الرئيسية', 'السلة', 'حسابي']
        : ['Home', 'Cart', 'Profile'];

    return Directionality(
      textDirection: languageCode == "ar" ? TextDirection.rtl : TextDirection.ltr,
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
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final isAr = languageCode == 'ar';
    final isLoggedIn = userProvider.isLoggedIn;

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xff180cb5)),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context); // يغلق القائمة الجانبية
                Navigator.pushNamed(context, '/profile'); // يذهب إلى حسابي
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 32, color: Color(0xff180cb5)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isLoggedIn
                        ? (userProvider.user?.username ?? 'User')
                        : (isAr ? "مرحباً بك" : "Welcome"),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoggedIn
                        ? (userProvider.user?.email ?? '')
                        : (isAr ? "يرجى تسجيل الدخول" : "Please login"),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.home),
            title: Text(isAr ? "الرئيسية" : "Home"),
            onTap: () => Navigator.pushReplacementNamed(context, '/main'),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: Text(isAr ? "التصنيفات" : "Categories"),
            onTap: () => Navigator.pushNamed(context, '/categories'),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: Text(isAr ? "السلة" : "Cart"),
            onTap: () => Navigator.pushNamed(context, '/cart'),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: Text(isAr ? "طلباتي" : "Orders"),
            onTap: () {
              if (isLoggedIn) {
                Navigator.pushNamed(context, '/orders');
              } else {
                Navigator.pushNamed(context, '/login');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(isAr ? "الإعدادات / Settings" : "الإعدادات / Settings"),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          const Divider(),

          if (!isLoggedIn)
            ListTile(
              leading: const Icon(Icons.phone_in_talk),
              title: Text(isAr ? "تواصل معنا" : "Contact Us"),
              onTap: () {
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
              },
            ),

          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(isAr ? "سياسة الخصوصية" : "Privacy Policy"),
            onTap: () => Navigator.pushNamed(context, '/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.rule),
            title: Text(isAr ? "شروط الاستخدام" : "Terms of Use"),
            onTap: () => Navigator.pushNamed(context, '/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(isAr ? "نبذة عنا" : "About Us"),
            onTap: () => Navigator.pushNamed(context, '/about'),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(isAr ? "الأسئلة الشائعة" : "FAQs"),
            onTap: () => Navigator.pushNamed(context, '/faq'),
          ),
        ],
      ),
    );
  }

  /// فتح واتساب
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
                  int count = cartProvider.items.fold(0, (prev, item) => prev + item.quantity);
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
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
    );
  }
}
