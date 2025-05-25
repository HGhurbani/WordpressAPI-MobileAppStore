import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/product.dart'; // تأكد من صحة هذا المسار
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../utils.dart';
import 'full_screen_image_screen.dart';
import 'added_to_cart_screen.dart'; // <--- (الخطوة 1) قم باستيراد الشاشة الجديدة

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({Key? key, required this.productId}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final apiService = ApiService();
  late Future<Product> _futureProduct;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    final language = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    _futureProduct = apiService.getProductById(widget.productId, language: language);
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A2543),
        foregroundColor: Colors.white,
        elevation: 1.5,
      ),
      body: FutureBuilder<Product>(
        future: _futureProduct,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Failed to load product."));
          }

          final product = snapshot.data!;
          final priceText = isArabic
              ? "ر.ق ${formatNumber(product.price)}"
              : "QAR ${formatNumber(product.price)}";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageScreen(imageUrl: product.images.first),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      product.images.first,
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2543),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.price_change, color: Color(0xFF6FE0DA)),
                    const SizedBox(width: 6),
                    Text(
                      "$priceTitle: ",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      priceText,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF1A2543),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (product.images.length > 1)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? "معرض الصور" : "Product Gallery",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2543),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: product.images.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final imageUrl = product.images[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenImageScreen(imageUrl: imageUrl),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrl,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  icon: Icons.payment,
                  title: installmentPlanTitle,
                  child: Html(
                    data: product.shortDescription.isNotEmpty
                        ? product.shortDescription
                        : (isArabic ? "<p>غير متوفر</p>" : "<p>Not available</p>"),
                  ),
                ),
                _buildSectionCard(
                  icon: Icons.description,
                  title: descriptionTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Html(
                        data: _isExpanded
                            ? product.description
                            : (product.description.length > 300
                            ? product.description.substring(0, 300) + "..."
                            : product.description),
                      ),
                      if (product.description.length > 300)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => setState(() => _isExpanded = !_isExpanded),
                            child: Text(
                              _isExpanded
                                  ? (isArabic ? "عرض أقل" : "Show Less")
                                  : (isArabic ? "عرض المزيد" : "Show More"),
                              style: const TextStyle(color: Color(0xFF6FE0DA)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
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

          return Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
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
                    shadowColor: Colors.black.withOpacity(0.15),
                  ),
                  onPressed: () async {
                    final player = AudioPlayer();
                    await player.play(AssetSource('sounds/click.mp3'));

                    cartProvider.addToCart(product);
                    setState(() {});

                    // <--- (الخطوة 2) استبدال AlertDialog بالانتقال إلى الشاشة الجديدة
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddedToCartScreen(product: product),
                      ),
                    );
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
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.white, size: 28),
                      onPressed: () {
                        cartProvider.decreaseQuantity(product);
                        setState(() {});
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                      onPressed: () {
                        cartProvider.addToCart(product);
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/cart'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6FE0DA),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shopping_cart_checkout, size: 20, color: Colors.black87),
                            const SizedBox(width: 6),
                            Text(
                              isArabic ? "السلة" : "Cart",
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                            ),
                          ],
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

  Widget _buildSectionCard({required IconData icon, required String title, required Widget child}) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF6FE0DA)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2543),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}