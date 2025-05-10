import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
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
  String? previousLanguage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      _loadData(localeProvider.locale.languageCode);
    });
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
      child: Column(
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
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      currentLanguage == "ar" ? "التصنيفات" : "Categories",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildCategoriesSection(
                    currentLanguage: currentLanguage,
                    noCategoriesText: currentLanguage == "ar" ? "لا توجد تصنيفات" : "No categories",
                  ),
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
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: const Color(0xff180cb5), // هنا نلون كل المساحة بما فيها SafeArea
      child: SafeArea(
        bottom: false, // عشان ما يحسب المسافة من الأسفل
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
              Image.asset(
                'assets/images/logo.png',
                height: 40,
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                      NotificationService().markAllAsRead();
                    },
                  ),
                  StreamBuilder<int>(
                    stream: Stream.periodic(const Duration(seconds: 1))
                        .asyncMap((_) => NotificationService().getUnreadCount()),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data! > 0) {
                        return Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${snapshot.data}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


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
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
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

  Widget _buildCategorySection(Category category,
      {required String currentLanguage,
        required String moreLabel,
        required String noProductsForCategoryText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
