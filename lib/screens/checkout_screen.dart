import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils.dart'; // Assuming this contains formatNumber

extension ContextExtensions on BuildContext {
  bool get isAr => Provider.of<LocaleProvider>(this, listen: false).locale.languageCode == 'ar';
}

class CheckoutScreen extends StatefulWidget {
  final bool isCustomPlan;
  final double totalPrice;
  final double downPayment;
  final double remainingAmount;
  final double monthlyPayment;
  final int numberOfInstallments;

  const CheckoutScreen({
    Key? key,
    required this.isCustomPlan,
    required this.totalPrice,
    required this.downPayment,
    required this.remainingAmount,
    required this.monthlyPayment,
    required this.numberOfInstallments,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _authService = AuthService(); // Consider if this is truly needed here
  final _apiService = ApiService();
  bool _loading = false;
  final _formKey = GlobalKey<FormState>(); // Added for form validation

  final _noteController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _residentInQatar;
  String? _hasChecks;
  String? _canObtainChecks;

  final primaryColor = const Color(0xFF1A2543);
  final secondaryColor = const Color(0xFFDEE3ED);
  final accentColor = const Color(0xFF00BFA5); // A new accent color for highlights

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.isLoggedIn) {
      _emailController.text = userProvider.user?.email ?? '';
      _phoneController.text = userProvider.user?.phone ?? '';
      _fullNameController.text = userProvider.user?.username ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isAr;
    final isLoggedIn = Provider.of<UserProvider>(context).isLoggedIn;
    final cartItems = Provider.of<CartProvider>(context).items;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? "إتمام الشراء" : "Checkout"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form( // Wrap with Form for validation
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader(isAr ? "معلومات الاتصال" : "Contact Information"),
                _buildUserForm(isAr, isLoggedIn),
                const SizedBox(height: 20),
                _buildSectionHeader(isAr ? "ملخص الطلب" : "Order Summary"),
                _buildOrderSummary(isAr, cartItems),
                const SizedBox(height: 20),
                _buildSectionHeader(isAr ? "تفاصيل الدفعة" : "Payment Details"),
                _buildPriceSummary(isAr),
                const SizedBox(height: 30),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  child: Text(
                    isAr ? "تأكيد وإرسال الطلب" : "Confirm & Submit Order",
                    style: const TextStyle(color: Colors.white,fontFamily: 'Cairo',fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildUserForm(bool isAr, bool isLoggedIn) {
    return Card(
      elevation: 1, // Slightly higher elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // More rounded corners
      child: Padding(
        padding: const EdgeInsets.all(20), // More padding
        child: Column(
          children: [
            if (!isLoggedIn) ...[
              _buildTextField(
                _fullNameController,
                isAr ? "الاسم الكامل" : "Full Name",
                validator: (value) => value!.isEmpty ? (isAr ? "الاسم مطلوب" : "Name is required") : null,
              ),
              _buildTextField(
                _phoneController,
                isAr ? "رقم الهاتف" : "Phone",
                inputType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? (isAr ? "رقم الهاتف مطلوب" : "Phone is required") : null,
              ),
              _buildTextField(
                _emailController,
                isAr ? "البريد الإلكتروني" : "Email",
                inputType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) return isAr ? "البريد الإلكتروني مطلوب" : "Email is required";
                  if (!isValidEmail(value)) return isAr ? "صيغة بريد إلكتروني غير صحيحة" : "Invalid email format";
                  return null;
                },
              ),
              _buildTextField(
                _passwordController,
                isAr ? "كلمة المرور" : "Password",
                obscure: true,
                validator: (value) {
                  if (value!.isEmpty) return isAr ? "كلمة المرور مطلوبة" : "Password is required";
                  if (value.length < 6) return isAr ? "كلمة المرور قصيرة جداً (6 أحرف على الأقل)" : "Password too short (min 6 chars)";
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildRadioQuestion(
                isAr ? "هل تقيم في قطر؟" : "Are you resident in Qatar?",
                _residentInQatar,
                    (v) => setState(() => _residentInQatar = v),
                isAr,
              ),
              if (_residentInQatar == "yes")
                _buildRadioQuestion(
                  isAr ? "هل لديك شيكات؟" : "Do you have checks?",
                  _hasChecks,
                      (v) => setState(() => _hasChecks = v),
                  isAr,
                ),
              if (_hasChecks == "no" && _residentInQatar == "yes") // Only show if resident and no checks
                _buildRadioQuestion(
                  isAr ? "هل يمكنك استخراج شيكات؟" : "Can you obtain checks?",
                  _canObtainChecks,
                      (v) => setState(() => _canObtainChecks = v),
                  isAr,
                ),
            ],
            const SizedBox(height: 15),
            _buildTextField(_noteController, isAr ? "ملاحظة (اختياري)" : "Note (optional)", maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        TextInputType inputType = TextInputType.text,
        bool obscure = false,
        int maxLines = 1,
        String? Function(String?)? validator, // Added validator
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        obscureText: obscure,
        maxLines: maxLines,
        validator: validator, // Assign validator
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: primaryColor.withOpacity(0.8)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), // Borderless by default
          filled: true,
          fillColor: secondaryColor.withOpacity(0.3), // Light fill color
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          errorBorder: OutlineInputBorder( // Error border style
            borderSide: BorderSide(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedErrorBorder: OutlineInputBorder( // Focused error border style
            borderSide: BorderSide(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildRadioQuestion(String question, String? value, Function(String?) onChanged, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        Row( // Use Row for better control over spacing
          children: ['yes', 'no'].map((option) {
            return Expanded( // Use Expanded to give equal space
              child: RadioListTile(
                activeColor: primaryColor,
                title: Text(option == 'yes' ? (isAr ? "نعم" : "Yes") : (isAr ? "لا" : "No")),
                value: option,
                groupValue: value,
                onChanged: onChanged,
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 0), // Adjust padding
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildOrderSummary(bool isAr, List cartItems) {
    if (cartItems.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              isAr ? "سلة التسوق فارغة." : "Your cart is empty.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...cartItems.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "${isAr ? 'الكمية' : 'Qty'}: ${item.quantity}",
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(20), // More padding
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.3), // Slightly darker background
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryColor.withOpacity(0.2)), // Subtle border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRowText(isAr ? "نوع الخطة" : "Plan Type", widget.isCustomPlan ? (isAr ? "مخصصة" : "Custom") : (isAr ? "افتراضية" : "Default")),
          _summaryRow(isAr ? "الدفعة الأولى" : "Down Payment", widget.downPayment),
          _summaryRow(isAr ? "المبلغ المتبقي" : "Remaining Amount", widget.remainingAmount),
          _summaryRow(isAr ? "عدد الأقساط" : "Number of Installments", widget.numberOfInstallments.toDouble()),
          _summaryRow(isAr ? "قيمة كل قسط" : "Monthly Installment", widget.monthlyPayment),
          const Divider(height: 25, thickness: 1.5, color: Colors.black12), // More prominent divider
          _summaryRow(isAr ? "الإجمالي الكلي" : "Total Amount", widget.totalPrice, isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryRowText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6), // Increased vertical padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: primaryColor.withOpacity(0.9), fontSize: 15)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isTotal ? primaryColor : primaryColor.withOpacity(0.9),
              fontSize: isTotal ? 17 : 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "${formatNumber(value)} ${context.isAr ? 'ر.ق' : 'QAR'}", // Use context.isAr
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 17 : 15,
              color: isTotal ? accentColor : primaryColor, // Highlight total
            ),
          ),
        ],
      ),
    );
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _placeOrder() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isAr = context.isAr;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? "يرجى ملء جميع الحقول المطلوبة بشكل صحيح." : "Please fill all required fields correctly."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!userProvider.isLoggedIn) {
      if (_residentInQatar == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? "يرجى تحديد ما إذا كنت تقيم في قطر." : "Please specify if you are resident in Qatar."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_residentInQatar == "yes") {
        if (_hasChecks == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAr ? "يرجى تحديد ما إذا كان لديك شيكات." : "Please specify if you have checks."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        if (_hasChecks == "no" && _canObtainChecks == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAr ? "يرجى تحديد ما إذا كان يمكنك استخراج شيكات." : "Please specify if you can obtain checks."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }


    final isLoggedIn = userProvider.isLoggedIn;
    final customerName = _fullNameController.text.trim();
    final customerEmail = _emailController.text.trim();
    final customerPhone = _phoneController.text.trim();

    final cartItems = cartProvider.items;

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? "لا يوجد منتجات في سلة التسوق." : "No products in the cart."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final lineItems = cartItems.map((item) {
      return {
        'product_id': item.product.id,
        'quantity': item.quantity,
      };
    }).toList();

    setState(() => _loading = true);

    try {
      await _apiService.createOrder(
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        lineItems: lineItems,
        installmentType: widget.isCustomPlan ? "custom" : "default",
        isNewCustomer: !isLoggedIn,
        customerNote: _noteController.text,
        customInstallment: widget.isCustomPlan
            ? {
          'downPayment': widget.downPayment,
          'remainingAmount': widget.remainingAmount,
          'monthlyPayment': widget.monthlyPayment,
          'numberOfInstallments': widget.numberOfInstallments,
        }
            : null,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? "تم إرسال الطلب بنجاح! سيتم مراجعة طلبك والتواصل معك قريباً." : "Order submitted successfully! Your order will be reviewed and you will be contacted shortly."),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      cartProvider.clearCart();

      Navigator.of(context).pushNamedAndRemoveUntil('/orders', (route) => false);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? "فشل في إرسال الطلب. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى." : "Failed to submit order. Please check your internet connection and try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
}