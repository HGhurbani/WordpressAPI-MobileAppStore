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
import 'product_list_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final apiService = ApiService();
  late Future<List<Category>> _futureCategories;
  final ValueNotifier<int> _notificationCount = ValueNotifier<int>(0);
  final List<int> topRequestedProductIdsAr = [12226, 12261, 12245, 12762]; // منتجات اللغة العربية
  final List<int> topRequestedProductIdsEn = [12902, 13310, 13325, 12835]; // منتجات اللغة الإنجليزية


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      _loadData(localeProvider.locale.languageCode);
      _startNotificationPolling();
    });
  }

  void _startNotificationPolling() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final user = userProvider.user;

    if (user != null && user.email != null) {
      // تنفيذ كل 15 ثانية
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
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLanguage = localeProvider.locale.languageCode;
    final direction = currentLanguage == "ar" ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBannerSlider(currentLanguage),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        currentLanguage == "ar" ? "التصنيفات" : "Categories",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildCategoriesSection(
                      currentLanguage: currentLanguage,
                      noCategoriesText: currentLanguage == "ar" ? "لا توجد تصنيفات" : "No categories",
                    ),
                    _buildTopRequestedSection(currentLanguage),
                    _buildCategorySections(
                      currentLanguage: currentLanguage,
                      moreLabel: currentLanguage == "ar" ? "المزيد >" : "More >",
                      noProductsForCategoryText: currentLanguage == "ar"
                          ? "لا توجد منتجات لهذا التصنيف"
                          : "No products for this category",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2543),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
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
              Image.asset('assets/images/logo.png', height: 80),
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0x206FE0DA),
            shape: BoxShape.circle,
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
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
      },
      {
        'title': isArabic ? "خطط تقسيط سهلة ومرنة" : "Flexible and easy installment options",
        'subtitle': isArabic ? "خطط مخصصة تناسب ميزانيتك مع خيارات دفع متعددة"
            : "Customized plans that fit your budget with multiple payment options",
        'icon': Icons.credit_card_rounded,
        'gradient': [const Color(0xFF6FE0DA), const Color(0xFF192544)],
      },
      {
        'title': isArabic ? "الدفع عند الاستلام" : "Pay on delivery",
        'subtitle': isArabic ? "استلم منتجك أولاً ثم ادفع بكل ثقة وأمان"
            : "Receive your product first then pay with confidence",
        'icon': Icons.local_shipping_rounded,
        'gradient': [const Color(0xFF192544), const Color(0xFF6FE0DA).withOpacity(0.8)],
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 180.0, // Increased height to accommodate subtitle
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
                              child: Row(
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ShaderMask(
                                          shaderCallback: (bounds) {
                                            return LinearGradient(
                                              colors: [
                                                Colors.white,
                                                Colors.white.withOpacity(0.8),
                                              ],
                                            ).createShader(bounds);
                                          },
                                          child: Text(
                                            slide['title'],
                                            style: const TextStyle(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              height: 1.3,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          slide['subtitle'],
                                          style: TextStyle(
                                            fontSize: 14.0,
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

        ],
      ),
    );
  }

  Widget _buildCategoriesSection({required String currentLanguage, required String noCategoriesText}) {
    return FutureBuilder<List<Category>>(
      future: _futureCategories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(child: Text(noCategoriesText)),
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
              return HomeCategoryCard(category: categories[index]);
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
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(child: Text(noProductsForCategoryText)),
          );
        }
        final categories = snapshot.data!;
        return Column(
          children: categories
              .map((category) => _buildCategorySection(
              category,
              moreLabel: moreLabel,
              noProductsForCategoryText: noProductsForCategoryText,
              currentLanguage: currentLanguage))
              .toList(),
        );
      },
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
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text(language == 'ar'
                  ? 'لا توجد منتجات مميزة حالياً'
                  : 'No featured products currently'),
            ),
          );
        }

        final products = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Text(
                language == 'ar' ? 'الأكثر طلباً' : 'Top Requested',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 290,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 160,
                    child: ProductCard(product: products[index]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildCategorySection(Category category,
      {required String currentLanguage,
        required String moreLabel,
        required String noProductsForCategoryText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductListScreen(categoryId: category.id),
                    ),
                  );
                },
                child: Text(
                  moreLabel,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6FE0DA)),
                ),
              ),
            ],
          ),
        ),
        FutureBuilder<List<Product>>(
          future: apiService.getProducts(categoryId: category.id, language: currentLanguage, perPage: 10),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(child: Text(noProductsForCategoryText)),
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
                  return SizedBox(
                    width: 160,
                    child: ProductCard(product: products[index]),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  void _openWhatsApp(String phoneNumber) async {
    final url = "https://wa.me/$phoneNumber";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
