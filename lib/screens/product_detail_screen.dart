import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
// If 'Margins' is not recognized, you might need to import it explicitly like this:
// import 'package:flutter_html/src/style.dart'; // (Note: 'src' imports are generally discouraged)
import '../models/product.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../utils.dart';
import 'full_screen_image_screen.dart';
import 'added_to_cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({Key? key, required this.productId}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Product> _futureProduct;
  bool _isDescriptionExpanded = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  void _fetchProductDetails() {
    final language = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    _futureProduct = _apiService.getProductById(widget.productId, language: language);
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final language = Provider.of<LocaleProvider>(context).locale.languageCode;
    final isArabic = language == 'ar';

    final appBarTitle = isArabic ? "تفاصيل المنتج" : "Product Details";
    final addToCartText = isArabic ? "إضافة للسلة" : "Add to Cart";
    final installmentPlanTitle = isArabic ? "خطة التقسيط" : "Installment Plan";
    final descriptionTitle = isArabic ? "وصف المنتج" : "Product Description";
    final priceTitle = isArabic ? "السعر" : "Price";
    final productGalleryTitle = isArabic ? "معرض الصور" : "Product Gallery";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A2543),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<Product>(
        future: _futureProduct,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1A2543)));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                isArabic ? "فشل تحميل المنتج. يرجى المحاولة لاحقًا." : "Failed to load product. Please try again later.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          final product = snapshot.data!;
          final priceText = isArabic
              ? "ر.ق ${formatNumber(product.price)}"
              : "QAR ${formatNumber(product.price)}";

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _futureProduct = _apiService.getProductById(widget.productId, language: language);
              });
              await _futureProduct;
            },
            color: const Color(0xFF1A2543),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProductImageSection(product, context),
                  const SizedBox(height: 20),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2543),
                    ),
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Icon(Icons.monetization_on, color: const Color(0xFF6FE0DA), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        priceTitle,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A2543)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        priceText,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFF1A2543),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (product.shortDescription.isNotEmpty)
                    _buildSectionCard(
                      icon: Icons.credit_card,
                      title: installmentPlanTitle,
                      child: Html(
                        data: product.shortDescription,
                        style: {
                          "p": Style(
                            fontSize: FontSize.medium,
                            color: Colors.grey[700],
                            lineHeight: LineHeight.em(1.5),
                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                            margin: Margins.zero, // <-- Corrected
                          ),
                          "ul": Style(
                            margin: Margins.zero, // <-- Corrected
                          ),
                          "li": Style(
                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                            margin: Margins.only(bottom: 6), // <-- Corrected
                          )
                        },
                      ),
                    ),
                  if (product.description.isNotEmpty)
                    _buildSectionCard(
                      icon: Icons.info_outline,
                      title: descriptionTitle,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Html(
                            data: _isDescriptionExpanded
                                ? product.description
                                : (product.description.length > 300
                                ? product.description.substring(0, 300) + "..."
                                : product.description),
                            style: {
                              "p": Style(
                                fontSize: FontSize.medium,
                                color: Colors.grey[700],
                                lineHeight: LineHeight.em(1.5),
                                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                margin: Margins.zero, // <-- Corrected
                              ),
                              "ul": Style(
                                margin: Margins.zero, // <-- Corrected
                              ),
                              "li": Style(
                                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                margin: Margins.only(bottom: 6), // <-- Corrected
                              )
                            },
                          ),
                          if (product.description.length > 300)
                            Align(
                              alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                                child: Text(
                                  _isDescriptionExpanded
                                      ? (isArabic ? "عرض أقل" : "Show Less")
                                      : (isArabic ? "عرض المزيد" : "Show More"),
                                  style: const TextStyle(
                                    color: Color(0xFF6FE0DA),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<Product>(
        future: _futureProduct,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final product = snapshot.data!;
          final quantity = cartProvider.getQuantity(product);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: quantity == 0
                  ? SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const ValueKey("addButton"),
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                  label: Text(
                    addToCartText,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2543),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(0.2),
                  ),
                  onPressed: () async {
                    final player = AudioPlayer();
                    await player.play(AssetSource('sounds/click.mp3'));
                    cartProvider.addToCart(product);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddedToCartScreen(product: product),
                        ),
                      );
                    });
                  },
                ),
              )
                  : Container(
                key: const ValueKey("quantityRow"),
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2543),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.white, size: 28),
                      onPressed: () {
                        cartProvider.decreaseQuantity(product);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                      onPressed: () {
                        cartProvider.addToCart(product);
                      },
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/cart'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6FE0DA),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_cart_checkout, size: 20, color: Color(0xFF1A2543)),
                              const SizedBox(width: 6),
                              Text(
                                isArabic ? "عرض السلة" : "View Cart",
                                style: const TextStyle(
                                  color: Color(0xFF1A2543),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductImageSection(Product product, BuildContext context) {
    final language = Provider.of<LocaleProvider>(context).locale.languageCode;
    final isArabic = language == 'ar';
    final productGalleryTitle = isArabic ? "معرض الصور" : "Product Gallery";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Hero(
          tag: 'productImage-${product.id}',
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenImageScreen(imageUrl: product.images[_currentImageIndex]),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 280,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: product.images.isNotEmpty
                    ? Image.network(
                  product.images[_currentImageIndex],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFF1A2543),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey)),
                )
                    : const Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (product.images.length > 1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                productGalleryTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2543),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: product.images.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final imageUrl = product.images[index];
                    final isSelected = index == _currentImageIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF6FE0DA) : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: const Color(0xFF6FE0DA).withOpacity(0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                                ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSectionCard({required IconData icon, required String title, required Widget child}) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF6FE0DA), size: 24),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2543),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1, color: Colors.black12),
            child,
          ],
        ),
      ),
    );
  }
}