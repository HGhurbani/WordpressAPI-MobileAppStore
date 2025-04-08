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


  @override
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
      
      // Auto-fill user data if logged in
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isLoggedIn) {
        _emailController.text = userProvider.user?.email ?? '';
        _phoneController.text = userProvider.user?.phone ?? '';
      }
    });
  }

  void _checkAuthentication() {
    final isLoggedIn = Provider.of<UserProvider>(context, listen: false).isLoggedIn;
    if (!isLoggedIn) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(context.isAr ? 'تسجيل الدخول مطلوب' : 'Login Required'),
          content: Text(context.isAr ? 'يرجى تسجيل الدخول للمتابعة' : 'Please login to continue'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: Text(context.isAr ? 'تسجيل الدخول' : 'Login'),
            ),
          ],
        ),
      );
    }
  }

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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _placeOrder() async {
    final isLoggedIn = Provider.of<UserProvider>(context, listen: false).isLoggedIn;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final lang = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    final isAr = lang == 'ar';

    // Validate email
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

    if (isNewCustomer == null && !isLoggedIn) return; // User cancelled

    try {
      setState(() => _loading = true);

      final items = cartProvider.items;
      final lineItems = items.map((item) => {
        'product_id': item.product.id,
        'quantity': item.quantity,
      }).toList();

      // Build installment plan notes
      final installmentNotes = StringBuffer();
      final plan = items.first.installmentPlan;
      installmentNotes.writeln('Plan Type: ${plan?.type ?? 'standard'}');
      if (plan?.type == 'custom') {
        installmentNotes.writeln('Down Payment: ${plan?.downPayment} QAR');
        installmentNotes.writeln('Remaining Amount: ${plan?.remainingAmount} QAR');
        installmentNotes.writeln('Monthly Payment: ${plan?.monthlyPayment} QAR (4 installments)');
      }
      installmentNotes.writeln('Customer Status: ${isNewCustomer ?? (isLoggedIn ? 'Existing Customer' : 'New Customer')}');

      final result = await _apiService.createOrder(
        customerName: _fullNameController.text.trim(),
        customerEmail: _emailController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        lineItems: lineItems,
        installmentType: items.first.installmentPlan?.type ?? 'standard',
        isNewCustomer: isNewCustomer ?? isLoggedIn,
        customerNote: '${_noteController.text.trim()}\n\nInstallment Plan Details:\n$installmentNotes',
      );

      cartProvider.clearCart();

      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
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
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/orders',
                        (route) => route.settings.name == '/main'
                );
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

}