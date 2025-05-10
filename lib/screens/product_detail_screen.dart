import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../Models/installment_plan.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../utils.dart';
import 'full_screen_image_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({Key? key, required this.productId}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final apiService = ApiService();
  late Future<Product> _futureProduct;
  bool _isCustomPlan = false;
  final TextEditingController _downPaymentController = TextEditingController();
  String? _downPaymentError;
  InstallmentPlan? _installmentPlan;

  bool _isExpanded = false; // <-- عشان نتحكم في عرض المزيد

  @override
  void initState() {
    super.initState();
    final language =
        Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    _futureProduct = apiService.getProductById(widget.productId, language: language);
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final language = Provider.of<LocaleProvider>(context).locale.languageCode;
    final isArabic = language == 'ar';

    final appBarTitle = isArabic ? "تفاصيل المنتج" : "Product Details";
    final addToCartText = isArabic ? "إضافة للسلة" : "Add to Cart";
    final snackBarText = isArabic ? "تم إضافة المنتج إلى السلة" : "Product added to cart";
    final installmentPlanTitle = isArabic ? "خطة التقسيط" : "Installment Plan";
    final descriptionTitle = isArabic ? "وصف المنتج" : "Product Description";
    final priceTitle = isArabic ? "السعر" : "Price";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
        backgroundColor: const Color(0xFF1d0fe3),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: FutureBuilder<Product>(
        future: _futureProduct,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final product = snapshot.data!;
          final priceText = isArabic
              ? "ر.ق ${formatNumber(product.price)}"
              : "QAR ${formatNumber(product.price)}";

          final double minDownPayment = product.price;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageScreen(imageUrl: product.images.first),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      product.images.first,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  product.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(Icons.price_change, color: Color(0xff1d0fe3)),
                    const SizedBox(width: 6),
                    Text(
                      "$priceTitle: ",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      priceText,
                      style: const TextStyle(fontSize: 18, color: Color(0xff1d0fe3), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.payment, color: Color(0xff1d0fe3)),
                            const SizedBox(width: 6),
                            Text(
                              installmentPlanTitle,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Html(
                          data: product.shortDescription.isNotEmpty
                              ? product.shortDescription
                              : (isArabic ? "<p>غير متوفر</p>" : "<p>Not available</p>"),
                        ),
                      ],
                    ),
                  ),
                ),

                Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.description, color: Color(0xff1d0fe3)),
                            const SizedBox(width: 6),
                            Text(
                              descriptionTitle,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // هنا نعرض جزء من الوصف فقط اذا ما كان مضغوط
                        Html(
                          data: _isExpanded
                              ? product.description
                              : (product.description.length > 300
                              ? product.description.substring(0, 300) + "..."
                              : product.description),
                        ),
                        // زر عرض المزيد أو عرض أقل
                        if (product.description.length > 300)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _isExpanded = !_isExpanded;
                                });
                              },
                              child: Text(
                                _isExpanded
                                    ? (isArabic ? "عرض أقل" : "Show Less")
                                    : (isArabic ? "عرض المزيد" : "Show More"),
                                style: const TextStyle(color: Color(0xff1d0fe3)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 80), // مساحة للزر السفلي
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xff1d0fe3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              elevation: 3,
            ),
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
            label: Text(
              addToCartText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            onPressed: () async {
              final player = AudioPlayer();
              await player.play(AssetSource('sounds/click.mp3'));

              cartProvider.addToCart(await _futureProduct);

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Color(0xff1d0fe3)),
                      const SizedBox(width: 8),
                      Text(isArabic ? 'تمت الإضافة' : 'Added to Cart'),
                    ],
                  ),
                  content: Text(
                    isArabic
                        ? 'تمت إضافة المنتج إلى السلة بنجاح.\nهل ترغب بمتابعة التسوق أو الذهاب إلى السلة؟'
                        : 'Product has been added to your cart.\nWould you like to continue shopping or go to your cart?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(isArabic ? 'متابعة التسوق' : 'Continue Shopping'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff1d0fe3)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushNamed(context, '/cart');
                      },
                      child: Text(
                        isArabic ? 'الذهاب للسلة' : 'Go to Cart',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

