// lib/screens/checkout_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

extension ContextExtensions on BuildContext {
  bool get isAr => Provider.of<LocaleProvider>(this).locale.languageCode == 'ar';
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  bool _loading = false;

  final _noteController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _residentInQatar;
  String? _hasChecks;
  String? _canObtainChecks;
  bool isCustomPlan = false;
  final TextEditingController downPaymentController = TextEditingController();




  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isLoggedIn) {
        setState(() {
          _emailController.text = userProvider.user?.email ?? '';
          _phoneController.text = userProvider.user?.phone ?? '';
          _fullNameController.text = userProvider.user?.username ?? '';
        });
      }

      // ✅ هنا نستقبل البيانات من السلة فقط مرة واحدة
      final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (arguments != null) {
        setState(() {
          isCustomPlan = arguments['isCustomPlan'] ?? false;
          downPaymentController.text = (arguments['downPayment']?.toString() ?? '');
        });
      }
    });
  }


  Widget build(BuildContext context) {
    String getCurrencyName(bool isAr) {
      return isAr ? "ريال قطري" : "Qatari Riyal";
    }

    final isLoggedIn = Provider.of<UserProvider>(context).isLoggedIn;
    final lang = Provider.of<LocaleProvider>(context).locale.languageCode;
    final isAr = lang == 'ar';
    final cartItems = Provider.of<CartProvider>(context).items;

    final double installmentProductsTotal = cartItems
        .where((item) => item.product.shortDescription.trim().isNotEmpty)
        .fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));

    final double cashProductsTotal = cartItems
        .where((item) => item.product.shortDescription.trim().isEmpty)
        .fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));

    final double downPaymentValue = double.tryParse(downPaymentController.text) ?? 0;

    final double totalPrice = isCustomPlan
        ? downPaymentValue + cashProductsTotal
        : installmentProductsTotal + cashProductsTotal;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? "إتمام الشراء" : "Checkout"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1d0fe3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: isLoggedIn
                      ? [_buildTextField(_noteController, isAr ? "ملاحظة" : "Note", maxLines: 3)]
                      : [
                    _buildTextField(_fullNameController, isAr ? "الاسم الكامل" : "Full Name"),
                    _buildTextField(_phoneController, isAr ? "رقم الهاتف" : "Phone", inputType: TextInputType.phone),
                    const SizedBox(height: 20),
                    if (!isLoggedIn)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isAr
                                    ? "سيتم استخدام البريد الإلكتروني وكلمة المرور لإنشاء حساب جديد لك على تطبيق كريدت فون، أو قم بتسجيل الدخول وأطلب."
                                    : "Your email and password will be used to create a new account on Credit Phone, or to login then order.",
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildTextField(_emailController, isAr ? "البريد الإلكتروني" : "Email", inputType: TextInputType.emailAddress),
                    _buildTextField(_passwordController, isAr ? "كلمة المرور" : "Password", obscure: true),
                    const SizedBox(height: 10),
                    _buildRadioQuestion(isAr ? "هل تقيم في قطر؟" : "Are you resident in Qatar?", _residentInQatar,
                        (v) => setState(() => _residentInQatar = v), lang),
                    if (_residentInQatar == "yes")
                      _buildRadioQuestion(isAr ? "هل لديك شيكات؟" : "Do you have checks?", _hasChecks,
                          (v) => setState(() => _hasChecks = v), lang),
                    if (_hasChecks == "no")
                      _buildRadioQuestion(isAr ? "هل يمكنك استخراج شيكات؟" : "Can you obtain checks?", _canObtainChecks,
                          (v) => setState(() => _canObtainChecks = v), lang),
                    _buildTextField(_noteController, isAr ? "ملاحظة" : "Note", maxLines: 3),
                  ],
                ),
              ),
            ),
           Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: Color(0xFF1d0fe3)),
                const SizedBox(width: 8),
                Text(
                  isAr ? "تفاصيل الطلب" : "Order Summary",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),
            if (!isLoggedIn) ...[
              infoRow(Icons.person_outline, isAr ? "الاسم الكامل" : "Full Name", _fullNameController.text),
              infoRow(Icons.phone, isAr ? "رقم الهاتف" : "Phone", _phoneController.text),
              infoRow(Icons.email_outlined, isAr ? "البريد الإلكتروني" : "Email", _emailController.text),
              const SizedBox(height: 12),
            ],

            infoRow(
              Icons.payment_outlined,
              isAr ? "الخطة" : "Plan",
              isCustomPlan
                  ? (isAr ? "مخصصة" : "Custom")
                  : (isAr ? "افتراضية" : "Standard"),
            ),


            if (_noteController.text.isNotEmpty)
              infoRow(Icons.notes, isAr ? "ملاحظة" : "Note", _noteController.text),

            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade300),

            Text(
              isAr ? "المنتجات:" : "Products:",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...Provider.of<CartProvider>(context).items.map((item) {
              final name = item.product.name;
              final qty = item.quantity;
              final plan = item.installmentPlan;
              final isCustom = plan?.type == 'custom';
              final priceText = isAr ? "ر.ق" : "QAR";

              final unitPrice = isCustom ? plan!.downPayment : item.product.price;
              final total = unitPrice * qty;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${isAr ? "الكمية" : "Qty"}: $qty",
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        Text(
                          "$priceText ${total.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),



            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade300),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? "المجموع الكلي" : "Total",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "${totalPrice.toStringAsFixed(2)} ${isAr ? "ريال قطري" : "Qatari Riyal"}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),

          ],
        ),
      ),
    ),



    const SizedBox(height: 24),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1d0fe3),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              ),
              label: Text(isAr ? "إرسال الطلب" : "Submit Order", style: const TextStyle(fontSize: 18)),
              onPressed: _placeOrder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType inputType = TextInputType.text, bool obscure = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        obscureText: obscure,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildRadioQuestion(String question, String? value, Function(String?) onChanged, String lang) {
    final isAr = lang == 'ar';
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    isCustomPlan = arguments?['isCustomPlan'] ?? false;
    downPaymentController.text = (arguments?['downPayment']?.toString() ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 10, bottom: 5), child: Text(question, style: const TextStyle(fontWeight: FontWeight.bold))),
        Row(
          children: ["yes", "no"].map((option) {
            return Expanded(
              child: RadioListTile(
                title: Text(option == "yes" ? (isAr ? "نعم" : "Yes") : (isAr ? "لا" : "No")),
                value: option,
                groupValue: value,
                onChanged: onChanged,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _placeOrder() async {
    final isLoggedIn = Provider.of<UserProvider>(context, listen: false).isLoggedIn;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final lang = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    final isAr = lang == 'ar';

    if (!_isValidEmail(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'الرجاء إدخال بريد إلكتروني صحيح' : 'Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool? isNewCustomer;
    if (!isLoggedIn) {
      isNewCustomer = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(isAr ? 'هل أنت عميل جديد؟' : 'Are you a new customer?'),
            actions: [
              TextButton(
                child: Text(isAr ? 'لا' : 'No'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(isAr ? 'نعم' : 'Yes'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );
    }

    if (isNewCustomer == null && !isLoggedIn) return;

    try {
      setState(() => _loading = true);

      final items = cartProvider.items;
      final plan = items.first.installmentPlan;
      final lineItems = items.map((item) => {
        'product_id': item.product.id,
        'quantity': item.quantity,
      }).toList();

      final buffer = StringBuffer();

      // Note
      if (_noteController.text.trim().isNotEmpty) {
        buffer.writeln(isAr ? 'ملاحظة: ${_noteController.text.trim()}' : 'Note: ${_noteController.text.trim()}');
      }

      // Survey answers
      buffer.writeln(isAr ? '\nإجابات الأسئلة:' : '\nSurvey Answers:');
      buffer.writeln('${isAr ? ' - هل تقيم في قطر؟' : ' - Resident in Qatar?'} ${_residentInQatar ?? (isAr ? 'غير مجاب' : 'Not answered')}');
      if (_residentInQatar == 'yes') {
        buffer.writeln('${isAr ? ' - هل لديك شيكات؟' : ' - Has checks?'} ${_hasChecks ?? (isAr ? 'غير مجاب' : 'Not answered')}');
        if (_hasChecks == 'no') {
          buffer.writeln('${isAr ? ' - هل يمكنك استخراج شيكات؟' : ' - Can obtain checks?'} ${_canObtainChecks ?? (isAr ? 'غير مجاب' : 'Not answered')}');
        }
      }

      // Installment plan
      buffer.writeln(isAr ? '\nتفاصيل خطة التقسيط:' : '\nInstallment Plan Details:');
      buffer.writeln('${isAr ? ' - نوع الخطة: ' : ' - Plan Type: '}${plan?.type ?? (isAr ? 'افتراضية' : 'Standard')}');
      if (plan?.type == 'custom') {
        buffer.writeln('${isAr ? ' - الدفعة الأولى: ' : ' - Down Payment: '}${plan?.downPayment} QAR');
        buffer.writeln('${isAr ? ' - المبلغ المتبقي: ' : ' - Remaining Amount: '}${plan?.remainingAmount} QAR');
        buffer.writeln('${isAr ? ' - القسط الشهري: ' : ' - Monthly Payment: '}${plan?.monthlyPayment} QAR × 4');
      }

      buffer.writeln('${isAr ? ' - حالة العميل: ' : ' - Customer Status: '}${isNewCustomer ?? (isLoggedIn ? (isAr ? 'عميل حالي' : 'Existing Customer') : (isAr ? 'عميل جديد' : 'New Customer'))}');

      final result = await _apiService.createOrder(
        customerName: _fullNameController.text.trim(),
        customerEmail: _emailController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        lineItems: lineItems,
        installmentType: plan?.type ?? 'standard',
        isNewCustomer: isNewCustomer ?? isLoggedIn,
        customerNote: buffer.toString(),
      );

      cartProvider.clearCart();

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                isAr ? 'تم تقديم طلبك بنجاح' : 'Order Placed Successfully',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isAr ? 'سنتواصل معك خلال الساعات القليلة القادمة' : "We'll contact you within the next few hours",
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil('/orders', (route) => route.settings.name == '/main');
              },
              child: Text(isAr ? 'حسناً' : 'OK'),
            ),
          ],
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم استلام طلبك وهو قيد المراجعة. سنتواصل معك قريباً' : 'Your order has been received and is under review. We will contact you soon.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'فشل إرسال الطلب: $e' : 'Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
  Widget infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

}