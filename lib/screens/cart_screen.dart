import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/user_provider.dart';

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
    final emptyCartText = isArabic ? "السلة فارغة" : "Cart is empty";
    final quantityText = isArabic ? "الكمية" : "Qty";
    final priceText = isArabic ? "ر.ق" : "QAR";
    final checkoutText = isArabic
        ? "إتمام الشراء - المجموع: $priceText ${cartProvider.totalAmount.toStringAsFixed(2)}"
        : "Checkout - Total: $priceText ${cartProvider.totalAmount.toStringAsFixed(2)}";

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
        backgroundColor: const Color(0xFF1d0fe3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: items.isEmpty
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                emptyCartText,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        )

            : Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final cartItem = items[index];
                  final product = cartItem.product;

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
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
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "$priceText ${product.price.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (cartItem.installmentPlan != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1d0fe3).withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isArabic ? "خطة التقسيط" : "Installment Plan",
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${isArabic ? 'النوع: ' : 'Type: '}${cartItem.installmentPlan!.type == 'custom' ? (isArabic ? 'مخصص' : 'Custom') : (isArabic ? 'قياسي' : 'Standard')}",
                                        ),
                                        if (cartItem.installmentPlan!.type == 'custom') ...[
                                          Text(
                                            "${isArabic ? 'الدفعة الأولى: ' : 'Down Payment: '}$priceText ${cartItem.installmentPlan!.downPayment}",
                                          ),
                                          Text(
                                            "${isArabic ? 'المبلغ المتبقي: ' : 'Remaining: '}$priceText ${cartItem.installmentPlan!.remainingAmount}",
                                          ),
                                          Text(
                                            "${isArabic ? 'القسط الشهري: ' : 'Monthly: '}$priceText ${cartItem.installmentPlan!.monthlyPayment}",
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(quantityText),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1d0fe3).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: () {
                                              cartProvider.decreaseQuantity(product);
                                            },
                                          ),
                                          Text('${cartItem.quantity}'),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () {
                                              cartProvider.increaseQuantity(product);
                                            },
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
                            onPressed: () {
                              cartProvider.removeFromCart(product);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1d0fe3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/checkout');
                },
                child: Text(
                  checkoutText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
