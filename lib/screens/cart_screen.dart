// lib/screens/cart_screen.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/user_provider.dart';
import '../utils.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool isCustomPlan = false;
  final TextEditingController downPaymentController = TextEditingController();
  String? downPaymentError;



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
    final checkoutText = isArabic ? "التالي" : "Next";


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
                  final plan = cartItem.installmentPlan;

                  final isCustom = plan?.type == 'custom';
                  final displayPrice = isCustom
                      ? formatNumber(plan!.downPayment)
                      : formatNumber(product.price);


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
                                  "$priceText $displayPrice",
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                if (plan != null) ...[
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
                                          "${isArabic ? 'النوع: ' : 'Type: '}${isCustom ? (isArabic ? 'مخصص' : 'Custom') : (isArabic ? 'قياسي' : 'Standard')}",
                                        ),
                                        if (isCustom) ...[
                                          Text(
                                            "${isArabic ? 'الدفعة الأولى: ' : 'Down Payment: '}$priceText ${formatNumber(plan.downPayment)}",
                                          ),
                                          Text(
                                            "${isArabic ? 'المبلغ المتبقي: ' : 'Remaining: '}$priceText ${formatNumber(plan.remainingAmount)}",
                                          ),
                                          Text(
                                            "${isArabic ? 'القسط الشهري: ' : 'Monthly: '}$priceText ${formatNumber(plan.monthlyPayment)}",
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
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: Text(
                                    isArabic ? "تأكيد الحذف" : "Confirm Deletion",
                                  ),
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
                                      child: Text(
                                        isArabic ? "حذف" : "Delete",
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      onPressed: () async {
                                        // تشغيل صوت الحذف أولاً
                                        final player = AudioPlayer();
                                         player.play(AssetSource('sounds/delete.mp3'));

                                        // ثم تنفيذ حذف المنتج
                                        cartProvider.removeFromCart(product);

                                        Navigator.of(ctx).pop();
                                      },

                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        ],
                      ),
                    ),
                  );
                },

              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    backgroundColor: Colors.white,
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => Padding(
                      padding: MediaQuery.of(context).viewInsets,
                      child: StatefulBuilder(
                        builder: (context, setModalState) {
                          return buildInstallmentSection(cartProvider, isArabic, setModalState);
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xff1d0fe3), width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payment, color: Color(0xff1d0fe3)),
                      const SizedBox(width: 10),
                      Text(
                        isArabic ? 'خيارات التقسيط' : 'Installment Options',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1d0fe3),
                        ),
                      ),
                    ],
                  ),
                ),
              )

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
                  final double installmentTotal = cartProvider.items
                      .where((item) => item.product.shortDescription.trim().isNotEmpty)
                      .fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));

                  final double cashTotal = cartProvider.items
                      .where((item) => item.product.shortDescription.trim().isEmpty)
                      .fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));

                  final double minDownPayment = installmentTotal;
                  final double enteredDownPayment = double.tryParse(downPaymentController.text) ?? 0;

                  if (isCustomPlan) {
                    if (enteredDownPayment < minDownPayment) {
                      setState(() {
                        downPaymentError = isArabic
                            ? "الدفعة الأولى أقل من المسموح (${minDownPayment.toStringAsFixed(2)} ر.ق)"
                            : "Down payment is less than allowed (${minDownPayment.toStringAsFixed(2)} QAR)";
                      });

                      // 👇👇👇 أضف هذا الجزء الجديد هنا 👇👇👇
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red.shade600,
                          content: Text(
                            isArabic
                                ? "الرجاء إدخال دفعة أولى لا تقل عن ${minDownPayment.toStringAsFixed(2)} ر.ق"
                                : "Please enter a down payment not less than ${minDownPayment.toStringAsFixed(2)} QAR",
                            style: const TextStyle(color: Colors.white),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      // 👆👆👆 نهاية الإضافة 👆👆👆

                      return;
                    }
                  }

                  Navigator.pushNamed(context, '/checkout', arguments: {
                    'isCustomPlan': isCustomPlan,
                    'downPayment': enteredDownPayment,
                  });
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
  Widget buildInstallmentSection(CartProvider cartProvider, bool isArabic, void Function(void Function()) setModalState) {
    final double installmentTotal = cartProvider.items
        .where((item) => item.product.shortDescription.trim().isNotEmpty)
        .fold(0.0, (sum, item) => sum + item.product.price * item.quantity);

    final double cashTotal = cartProvider.items
        .where((item) => item.product.shortDescription.trim().isEmpty)
        .fold(0.0, (sum, item) => sum + item.product.price * item.quantity);

    final double fullTotal = installmentTotal * 5 + cashTotal;
    final double minDownPayment = installmentTotal;

    double? customDownPayment = double.tryParse(downPaymentController.text);
    double monthlyPayment = ((installmentTotal * 5) - (customDownPayment ?? 0)) / 4;

    if (installmentTotal == 0) return const SizedBox();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // شريط السحب العلوي
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // عنوان رئيسي
            Row(
              children: [
                const Icon(Icons.payment, color: Color(0xFF1d0fe3)),
                const SizedBox(width: 8),
                Text(
                  isArabic ? "خيارات التقسيط" : "Installment Options",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // وصف مختصر
            Text(
              isArabic
                  ? "اختر الخطة الافتراضية لتقسيط الجهاز حسب السياسة المحددة، أو اختر خطة مخصصة وأدخل الدفعة الأولى المناسبة لك وسيتم توزيع المتبقي على ٤ دفعات شهرية متساوية."
                  : "Choose the default plan as per the policy, or select a custom plan and enter your own down payment to split the rest into 4 equal monthly installments.",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            // الخيارات
            RadioListTile<bool>(
              value: false,
              groupValue: isCustomPlan,
              activeColor: const Color(0xFF1d0fe3),
              title: Row(
                children: [
                  const Icon(Icons.auto_mode, size: 20, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(isArabic ? "الخطة الافتراضية" : "Default Plan"),
                ],
              ),
              onChanged: (value) {
                setModalState(() {
                  isCustomPlan = value!;
                  downPaymentController.clear();
                  downPaymentError = null;
                });
              },

            ),
            RadioListTile<bool>(
              value: true,
              groupValue: isCustomPlan,
              activeColor: const Color(0xFF1d0fe3),
              title: Row(
                children: [
                  const Icon(Icons.edit, size: 20, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(isArabic ? "خطة مخصصة" : "Custom Plan"),
                ],
              ),
              onChanged: (value) {
                setModalState(() {
                  isCustomPlan = value!;
                  downPaymentController.clear();
                  downPaymentError = null;
                });
              },

            ),

            // الحقل عند اختيار الخطة المخصصة
            if (isCustomPlan) ...[
              const SizedBox(height: 10),
              TextField(
                controller: downPaymentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(Icons.payments_outlined),
                  labelText: isArabic ? "الدفعة الأولى" : "Down Payment",
                  hintText: isArabic
                      ? "الحد الأدنى ${formatNumber(minDownPayment)}"
                      : "Minimum ${formatNumber(minDownPayment)}",
                  errorText: downPaymentError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (val) {
                  final double? value = double.tryParse(val);
                  setModalState(() {
                    if (value == null) {
                      downPaymentError = isArabic
                          ? "يرجى إدخال رقم صالح"
                          : "Enter a valid number";
                    } else if (value < minDownPayment) {
                      downPaymentError = isArabic
                          ? "الحد الأدنى ${formatNumber(minDownPayment)}"
                          : "Minimum ${formatNumber(minDownPayment)}";
                    } else {
                      downPaymentError = null;
                    }
                  });
                },

              ),
            ],

            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 10),

            // تفاصيل الدفع
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isArabic ? "تفاصيل الدفع:" : "Payment Summary:",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            if (!isCustomPlan)
              Text(
                isArabic
                    ? "تم اعتماد خطة التقسيط الموجودة في تفاصيل المنتج."
                    : "The installment plan from the product details has been applied.",
                style: const TextStyle(color: Colors.black87),
              )
            else ...[
              Row(
                children: [
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    isArabic
                        ? "إجمالي الدفعة الأولى: ${formatNumber((customDownPayment ?? 0) + cashTotal)} ر.ق"
                        : "Down Payment Total: ${formatNumber((customDownPayment ?? 0) + cashTotal)} QAR",
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.date_range, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    isArabic
                        ? "القسط الشهري (٤ شهور): ${formatNumber(monthlyPayment)} ر.ق"
                        : "Monthly (x4): ${formatNumber(monthlyPayment)} QAR",
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Text(
              isArabic
                  ? "إجمالي السعر الكامل: ${formatNumber(fullTotal)} ر.ق"
                  : "Full Total: ${formatNumber(fullTotal)} QAR",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }


}
