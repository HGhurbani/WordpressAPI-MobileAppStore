import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import '../providers/locale_provider.dart';

class ProductListScreen extends StatefulWidget {
  final int? categoryId;
  final String? sortBy; // ← أضفنا هذا السطر لدعم الفرز
  final bool showInstallmentOnly;
  final bool showCashOnly;
  final String? initialQuery;
  final String? titleAr;
  final String? titleEn;
  final String? searchHintAr;
  final String? searchHintEn;
  final String? noResultsTextAr;
  final String? noResultsTextEn;

  const ProductListScreen({
    Key? key,
    this.categoryId,
    this.sortBy,
    this.showInstallmentOnly = false,
    this.showCashOnly = false,
    this.initialQuery,
    this.titleAr,
    this.titleEn,
    this.searchHintAr,
    this.searchHintEn,
    this.noResultsTextAr,
    this.noResultsTextEn,
  }) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final apiService = ApiService();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  int _page = 1;
  final int _perPage = 6;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  String _language = "ar";

  @override
  void initState() {
    super.initState();
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    _language = locale.languageCode;
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }

    _fetchProducts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore && _hasMore) {
        _fetchMoreProducts();
      }
    });
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    final products = await apiService.getProducts(
      categoryId: widget.categoryId,
      language: _language,
      perPage: _perPage,
      page: _page,
    );

    // تطبيق الفرز إذا طلب
    final sorted = _applySorting(products);

    final filteredAll = _applyInstallmentFilter(sorted);

    setState(() {
      _allProducts = filteredAll;
      _filteredProducts = _applySearch(
        _searchController.text,
        baseList: filteredAll,
      );
      _isLoading = false;
      _hasMore = products.length == _perPage;
    });
  }

  Future<void> _fetchMoreProducts() async {
    _isLoadingMore = true;
    _page++;
    final more = await apiService.getProducts(
      categoryId: widget.categoryId,
      language: _language,
      perPage: _perPage,
      page: _page,
    );

    if (more.isNotEmpty) {
      final sorted = _applySorting(more);
      final filteredMore = _applyInstallmentFilter(sorted);

      setState(() {
        _allProducts.addAll(filteredMore);
        _filteredProducts = _applySearch(_searchController.text);
        _hasMore = more.length == _perPage;
      });
    } else {
      setState(() => _hasMore = false);
    }
    _isLoadingMore = false;
  }

  List<Product> _applySorting(List<Product> products) {
    if (widget.sortBy == 'price_asc') {
      products.sort((a, b) => a.price.compareTo(b.price));
    }
    // يمكنك لاحقًا إضافة دعم لمزيد من الفرز مثل: 'price_desc' أو 'name_asc'
    return products;
  }

  List<Product> _applyInstallmentFilter(List<Product> products) {
    // If cash-only requested, keep products with empty shortDescription
    if (widget.showCashOnly) {
      return products
          .where((product) => product.shortDescription.trim().isEmpty)
          .toList();
    }
    // If installment-only requested, keep products with non-empty shortDescription
    if (widget.showInstallmentOnly) {
      return products
          .where((product) => product.shortDescription.trim().isNotEmpty)
          .toList();
    }
    return products;
  }

  List<Product> _applySearch(String query, {List<Product>? baseList}) {
    final source = baseList ?? _allProducts;
    if (query.isEmpty) return List<Product>.from(source);
    return source.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  void _filterProducts(String query) {
    setState(() => _filteredProducts = _applySearch(query));
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _language == 'ar';
    final appBarTitle = isAr
        ? (widget.titleAr ?? "المنتجات")
        : (widget.titleEn ?? "Products");
    final searchHint = isAr
        ? (widget.searchHintAr ?? "ابحث عن منتج...")
        : (widget.searchHintEn ?? "Search for product...");
    final noResults = isAr
        ? (widget.noResultsTextAr ?? "لا توجد نتائج")
        : (widget.noResultsTextEn ?? "No results found");

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A2543),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: searchHint,
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
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? Center(child: Text(noResults))
                : NotificationListener<ScrollNotification>(
              onNotification: (_) => true,
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.6,
                ),
                itemCount: _filteredProducts.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _filteredProducts.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ProductCard(product: _filteredProducts[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
