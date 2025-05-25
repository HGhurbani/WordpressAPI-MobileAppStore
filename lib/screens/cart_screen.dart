import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../utils.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final items = cartProvider.items;

    final localeProvider = Provider.of<LocaleProvider>(context);
    final language = localeProvider.locale.languageCode;
    final isArabic = language == 'ar';

    final appBarTitle = isArabic ? "سلة المشتريات" : "Cart";
    final emptyCartText = isArabic ? "سلتك فارغة" : "Your cart is empty";
    final quantityText = isArabic ? "الكمية" : "Qty";
    final priceText = isArabic ? "ر.ق" : "QAR";
    final checkoutText = isArabic ? "التالي" : "Next";

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A2543),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: items.isEmpty
            ? _buildEmptyCart(emptyCartText)
            : Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final cartItem = items[index];
                  final product = cartItem.product;
                  final displayPrice = formatNumber(product.price);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: product.images.isNotEmpty
                                ? Image.network(
                              product.images.first,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1A2543),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "$priceText $displayPrice",
                                  style: const TextStyle(color: Color(0xFF6FE0DA)),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      quantityText,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6FE0DA).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: () {
                                              if (cartItem.quantity == 1) {
                                                _showDeleteDialog(context, product, cartProvider, isArabic, checkEmptyCartAfter: true);
                                              } else {
                                                cartProvider.decreaseQuantity(product);
                                              }
                                            },
                                          ),

                                          Text('${cartItem.quantity}'),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () => cartProvider.increaseQuantity(product),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteDialog(context, product, cartProvider, isArabic, checkEmptyCartAfter: true),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildCheckoutButton(context, checkoutText),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart(String emptyCartText) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            emptyCartText,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A2543),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/installment-options');
        },
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, product, cartProvider, bool isArabic, {bool checkEmptyCartAfter = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(isArabic ? "تأكيد الحذف" : "Confirm Deletion"),
        content: Text(
          isArabic
              ? "هل أنت متأكد أنك تريد حذف هذا المنتج من السلة؟"
              : "Are you sure you want to remove this product from the cart?",
        ),
        actions: [
          TextButton(
            child: Text(isArabic ? "إلغاء" : "Cancel"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final player = AudioPlayer();
              await player.play(AssetSource('sounds/delete.mp3'));
              cartProvider.removeFromCart(product);
              Navigator.of(ctx).pop();

              if (checkEmptyCartAfter && cartProvider.items.isEmpty) {
                Navigator.of(context).pushReplacementNamed('/main');
              }
            },
            child: Text(isArabic ? "حذف" : "Delete", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

}
