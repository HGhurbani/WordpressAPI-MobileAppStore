// lib/screens/checkout_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _authService = AuthService();
  bool _loading = false;

  final _noteController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _residentInQatar;
  String? _hasChecks;
  String? _canObtainChecks;

  final whatsappNumber = "97450105685";

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Provider.of<UserProvider>(context).isLoggedIn;
    final lang = Provider.of<LocaleProvider>(context).locale.languageCode;
    final isAr = lang == 'ar';

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

  Future<void> _placeOrder() async {
    final isLoggedIn = Provider.of<UserProvider>(context, listen: false).isLoggedIn;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final lang = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    final isAr = lang == 'ar';

    final fullName = _fullNameController.text.trim().isEmpty
        ? userProvider.user?.username ?? ""
        : _fullNameController.text.trim();

    final phone = _phoneController.text.trim().isEmpty
        ? userProvider.user?.phone ?? ""
        : _phoneController.text.trim();

    final note = _noteController.text.trim();
    final items = cartProvider.items;
    final total = cartProvider.totalAmount.toStringAsFixed(2);
    final priceText = isAr ? "ر.ق" : "QAR";

    final orderDetails = StringBuffer();
    for (var item in items) {
      orderDetails.writeln("- ${item.product.name} × ${item.quantity}");
    }

    final message = StringBuffer()
      ..writeln("📦 ${isAr ? 'طلب جديد' : 'New Order'}")
      ..writeln("👤 ${isAr ? 'الاسم' : 'Name'}: $fullName")
      ..writeln("📱 ${isAr ? 'الهاتف' : 'Phone'}: $phone")
      ..writeln("📝 ${isAr ? 'ملاحظة' : 'Note'}: $note")
      ..writeln("🛒 ${isAr ? 'المنتجات' : 'Products'}:\n$orderDetails")
      ..writeln("💰 ${isAr ? 'الإجمالي' : 'Total'}: $priceText $total");

    // إظهار مربع تأكيد قبل الإرسال
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isAr ? "تأكيد الطلب" : "Confirm Order"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${isAr ? 'الاسم' : 'Name'}: $fullName"),
              Text("${isAr ? 'الهاتف' : 'Phone'}: $phone"),
              if (note.isNotEmpty) Text("${isAr ? 'ملاحظة' : 'Note'}: $note"),
              const Divider(height: 20),
              Text(isAr ? "المنتجات المطلوبة:" : "Ordered Products:"),
              Text(orderDetails.toString()),
              const Divider(height: 20),
              Text("${isAr ? 'الإجمالي' : 'Total'}: $priceText $total",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isAr ? "إلغاء" : "Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // إغلاق مربع التأكيد
              setState(() => _loading = true);

              try {
                // إذا لم يكن المستخدم مسجلاً
                if (!isLoggedIn) {
                  final username = _fullNameController.text.trim();
                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();

                  // تسجيل وإنشاء المستخدم
                  final newUser = await _authService.register(username, email, password,phone);

                  // حفظ بيانات المستخدم
                  Provider.of<UserProvider>(context, listen: false).setUser(newUser);
                }

                final encodedMessage = Uri.encodeComponent(message.toString());
                final url = Uri.parse("https://wa.me/$whatsappNumber?text=$encodedMessage");

                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }

                cartProvider.clearCart();
                setState(() => _loading = false);
                Navigator.popUntil(context, ModalRoute.withName('/main'));

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isAr ? "تم إرسال الطلب" : "Order sent via WhatsApp")),
                );
              } catch (e) {
                setState(() => _loading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isAr ? "فشل إرسال الطلب: $e" : "Failed to place order: $e")),
                );
              }
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1d0fe3),
              foregroundColor: Colors.white,
            ),
            child: Text(isAr ? "تأكيد الطلب" : "Confirm Order"),
          ),
        ],
      ),
    );
  }

}
