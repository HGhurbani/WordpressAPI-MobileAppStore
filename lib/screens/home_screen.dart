import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../providers/user_provider.dart';
import '../services/notification_service.dart';
import '../widgets/home_card_category.dart';
import '../services/api_service.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import 'categories_screen.dart';
import 'product_list_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final apiService = ApiService();
  late Future<List<Category>> _futureCategories;
  final ValueNotifier<int> _notificationCount = ValueNotifier<int>(0);
  final List<int> topRequestedProductIdsAr = [12226, 12261, 12245, 12762];
  final List<int> topRequestedProductIdsEn = [12902, 13310, 13325, 12835];

  late AnimationController _welcomeAnimationController;
  late Animation<double> _welcomeAnimation;
  late AnimationController _sectionsAnimationController;
  late Animation<double> _sectionsAnimation;

  bool _showWelcomeMessage = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _welcomeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _welcomeAnimation = CurvedAnimation(
      parent: _welcomeAnimationController,
      curve: Curves.easeOutBack,
    );

    _sectionsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _sectionsAnimation = CurvedAnimation(
      parent: _sectionsAnimationController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      _loadData(localeProvider.locale.languageCode);
      _startNotificationPolling();
      _startAnimations();
      await _checkFirstTime(); // ← اجعلها async
    });
  }


  void _startAnimations() {
    _welcomeAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _sectionsAnimationController.forward();
    });
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;

    if (!hasSeenWelcome) {
      // أظهر الرسالة الآن
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showWelcomeMessage = false;
          });
        }
      });

      // خزّن الحالة حتى لا تظهر مرة أخرى
      await prefs.setBool('hasSeenWelcome', true);
    } else {
      // لا تظهر الرسالة
      setState(() {
        _showWelcomeMessage = false;
      });
    }
  }


  @override
  void dispose() {
    _welcomeAnimationController.dispose();
    _sectionsAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startNotificationPolling() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final user = userProvider.user;

    if (user != null && user.email != null) {
      Stream.periodic(const Duration(seconds: 15)).listen((_) async {
        await NotificationService().checkOrderStatusUpdates(
          userEmail: user.email!,
          langCode: localeProvider.locale.languageCode,
        );
        final count = await NotificationService().getUnreadCount();
        _notificationCount.value = count;
      });
    }
  }

  void _loadData(String language) {
    setState(() {
      _futureCategories = apiService.getCategories(language: language);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currentLanguage = localeProvider.locale.languageCode;
    final direction = currentLanguage == "ar" ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _loadData(currentLanguage);
                      HapticFeedback.lightImpact();
                    },
                    color: const Color(0xFF6FE0DA),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: AnimatedBuilder(
                        animation: _sectionsAnimation,
                        builder: (context, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              // رسالة ترحيب شخصية
                              _buildPersonalizedWelcome(currentLanguage, userProvider),
                              const SizedBox(height: 8),
                              // إحصائيات سريعة
                              _buildQuickStats(currentLanguage),
                              const SizedBox(height: 16),
                              // البانرات التفاعلية
                              Transform.translate(
                                offset: Offset(0, 50 * (1 - _sectionsAnimation.value)),
                                child: Opacity(
                                  opacity: _sectionsAnimation.value,
                                  child: _buildBannerSlider(currentLanguage),
                                ),
                              ),
                              const SizedBox(height: 25),
                              // التصنيفات مع مؤشر التقدم
                              Transform.translate(
                                offset: Offset(0, 30 * (1 - _sectionsAnimation.value)),
                                child: Opacity(
                                  opacity: _sectionsAnimation.value,
                                  child: _buildCategoriesWithHeader(currentLanguage),
                                ),
                              ),
                              // الأكثر طلباً
                              Transform.translate(
                                offset: Offset(0, 20 * (1 - _sectionsAnimation.value)),
                                child: Opacity(
                                  opacity: _sectionsAnimation.value,
                                  child: _buildTopRequestedSection(currentLanguage),
                                ),
                              ),
                              // أقسام المنتجات
                              Transform.translate(
                                offset: Offset(0, 10 * (1 - _sectionsAnimation.value)),
                                child: Opacity(
                                  opacity: _sectionsAnimation.value,
                                  child: _buildCategorySections(
                                    currentLanguage: currentLanguage,
                                    moreLabel: currentLanguage == "ar" ? "المزيد >" : "More >",
                                    noProductsForCategoryText: currentLanguage == "ar"
                                        ? "لا توجد منتجات لهذا التصنيف"
                                        : "No products for this category",
                                  ),
                                ),
                              ),
                              // زر المساعدة السريعة
                              _buildQuickHelpSection(currentLanguage),
                              const SizedBox(height: 100), // مساحة إضافية
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // رسالة الترحيب المنبثقة
            if (_showWelcomeMessage) _buildWelcomeOverlay(currentLanguage),
            // زر العودة إلى الأعلى
            _buildScrollToTopButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedWelcome(String currentLanguage, UserProvider userProvider) {
    final user = userProvider.user;
    final greeting = _getTimeBasedGreeting(currentLanguage);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6FE0DA).withOpacity(0.1),
            Colors.white.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6FE0DA).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6FE0DA).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getTimeBasedIcon(),
              color: const Color(0xFF1A2543),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2543),
                  ),
                ),
                if (user?.username != null)
                  Text(
                    user!.username!,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF1A2543).withOpacity(0.7),
                    ),
                  ),
                Text(
                  currentLanguage == "ar"
                      ? "اكتشف أحدث المنتجات في كريدت فون بالتقسيط"
                      : "Discover one of the products at Credit Phone with installment",
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF1A2543).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeBasedGreeting(String language) {
    final hour = DateTime.now().hour;
    if (language == "ar") {
      if (hour < 12) return "صباح الخير";
      if (hour < 17) return "مساء الخير";
      return "مساء الخير";
    } else {
      if (hour < 12) return "Good Morning";
      if (hour < 17) return "Good Afternoon";
      return "Good Evening";
    }
  }

  IconData _getTimeBasedIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_cloudy_rounded;
    return Icons.brightness_3_rounded;
  }

  Widget _buildQuickStats(String currentLanguage) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.payments_rounded,
              title: currentLanguage == "ar" ? "خصص خطتك" : "Customize Your Plan",
              subtitle: currentLanguage == "ar"
                  ? "خصص دفعتك الأولى كما يناسبك"
                  : "Customize your first payment as you wish",
              color: const Color(0xFF6FE0DA),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.flash_on_rounded,
              title: currentLanguage == "ar" ? "تسليم سريع" : "Fast Delivery",
              subtitle: currentLanguage == "ar" ? "خلال 24 ساعة" : "Within 24hrs",
              color: const Color(0xFF1A2543),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeOverlay(String currentLanguage) {
    return AnimatedBuilder(
      animation: _welcomeAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.3 * _welcomeAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: _welcomeAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6FE0DA).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.celebration_rounded,
                        color: Color(0xFF1A2543),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentLanguage == "ar"
                          ? "مرحباً بك!"
                          : "Welcome!",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2543),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentLanguage == "ar"
                          ? "اكتشف مجموعة واسعة من المنتجات الإلكترونية بأفضل الأسعار"
                          : "Discover a wide range of electronic products at the best prices",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF1A2543).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollToTopButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _scrollController,
        builder: (context, child) {
          final showButton = _scrollController.hasClients &&
              _scrollController.offset > 300;

          return AnimatedOpacity(
            opacity: showButton ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedScale(
              scale: showButton ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: FloatingActionButton.small(
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                  HapticFeedback.lightImpact();
                },
                backgroundColor: const Color(0xFF6FE0DA),
                child: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickHelpSection(String currentLanguage) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A2543),
            const Color(0xFF1A2543).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentLanguage == "ar"
                      ? "تحتاج مساعدة؟"
                      : "Need Help?",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentLanguage == "ar"
                      ? "تواصل معنا عبر الواتساب"
                      : "Contact us via WhatsApp",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _openWhatsApp("97450105685"), // ضع رقم الواتساب
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6FE0DA),
              foregroundColor: const Color(0xFF1A2543),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.chat_rounded, size: 20,color: Color(0xFF1A2543)),
            label: Text(
              currentLanguage == "ar" ? "تواصل" : "Contact",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesWithHeader(String currentLanguage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6FE0DA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.category_rounded,
                  color: Color(0xFF1A2543),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                currentLanguage == "ar" ? "التصنيفات" : "Categories",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2543),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoriesScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.grid_view_rounded,
                  size: 16,
                  color: Color(0xFF6FE0DA),
                ),
                label: Text(
                  currentLanguage == "ar" ? "عرض الكل" : "View All",
                  style: const TextStyle(
                    color: Color(0xFF6FE0DA),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildCategoriesSection(
          currentLanguage: currentLanguage,
          noCategoriesText: currentLanguage == "ar" ? "لا توجد تصنيفات" : "No categories",
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2543), Color(0xFF1A2543)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconWithBackground(Icons.menu, () {
                Scaffold.of(context).openDrawer();
              }),
              Hero(
                tag: 'app_logo',
                child: Image.asset('assets/images/logo.png', height: 80),
              ),
              _buildNotificationIcon(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconWithBackground(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap();
          HapticFeedback.lightImpact();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0x206FE0DA),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF6FE0DA).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: const Color(0xFF6FE0DA)),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildIconWithBackground(Icons.notifications, () {
          Navigator.pushNamed(context, '/notifications').then((_) async {
            final count = await NotificationService().getUnreadCount();
            _notificationCount.value = count;
          });
          NotificationService().markAllAsRead();
        }),
        Positioned(
          right: 0,
          top: 0,
          child: StreamBuilder<int>(
            stream: Stream.periodic(const Duration(seconds: 2))
                .asyncMap((_) => NotificationService().getUnreadCount()),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox();

              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.red, Colors.redAccent],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBannerSlider(String language) {
    final isArabic = language == 'ar';

    final List<Map<String, dynamic>> slides = [
      {
        'title': isArabic ? "تقسيط جميع الجوالات والأجهزة الإلكترونية" : "Installment plans for all mobiles and electronics",
        'subtitle': isArabic ? "اختر أي جهاز إلكتروني واحصل عليه بالتقسيط المناسب لك"
            : "Choose any electronic device and get it with installment plans tailored for you",
        'icon': Icons.phone_iphone_rounded,
        'gradient': [const Color(0xFF192544), const Color(0xFF6FE0DA)],
        'action': isArabic ? "تسوق الآن" : "Shop Now",
      },
      {
        'title': isArabic ? "خطط تقسيط سهلة ومرنة" : "Flexible and easy installment options",
        'subtitle': isArabic ? "خطط مخصصة تناسب ميزانيتك مع خيارات دفع متعددة"
            : "Customized plans that fit your budget with multiple payment options",
        'icon': Icons.credit_card_rounded,
        'gradient': [const Color(0xFF6FE0DA), const Color(0xFF192544)],
        'action': isArabic ? "اعرف المزيد" : "Learn More",
      },
      {
        'title': isArabic ? "الدفع عند الاستلام" : "Pay on delivery",
        'subtitle': isArabic ? "استلم منتجك أولاً ثم ادفع بكل ثقة وأمان"
            : "Receive your product first then pay with confidence",
        'icon': Icons.local_shipping_rounded,
        'gradient': [const Color(0xFF192544), const Color(0xFF6FE0DA).withOpacity(0.8)],
        'action': isArabic ? "اطلب الآن" : "Order Now",
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 12.0),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 159.0,
          autoPlay: true,
          enlargeCenterPage: true,
          autoPlayInterval: const Duration(seconds: 6),
          autoPlayAnimationDuration: const Duration(milliseconds: 1000),
          autoPlayCurve: Curves.easeInOutCirc,
          pauseAutoPlayOnTouch: true,
          viewportFraction: 0.93,
        ),
        items: slides.map((slide) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: slide['gradient'],
                  ),
                  borderRadius: BorderRadius.circular(22.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Opacity(
                        opacity: 0.08,
                        child: Icon(
                          slide['icon'],
                          size: 120.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22.0),
                        onTap: () {
                          HapticFeedback.selectionClick();
                        },
                        splashColor: Colors.white.withOpacity(0.2),
                        highlightColor: Colors.white.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 2.0,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16.0),
                                    child: Icon(
                                      slide['icon'],
                                      size: 30.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 24.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          slide['title'],
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            height: 1.3,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          slide['subtitle'],
                                          style: TextStyle(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white.withOpacity(0.9),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoriesSection({required String currentLanguage, required String noCategoriesText}) {
    return FutureBuilder<List<Category>>(
      future: _futureCategories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
                  width: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                );
              },
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    color: Colors.grey.withOpacity(0.5),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    noCategoriesText,
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final categories = snapshot.data!;
        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder(
                duration: Duration(milliseconds: 300 + (index * 100)),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: HomeCategoryCard(category: categories[index]),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategorySections({required String currentLanguage, required String moreLabel, required String noProductsForCategoryText}) {
    return FutureBuilder<List<Category>>(
      future: _futureCategories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: List.generate(2, (index) => _buildLoadingCategorySection()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.grey.withOpacity(0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    noProductsForCategoryText,
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final categories = snapshot.data!;
        return Column(
          children: categories
              .map(
                (category) => TweenAnimationBuilder(
              duration: const Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: _buildCategorySection(
                      category,
                      moreLabel: moreLabel,
                      noProductsForCategoryText: noProductsForCategoryText,
                      currentLanguage: currentLanguage,
                    ),
                  ),
                );
              },
            ),
          )
              .toList(),
        );
      },
    );
  }

  Widget _buildLoadingCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 120,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 290,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopRequestedSection(String language) {
    final List<int> selectedIds = language == 'ar'
        ? topRequestedProductIdsAr
        : topRequestedProductIdsEn;

    return FutureBuilder<List<Product>>(
      future: apiService.getProductsByIds(selectedIds, language: language),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingTopRequestedSection(language);
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_outline_rounded,
                    color: Colors.grey.withOpacity(0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    language == 'ar'
                        ? 'لا توجد منتجات مميزة حالياً'
                        : 'No featured products currently',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final products = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6FE0DA).withOpacity(0.2),
                          const Color(0xFF6FE0DA).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Color(0xFF1A2543),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    language == 'ar' ? 'الأكثر طلباً' : 'Top Requested',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2543),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      language == 'ar' ? 'جديد' : 'New',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 290,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 400 + (index * 100)),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: SizedBox(
                            width: 160,
                            child: ProductCard(product: products[index]),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingTopRequestedSection(String language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 100,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 290,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(Category category,
      {required String currentLanguage,
        required String moreLabel,
        required String noProductsForCategoryText}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),

            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Container(
                    //   padding: const EdgeInsets.all(8),
                    //   decoration: BoxDecoration(
                    //     color: const Color(0xFF6FE0DA).withOpacity(0.2),
                    //     borderRadius: BorderRadius.circular(8),
                    //   ),
                    //   child: const Icon(
                    //     Icons.inventory_2_rounded,
                    //     color: Color(0xFF1A2543),
                    //     size: 20,
                    //   ),
                    // ),
                    const SizedBox(width: 12),
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2543),
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductListScreen(categoryId: category.id),
                        ),
                      );
                      HapticFeedback.lightImpact();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6FE0DA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF6FE0DA).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            moreLabel.replaceAll('>', '').trim(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6FE0DA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Color(0xFF6FE0DA),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Product>>(
            future: apiService.getProducts(categoryId: category.id, language: currentLanguage, perPage: 10),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 290,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      );
                    },
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  height: 150,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey.withOpacity(0.5),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          noProductsForCategoryText,
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final products = snapshot.data!;
              return SizedBox(
                height: 290,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return TweenAnimationBuilder(
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, double value, child) {
                        return Transform.translate(
                          offset: Offset(0, 15 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: SizedBox(
                              width: 160,
                              child: ProductCard(product: products[index]),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openWhatsApp(String phoneNumber) async {
    final url = "https://wa.me/$phoneNumber";
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      // Handle error gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<LocaleProvider>(context, listen: false).locale.languageCode == "ar"
                  ? "حدث خطأ في فتح الواتساب"
                  : "Error opening WhatsApp",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}