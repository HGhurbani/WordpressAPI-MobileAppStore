import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import '../services/api_service.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import 'product_list_screen.dart';
import '../widgets/home_card_category.dart';

class InstallmentStoreScreen extends StatefulWidget {
  const InstallmentStoreScreen({Key? key}) : super(key: key);

  @override
  State<InstallmentStoreScreen> createState() => _InstallmentStoreScreenState();
}

class _InstallmentStoreScreenState extends State<InstallmentStoreScreen>
    with AutomaticKeepAliveClientMixin {
  final ApiService _api = ApiService();
  late Future<List<Category>> _futureCategories;
  String? _currentLanguage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final lang = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    _currentLanguage = lang;
    _futureCategories = _api.getCategories(language: lang);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Provider.of<LocaleProvider>(context).locale.languageCode;
    if (_currentLanguage != lang) {
      setState(() {
        _currentLanguage = lang;
        _futureCategories = _api.getCategories(language: lang);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final language = Provider.of<LocaleProvider>(context).locale.languageCode;
    final isArabic = language == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          title: Text(isArabic ? 'متجر التقسيط' : 'Installment Store'),
          centerTitle: true,
          backgroundColor: const Color(0xFF1A2543),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            final lang = _currentLanguage ??
                Provider.of<LocaleProvider>(context, listen: false)
                    .locale
                    .languageCode;
            setState(() {
              _futureCategories = _api.getCategories(language: lang);
              _currentLanguage = lang;
            });
            HapticFeedback.lightImpact();
          },
          color: const Color(0xFF6FE0DA),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildSearchBar(isArabic),
                const SizedBox(height: 8),
                _buildCategoriesHeader(isArabic),
                const SizedBox(height: 8),
                _buildCategoriesList(language),
                const SizedBox(height: 8),
                _buildCategorySections(language, isArabic),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        // floatingActionButton: FloatingActionButton.extended(
        //   onPressed: () {
        //     Navigator.pushNamed(context, '/installment-options');
        //     HapticFeedback.lightImpact();
        //   },
        //   label: Text(isArabic ? 'خصص خطتك' : 'Customize Plan'),
        //   icon: const Icon(Icons.tune_rounded),
        //   backgroundColor: const Color(0xFF6FE0DA),
        //   foregroundColor: const Color(0xFF1A2543),
        // ),
      ),
    );
  }

  Widget _buildSearchBar(bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        readOnly: true,
        onTap: () {
          showSearchDialog(isArabic);
        },
        decoration: InputDecoration(
          hintText: isArabic ? 'ابحث عن عروض التقسيط...' : 'Search for installment deals...',
          prefixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> showSearchDialog(bool isArabic) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isArabic ? 'ابحث' : 'Search'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: isArabic ? 'اكتب اسم المنتج' : 'Type product name',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final query = controller.text.trim();
                Navigator.pop(context);
                if (query.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductListScreen(
                        initialQuery: query,
                        showInstallmentOnly: true,
                        titleAr: 'نتائج التقسيط',
                        titleEn: 'Installment Results',
                        searchHintAr: 'ابحث عن عروض التقسيط...',
                        searchHintEn: 'Search for installment deals...',
                      ),
                    ),
                  );
                }
              },
              child: Text(isArabic ? 'بحث' : 'Search'),
            ),
          ],
        );
      },
    );
  }

  void _retryFetchCategories([String? language]) {
    final lang = language ??
        _currentLanguage ??
        Provider.of<LocaleProvider>(context, listen: false)
            .locale
            .languageCode;

    setState(() {
      _futureCategories = _api.getCategories(language: lang);
      _currentLanguage = lang;
    });
  }

  Widget _buildErrorState({
    required bool isArabic,
    required VoidCallback onRetry,
    String? message,
    double? height,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16),
  }) {
    final displayMessage = message ??
        (isArabic
            ? 'حدث خطأ أثناء تحميل البيانات.'
            : 'An error occurred while loading the data.');
    final retryLabel = isArabic ? 'إعادة المحاولة' : 'Retry';

    final content = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            displayMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A2543),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6FE0DA),
              foregroundColor: const Color(0xFF1A2543),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(retryLabel),
          ),
        ],
      ),
    );

    final child = Center(child: content);

    if (height != null) {
      return SizedBox(height: height, child: child);
    }

    return child;
  }

  Widget _buildCategoriesHeader(bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
            isArabic ? 'التصنيفات' : 'Categories',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2543),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(String language) {
    return FutureBuilder<List<Category>>(
      future: _futureCategories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: 6,
              itemBuilder: (context, index) => Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          final isArabic = language == 'ar';
          return _buildErrorState(
            isArabic: isArabic,
            onRetry: () {
              _retryFetchCategories(language);
            },
            message:
                isArabic ? 'تعذر تحميل التصنيفات.' : 'Failed to load categories.',
            height: 140,
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final categories = snapshot.data!;
        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return HomeCategoryCard(
                category: categories[index],
                showInstallmentOnly: true,
                showCashOnly: false,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategorySections(String language, bool isArabic) {
    return FutureBuilder<List<Category>>(
      future: _futureCategories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: List.generate(2, (_) => _buildLoadingCategorySection()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: _buildErrorState(
              isArabic: isArabic,
              onRetry: () {
                _retryFetchCategories(language);
              },
              message: isArabic
                  ? 'تعذر تحميل أقسام المتجر بالتقسيط.'
                  : 'Failed to load installment sections.',
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final categories = snapshot.data!;
        return Column(
          children: categories.map((c) => _buildSingleCategorySection(c, language, isArabic)).toList(),
        );
      },
    );
  }

  Widget _buildSingleCategorySection(
      Category category, String language, bool isArabic) {
    final moreLabel = isArabic ? 'المزيد' : 'More';

    return FutureBuilder<List<Product>>(
      future: _api.getProducts(
        categoryId: category.id,
        language: language,
        perPage: 10,
      ),
      builder: (context, snapshot) {
        Widget buildHeader() {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2543),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductListScreen(
                          categoryId: category.id,
                          showInstallmentOnly: true,
                          titleAr: 'متجر التقسيط',
                          titleEn: 'Installment Store',
                          searchHintAr: 'ابحث عن عروض التقسيط...',
                          searchHintEn: 'Search for installment deals...',
                        ),
                      ),
                    );
                    HapticFeedback.lightImpact();
                  },
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF6FE0DA),
                  ),
                  label: Text(
                    moreLabel,
                    style:
                        const TextStyle(color: Color(0xFF6FE0DA), fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }

        Widget buildSkeleton() {
          return SizedBox(
            height: 290,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 4,
              itemBuilder: (context, index) => Container(
                width: 160,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              ),
            ),
          );
        }

        Widget buildProducts(List<Product> products) {
          if (products.isEmpty) {
            return const SizedBox.shrink();
          }

          if (products.length == 1) {
            return SizedBox(
              height: 290,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 350),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, 15 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: ProductCard(product: products.first),
                      ),
                    );
                  },
                ),
              ),
            );
          }

          if (products.length == 2) {
            return SizedBox(
              height: 290,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: List.generate(products.length * 2 - 1, (index) {
                    if (index.isOdd) {
                      return const SizedBox(width: 12);
                    }
                    final productIndex = index ~/ 2;
                    return Expanded(
                      child: TweenAnimationBuilder(
                        duration: Duration(
                            milliseconds: 300 + (productIndex * 50)),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Transform.translate(
                            offset: Offset(0, 15 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child:
                                  ProductCard(product: products[productIndex]),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ),
            );
          }

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
        }

        if (snapshot.hasError) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildHeader(),
                const SizedBox(height: 12),
                _buildErrorState(
                  isArabic: isArabic,
                  onRetry: () {
                    setState(() {});
                  },
                  message: isArabic
                      ? 'تعذر تحميل منتجات هذا التصنيف.'
                      : "Failed to load this category's products.",
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ],
            ),
          );
        }

        final isWaiting = snapshot.connectionState == ConnectionState.waiting;
        final fetched = snapshot.data ?? const <Product>[];
        final installmentProducts = fetched
            .where((p) => p.shortDescription.trim().isNotEmpty)
            .toList();

        if (!isWaiting && installmentProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        final body = isWaiting
            ? buildSkeleton()
            : buildProducts(installmentProducts);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(),
              const SizedBox(height: 12),
              body,
            ],
          ),
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
}
