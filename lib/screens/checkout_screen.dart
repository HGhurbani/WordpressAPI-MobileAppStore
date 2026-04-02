import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/finance_profile.dart';
import '../models/profile_document.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../utils.dart'; // Assuming this contains formatNumber

extension ContextExtensions on BuildContext {
  bool get isAr => Provider.of<LocaleProvider>(this, listen: false).locale.languageCode == 'ar';
}

class CheckoutScreen extends StatefulWidget {
  final bool isCustomPlan;
  final bool isCashOrder;
  final double totalPrice;
  final double? downPayment;
  final double? remainingAmount;
  final double? monthlyPayment;
  final int? numberOfInstallments;

  const CheckoutScreen({
    Key? key,
    this.isCustomPlan = false,
    this.isCashOrder = false,
    required this.totalPrice,
    this.downPayment,
    this.remainingAmount,
    this.monthlyPayment,
    this.numberOfInstallments,
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
  FinanceProfile _financeProfile = const FinanceProfile();
  bool _financeLoading = false;
  PlatformFile? _pendingFrontFile;
  PlatformFile? _pendingBackFile;
  final List<PlatformFile> _pendingBankFiles = [];
  final List<PlatformFile> _pendingAdditionalFiles = [];
  final Set<String> _deletedBankStatementIds = <String>{};
  final Set<String> _deletedAdditionalAttachmentIds = <String>{};
  bool _deleteFrontDocument = false;
  bool _deleteBackDocument = false;

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
      _loadFinanceProfile();
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
                if (!widget.isCashOrder) ...[
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    isAr ? "الأهلية والمرفقات" : "Eligibility & Attachments",
                  ),
                  _buildInstallmentRequirementsSection(isAr),
                ],
                const SizedBox(height: 20),
                _buildSectionHeader(isAr ? "ملخص الطلب" : "Order Summary"),
                _buildOrderSummary(isAr, cartItems),
                const SizedBox(height: 20),
                if (!widget.isCashOrder)
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
          children: ['Yes', 'No'].map((option) {
            return Expanded( // Use Expanded to give equal space
              child: RadioListTile(
                activeColor: primaryColor,
                title: Text(option == 'Yes' ? (isAr ? "نعم" : "Yes") : (isAr ? "لا" : "No")),
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
    final planTypeLabel = widget.isCashOrder
        ? (isAr ? "نقدي" : "Cash")
        : widget.isCustomPlan
            ? (isAr ? "مخصصة" : "Custom")
            : (isAr ? "افتراضية" : "Default");

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
          _summaryRowText(isAr ? "نوع الخطة" : "Plan Type", planTypeLabel),
          if (!widget.isCashOrder && widget.remainingAmount != null)
            _summaryRow(
              isAr ? "المبلغ المتبقي" : "Remaining Amount",
              widget.remainingAmount!,
            ),
          if (!widget.isCashOrder && widget.numberOfInstallments != null)
            _summaryRow(
              isAr ? "عدد الأقساط" : "Number of Installments",
              widget.numberOfInstallments!.toDouble(),
            ),
          if (!widget.isCashOrder && widget.monthlyPayment != null)
            _summaryRow(
              isAr ? "قيمة كل قسط" : "Monthly Installment",
              widget.monthlyPayment!,
            ),
          _summaryRow(isAr ? "الإجمالي الكلي" : "Total Amount", widget.totalPrice),
          const Divider(height: 25, thickness: 1.5, color: Colors.black12), // More prominent divider
          _summaryRow(
            widget.isCashOrder
                ? (isAr ? "المبلغ المستحق" : "Amount Due")
                : (isAr ? "الدفعة الأولى" : "Down Payment"),
            widget.downPayment ?? widget.totalPrice,
            isTotal: true,
          ),
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

  Future<void> _loadFinanceProfile() async {
    setState(() => _financeLoading = true);
    try {
      final profile = await _apiService.getFinanceProfile();
      if (!mounted) return;
      setState(() {
        _financeProfile = profile;
        _residentInQatar = profile.residencyInQatar;
        _hasChecks = profile.haveBankChecks;
        _canObtainChecks = profile.canGetBankChecks;
      });
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() => _financeLoading = false);
      }
    }
  }

  Widget _buildInstallmentRequirementsSection(bool isAr) {
    if (_financeLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRadioQuestion(
              isAr ? "هل تقيم في قطر؟" : "Do you live in Qatar?",
              _residentInQatar,
              (v) => setState(() {
                _residentInQatar = v;
                if (v != 'Yes') {
                  _hasChecks = null;
                  _canObtainChecks = null;
                }
              }),
              isAr,
            ),
            if (_residentInQatar == 'Yes')
              _buildRadioQuestion(
                isAr
                    ? "هل لديك شيكات بنكية باسمك؟"
                    : "Do you have bank checks in your name?",
                _hasChecks,
                (v) => setState(() {
                  _hasChecks = v;
                  if (v != 'No') {
                    _canObtainChecks = null;
                  }
                }),
                isAr,
              ),
            if (_residentInQatar == 'Yes' && _hasChecks == 'No')
              _buildRadioQuestion(
                isAr
                    ? "هل يمكنك استخراج شيكات بنكية باسمك؟"
                    : "Can you issue bank checks in your name?",
                _canObtainChecks,
                (v) => setState(() => _canObtainChecks = v),
                isAr,
              ),
            const SizedBox(height: 8),
            _buildCheckoutAttachmentGroup(
              title: isAr
                  ? 'صورة البطاقة الشخصية (الوجه الأمامي) *'
                  : 'ID Card (Front) *',
              existingDocuments: _visibleSingleDocument(
                _financeProfile.idCardFront,
                deleted: _deleteFrontDocument,
              ),
              pendingFiles: _pendingFrontFile == null ? const [] : [_pendingFrontFile!],
              onPickFiles: () => _pickFiles(
                isAr: isAr,
                category: 'id_card_front',
              ),
              onRemoveExisting: (doc) => setState(() {
                _deleteFrontDocument = true;
              }),
              onRemovePending: (index) => setState(() {
                _pendingFrontFile = null;
                _deleteFrontDocument = false;
              }),
              isAr: isAr,
            ),
            const SizedBox(height: 16),
            _buildCheckoutAttachmentGroup(
              title: isAr
                  ? 'صورة البطاقة الشخصية (الوجه الخلفي) *'
                  : 'ID Card (Back) *',
              existingDocuments: _visibleSingleDocument(
                _financeProfile.idCardBack,
                deleted: _deleteBackDocument,
              ),
              pendingFiles: _pendingBackFile == null ? const [] : [_pendingBackFile!],
              onPickFiles: () => _pickFiles(
                isAr: isAr,
                category: 'id_card_back',
              ),
              onRemoveExisting: (doc) => setState(() {
                _deleteBackDocument = true;
              }),
              onRemovePending: (index) => setState(() {
                _pendingBackFile = null;
                _deleteBackDocument = false;
              }),
              isAr: isAr,
            ),
            const SizedBox(height: 16),
            _buildCheckoutAttachmentGroup(
              title: isAr
                  ? 'كشف حساب آخر 3 شهور *'
                  : 'Bank Statements (Last 3 Months) *',
              existingDocuments: _financeProfile.bankStatements
                  .where((doc) => !_deletedBankStatementIds.contains(doc.id))
                  .toList(),
              pendingFiles: _pendingBankFiles,
              onPickFiles: () => _pickFiles(
                isAr: isAr,
                category: 'bank_statements',
                allowMultiple: true,
              ),
              onRemoveExisting: (doc) => setState(() {
                _deletedBankStatementIds.add(doc.id);
              }),
              onRemovePending: (index) => setState(() {
                _pendingBankFiles.removeAt(index);
              }),
              isAr: isAr,
            ),
            const SizedBox(height: 16),
            _buildCheckoutAttachmentGroup(
              title: isAr
                  ? 'مرفقات إضافية (اختياري)'
                  : 'Additional Attachments (Optional)',
              existingDocuments: _financeProfile.additionalAttachments
                  .where((doc) => !_deletedAdditionalAttachmentIds.contains(doc.id))
                  .toList(),
              pendingFiles: _pendingAdditionalFiles,
              onPickFiles: () => _pickFiles(
                isAr: isAr,
                category: 'additional_attachments',
                allowMultiple: true,
              ),
              onRemoveExisting: (doc) => setState(() {
                _deletedAdditionalAttachmentIds.add(doc.id);
              }),
              onRemovePending: (index) => setState(() {
                _pendingAdditionalFiles.removeAt(index);
              }),
              isAr: isAr,
            ),
          ],
        ),
      ),
    );
  }

  List<ProfileDocument> _visibleSingleDocument(
    ProfileDocument? document, {
    required bool deleted,
  }) {
    if (document == null || deleted) {
      return const [];
    }
    return [document];
  }

  Future<void> _pickFiles({
    required bool isAr,
    required String category,
    bool allowMultiple = false,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    setState(() {
      if (category == 'id_card_front') {
        _pendingFrontFile = result.files.first;
        _deleteFrontDocument = false;
      } else if (category == 'id_card_back') {
        _pendingBackFile = result.files.first;
        _deleteBackDocument = false;
      } else if (category == 'bank_statements') {
        _pendingBankFiles.addAll(result.files);
      } else if (category == 'additional_attachments') {
        _pendingAdditionalFiles.addAll(result.files);
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr ? 'تمت إضافة الملفات إلى الطلب.' : 'Files added to the order.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildCheckoutAttachmentGroup({
    required String title,
    required List<ProfileDocument> existingDocuments,
    required List<PlatformFile> pendingFiles,
    required VoidCallback onPickFiles,
    required ValueChanged<ProfileDocument> onRemoveExisting,
    required ValueChanged<int> onRemovePending,
    required bool isAr,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2543),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onPickFiles,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(isAr ? 'اختيار' : 'Choose'),
              ),
            ],
          ),
          if (existingDocuments.isEmpty && pendingFiles.isEmpty)
            Text(
              isAr ? 'لا توجد ملفات محددة.' : 'No files selected.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ...existingDocuments.map(
            (doc) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link_rounded),
              title: Text(
                doc.name.isEmpty ? doc.url : doc.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(isAr ? 'من البروفايل' : 'From profile'),
              onTap: () => _openDocument(doc.url, isAr),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                onPressed: () => onRemoveExisting(doc),
              ),
            ),
          ),
          ...pendingFiles.asMap().entries.map(
            (entry) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file_rounded),
              title: Text(
                entry.value.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(isAr ? 'جديد وسيتم رفعه عند الإرسال' : 'New, will upload on submit'),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => onRemovePending(entry.key),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDocument(String url, bool isAr) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'تعذر فتح المرفق.' : 'Could not open the attachment.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _validateInstallmentRequirements(bool isAr) {
    if (_residentInQatar == null) {
      _showCheckoutError(
        isAr
            ? "يرجى تحديد ما إذا كنت تقيم في قطر."
            : "Please specify if you live in Qatar.",
      );
      return false;
    }
    if (_residentInQatar == 'No') {
      _showCheckoutError(
        isAr
            ? "لا يمكن الطلب إلا للمقيمين في قطر."
            : "Orders are only allowed for residents in Qatar.",
      );
      return false;
    }
    if (_hasChecks == null) {
      _showCheckoutError(
        isAr
            ? "يرجى تحديد ما إذا كان لديك شيكات بنكية باسمك."
            : "Please specify whether you have bank checks in your name.",
      );
      return false;
    }
    if (_hasChecks == 'No') {
      if (_canObtainChecks == null) {
        _showCheckoutError(
          isAr
              ? "يرجى تحديد ما إذا كان يمكنك استخراج شيكات بنكية باسمك."
              : "Please specify whether you can issue bank checks in your name.",
        );
        return false;
      }
      if (_canObtainChecks == 'No') {
        _showCheckoutError(
          isAr
              ? "لا يمكن الطلب إلا بشيكات شخصية باسمك أو إمكانية استخراجها."
              : "Orders are only allowed with personal checks in your name or ability to issue them.",
        );
        return false;
      }
    }

    final hasFront = _pendingFrontFile != null ||
        (_financeProfile.idCardFront != null && !_deleteFrontDocument);
    final hasBack = _pendingBackFile != null ||
        (_financeProfile.idCardBack != null && !_deleteBackDocument);
    final hasBankStatements =
        _pendingBankFiles.isNotEmpty ||
            _financeProfile.bankStatements
                .where((doc) => !_deletedBankStatementIds.contains(doc.id))
                .isNotEmpty;

    if (!hasFront) {
      _showCheckoutError(
        isAr
            ? "يرجى رفع صورة البطاقة (الوجه الأمامي)."
            : "Please upload ID card (front).",
      );
      return false;
    }
    if (!hasBack) {
      _showCheckoutError(
        isAr
            ? "يرجى رفع صورة البطاقة (الوجه الخلفي)."
            : "Please upload ID card (back).",
      );
      return false;
    }
    if (!hasBankStatements) {
      _showCheckoutError(
        isAr
            ? "يرجى رفع كشف حساب آخر 3 شهور."
            : "Please upload your bank statements for the last 3 months.",
      );
      return false;
    }

    return true;
  }

  void _showCheckoutError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _syncFinanceProfileChanges() async {
    await _apiService.updateFinanceProfileAnswers(
      residencyInQatar: _residentInQatar!,
      haveBankChecks: _hasChecks!,
      canGetBankChecks: _hasChecks == 'No' ? _canObtainChecks : null,
    );

    if (_deleteFrontDocument && _financeProfile.idCardFront != null) {
      await _apiService.deleteFinanceDocument(
        category: 'id_card_front',
        documentId: _financeProfile.idCardFront!.id,
      );
    }
    if (_deleteBackDocument && _financeProfile.idCardBack != null) {
      await _apiService.deleteFinanceDocument(
        category: 'id_card_back',
        documentId: _financeProfile.idCardBack!.id,
      );
    }

    for (final id in _deletedBankStatementIds) {
      await _apiService.deleteFinanceDocument(
        category: 'bank_statements',
        documentId: id,
      );
    }
    for (final id in _deletedAdditionalAttachmentIds) {
      await _apiService.deleteFinanceDocument(
        category: 'additional_attachments',
        documentId: id,
      );
    }

    if (_pendingFrontFile != null) {
      await _apiService.uploadFinanceDocument(
        category: 'id_card_front',
        file: _pendingFrontFile!,
      );
    }
    if (_pendingBackFile != null) {
      await _apiService.uploadFinanceDocument(
        category: 'id_card_back',
        file: _pendingBackFile!,
      );
    }

    for (final file in _pendingBankFiles) {
      await _apiService.uploadFinanceDocument(
        category: 'bank_statements',
        file: file,
      );
    }
    for (final file in _pendingAdditionalFiles) {
      await _apiService.uploadFinanceDocument(
        category: 'additional_attachments',
        file: file,
      );
    }

    _financeProfile = await _apiService.getFinanceProfile();
  }

  Future<void> _ensureUserIsRegisteredAndLoggedIn({
    required String username,
    required String email,
    required String phone,
    required String password,
    required bool isAr,
    required UserProvider userProvider,
  }) async {
    try {
      await _authService.register(username, email, password, phone);
    } catch (error) {
      final message = _extractErrorMessage(error);
      if (!_isDuplicateAccountError(message)) {
        throw CheckoutAuthException(
          isAr
              ? 'تعذّر إنشاء الحساب: $message'
              : 'Failed to create the account: $message',
        );
      }
    }

    try {
      final user = await _loginWithEmailOrUsername(
        email: email,
        username: username,
        password: password,
      );
      userProvider.setUser(user);
    } catch (error) {
      final message = _extractErrorMessage(error);
      throw CheckoutAuthException(
        isAr
            ? 'تعذّر تسجيل الدخول. يرجى التأكد من صحة البريد الإلكتروني/اسم المستخدم وكلمة المرور أو تسجيل الدخول يدويًا. التفاصيل: $message'
            : 'We could not sign you in. Please verify your email/username and password or sign in manually. Details: $message',
      );
    }
  }

  Future<User> _loginWithEmailOrUsername({
    required String email,
    required String username,
    required String password,
  }) async {
    dynamic lastError;

    if (email.isNotEmpty) {
      try {
        return await _authService.login(email, password);
      } catch (error) {
        lastError = error;
      }
    }

    if (username.isNotEmpty) {
      try {
        return await _authService.login(username, password);
      } catch (error) {
        lastError = error;
      }
    }

    if (lastError is Exception) {
      throw lastError;
    }

    throw Exception(lastError?.toString() ?? 'Unknown login error');
  }

  String _extractErrorMessage(dynamic error) {
    final rawMessage = error.toString();
    const prefix = 'Exception: ';
    if (rawMessage.startsWith(prefix)) {
      return rawMessage.substring(prefix.length);
    }
    return rawMessage;
  }

  bool _isDuplicateAccountError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('already registered') ||
        lower.contains('already exists') ||
        lower.contains('email exists') ||
        lower.contains('email address is already') ||
        lower.contains('مسجل') ||
        lower.contains('موجود') ||
        lower.contains('duplicate');
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

    final wasLoggedIn = userProvider.isLoggedIn;

    if (!widget.isCashOrder && !_validateInstallmentRequirements(isAr)) {
      return;
    }


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
      if (!wasLoggedIn) {
        await _ensureUserIsRegisteredAndLoggedIn(
          username: customerName,
          email: customerEmail,
          phone: customerPhone,
          password: _passwordController.text.trim(),
          isAr: isAr,
          userProvider: userProvider,
        );
      }

      final customerId = userProvider.user?.id;

      if (!widget.isCashOrder) {
        await _syncFinanceProfileChanges();
      }

      final installmentType = widget.isCashOrder
          ? 'cash'
          : (widget.isCustomPlan ? 'custom' : 'default');

      await _apiService.createOrder(
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        lineItems: lineItems,
        installmentType: installmentType,
        isNewCustomer: !wasLoggedIn,
        customerNote: _noteController.text,
        customerId: customerId,
        // Send plan details for BOTH default & custom plans so admin/app can track installments.
        customInstallment: widget.isCashOrder
            ? null
            : {
                'downPayment': widget.downPayment,
                'remainingAmount': widget.remainingAmount,
                'monthlyPayment': widget.monthlyPayment,
                'numberOfInstallments': widget.numberOfInstallments,
              },
      );

      if (!mounted) {
        cartProvider.clearCart();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? "تم إرسال الطلب بنجاح! سيتم مراجعة طلبك والتواصل معك قريباً." : "Order submitted successfully! Your order will be reviewed and you will be contacted shortly."),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      cartProvider.clearCart();

      Navigator.of(context).pushNamedAndRemoveUntil('/orders', (route) => false);

    } on CheckoutAuthException catch (authError) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authError.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? "فشل في إرسال الطلب. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى." : "Failed to submit order. Please check your internet connection and try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class CheckoutAuthException implements Exception {
  final String message;

  CheckoutAuthException(this.message);

  @override
  String toString() => message;
}
