import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../utils.dart';
import 'checkout_screen.dart';

class InstallmentOptionsScreen extends StatefulWidget {
  const InstallmentOptionsScreen({Key? key}) : super(key: key);

  @override
  State<InstallmentOptionsScreen> createState() => _InstallmentOptionsScreenState();
}

class _InstallmentOptionsScreenState extends State<InstallmentOptionsScreen> {
  String selectedPlan = 'default';
  int customMonths = 2;
  double userDefinedFirstPayment = 0.0;

  final Color primaryColor = const Color(0xFF1A2543);
  final Color accentColor = const Color(0xFF6FE0DA);

  double _extractFlexibleValue(String text, List<String> patterns) {
    for (var pattern in patterns) {
      final match = RegExp(pattern).firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final value = match.group(1)!.replaceAll(',', '');
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

    final installmentItems = items.where((item) => item.product.shortDescription.isNotEmpty).toList();
    final cashItems = items.where((item) => item.product.shortDescription.isEmpty).toList();

    double cashTotal = cashItems.fold(0.0, (sum, item) => sum + item.product.price * item.quantity);

    double installmentFirstPayment = 0.0;
    double customTotal = 0.0;
    double defaultTotal = 0.0;

    String _stripHtml(String htmlText) {
      final document = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
      final entities = RegExp(r'&[^;\s]+;', multiLine: true, caseSensitive: false);
      return htmlText
          .replaceAll(document, '')
          .replaceAll(entities, '')
          .replaceAll('\n', ' ')
          .replaceAll('\r', '')
          .trim();
    }

    for (var item in installmentItems) {
      final desc = _stripHtml(item.product.shortDescription);

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

      final calculatedTotal = (totalAmount == 0 && numInstallments > 0 && perInstallment > 0)
          ? numInstallments * perInstallment
          : totalAmount;

      installmentFirstPayment += firstPayment * item.quantity;
      final defaultItemTotal = calculatedTotal > 0 ? calculatedTotal : firstPayment * 4;
      defaultTotal += defaultItemTotal * item.quantity;
      customTotal += calculatedTotal * item.quantity;
    }

    double minFirstPayment = installmentFirstPayment;


    double extraCharge = (selectedPlan == 'custom' && customMonths == 6) ? 300.0 : 0.0;
    double installmentTotalPrice = selectedPlan == 'custom'
        ? customTotal + extraCharge
        : defaultTotal + extraCharge;

    int numberOfInstallments = selectedPlan == 'default' ? 4 : customMonths;
    double actualFirstPayment = selectedPlan == 'custom'
        ? (userDefinedFirstPayment > 0 ? userDefinedFirstPayment : installmentFirstPayment)
        : installmentFirstPayment;
    double remainingInstallmentAmount = installmentTotalPrice - actualFirstPayment;
    double perInstallment = numberOfInstallments > 0 ? remainingInstallmentAmount / numberOfInstallments : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? "خيارات التقسيط" : "Installment Options"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...items.map((item) => Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    item.product.images.isNotEmpty
                        ? item.product.images.first
                        : 'https://via.placeholder.com/50',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${formatNumber(item.product.price)} ${isArabic ? "ر.ق" : "QAR"} x ${item.quantity}'),
                    if (item.product.shortDescription.isNotEmpty)
                      Text(
                        isArabic ? "قابل للتقسيط" : "Installment Eligible",
                        style: TextStyle(fontSize: 12, color: Colors.green[700]),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    cartProvider.removeItem(item.product.id.toString());
                  },
                ),
              ),
            )),

            const Divider(),

            Text(
              isArabic ? "اختر نوع الخطة:" : "Choose Plan Type:",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            ToggleButtons(
              isSelected: [selectedPlan == 'default', selectedPlan == 'custom'],
              onPressed: (index) {
                setState(() {
                  selectedPlan = index == 0 ? 'default' : 'custom';
                });
              },
              borderRadius: BorderRadius.circular(10),
              selectedColor: Colors.white,
              fillColor: primaryColor,
              color: primaryColor,
              constraints: const BoxConstraints(minHeight: 40, minWidth: 150),
              children: [
                Text(isArabic ? "الخطة الافتراضية" : "Default Plan"),
                Text(isArabic ? "خطة مخصصة" : "Custom Plan"),
              ],
            ),

            if (selectedPlan == 'custom') ...[
              const SizedBox(height: 16),
              Text(
                isArabic ? "اختر عدد الأشهر:" : "Choose number of months:",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [2, 4, 6].map((month) {
                  final isSelected = customMonths == month;
                  return ChoiceChip(
                    label: Text('$month'),
                    selected: isSelected,
                    onSelected: (_) => setState(() => customMonths = month),
                    selectedColor: accentColor,
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isSelected ? primaryColor : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                isArabic
                    ? "أدخل الدفعة الأولى (الحد الأدنى ${formatNumber(minFirstPayment)} ر.ق)"
                    : "Enter Down Payment (Min ${formatNumber(minFirstPayment)} QAR)",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    hintText: isArabic ? "مثال: 500" : "e.g. 500",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryColor, width: 2),
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

            const Divider(),

            _buildSummary(
              isArabic: isArabic,
              totalFirstPayment: actualFirstPayment + cashTotal,
              totalInstallments: numberOfInstallments,
              extraCharge: extraCharge,
              totalInstallmentPrice: installmentTotalPrice,
              perInstallment: perInstallment,
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                if (selectedPlan == 'custom') {
                  if (userDefinedFirstPayment == 0.0 || userDefinedFirstPayment < minFirstPayment) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(isArabic ? "تنبيه" : "Warning"),
                        content: Text(isArabic
                            ? "يرجى إدخال دفعة أولى لا تقل عن ${formatNumber(minFirstPayment)} ر.ق"
                            : "Please enter a down payment of at least ${formatNumber(minFirstPayment)} QAR."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(isArabic ? "حسناً" : "OK"),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(
                      isCustomPlan: selectedPlan == 'custom',
                      downPayment: actualFirstPayment + cashTotal,
                      remainingAmount: remainingInstallmentAmount,
                      monthlyPayment: perInstallment,
                      numberOfInstallments: numberOfInstallments,
                      totalPrice: installmentTotalPrice + cashTotal,
                    ),
                  ),
                );
              },

              child: Text(
                isArabic ? "تأكيد الخطة" : "Confirm Plan",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary({
    required bool isArabic,
    required double totalFirstPayment,
    required int totalInstallments,
    required double extraCharge,
    required double totalInstallmentPrice,
    required double perInstallment,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? "ملخص الخطة" : "Plan Summary",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _summaryRow(isArabic ? "الدفعة الأولى" : "First Payment", totalFirstPayment),
          _summaryRow(isArabic ? "عدد الأقساط" : "Number of Installments", totalInstallments.toDouble()),
          if (extraCharge > 0)
            _summaryRow(isArabic ? "رسوم إضافية (6 أشهر)" : "Extra Fee (6 Months)", extraCharge),
          _summaryRow(isArabic ? "السعر الإجمالي" : "Total Price", totalInstallmentPrice),
          _summaryRow(isArabic ? "قيمة كل قسط" : "Each Installment", perInstallment),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, double value) {
    String displayValue;
    if (title.contains("عدد") || title.contains("Installments")) {
      displayValue = "${value.toInt()} ${title.contains("شهر") || title.contains("عدد") ? "شهر" : "months"}";
    } else {
      displayValue = '${formatNumber(value)} ر.ق';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(displayValue, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
