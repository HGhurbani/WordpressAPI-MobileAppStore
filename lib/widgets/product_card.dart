import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../screens/product_detail_screen.dart';
import '../providers/cart_provider.dart';
import '../utils.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final String currencySymbol = isArabic ? "ر.ق" : "QAR";

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final int quantity = cartProvider.getQuantity(product);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Card(
        elevation: 0, // Increased elevation for a more premium feel
        shadowColor: Colors.grey.withOpacity(0.2), // Subtle shadow
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Slightly more rounded corners
        clipBehavior: Clip.antiAlias, // Ensures content respects rounded corners
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => ProductDetailScreen(productId: product.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Product Image with Overlay Ribbon ---
              _buildProductImage(context, isArabic),

              // --- Product Details ---
              _buildProductDetails(context, isArabic, currencySymbol),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context, bool isArabic) {
    final bool hasInstallment = product.shortDescription.isNotEmpty;

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1.1, // Slightly less tall to give more space for text
          child: product.images.isNotEmpty
              ? Image.network(
            product.images.first,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  color: const Color(0xFF6FE0DA), // Loading indicator color
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
            ),
          )
              : Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.image, size: 50, color: Colors.grey),
          ),
        ),
        Positioned(
          top: 10,
          left: isArabic ? null : 10,
          right: isArabic ? 10 : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Increased padding
            decoration: BoxDecoration(
              color: hasInstallment ? const Color(0xFF6FE0DA) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10), // More rounded corners for the tag
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              hasInstallment ? (isArabic ? "بالتقسيط" : "Installments") : (isArabic ? "كاش" : "Cash"),
              style: TextStyle(
                color: hasInstallment ? const Color(0xFF1A2543) : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 11, // Slightly smaller font for subtlety
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetails(BuildContext context, bool isArabic, String currencySymbol) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12), // Adjusted padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
          children: [
            // Product Name
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700, // Bolder for more emphasis
                fontSize: 15, // Slightly larger
                color: Color(0xFF1A2543),
                height: 1.3, // Line height for better readability
              ),
            ),
            const SizedBox(height: 8), // More space between name and price

            // Price
            Align(
              alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft, // Align price based on direction
              child: Text(
                "${formatNumber(product.price)} $currencySymbol",
                style: const TextStyle(
                  fontSize: 16, // Slightly larger price
                  color: Color(0xFF6FE0DA),
                  fontWeight: FontWeight.w900, // Even bolder
                  letterSpacing: 0.5, // Slightly increased letter spacing
                ),
              ),
            ),
            const Spacer(), // Pushes the button to the bottom

            // Add to Cart Button/Quantity Controls
            Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
                final int quantity = cartProvider.getQuantity(product);
                if (quantity == 0) {
                  return SizedBox(
                    height: 40, // Fixed height for consistency
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A2543),
                        foregroundColor: Colors.white, // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // Fully rounded button
                        ),
                        elevation: 2, // Slight elevation for the button
                        padding: EdgeInsets.zero, // Remove default padding
                      ),
                      onPressed: () async {
                        final player = AudioPlayer();
                        await player.play(AssetSource('sounds/click.mp3'));
                        cartProvider.addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isArabic
                                  ? "تم إضافة المنتج إلى السلة"
                                  : "Product added to the cart",
                            ),
                            duration: const Duration(seconds: 1), // Shorter duration
                            behavior: SnackBarBehavior.floating, // Floating snackbar
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_shopping_cart, size: 18), // Icon for add to cart
                          const SizedBox(width: 6),
                          Text(
                            isArabic ? "أضف للسلة" : "Add to Cart",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Container(
                    height: 40, // Fixed height
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2543),
                      borderRadius: BorderRadius.circular(8), // Fully rounded
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute space evenly
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 20),
                          onPressed: () => cartProvider.decreaseQuantity(product),
                          splashRadius: 20, // Visual feedback on tap
                        ),
                        Text(
                          "$quantity",
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                          onPressed: () => cartProvider.addToCart(product),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}