import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  bool _isDrawerOpen = false; // يتم استخدامه لتتبع حالة الدرج

  final List<Widget> _screens = const [
    HomeScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      // تأثير اهتزاز خفيف عند التنقل
      HapticFeedback.lightImpact();

      setState(() => _selectedIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
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
        extendBody: true, // لجعل الـ BottomNavigationBar يطفو فوق المحتوى
        extendBodyBehindAppBar: true, // لجعل الـ AppBar شفافًا أو عائمًا فوق المحتوى
        drawer: _buildEnhancedDrawer(context, languageCode),
        onDrawerChanged: (isOpened) {
          setState(() => _isDrawerOpen = isOpened);
          if (isOpened) {
            HapticFeedback.mediumImpact(); // اهتزاز عند فتح الدرج
          }
        },
        body: Stack(
          children: [
            // خلفية متدرجة للشاشة
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[50]!, // لون أفتح في الأعلى
                    Colors.white, // لون أغمق أو أبيض في الأسفل
                  ],
                ),
              ),
            ),
            // محتوى الشاشات
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _selectedIndex = index);
              },
              children: _screens,
            ),
          ],
        ),
        bottomNavigationBar: _buildModernBottomNavigationBar(navLabels),
        // تم إزالة FloatingActionButton (السهم للأعلى)
      ),
    );
  }

  // تم تحسين تصميم الدرج الجانبي (Drawer)
  Widget _buildEnhancedDrawer(BuildContext context, String languageCode) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isAr = languageCode == 'ar';
    final isLoggedIn = userProvider.isLoggedIn;

    return Drawer(
      backgroundColor: Colors.transparent, // لجعل الخلفية شفافة لرؤية الظل والتدرج
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A2543), // لون أزرق داكن
              const Color(0xFF1A2543).withOpacity(0.95), // تدرج خفيف
              const Color(0xFF2A3553), // لون أزرق داكن أفتح قليلاً
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(5, 0), // ظل على اليمين
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              // هيدر محسن مع تأثيرات بصرية
              _buildEnhancedDrawerHeader(context, isAr, isLoggedIn, userProvider),
              // قائمة العناصر مع تحسينات
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildAnimatedDrawerItem(
                      Icons.home_filled,
                      isAr ? "الرئيسية" : "Home",
                          () => _navigateFromDrawer(context, '/main'),
                      delay: 0, // لا يوجد تأخير لأول عنصر
                    ),
                    _buildAnimatedDrawerItem(
                      Icons.dashboard_customize_rounded,
                      isAr ? "التصنيفات" : "Categories",
                          () => _navigateFromDrawer(context, '/categories'),
                      delay: 100,
                    ),
                    _buildAnimatedDrawerItem(
                      Icons.shopping_bag_rounded,
                      isAr ? "السلة" : "Cart",
                          () => _navigateFromDrawer(context, '/cart'),
                      delay: 200,
                    ),
                    _buildAnimatedDrawerItem(
                      Icons.receipt_long_rounded,
                      isAr ? "طلباتي" : "Orders",
                          () => _navigateFromDrawer(context, isLoggedIn ? '/orders' : '/login'),
                      delay: 300,
                    ),
                    _buildAnimatedDrawerItem(
                      Icons.settings_rounded,
                      isAr ? "الإعدادات / Settings" : "الإعدادات / Settings",
                          () => _navigateFromDrawer(context, '/settings'),
                      delay: 400,
                    ),
                    // خط فاصل أنيق
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    _buildAnimatedDrawerItem(
                      Icons.support_agent_rounded,
                      isAr ? "تواصل معنا" : "Contact Us",
                          () => _showContactDialog(context, isAr),
                      delay: 500,
                    ),
                    _buildAnimatedDrawerItem(
                      Icons.lock_person_rounded,
                      isAr ? "سياسة الخصوصية" : "Privacy Policy",
                          () => _navigateFromDrawer(context, '/privacy'),
                      delay: 600,
                    ),
                    _buildAnimatedDrawerItem(
                      Icons.rule_folder_rounded,
                      isAr ? "شروط الاستخدام" : "Terms of Use",
                          () => _navigateFromDrawer(context, '/terms'),
                      delay: 700,
                    ),
                    _buildAnimatedDrawerItem(
                      Icons.info_rounded,
                      isAr ? "نبذة عنا" : "About Us",
                          () => _navigateFromDrawer(context, '/about'),
                      delay: 800,
                    ),
                    _buildAnimatedDrawerItem(
                      Icons.help_outline_rounded,
                      isAr ? "الأسئلة الشائعة" : "FAQs",
                          () => _navigateFromDrawer(context, '/faq'),
                      delay: 900,
                      isLast: true, // للإشارة إلى العنصر الأخير لتعديل الهامش
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // هيدر الدرج الجانبي المحسن
  Widget _buildEnhancedDrawerHeader(BuildContext context, bool isAr, bool isLoggedIn, UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact(); // اهتزاز خفيف عند النقر
          Navigator.pop(context); // إغلاق الدرج
          Navigator.pushNamed(context, '/profile'); // الانتقال لصفحة البروفايل
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1), // خلفية شفافة
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)), // حدود شفافة
          ),
          child: Row(
            children: [
              // صورة المستخدم مع تأثير متوهج
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6FE0DA).withOpacity(0.5), // لون توهج
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: isLoggedIn
                      ? Text(
                    userProvider.user?.username?.isNotEmpty == true
                        ? userProvider.user!.username![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2543), // لون النص
                    ),
                  )
                      : const Icon(Icons.person, size: 32, color: Color(0xFF6FE0DA)),
                ),
              ),
              const SizedBox(width: 16),
              // معلومات المستخدم
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // أيقونة للإشارة لإمكانية النقر
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // عنصر في قائمة الدرج مع تأثيرات حركية
  Widget _buildAnimatedDrawerItem(
      IconData icon,
      String title,
      VoidCallback onTap, {
        required int delay,
        bool isLast = false,
      }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + delay), // تأخير لكل عنصر
      curve: Curves.easeOutBack, // تأثير حركي مرن
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        // **التحسين هنا:**
        // التأكد من أن القيمة ضمن النطاق [0.0, 1.0] لتجنب أخطاء الشفافية.
        final clampedValue = value.clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset((1 - clampedValue) * 50, 0), // حركة من اليسار
          child: Opacity(
            opacity: clampedValue, // استخدام القيمة المقيدة هنا للشفافية
            child: Container(
              margin: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: isLast ? 20 : 4, // هامش سفلي أكبر للعنصر الأخير
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.05), // خلفية خفيفة عند النقر
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6FE0DA).withOpacity(0.2), // خلفية الأيقونة
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            color: const Color(0xFF6FE0DA),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // وظيفة التنقل من الدرج
  void _navigateFromDrawer(BuildContext context, String route) {
    Navigator.pop(context); // إغلاق الدرج أولاً
    Future.delayed(const Duration(milliseconds: 250), () {
      // تأخير بسيط قبل الانتقال لإعطاء وقت لإغلاق الدرج
      if (route == '/main') {
        // إذا كان الانتقال للصفحة الرئيسية، استخدم pushReplacementNamed لتجنب تكديس الشاشات
        Navigator.pushReplacementNamed(context, route);
      } else {
        Navigator.pushNamed(context, route);
      }
    });
  }

  // نافذة الاتصال المنبثقة
  void _showContactDialog(BuildContext context, bool isAr) {
    Navigator.pop(context); // إغلاق الدرج أولاً
    Future.delayed(const Duration(milliseconds: 250), () {
      showDialog(
        context: context,
        barrierDismissible: true, // يمكن إغلاقها بالنقر خارجها
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent, // لجعل الخلفية شفافة
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6FE0DA).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    size: 32,
                    color: Color(0xFF6FE0DA),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAr ? "اختر رقم للتواصل" : "Choose a number",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2543),
                  ),
                ),
                const SizedBox(height: 24),
                _buildContactOption("+97450105685", "50105685"),
                const SizedBox(height: 12),
                _buildContactOption("+97477704313", "77704313"),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isAr ? "إغلاق" : "Close",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // خيار الاتصال (مثل رقم الواتساب)
  Widget _buildContactOption(String phoneNumber, String displayNumber) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _openWhatsApp(phoneNumber);
          Navigator.pop(context); // إغلاق نافذة الحوار بعد النقر
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.phone,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  displayNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2543),
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // فتح رابط واتساب
  void _openWhatsApp(String phoneNumber) async {
    final url = "https://wa.me/$phoneNumber";
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // التعامل مع الخطأ بشكل صامت أو إظهار رسالة
      debugPrint('Error opening WhatsApp: $e');
    }
  }

  // شريط التنقل السفلي الحديث
  Widget _buildModernBottomNavigationBar(List<String> navLabels) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // لون خلفية شريط التنقل
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1), // حدود خفيفة
              width: 1,
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.transparent, // لجعل الخلفية شفافة لتظهر خلفية الحاوية
            elevation: 0, // إزالة الظل الافتراضي
            selectedItemColor: const Color(0xFF6FE0DA), // لون الأيقونة والنص المختار
            unselectedItemColor: Colors.grey[600], // لون الأيقونة والنص غير المختار
            type: BottomNavigationBarType.fixed, // لجعل كل الأيقونات بنفس الحجم
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            items: [
              BottomNavigationBarItem(
                icon: _buildEnhancedNavIcon(Icons.home_filled, 0),
                label: navLabels[0],
              ),
              BottomNavigationBarItem(
                icon: Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    int count = cartProvider.items.fold(0, (sum, item) => sum + item.quantity);
                    return Stack(
                      clipBehavior: Clip.none, // للسماح للشارة بالظهور خارج الحدود
                      children: [
                        _buildEnhancedNavIcon(Icons.shopping_bag_rounded, 1),
                        if (count > 0) // إظهار الشارة فقط إذا كان هناك عناصر في السلة
                          Positioned(
                            right: -8,
                            top: -8,
                            child: AnimatedScale(
                              scale: count > 0 ? 1.0 : 0.0, // تأثير ظهور/اختفاء الشارة
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient( // تدرج لوني للشارة
                                    colors: [Colors.red, Colors.redAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  count > 99 ? '99+' : '$count', // عرض 99+ إذا كان العدد كبيرًا
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                icon: _buildEnhancedNavIcon(Icons.account_circle_rounded, 2),
                label: navLabels[2],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // أيقونة شريط التنقل المحسنة
  Widget _buildEnhancedNavIcon(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      padding: EdgeInsets.all(isSelected ? 8 : 6), // حجم أكبر عند الاختيار
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF6FE0DA).withOpacity(0.15) // خلفية خفيفة عند الاختيار
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedScale(
        scale: isSelected ? 1.1 : 1.0, // تكبير الأيقونة عند الاختيار
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
        child: Icon(
          icon,
          size: 28,
          color: isSelected
              ? const Color(0xFF6FE0DA) // لون الأيقونة المختار
              : Colors.grey[600], // لون الأيقونة غير المختار
        ),
      ),
    );
  }
}