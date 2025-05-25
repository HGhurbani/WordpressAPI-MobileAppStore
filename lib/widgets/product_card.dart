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

    final cartProvider = Provider.of<CartProvider>(context);
    final int quantity = cartProvider.getQuantity(product);

    final bool hasInstallment = product.shortDescription.isNotEmpty;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: SizedBox(
        height: 280,
        child: Card(
          elevation: 3,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
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
                // ==== صورة المنتج مع شريط أعلى ====
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: AspectRatio(
                        aspectRatio: 1.2,
                        child: product.images.isNotEmpty
                            ? Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image, size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                    if (hasInstallment)
                      Positioned(
                        top: 8,
                        left: isArabic ? null : 8,
                        right: isArabic ? 8 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6FE0DA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isArabic ? "بالتقسيط" : "Installments",
                            style: const TextStyle(
                              color: Color(0xFF1A2543),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        top: 8,
                        left: isArabic ? null : 8,
                        right: isArabic ? 8 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isArabic ? "كاش" : "Cash",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // ==== التفاصيل ====
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // اسم المنتج
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1A2543),
                          ),
                        ),
                        const Spacer(),

                        // السعر
                        Text(
                          "${formatNumber(product.price)} $currencySymbol",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6FE0DA),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // زر أو أدوات السلة
                        Consumer<CartProvider>(
                          builder: (context, cartProvider, child) {
                            final int quantity = cartProvider.getQuantity(product);
                            if (quantity == 0) {
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A2543),
                                  minimumSize: const Size.fromHeight(34),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
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
                                    ),
                                  );
                                },
                                child: Text(
                                  isArabic ? "أضف للسلة" : "Add to Cart",
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              );
                            } else {
                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A2543),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                                      onPressed: () => cartProvider.decreaseQuantity(product),
                                    ),
                                    Text(
                                      "$quantity",
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                      onPressed: () => cartProvider.addToCart(product),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
