import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../utils.dart';
import '../models/product.dart'; // Make sure Product model is imported
import 'checkout_screen.dart';

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
    final quantityText = isArabic ? "الكمية" : "Qty";
    final priceText = isArabic ? "ر.ق" : "QAR";
    final checkoutText = isArabic
        ? "اختيار خطة الدفع (التالي)"
        : "Choose Payment Plan (Next)";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A2543),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: items.isEmpty
            ? _buildEmptyCartSection(context, isArabic)
            : Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final cartItem = items[index];
                  final product = cartItem.product;

                  return Dismissible(
                    key: ValueKey(product.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red.shade600,
                      child: const Icon(Icons.delete_forever, color: Colors.white, size: 30),
                    ),
                    confirmDismiss: (direction) async {
                      return await _showDeleteConfirmationDialog(context, product, cartProvider, isArabic);
                    },
                    onDismissed: (direction) {
                      // Action already handled by confirmDismiss, but good to have
                      // cartProvider.removeFromCart(product);
                    },
                    child: CartItemCard(
                      product: product,
                      quantity: cartItem.quantity,
                      isArabic: isArabic,
                      priceText: priceText,
                      quantityText: quantityText,
                      onRemove: () {
                        if (cartItem.quantity == 1) {
                          _showDeleteConfirmationDialog(context, product, cartProvider, isArabic);
                        } else {
                          cartProvider.decreaseQuantity(product);
                        }
                      },
                      onAdd: () => cartProvider.increaseQuantity(product),
                      onDelete: () => _showDeleteConfirmationDialog(context, product, cartProvider, isArabic),
                    ),
                  );
                },
              ),
            ),
            // Removed the _buildCartSummary section here
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/main');
                      },
                      icon: Icon(
                        isArabic ? Icons.arrow_back : Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        isArabic ? "الرجوع للتسوق" : "Back to Shopping",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6FE0DA),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ),
                _buildCheckoutButton(context, checkoutText, cartProvider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Empty Cart Section ---
  Widget _buildEmptyCartSection(BuildContext context, bool isArabic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF6FE0DA).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isArabic ? "سلتك فارغة!" : "Your Cart is Empty!",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2543),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            isArabic
                ? "يبدو أنك لم تضف أي منتجات للسلة بعد.\nابدأ التسوق واكتشف منتجاتنا المميزة!"
                : "Looks like you haven't added any products to your cart yet.\nStart shopping and discover our amazing products!",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6FE0DA),
                foregroundColor: const Color(0xFF1A2543),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/main');
              },
              icon: Icon(
                isArabic ? Icons.arrow_forward : Icons.shopping_bag_outlined,
                size: 20,
              ),
              label: Text(
                isArabic ? "ابدأ التسوق الآن" : "Start Shopping Now",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Removed the _buildCartSummary method as it's no longer needed

  // --- Checkout Button ---
  Widget _buildCheckoutButton(
      BuildContext context, String label, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A2543),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.2),
        ),
        onPressed: () {
          final items = cartProvider.items;
          if (items.isEmpty) {
            return;
          }

          final isCashOrder =
              items.every((item) => item.product.shortDescription.trim().isEmpty);

          if (isCashOrder) {
            final totalAmount = cartProvider.totalAmount;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CheckoutScreen(
                  isCashOrder: true,
                  totalPrice: totalAmount,
                  downPayment: totalAmount,
                  remainingAmount: 0,
                  monthlyPayment: 0,
                  numberOfInstallments: 0,
                  isCustomPlan: false,
                ),
              ),
            );
          } else {
            Navigator.pushNamed(context, '/installment-options');
          }
        },
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- Delete Confirmation Dialog ---
  Future<bool?> _showDeleteConfirmationDialog(
      BuildContext context, Product product, CartProvider cartProvider, bool isArabic) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isArabic ? "تأكيد الحذف" : "Confirm Deletion",
          style: const TextStyle(color: Color(0xFF1A2543), fontWeight: FontWeight.bold),
        ),
        content: Text(
          isArabic
              ? "هل أنت متأكد أنك تريد حذف \"${product.name}\" من السلة؟"
              : "Are you sure you want to remove \"${product.name}\" from the cart?",
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: Text(isArabic ? "إلغاء" : "Cancel", style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final player = AudioPlayer();
              await player.play(AssetSource('sounds/delete.mp3'));
              cartProvider.removeFromCart(product);
              Navigator.of(ctx).pop(true);
            },
            child: Text(isArabic ? "حذف" : "Delete", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// --- Extracted Cart Item Card Widget ---
class CartItemCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final bool isArabic;
  final String priceText;
  final String quantityText;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  const CartItemCard({
    Key? key,
    required this.product,
    required this.quantity,
    required this.isArabic,
    required this.priceText,
    required this.quantityText,
    required this.onRemove,
    required this.onAdd,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayPrice = formatNumber(product.price);
    // Removed itemTotalPrice as it's no longer needed for display

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: product.images.isNotEmpty
                    ? Image.network(
                  product.images.first,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  ),
                )
                    : Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),

              // Product Details (Name, Price, Quantity Controls)
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
                        fontSize: 17,
                        color: Color(0xFF1A2543),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price per item
                    Text(
                      isArabic ? "السعر: $priceText $displayPrice" : "Price: $priceText $displayPrice",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    // Removed the "Total Price for this item" (Subtotal) line
                    const SizedBox(height: 10),
                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2543),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildQuantityButton(
                            icon: Icons.remove,
                            onPressed: onRemove,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$quantity',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildQuantityButton(
                            icon: Icons.add,
                            onPressed: onAdd,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Delete button on the far end
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
                onPressed: onDelete,
                tooltip: isArabic ? "حذف المنتج" : "Remove item",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}