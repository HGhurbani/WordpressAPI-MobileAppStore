import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils.dart';

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

  final primaryColor = const Color(0xFF1A2543);
  final secondaryColor = const Color(0xFFDEE3ED);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUserForm(isAr, isLoggedIn),
              const SizedBox(height: 20),
              _buildOrderSummary(isAr, cartItems),
              const SizedBox(height: 20),
              _buildPriceSummary(isAr),
              const SizedBox(height: 30),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  isAr ? "تأكيد الطلب" : "Confirm Order",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserForm(bool isAr, bool isLoggedIn) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!isLoggedIn) ...[
              _buildTextField(_fullNameController, isAr ? "الاسم الكامل" : "Full Name"),
              _buildTextField(_phoneController, isAr ? "رقم الهاتف" : "Phone", inputType: TextInputType.phone),
              _buildTextField(_emailController, isAr ? "البريد الإلكتروني" : "Email", inputType: TextInputType.emailAddress),
              _buildTextField(_passwordController, isAr ? "كلمة المرور" : "Password", obscure: true),
              const SizedBox(height: 12),
              _buildRadioQuestion(isAr ? "هل تقيم في قطر؟" : "Are you resident in Qatar?", _residentInQatar, (v) => setState(() => _residentInQatar = v), isAr),
              if (_residentInQatar == "yes")
                _buildRadioQuestion(isAr ? "هل لديك شيكات؟" : "Do you have checks?", _hasChecks, (v) => setState(() => _hasChecks = v), isAr),
              if (_hasChecks == "no")
                _buildRadioQuestion(isAr ? "هل يمكنك استخراج شيكات؟" : "Can you obtain checks?", _canObtainChecks, (v) => setState(() => _canObtainChecks = v), isAr),
            ],
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
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        obscureText: obscure,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildRadioQuestion(String question, String? value, Function(String?) onChanged, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          children: ['yes', 'no'].map((option) {
            return SizedBox(
              width: 150,
              child: RadioListTile(
                activeColor: primaryColor,
                title: Text(option == 'yes' ? (isAr ? "نعم" : "Yes") : (isAr ? "لا" : "No")),
                value: option,
                groupValue: value,
                onChanged: onChanged,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildOrderSummary(bool isAr, List cartItems) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? "المنتجات" : "Products",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ...cartItems.map((item) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${isAr ? 'الكمية' : 'Quantity'}: ${item.quantity}",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const Divider(height: 20, thickness: 1),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }


  Widget _buildPriceSummary(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.2),
        border: Border.all(color: secondaryColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRowText(isAr ? "نوع الخطة" : "Plan Type", widget.isCustomPlan ? (isAr ? "مخصصة" : "Custom") : (isAr ? "افتراضية" : "Default")),
          _summaryRow(isAr ? "الدفعة الأولى" : "Down Payment", widget.downPayment),
          _summaryRow(isAr ? "المبلغ المتبقي" : "Remaining", widget.remainingAmount),
          _summaryRow(isAr ? "عدد الأقساط" : "Installments", widget.numberOfInstallments.toDouble()),
          _summaryRow(isAr ? "قيمة كل قسط" : "Monthly Payment", widget.monthlyPayment),
          const Divider(),
          _summaryRow(isAr ? "الإجمالي الكلي" : "Total", widget.totalPrice),
        ],
      ),
    );
  }

  Widget _summaryRowText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(title), Text(value)],
      ),
    );
  }

  Widget _summaryRow(String title, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text("${formatNumber(value)} ر.ق", style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isAr = context.isAr;

    final isLoggedIn = userProvider.isLoggedIn;
    final customerName = _fullNameController.text.trim();
    final customerEmail = _emailController.text.trim();
    final customerPhone = _phoneController.text.trim();

    final cartItems = cartProvider.items;

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

      // إظهار رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? "تم إرسال الطلب بنجاح!" : "Order submitted successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // تفريغ السلة
      cartProvider.clearCart();

      // الانتقال إلى صفحة الطلبات
      Navigator.of(context).pushNamedAndRemoveUntil('/orders', (route) => false);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? "فشل في إرسال الطلب. حاول مرة أخرى." : "Failed to submit order. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

}
