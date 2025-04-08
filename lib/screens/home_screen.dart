import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../widgets/product_card.dart';
import '../widgets/category_card.dart';
import 'product_list_screen.dart';
import '../providers/locale_provider.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final apiService = ApiService();

  // تعريف متغير اللغة الافتراضي "ar"
  String _language = "ar";



  late Future<List<Category>> _futureCategories;
  late Future<List<Product>> _futureNewProducts; // أحدث المنتجات

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // دالة لتحميل البيانات باستخدام اللغة المختارة
  void _loadData() {
    _futureCategories = apiService.getCategories(language: _language);
    _futureNewProducts = apiService.getProducts(language: _language, perPage: 10);  }

  @override
  Widget build(BuildContext context) {
    // الحصول على لغة التطبيق من LocaleProvider
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLanguage = localeProvider.locale.languageCode;

    // ضبط الاتجاه حسب اللغة
    final direction = currentLanguage == "ar" ? TextDirection.rtl : TextDirection.ltr;

    // تحديد النصوص الثابتة حسب اللغة
    final categoriesLabel = currentLanguage == "ar" ? "التصنيفات" : "Categories";
    final newProductsLabel = currentLanguage == "ar" ? "أحدث المنتجات" : "New Products";
    final moreLabel = currentLanguage == "ar" ? "المزيد >" : "More >";
    final noCategoriesText = currentLanguage == "ar" ? "لا توجد تصنيفات" : "No categories";
    final noProductsText = currentLanguage == "ar" ? "لا توجد منتجات" : "No products";
    final noProductsForCategoryText = currentLanguage == "ar"
        ? "لا توجد منتجات لهذا التصنيف"
        : "No products for this category";

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white), // <== هذا السطر
          // استبدال عنوان AppBar بالشعار (تأكد من وجود الملف في assets/images/logo.png)
          title: Image.asset(
            'assets/images/logo.png',
            height: 40,
          ),
          centerTitle: true,
          backgroundColor: const Color(0xff180cb5),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.g_translate, color: Colors.white),
              onSelected: (String value) {
                setState(() {
                  _language = value;
                  _loadData();
                });
                Provider.of<LocaleProvider>(context, listen: false)
                    .setLocale(Locale(value, ''));
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: "ar",
                  child: Text("العربية"),
                ),
                PopupMenuItem(
                  value: "en",
                  child: Text("English"),
                ),
              ],
            )
          ],
        ),
        drawer: Drawer(
          backgroundColor: Colors.white,
          child: Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              final isAr = _language == 'ar';
              final isLoggedIn = userProvider.isLoggedIn;

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Color(0xff180cb5)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.account_circle, size: 50, color: Colors.white),
                        const SizedBox(height: 10),
                        Text(
                          isLoggedIn
                              ? (userProvider.user?.username ?? 'User')
                              : (isAr ? "مرحباً بك" : "Welcome"),
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        Text(
                          isLoggedIn
                              ? (userProvider.user?.email ?? '')
                              : (isAr ? "يرجى تسجيل الدخول" : "Please login"),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: Text(isAr ? "الرئيسية" : "Home"),
                    onTap: () => Navigator.pushReplacementNamed(context, '/main'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.store),
                    title: Text(isAr ? "المتجر" : "Store"),
                    onTap: () => Navigator.pushNamed(context, '/product_list'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(isAr ? "حسابي" : "My Account"),
                    onTap: () => Navigator.pushNamed(context, '/login'),
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
                    title: Text(isAr ? "الإعدادات" : "Settings"),
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
                ],
              );
            },
          ),
        ),

        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildBannerSlider(currentLanguage),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: Text(
                  categoriesLabel,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _buildCategoriesSection(noCategoriesText: noCategoriesText),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildNewProductsHeader(newProductsLabel: newProductsLabel, moreLabel: moreLabel),
              ),
              _buildHorizontalProductsSection(noProductsText: noProductsText),
              _buildCategorySections(moreLabel: moreLabel, noProductsForCategoryText: noProductsForCategoryText),
            ],
          ),
        ),
      ),
    );
  }

  /// سلايدر البنرات
  Widget _buildBannerSlider(String language) {
    final List<String> bannerImages = language == 'ar'
        ? [
      "https://creditphoneqatar.com/img_app/1.png",
      "https://creditphoneqatar.com/img_app/2.png",
      "https://creditphoneqatar.com/img_app/3.png",
    ]
        : [
      "https://creditphoneqatar.com/img_app/1en.png",
      "https://creditphoneqatar.com/img_app/2en.png",
      "https://creditphoneqatar.com/img_app/3en.png",
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 200.0,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
      ),
      items: bannerImages.map((imgUrl) {
        return Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(imgUrl),
              fit: BoxFit.cover,
            ),
          ),
        );
      }).toList(),
    );
  }


  void _openWhatsApp(String phoneNumber) async {
    final url = "https://wa.me/$phoneNumber";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  /// عرض التصنيفات أفقياً (بطاقات التصنيفات)
  Widget _buildCategoriesSection({required String noCategoriesText}) {
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
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return CategoryCard(category: categories[index]);
            },
          ),
        );
      },
    );
  }

  /// رأس قسم "أحدث المنتجات" مع زر "المزيد >"
  Widget _buildNewProductsHeader({required String newProductsLabel, required String moreLabel}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          newProductsLabel,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/product_list');
          },
          child: Text(
            moreLabel,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  /// عرض أحدث المنتجات في قائمة أفقية
  Widget _buildHorizontalProductsSection({required String noProductsText}) {
    return FutureBuilder<List<Product>>(
      future: _futureNewProducts,
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
            child: Center(child: Text(noProductsText)),
          );
        }
        final products = snapshot.data!;
        return SizedBox(
          height: 290,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
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
    );
  }

  /// عرض أقسام المنتجات لكل تصنيف
  Widget _buildCategorySections({required String moreLabel, required String noProductsForCategoryText}) {
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
              .map((category) => _buildCategorySection(category, moreLabel: moreLabel, noProductsForCategoryText: noProductsForCategoryText))
              .toList(),
        );
      },
    );
  }

  /// بناء قسم لكل تصنيف: عنوان + زر "المزيد" وقائمة منتجات أفقية
  Widget _buildCategorySection(Category category, {required String moreLabel, required String noProductsForCategoryText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // رأس القسم بعنوان التصنيف وزر "المزيد"
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
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
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        // قائمة المنتجات الخاصة بهذا التصنيف (أفقية)
        FutureBuilder<List<Product>>(
          future: apiService.getProducts(categoryId: category.id, language: _language,perPage: 10,),
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
}
