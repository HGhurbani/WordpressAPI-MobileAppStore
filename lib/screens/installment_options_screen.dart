import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // لاستخدام HapticFeedback
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../utils.dart'; // تأكد أن هذه الدالة موجودة وتعمل بشكل صحيح لتنسيق الأرقام
import 'checkout_screen.dart'; // تأكد من مسار هذا الملف

// لتجريد HTML - يمكنك وضعها في ملف utils.dart إذا كنت تستخدمها في أماكن أخرى
import 'package:html/parser.dart' show parse;

class InstallmentOptionsScreen extends StatefulWidget {
  const InstallmentOptionsScreen({Key? key}) : super(key: key);

  @override
  State<InstallmentOptionsScreen> createState() => _InstallmentOptionsScreenState();
}

class _InstallmentOptionsScreenState extends State<InstallmentOptionsScreen> {
  // متغيرات الحالة
  String selectedPlan = 'default'; // 'default' أو 'custom'
  int customMonths = 2; // عدد الأشهر للخطة المخصصة
  double userDefinedFirstPayment = 0.0; // الدفعة الأولى التي يدخلها المستخدم

  // الألوان المستخدمة في الواجهة
  final Color primaryColor = const Color(0xFF1A2543); // أزرق داكن
  final Color accentColor = const Color(0xFF6FE0DA); // فيروزي

  // دالة لاستخلاص القيم الرقمية من النصوص التي قد تحتوي على تنسيق HTML أو مسافات
  double _extractFlexibleValue(String text, List<String> patterns) {
    // استخدم html parser لتجريد HTML بشكل موثوق
    final document = parse(text);
    final String cleanText = document.body?.text ?? text;

    for (var pattern in patterns) {
      final match = RegExp(pattern).firstMatch(cleanText);
      if (match != null && match.groupCount >= 1) {
        // إزالة الفواصل والنقاط التي قد تكون جزءًا من تنسيق الرقم
        final value = match.group(1)!.replaceAll(RegExp(r'[^\d.]'), '');
        return double.tryParse(value) ?? 0.0;
      }
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final isArabic = Provider.of<LocaleProvider>(context).locale.languageCode == 'ar';
    final items = cartProvider.items;

    // فصل المنتجات القابلة للتقسيط عن المنتجات النقدية
    final installmentItems = items.where((item) => item.product.shortDescription.isNotEmpty).toList();
    final cashItems = items.where((item) => item.product.shortDescription.isEmpty).toList();

    double cashTotal = cashItems.fold(0.0, (sum, item) => sum + item.product.price * item.quantity);

    double installmentFirstPayment = 0.0; // إجمالي الدفعة الأولى للمنتجات بالتقسيط
    double customPlanInstallmentTotal = 0.0; // إجمالي مبلغ التقسيط للخطة المخصصة
    double defaultPlanInstallmentTotal = 0.0; // إجمالي مبلغ التقسيط للخطة الافتراضية

    // حساب المجاميع من وصف المنتجات القابلة للتقسيط
    for (var item in installmentItems) {
      final desc = item.product.shortDescription;

      final firstPayment = _extractFlexibleValue(desc, [
        r'(?:المقدم|مقدم)[:\s]*([\d,\.]+)',
        r'(?:الدفعة\s*الأولى|دفعة\s*أولى)[:\s]*([\d,\.]+)',
      ]);

      final totalAmount = _extractFlexibleValue(desc, [
        r'إجمالي\s*المبلغ[:\s]*([\d,\.]+)',
        r'الإجمالي[:\s]*([\d,\.]+)',
        r'إجمالي\s*السعر[:\s]*([\d,\.]+)',
        r'المجموع[:\s]*([\d,\.]+)',
        r'إجمالي\s*الفاتورة[:\s]*([\d,\.]+)',
        r'الإجمالي\s*الكلي[:\s]*([\d,\.]+)',
      ]);

      final numInstallments = _extractFlexibleValue(desc, [
        r'عدد\s*الأقساط[:\s]*([\d]+)',
        r'(\d+)\s*أقساط',
      ]);

      final perInstallment = _extractFlexibleValue(desc, [
        r'قيمة\s*كل\s*قسط[:\s]*([\d,\.]+)',
        r'كل\s*قسط[:\s]*([\d,\.]+)',
      ]);

      // حساب إجمالي المبلغ إذا لم يكن متوفراً مباشرة (عدد الأقساط * قيمة القسط)
      final calculatedTotal = (totalAmount == 0 && numInstallments > 0 && perInstallment > 0)
          ? numInstallments * perInstallment
          : totalAmount;

      installmentFirstPayment += firstPayment * item.quantity;
      // إذا لم يتم تحديد calculatedTotal، استخدم 4 أضعاف الدفعة الأولى كافتراضي
      final defaultItemTotal = calculatedTotal > 0 ? calculatedTotal : firstPayment * 4;
      defaultPlanInstallmentTotal += defaultItemTotal * item.quantity;
      customPlanInstallmentTotal += calculatedTotal * item.quantity;
    }

    // الحد الأدنى للدفعة الأولى للخطة المخصصة يشمل أي منتجات نقدية
    double minFirstPaymentRequired = selectedPlan == 'custom'
        ? installmentFirstPayment + cashTotal
        : installmentFirstPayment;

    // حساب الرسوم الإضافية
    double extraCharge = (selectedPlan == 'custom' && customMonths == 6) ? 300.0 : 0.0;

    // السعر الإجمالي للمنتجات القابلة للتقسيط بناءً على الخطة المختارة
    double installmentTotalPrice = selectedPlan == 'custom'
        ? customPlanInstallmentTotal + extraCharge
        : defaultPlanInstallmentTotal + extraCharge;

    // عدد الأقساط بناءً على الخطة المختارة
    int numberOfInstallments = selectedPlan == 'default' ? 4 : customMonths;

    // الدفعة الأولى الفعلية: إما التي أدخلها المستخدم (إذا كانت صالحة) أو المحسوبة تلقائيًا
    double actualFirstPayment = (selectedPlan == 'custom' && userDefinedFirstPayment > 0)
        ? userDefinedFirstPayment.clamp(minFirstPaymentRequired, double.infinity) // ضمان ألا تقل عن الحد الأدنى
        : installmentFirstPayment;

    // المبلغ المتبقي بعد الدفعة الأولى
    double remainingInstallmentAmount = installmentTotalPrice - actualFirstPayment;
    if (remainingInstallmentAmount < 0) remainingInstallmentAmount = 0; // لا يمكن أن يكون المبلغ المتبقي سالباً

    // قيمة القسط الواحد
    double perInstallment = numberOfInstallments > 0 ? remainingInstallmentAmount / numberOfInstallments : 0;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isArabic ? "خيارات التقسيط" : "Installment Options"),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          // إزالة الزر الخلفي الافتراضي إذا لم يكن هناك حاجة له أو تخصيصه
          // leading: IconButton(
          //   icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          //   onPressed: () => Navigator.of(context).pop(),
          // ),
        ),
        body: Container(
          // خلفية متدرجة للجسم
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[50]!,
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // لجعل العناصر تمتد عرضياً
              children: [
                // قسم عرض المنتجات في السلة
                _buildSectionTitle(isArabic ? "المنتجات في السلة" : "Items in Cart", isArabic: isArabic),
                const SizedBox(height: 8),
                ...items.map((item) => _buildCartItemCard(item, isArabic, cartProvider)).toList(),

                const SizedBox(height: 20),
                const Divider(height: 1, color: Colors.grey),
                const SizedBox(height: 20),

                // قسم اختيار نوع الخطة
                _buildSectionTitle(isArabic ? "اختر نوع الخطة:" : "Choose Plan Type:", isArabic: isArabic),
                const SizedBox(height: 12),
                Center( // لتوسيط الـ SegmentedButton
                  child: SegmentedButton<String>(
                    segments: <ButtonSegment<String>>[
                      ButtonSegment<String>(
                        value: 'default',
                        label: Text(isArabic ? "الخطة الافتراضية" : "Default Plan"),
                        icon: const Icon(Icons.calendar_today_rounded),
                      ),
                      ButtonSegment<String>(
                        value: 'custom',
                        label: Text(isArabic ? "خطة مخصصة" : "Custom Plan"),
                        icon: const Icon(Icons.settings_rounded),
                      ),
                    ],
                    selected: <String>{selectedPlan},
                    onSelectionChanged: (Set<String> newSelection) {
                      HapticFeedback.lightImpact(); // اهتزاز خفيف
                      setState(() {
                        selectedPlan = newSelection.first;
                        // إعادة تعيين الدفعة الأولى المخصصة عند تغيير الخطة
                        if (selectedPlan == 'default') {
                          userDefinedFirstPayment = 0.0;
                        }
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      foregroundColor: primaryColor,
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor: primaryColor,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold,fontFamily: 'Cairo'),
                      side: BorderSide(color: primaryColor.withOpacity(0.5), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),

                if (selectedPlan == 'custom') ...[
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 20),

                  // قسم اختيار عدد الأشهر للخطة المخصصة
                  _buildSectionTitle(isArabic ? "اختر عدد الأشهر:" : "Choose number of months:", isArabic: isArabic),
                  const SizedBox(height: 12),
                  Center(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [2, 4, 6].map((month) {
                        final isSelected = customMonths == month;
                        return ChoiceChip(
                          label: Text('$month ${isArabic ? 'شهر' : 'Months'}'),
                          selected: isSelected,
                          onSelected: (_) {
                            HapticFeedback.lightImpact();
                            setState(() => customMonths = month);
                          },
                          selectedColor: accentColor.withOpacity(0.8),
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: isSelected ? primaryColor : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? primaryColor : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          elevation: isSelected ? 3 : 1,
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // قسم إدخال الدفعة الأولى المخصصة
                  _buildSectionTitle(
                    isArabic
                        ? "أدخل الدفعة الأولى (الحد الأدنى ${formatNumber(minFirstPaymentRequired)} ر.ق)"
                        : "Enter Down Payment (Min ${formatNumber(minFirstPaymentRequired)} QAR)",
                    isArabic: isArabic,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.money_rounded, color: accentColor),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        hintText: isArabic ? "أدخل الدفعة الأولى" : "Enter down payment",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none, // إزالة الحدود الصلبة
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: accentColor, width: 2), // حدود عند التركيز
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade300, width: 1), // حدود عندما يكون غير مركز
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val.replaceAll(',', ''));
                        setState(() {
                          userDefinedFirstPayment = parsed ?? 0.0;
                        });
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                const Divider(height: 1, color: Colors.grey),
                const SizedBox(height: 20),

                // قسم ملخص الخطة
                _buildSectionTitle(isArabic ? "ملخص الخطة" : "Plan Summary", isArabic: isArabic),
                const SizedBox(height: 12),
                _buildSummary(
                  isArabic: isArabic,
                  totalFirstPayment: actualFirstPayment + cashTotal,
                  totalInstallments: numberOfInstallments,
                  extraCharge: extraCharge,
                  totalInstallmentPrice: installmentTotalPrice,
                  perInstallment: perInstallment,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                ),

                const SizedBox(height: 30),
                // زر تأكيد الخطة
                ElevatedButton.icon(
                  label: Text(
                    isArabic ? "تأكيد الخطة والمتابعة" : "Confirm Plan & Proceed",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size.fromHeight(60), // زر أكبر
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0, // ظل أكبر للزر
                    shadowColor: primaryColor.withOpacity(0.5),
                  ),
                  onPressed: () {
                    HapticFeedback.heavyImpact(); // اهتزاز قوي عند التأكيد
                    if (selectedPlan == 'custom') {
                      if (userDefinedFirstPayment < minFirstPaymentRequired) {
                        // عرض تنبيه بشكل أفضل
                        _showInfoDialog(
                          context,
                          isArabic ? "تنبيه" : "Warning",
                          isArabic
                              ? "يرجى إدخال دفعة أولى لا تقل عن ${formatNumber(minFirstPaymentRequired)} ر.ق."
                              : "Please enter a down payment of at least ${formatNumber(minFirstPaymentRequired)} QAR.",
                          isArabic,
                        );
                        return;
                      }
                    }

                    // الانتقال إلى شاشة الدفع النهائية
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutScreen(
                          isCustomPlan: selectedPlan == 'custom',
                          downPayment: actualFirstPayment + cashTotal,
                          remainingAmount: remainingInstallmentAmount,
                          monthlyPayment: perInstallment,
                          numberOfInstallments: numberOfInstallments,
                          totalPrice: installmentTotalPrice + cashTotal, // السعر الإجمالي يشمل التقسيط والنقد
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ودجت لعرض المنتجات في السلة
  Widget _buildCartItemCard(CartItem item, bool isArabic, CartProvider cartProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0.5, // ظل أعمق
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.product.images.isNotEmpty
                    ? item.product.images.first
                    : 'https://via.placeholder.com/60', // حجم أكبر للصورة
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatNumber(item.product.price)} ${isArabic ? "ر.ق" : "QAR"} x ${item.quantity}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  if (item.product.shortDescription.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          isArabic ? "قابل للتقسيط" : "Installment Eligible",
                          style: TextStyle(fontSize: 11, color: Colors.green[800], fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 26),
              onPressed: () {
                HapticFeedback.lightImpact();
                cartProvider.removeItem(item.product.id.toString());
              },
              tooltip: isArabic ? "إزالة المنتج" : "Remove item",
            ),
          ],
        ),
      ),
    );
  }

  // ودجت لإنشاء عنوان قسم مع خط فاصل
  Widget _buildSectionTitle(String title, {required bool isArabic}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: primaryColor,
          ),
          textAlign: isArabic ? TextAlign.right : TextAlign.left,
        ),
        const SizedBox(height: 8),
        Container(
          width: 60, // طول الخط
          height: 3, // سمك الخط
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }

  // ودجت ملخص الخطة
  Widget _buildSummary({
    required bool isArabic,
    required double totalFirstPayment,
    required int totalInstallments,
    required double extraCharge,
    required double totalInstallmentPrice,
    required double perInstallment,
    required Color primaryColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRow(
            isArabic ? "الدفعة الأولى المطلوبة" : "Required First Payment",
            totalFirstPayment,
            isArabic,
            isHighlight: true, // تمييز الدفعة الأولى
          ),
          const Divider(height: 20, thickness: 0.8), // خط فاصل بين العناصر
          _summaryRow(
            isArabic ? "عدد الأقساط" : "Number of Installments",
            totalInstallments.toDouble(),
            isArabic,
            isMonths: true,
          ),
          if (extraCharge > 0)
            _summaryRow(
              isArabic ? "رسوم إضافية (لخطة 6 أشهر)" : "Extra Fee (for 6 Months Plan)",
              extraCharge,
              isArabic,
              isWarning: true, // تمييز الرسوم الإضافية
            ),
          _summaryRow(
            isArabic ? "إجمالي مبلغ التقسيط" : "Total Installment Amount",
            totalInstallmentPrice,
            isArabic,
          ),
          _summaryRow(
            isArabic ? "قيمة القسط الشهري" : "Monthly Installment Value",
            perInstallment,
            isArabic,
            isHighlight: true, // تمييز قيمة القسط
          ),
        ],
      ),
    );
  }

  // ودجت لإنشاء صف في الملخص
  Widget _summaryRow(String title, double value, bool isArabic, {bool isMonths = false, bool isHighlight = false, bool isWarning = false}) {
    String displayValue;
    if (isMonths) {
      displayValue = "${value.toInt()} ${isArabic ? "شهر" : "months"}";
    } else {
      displayValue = '${formatNumber(value)} ${isArabic ? "ر.ق" : "QAR"}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              fontSize: isHighlight ? 16 : 15,
              color: isWarning ? Colors.red[700] : primaryColor.withOpacity(0.9),
            ),
          ),
          Text(
            displayValue,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isHighlight ? 16 : 15,
              color: isHighlight ? accentColor : primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // دالة لعرض رسالة تنبيه منبثقة بشكل احترافي
  void _showInfoDialog(BuildContext context, String title, String message, bool isArabic) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Column(
          children: [
            Icon(Icons.info_outline, color: accentColor, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
            ),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isArabic ? "حسناً" : "OK",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}