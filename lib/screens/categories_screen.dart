// lib/screens/categories_screen.dart
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../widgets/category_card.dart'; // تأكد أن هذا هو الودجت الذي تم تحسينه
import '../services/api_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<Category>> _categoriesFuture;
  late String _languageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // جلب كود اللغة بمجرد توفر الـ BuildContext
    _languageCode = Localizations.localeOf(context).languageCode;
    _fetchCategories(); // استدعاء دالة لجلب الأصناف
  }

  // دالة مخصصة لجلب الأصناف
  void _fetchCategories() {
    setState(() {
      _categoriesFuture = ApiService().getCategories(language: _languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    // تحديد ما إذا كانت اللغة عربية لضبط النصوص
    final isArabic = _languageCode == 'ar';

    return Scaffold(
      // خلفية بيضاء نظيفة للشاشة بالكامل
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isArabic ? 'الأصناف' : 'Categories',
          style: const TextStyle(
            fontSize: 22, // حجم أكبر قليلاً لعنوان أكثر بروزًا
            fontWeight: FontWeight.bold, // خط سميك للعنوان
            color: Colors.white, // لون أبيض ليتناسق مع خلفية الـ AppBar
          ),
        ),
        // إزالة الظل لإعطاء مظهر عصري ومسطح
        elevation: 0,
        // توسيط العنوان لتحسين التوازن البصري
        centerTitle: true,
        // لون الهوية الأزرق الداكن من التصميم
        backgroundColor: const Color(0xFF1A2543),
        // لون الأيقونات والنص الافتراضي في الـ AppBar
        foregroundColor: Colors.white,
        // يمكنك إضافة زر رجوع مخصص هنا إذا كانت الشاشة ليست هي الشاشة الرئيسية
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          // --- حالة التحميل (Loading State) ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                // لون مؤشر التحميل بلون الهوية ليتناسق بصريًا
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A2543)),
                strokeWidth: 4, // سمك أكبر قليلاً للمؤشر ليكون أكثر وضوحًا
              ),
            );
          }
          // --- حالة الخطأ (Error State) ---
          else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0), // إضافة مسافة داخلية لتحسين المظهر
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center, // توسيط المحتوى أفقياً
                  children: [
                    // أيقونة خطأ واضحة بحجم كبير ولون أحمر جذاب
                    const Icon(Icons.error_outline, size: 70, color: Colors.redAccent),
                    const SizedBox(height: 15),
                    Text(
                      isArabic
                          ? 'عذراً! لم نتمكن من تحميل الأصناف.'
                          : 'Oops! Failed to load categories.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isArabic
                          ? 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.'
                          : 'Please check your internet connection and try again.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _fetchCategories, // استدعاء دالة جلب الأصناف
                      icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
                      label: Text(
                        isArabic ? 'إعادة المحاولة' : 'Retry',
                        style: const TextStyle(color: Colors.white, fontSize: 17),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A2543), // لون الزر بلون الهوية
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // حواف دائرية أكثر وضوحًا
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                        elevation: 5, // إضافة ظل خفيف للزر
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          // --- حالة عدم وجود بيانات (No Data State) ---
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center, // توسيط المحتوى أفقياً
                  children: [
                    // أيقونة تدل على عدم وجود أصناف بلون الهوية
                    const Icon(Icons.category_outlined, size: 70, color: Color(0xFF1A2543)),
                    const SizedBox(height: 15),
                    Text(
                      isArabic
                          ? 'لا توجد أصناف متاحة حالياً.'
                          : 'No categories available.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isArabic
                          ? 'نحن نعمل على إضافة المزيد! تفضل بالعودة لاحقاً.'
                          : 'We are working on adding more! Please check back later.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          }

          // --- حالة عرض البيانات (Data Display State) ---
          final categories = snapshot.data!;
          return GridView.builder(
            // مسافة داخلية شاملة حول الـ GridView لتحسين المظهر
            padding: const EdgeInsets.all(20.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              // 3 أعمدة للشاشات الكبيرة، 2 للصغيرة لتحسين الاستجابة
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              // تعديل الـ AspectRatio ليناسب تصميم الـ CategoryCard المحسّن
              // (قد تحتاج لضبط هذه القيمة بعد رؤية تصميم CategoryCard)
              childAspectRatio: 0.9,
              // تباعد أفقي ورأسي بين عناصر الـ Grid
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return CategoryCard(category: categories[index]);
            },
          );
        },
      ),
    );
  }
}