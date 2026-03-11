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
  int _perPage = 12; // زيادة العدد لتقليل حالات الصفحة الفارغة بعد الفلترة
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isAutoLoadingForFilter = false;

  String _language = "ar";
  _PaymentFilter _paymentFilter = _PaymentFilter.all;

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
    setState(() {
      _isLoading = true;
      _page = 1;
      _hasMore = true;
      _allProducts = [];
      _filteredProducts = [];
    });

    // Default behavior: show ALL (cash + installment) and allow user filtering.
    // If a screen explicitly opened "installment results" or "cash results", we
    // keep that as an initial filter preference without hiding other items forever.
    _paymentFilter = _initialPaymentFilter();

    final products = await apiService.getProducts(
      categoryId: widget.categoryId,
      language: _language,
      perPage: _perPage,
      page: _page,
    );

    final sorted = _applySorting(products);
    setState(() {
      _allProducts = sorted;
      _filteredProducts = _applySearch(
        _searchController.text,
        baseList: _applyPaymentFilter(sorted),
      );
      _hasMore = products.length == _perPage;
      _isLoading = false;
    });

    await _ensureResultsForFilterIfNeeded();
  }

  Future<void> _fetchMoreProducts() async {
    if (_isLoadingMore) return;
    if (!mounted) return;
    setState(() => _isLoadingMore = true);
    _page++;
    final more = await apiService.getProducts(
      categoryId: widget.categoryId,
      language: _language,
      perPage: _perPage,
      page: _page,
    );

    if (more.isNotEmpty) {
      final sorted = _applySorting(more);

      if (mounted) {
        setState(() {
          _allProducts.addAll(sorted);
          _applySorting(_allProducts);
          _filteredProducts = _applySearch(
            _searchController.text,
            baseList: _applyPaymentFilter(_allProducts),
          );
          _hasMore = more.length == _perPage;
        });
      }
    } else {
      if (mounted) {
        setState(() => _hasMore = false);
      }
    }
    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  List<Product> _applySorting(List<Product> products) {
    if (widget.sortBy == 'price_asc') {
      products.sort((a, b) => a.price.compareTo(b.price));
    }
    // يمكنك لاحقًا إضافة دعم لمزيد من الفرز مثل: 'price_desc' أو 'name_asc'
    return products;
  }

  _PaymentFilter _initialPaymentFilter() {
    // Requirement: category browsing should show BOTH cash + installment.
    // Keep old flags only as an *initial preference* (mostly for search results screens).
    if (widget.showCashOnly && !widget.showInstallmentOnly) {
      return _PaymentFilter.cash;
    }
    if (widget.showInstallmentOnly && !widget.showCashOnly) {
      return _PaymentFilter.installment;
    }
    return _PaymentFilter.all;
  }

  List<Product> _applyPaymentFilter(List<Product> products) {
    switch (_paymentFilter) {
      case _PaymentFilter.cash:
        return products
            .where((product) => product.shortDescription.trim().isEmpty)
            .toList();
      case _PaymentFilter.installment:
        return products
            .where((product) => product.shortDescription.trim().isNotEmpty)
            .toList();
      case _PaymentFilter.all:
        return products;
    }
  }

  List<Product> _applySearch(String query, {List<Product>? baseList}) {
    final source = baseList ?? _allProducts;
    if (query.isEmpty) return List<Product>.from(source);
    return source.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _applySearch(
        query,
        baseList: _applyPaymentFilter(_allProducts),
      );
    });
  }

  void _setPaymentFilter(_PaymentFilter filter) {
    if (_paymentFilter == filter) return;
    setState(() {
      _paymentFilter = filter;
      _filteredProducts = _applySearch(
        _searchController.text,
        baseList: _applyPaymentFilter(_allProducts),
      );
    });

    _ensureResultsForFilterIfNeeded();
  }

  Future<void> _ensureResultsForFilterIfNeeded() async {
    // If user filtered to cash/installment but we only loaded a few pages,
    // results can be empty until more pages are fetched. Auto-fetch a few pages.
    if (!mounted) return;
    if (_paymentFilter == _PaymentFilter.all) return;
    if (_isAutoLoadingForFilter) return;
    if (_isLoading || _isLoadingMore) return;
    if (!_hasMore) return;

    final query = _searchController.text;
    // For normal browsing (no search query), try to fill the grid with enough items.
    // For search results, avoid too many extra requests: stop once we have at least one match.
    final desiredCount = query.trim().isEmpty ? 8 : 1;

    final current = _applySearch(
      _searchController.text,
      baseList: _applyPaymentFilter(_allProducts),
    );
    if (current.length >= desiredCount) return;

    setState(() => _isAutoLoadingForFilter = true);
    var safety = 0;
    while (mounted && safety < 6) {
      final nowFiltered = _applySearch(
        _searchController.text,
        baseList: _applyPaymentFilter(_allProducts),
      );
      if (nowFiltered.length >= desiredCount || !_hasMore) break;
      await _fetchMoreProducts();
      safety++;
    }
    if (!mounted) return;
    setState(() {
      _filteredProducts = _applySearch(
        _searchController.text,
        baseList: _applyPaymentFilter(_allProducts),
      );
      _isAutoLoadingForFilter = false;
    });
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(isAr ? 'الكل' : 'All'),
                    selected: _paymentFilter == _PaymentFilter.all,
                    onSelected: (_) => _setPaymentFilter(_PaymentFilter.all),
                  ),
                  ChoiceChip(
                    label: Text(isAr ? 'كاش' : 'Cash'),
                    selected: _paymentFilter == _PaymentFilter.cash,
                    onSelected: (_) => _setPaymentFilter(_PaymentFilter.cash),
                  ),
                  ChoiceChip(
                    label: Text(isAr ? 'تقسيط' : 'Installment'),
                    selected: _paymentFilter == _PaymentFilter.installment,
                    onSelected: (_) => _setPaymentFilter(_PaymentFilter.installment),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? (_isAutoLoadingForFilter || (_isLoadingMore && _hasMore))
                    ? const Center(child: CircularProgressIndicator())
                    : Center(child: Text(noResults))
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

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

enum _PaymentFilter { all, cash, installment }
