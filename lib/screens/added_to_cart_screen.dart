import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/locale_provider.dart';

class AddedToCartScreen extends StatelessWidget {
  final Product product;

  const AddedToCartScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode == 'ar';

    final successTitle = isArabic ? "أحسنت الاختيار!" : "Excellent Choice!";
    final successMessage = isArabic
        ? "تمت إضافة '${product.name}' إلى سلتك بنجاح."
        : "'${product.name}' has been added to your cart successfully.";
    final goToCartText = isArabic ? "متابعة الطلب (الذهاب للسلة)" : "Proceed to Checkout (Go to Cart)";
    final goHomeText = isArabic ? "العودة للرئيسية" : "Back to Home";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA), // نفس لون خلفية التطبيق
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.check_circle_outline_rounded,
                color: const Color(0xFF6FE0DA), // اللون الثانوي الجذاب
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                successTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2543), // اللون الأساسي الداكن
                ),
              ),
              const SizedBox(height: 12),
              Text(
                successMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // عرض صورة مصغرة للمنتج لمزيد من التأكيد
              if (product.images.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      product.images.first,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const Spacer(),
              // الخيار الأول: متابعة الطلب (الأساسي)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2543), // اللون الأساسي
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 5,
                ),
                onPressed: () {
                  // إغلاق هذه الصفحة والانتقال لصفحة السلة
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/cart');
                },
                child: Text(goToCartText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              // الخيار الثاني: العودة للرئيسية (الثانوي)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A2543),
                  side: const BorderSide(color: Color(0xFF1A2543), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                onPressed: () {
                  // إغلاق كل الصفحات فوق الرئيسية والعودة لها
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(goHomeText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}