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
    // التحقق من لغة التطبيق الحالية
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    // تحديد رمز العملة حسب اللغة
    final String currencySymbol = isArabic ? "ر.ق" : "QAR";

    final cartProvider = Provider.of<CartProvider>(context);
    final int quantity = cartProvider.getQuantity(product);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: SizedBox(
        height: 260, // ارتفاع ثابت يناسب Grid و List
        child: Card(
          elevation: 3,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
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
                // صورة المنتج
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1.2, // تناسق مرن للصورة
                    child: product.images.isNotEmpty
                        ? Image.network(
                      product.images.first,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image,
                          size: 50, color: Colors.grey),
                    ),
                  ),
                ),

                // التفاصيل
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
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
                          ),
                        ),
                        const Spacer(),
                        // السعر
                        Text(
                          "${formatNumber(product.price)} $currencySymbol",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),
                        // زر الإضافة للسلة أو أدوات التحكم
                        Consumer<CartProvider>(
                          builder: (context, cartProvider, child) {
                            final int quantity =
                            cartProvider.getQuantity(product);
                            if (quantity == 0) {
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff1d0fe3),
                                  minimumSize: const Size.fromHeight(32),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50)),
                                ),
                                onPressed: () async {
                                  // 1. شغّل الصوت أولاً مباشرة
                                  final player = AudioPlayer();
                                  await player.play(AssetSource('sounds/click.mp3'));

                                  // 2. بعد الصوت، أضف المنتج للسلة
                                  cartProvider.addToCart(product);

                                  // 3. بعدين اعرض رسالة نجاح عادية
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isArabic
                                          ? "تم إضافة المنتج إلى السلة"
                                          : "Product added to the cart"),
                                    ),
                                  );
                                },

                                child: Text(
                                  isArabic ? "أضف للسلة" : "Add to cart",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                              );
                            } else {
                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xff1d0fe3),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove,
                                          color: Colors.white, size: 18),
                                      onPressed: () =>
                                          cartProvider.decreaseQuantity(product),
                                    ),
                                    Text(
                                      "$quantity",
                                      style:
                                      const TextStyle(color: Colors.white),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add,
                                          color: Colors.white, size: 18),
                                      onPressed: () =>
                                          cartProvider.addToCart(product),
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
