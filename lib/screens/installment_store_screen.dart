import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import '../services/api_service.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import 'product_list_screen.dart';

class InstallmentStoreScreen extends StatefulWidget {
  const InstallmentStoreScreen({Key? key}) : super(key: key);

  @override
  State<InstallmentStoreScreen> createState() => _InstallmentStoreScreenState();
}

class _InstallmentStoreScreenState extends State<InstallmentStoreScreen> {
  final ApiService _api = ApiService();
  late Future<List<Category>> _futureCategories;

  @override
  void initState() {
    super.initState();
    final lang = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    _futureCategories = _api.getCategories(language: lang);
  }

  @override
  Widget build(BuildContext context) {
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
            final lang = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
            setState(() {
              _futureCategories = _api.getCategories(language: lang);
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/installment-options');
            HapticFeedback.lightImpact();
          },
          label: Text(isArabic ? 'خصص خطتك' : 'Customize Plan'),
          icon: const Icon(Icons.tune_rounded),
          backgroundColor: const Color(0xFF6FE0DA),
          foregroundColor: const Color(0xFF1A2543),
        ),
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final categories = snapshot.data!;
        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.15)),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      category.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1A2543),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
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

  Widget _buildSingleCategorySection(Category category, String language, bool isArabic) {
    final moreLabel = isArabic ? 'المزيد' : 'More';
    final noProductsText = isArabic ? 'لا توجد منتجات لهذا التصنيف' : 'No products for this category';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
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
                  icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF6FE0DA)),
                  label: Text(
                    moreLabel,
                    style: const TextStyle(color: Color(0xFF6FE0DA), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<List<Product>>(
            future: _api.getProducts(categoryId: category.id, language: language, perPage: 10),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
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
                      child: const Center(child: CircularProgressIndicator.adaptive()),
                    ),
                  ),
                );
              }
              final fetched = snapshot.data ?? const <Product>[];
              final installmentProducts = fetched.where((p) => p.shortDescription.trim().isNotEmpty).toList();
              if (installmentProducts.isEmpty) {
                return Container(
                  height: 150,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Text(
                      noProductsText,
                      style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 14),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 290,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: installmentProducts.length,
                  itemBuilder: (context, index) {
                    final product = installmentProducts[index];
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: ProductCard(product: product),
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
