import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/finance_profile.dart';
import '../models/profile_document.dart';
import '../providers/locale_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;
  bool notificationsEnabled = true;
  bool _isLoading = false;
  bool _isFinanceLoading = false;
  bool _isFinanceSaving = false;
  bool _isAttachmentBusy = false;
  FinanceProfile _financeProfile = const FinanceProfile();
  String? _residentInQatar;
  String? _hasChecks;
  String? _canGetChecks;
  final NotificationService _notificationService = NotificationService.instance;
  final ApiService _apiService = ApiService(); // استخدام مثيل واحد للـ ApiService

  Future<void> _loadNotificationSettings() async {
    final enabled = await _notificationService.getNotificationsEnabled();
    setState(() => notificationsEnabled = enabled);
  }

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _passwordController = TextEditingController();
    if (user != null) {
      _loadFinanceProfile();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadFinanceProfile() async {
    setState(() => _isFinanceLoading = true);
    try {
      final profile = await _apiService.getFinanceProfile();
      if (!mounted) return;
      setState(() {
        _financeProfile = profile;
        _residentInQatar = profile.residencyInQatar;
        _hasChecks = profile.haveBankChecks;
        _canGetChecks = profile.canGetBankChecks;
      });
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        Provider.of<LocaleProvider>(context, listen: false)
                    .locale
                    .languageCode ==
                'ar'
            ? 'تعذر تحميل بيانات التقسيط من البروفايل.'
            : 'Failed to load installment profile data.',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isFinanceLoading = false);
      }
    }
  }

  bool _validateFinanceAnswers(bool isAr) {
    final hasAnyFinanceInput = _residentInQatar != null ||
        _hasChecks != null ||
        _canGetChecks != null ||
        _financeProfile.idCardFront != null ||
        _financeProfile.idCardBack != null ||
        _financeProfile.bankStatements.isNotEmpty ||
        _financeProfile.additionalAttachments.isNotEmpty;

    if (!hasAnyFinanceInput) {
      return true;
    }

    if (_residentInQatar == null) {
      _showSnackBar(
        isAr
            ? 'يرجى تحديد ما إذا كنت تقيم في قطر.'
            : 'Please specify whether you live in Qatar.',
        Colors.red,
      );
      return false;
    }

    if (_residentInQatar == 'No') {
      _showSnackBar(
        isAr
            ? 'لا يمكن الطلب إلا للمقيمين في قطر.'
            : 'Orders are only allowed for residents in Qatar.',
        Colors.red,
      );
      return false;
    }

    if (_hasChecks == null) {
      _showSnackBar(
        isAr
            ? 'يرجى تحديد ما إذا كان لديك شيكات بنكية باسمك.'
            : 'Please specify whether you have bank checks in your name.',
        Colors.red,
      );
      return false;
    }

    if (_hasChecks == 'No') {
      if (_canGetChecks == null) {
        _showSnackBar(
          isAr
              ? 'يرجى تحديد ما إذا كان يمكنك استخراج شيكات بنكية باسمك.'
              : 'Please specify whether you can issue bank checks in your name.',
          Colors.red,
        );
        return false;
      }
      if (_canGetChecks == 'No') {
        _showSnackBar(
          isAr
              ? 'لا يمكن الطلب إلا بشيكات شخصية باسمك أو إمكانية استخراجها.'
              : 'Orders are only allowed with personal checks in your name or ability to issue them.',
          Colors.red,
        );
        return false;
      }
    }

    return true;
  }

  /// حفظ بيانات الحساب فقط (الاسم، البريد، الجوال، كلمة المرور)
  Future<void> _saveAccountInfo(UserProvider userProvider, bool isAr) async {
    if (!_isValidEmail(_emailController.text.trim())) {
      _showSnackBar(isAr ? 'الرجاء إدخال بريد إلكتروني صحيح.' : 'Please enter a valid email address.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final success = await _apiService.updateUserInfo(
        name: name,
        email: email,
        phone: phone,
        password: password.isNotEmpty ? password : null,
      );

      if (!mounted) return;
      if (success) {
        await userProvider.updateUser(
          username: name,
          email: email,
          phone: phone,
        );
        _showSnackBar(isAr ? 'تم حفظ بيانات الحساب بنجاح!' : 'Account info saved successfully!', const Color(0xFF6FE0DA));
      } else {
        _showSnackBar(isAr ? 'فشل في حفظ البيانات. الرجاء المحاولة مرة أخرى.' : 'Failed to save. Please try again.', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('expired_token')) {
        _showSnackBar(isAr ? 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى.' : 'Session expired, please log in again.', Colors.red);
        await userProvider.logout();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      } else if (e.toString().contains('user_id_missing')) {
        _showSnackBar(
          isAr
              ? 'لم يتم العثور على معرف المستخدم. يرجى تسجيل الخروج ثم تسجيل الدخول مرة أخرى.'
              : 'User ID is missing. Please log out and log in again.',
          Colors.orange,
        );
      } else {
        _showSnackBar(isAr ? 'فشل في حفظ البيانات.' : 'Failed to save.', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// حفظ ملف التقسيط فقط (الإقامة، الشيكات، إلخ)
  Future<void> _saveInstallmentProfile(UserProvider userProvider, bool isAr) async {
    if (!_validateFinanceAnswers(isAr)) return;

    setState(() => _isFinanceSaving = true);

    try {
      final success = await _apiService.updateFinanceProfileAnswers(
        residencyInQatar: _residentInQatar!,
        haveBankChecks: _hasChecks!,
        canGetBankChecks: _hasChecks == 'No' ? _canGetChecks : null,
      );

      if (!mounted) return;
      if (success) {
        await _loadFinanceProfile();
        if (!mounted) return;
        _showSnackBar(isAr ? 'تم حفظ ملف التقسيط بنجاح!' : 'Installment profile saved successfully!', const Color(0xFF6FE0DA));
      } else {
        _showSnackBar(isAr ? 'فشل في حفظ ملف التقسيط.' : 'Failed to save installment profile.', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('expired_token')) {
        _showSnackBar(isAr ? 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى.' : 'Session expired, please log in again.', Colors.red);
        await userProvider.logout();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showSnackBar(isAr ? 'فشل في حفظ ملف التقسيط.' : 'Failed to save installment profile.', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isFinanceSaving = false);
    }
  }

  Future<void> _pickAndUploadDocuments({
    required String category,
    required bool isAr,
    bool allowMultiple = false,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      setState(() => _isAttachmentBusy = true);

      for (final file in result.files) {
        await _apiService.uploadFinanceDocument(
          category: category,
          file: file,
        );
      }

      await _loadFinanceProfile();
      if (!mounted) return;
      _showSnackBar(
        isAr ? 'تم رفع المرفقات بنجاح.' : 'Documents uploaded successfully.',
        const Color(0xFF6FE0DA),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        isAr ? 'تعذر رفع الملفات.' : 'Failed to upload files.',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isAttachmentBusy = false);
      }
    }
  }

  Future<void> _deleteDocument({
    required String category,
    required String documentId,
    required bool isAr,
  }) async {
    try {
      setState(() => _isAttachmentBusy = true);
      await _apiService.deleteFinanceDocument(
        category: category,
        documentId: documentId,
      );
      await _loadFinanceProfile();
      if (!mounted) return;
      _showSnackBar(
        isAr ? 'تم حذف المرفق.' : 'Attachment deleted.',
        const Color(0xFF6FE0DA),
      );
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        isAr ? 'تعذر حذف المرفق.' : 'Failed to delete attachment.',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isAttachmentBusy = false);
      }
    }
  }

  Future<void> _openDocument(String url, bool isAr) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnackBar(
        isAr ? 'رابط المرفق غير صالح.' : 'Invalid attachment URL.',
        Colors.red,
      );
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      _showSnackBar(
        isAr ? 'تعذر فتح المرفق.' : 'Could not open attachment.',
        Colors.red,
      );
    }
  }

  void _confirmLogout(UserProvider userProvider, bool isAr) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isAr ? 'تأكيد تسجيل الخروج' : 'Confirm Logout', style: const TextStyle(color: Color(0xFF1A2543))),
        content: Text(isAr ? 'هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟' : 'Are you sure you want to log out from your account?', style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Color(0xFF1A2543))),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          ElevatedButton( // استخدام ElevatedButton لزر تسجيل الخروج
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isAr ? 'تسجيل الخروج' : 'Logout', style: const TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await userProvider.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating, // لجعلها عائمة
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // دالة للتحقق من صحة البريد الإلكتروني
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// القسم المعروض: 'account' = بياناتي وملف التقسيط فقط، 'app' = اللغة والإشعارات فقط، null = الكل
  static String? _getSectionArgument(BuildContext context) {
    return ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final languageCode = localeProvider.locale.languageCode;
    final isAr = languageCode == 'ar';
    final isLoggedIn = userProvider.isLoggedIn;
    final section = _getSectionArgument(context);

    final showGeneral = section == null || section == 'app';
    final showAccountAndFinance = section == null || (section == 'account' && isLoggedIn);

    String appBarTitle;
    if (section == 'account') {
      appBarTitle = isAr ? 'بياناتي وملف التقسيط' : 'My data & installment profile';
    } else if (section == 'app') {
      appBarTitle = isAr ? 'إعدادات التطبيق' : 'App settings';
    } else {
      appBarTitle = isAr ? 'الإعدادات / Settings' : 'الإعدادات / Settings';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: const Color(0xFF1A2543),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          if (showGeneral) ...[
            _buildSectionHeader(isAr ? 'عام' : 'General', context),
            const SizedBox(height: 12),
            _sectionCard(
              icon: Icons.language_rounded,
              title: isAr ? 'اللغة / Language' : 'اللغة / Language',
            trailing: DropdownButtonHideUnderline( // إخفاء الخط السفلي
              child: DropdownButton<String>(
                value: languageCode,
                icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF1A2543)), // أيقونة سهم أوضح
                onChanged: (value) {
                  if (value != null) {
                    localeProvider.setLocale(Locale(value));
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
                    });
                  }
                },
                items: [
                  DropdownMenuItem(
                      value: 'ar',
                      child: Text('عربي / Arabic',
                          style: const TextStyle(color: Color(0xFF1A2543)))),
                  DropdownMenuItem(
                      value: 'en',
                      child: Text('إنجليزي / English',
                          style: const TextStyle(color: Color(0xFF1A2543)))),
                ],
                dropdownColor: Colors.white, // لون قائمة الخيارات
                borderRadius: BorderRadius.circular(12), // حواف دائرية للقائمة المنسدلة
              ),
            ),
          ),
          const SizedBox(height: 10),

            _sectionCard(
              icon: Icons.notifications_active_outlined,
              title: isAr ? 'الإشعارات' : 'Notifications',
              trailing: Switch.adaptive(
                value: notificationsEnabled,
                onChanged: (val) async {
                  await _notificationService.setNotificationsEnabled(val);
                  setState(() => notificationsEnabled = val);
                },
                activeColor: const Color(0xFF6FE0DA),
                inactiveTrackColor: Colors.grey.shade300,
                inactiveThumbColor: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
          ],

          if (showAccountAndFinance) ...[
            _buildSectionHeader(isAr ? "معلومات الحساب" : "Account Info", context),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _nameController,
              hint: isAr ? 'الاسم الكامل' : 'Full Name',
              icon: Icons.person_outline_rounded, // أيقونة أوضح
            ),
            const SizedBox(height: 15),
            _buildInputField(
              controller: _emailController,
              hint: isAr ? 'البريد الإلكتروني' : 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            _buildInputField(
              controller: _phoneController,
              hint: isAr ? 'رقم الجوال' : 'Phone Number',
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            _buildInputField(
              controller: _passwordController,
              hint: isAr ? 'كلمة المرور الجديدة (اترك فارغاً لعدم التغيير)' : 'New Password (leave blank to keep current)',
              icon: Icons.lock_outline_rounded, // أيقونة أوضح
              obscure: true,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : const Icon(Icons.save_alt_rounded, color: Colors.white, size: 24),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2543),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              label: Text(
                isAr ? 'حفظ بيانات الحساب' : 'Save account info',
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              ),
              onPressed: _isLoading ? null : () => _saveAccountInfo(userProvider, isAr),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(
              isAr ? 'ملف التقسيط' : 'Installment Profile',
              context,
            ),
            const SizedBox(height: 15),
            _buildFinanceSection(isAr),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: _isFinanceSaving
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : const Icon(Icons.save_rounded, color: Colors.white, size: 24),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2543),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              label: Text(
                isAr ? 'حفظ ملف التقسيط' : 'Save installment profile',
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              ),
              onPressed: _isFinanceSaving ? null : () => _saveInstallmentProfile(userProvider, isAr),
            ),
            const SizedBox(height: 40),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), // حواف دائرية أكثر
                side: BorderSide(color: Colors.red.shade100, width: 1.5), // حدود خفيفة
              ),
              tileColor: Colors.red.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // حشوة داخلية
              leading: const Icon(Icons.logout_rounded, color: Colors.red, size: 26), // أيقونة أوضح وأكبر
              title: Text(
                isAr ? 'تسجيل الخروج' : 'Logout',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 17), // خط أكثر سمكاً وحجماً
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.red, size: 20), // سهم أوضح
              onTap: () => _confirmLogout(userProvider, isAr),
            ),
            const SizedBox(height: 40),
          ],

          const SizedBox(height: 24),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          _buildSectionHeader(isAr ? 'الدعم والمساعدة' : 'Support & Help', context),
          const SizedBox(height: 15),
          _sectionCard(
            icon: Icons.support_agent_rounded, // أيقونة أوضح
            title: isAr ? 'الاستفسارات والشكاوى' : 'Inquiries & Complaints',
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF1A2543)), // سهم أوضح
            onTap: () => _showContactDialog(isAr), // إضافة onTap إلى البطاقة مباشرة
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // دالة مساعدة لبناء رأس القسم
  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: const Color(0xFF1A2543),
          letterSpacing: 0.5, // مسافة بين الحروف
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap, // جعل onTap اختيارياً
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // حواف دائرية أكثر
      elevation: 3, // ظل أكبر للبطاقة
      shadowColor: Colors.grey.withOpacity(0.2), // لون ظل البطاقة
      child: InkWell( // استخدام InkWell لتوفير تأثير النقر على البطاقة بالكامل
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // حشوة داخلية للبطاقة
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF1A2543), size: 28), // أيقونة أكبر
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1A2543),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF1A2543)), // لون النص المدخل
      cursorColor: const Color(0xFF6FE0DA), // لون مؤشر الكتابة
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF6FE0DA), size: 24), // أيقونة أكبر
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500), // لون نص التلميح
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18), // حشوة أكبر للحقل
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), // حواف دائرية أكثر
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5), // حدود أسمك
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF6FE0DA), width: 3), // حدود أسمك عند التركيز
        ),
      ),
    );
  }

  Widget _buildFinanceSection(bool isAr) {
    if (_isFinanceLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionSelector(
              label: isAr ? 'هل تقيم في قطر؟' : 'Do you live in Qatar?',
              value: _residentInQatar,
              onChanged: (value) {
                setState(() {
                  _residentInQatar = value;
                  if (value != 'Yes') {
                    _hasChecks = null;
                    _canGetChecks = null;
                  }
                });
              },
              isAr: isAr,
            ),
            const SizedBox(height: 12),
            _buildQuestionSelector(
              label: isAr
                  ? 'هل لديك شيكات بنكية باسمك؟'
                  : 'Do you have bank checks in your name?',
              value: _hasChecks,
              onChanged: _residentInQatar == 'Yes'
                  ? (value) {
                      setState(() {
                        _hasChecks = value;
                        if (value != 'No') {
                          _canGetChecks = null;
                        }
                      });
                    }
                  : null,
              isAr: isAr,
            ),
            if (_hasChecks == 'No') ...[
              const SizedBox(height: 12),
              _buildQuestionSelector(
                label: isAr
                    ? 'هل يمكنك استخراج شيكات بنكية باسمك؟'
                    : 'Can you issue bank checks in your name?',
                value: _canGetChecks,
                onChanged: (value) => setState(() => _canGetChecks = value),
                isAr: isAr,
              ),
            ],
            const SizedBox(height: 12),
            _buildInstallmentDisclosure(isAr),
            const SizedBox(height: 20),
            _buildAttachmentGroup(
              title: isAr
                  ? 'صورة البطاقة الشخصية (الوجه الأمامي)'
                  : 'ID Card (Front)',
              documents: _financeProfile.idCardFront == null
                  ? const []
                  : [_financeProfile.idCardFront!],
              uploadLabel: isAr ? 'رفع / استبدال' : 'Upload / Replace',
              onUpload: () => _pickAndUploadDocuments(
                category: 'id_card_front',
                isAr: isAr,
              ),
              onDelete: (doc) => _deleteDocument(
                category: 'id_card_front',
                documentId: doc.id,
                isAr: isAr,
              ),
              isAr: isAr,
            ),
            const SizedBox(height: 16),
            _buildAttachmentGroup(
              title: isAr
                  ? 'صورة البطاقة الشخصية (الوجه الخلفي)'
                  : 'ID Card (Back)',
              documents: _financeProfile.idCardBack == null
                  ? const []
                  : [_financeProfile.idCardBack!],
              uploadLabel: isAr ? 'رفع / استبدال' : 'Upload / Replace',
              onUpload: () => _pickAndUploadDocuments(
                category: 'id_card_back',
                isAr: isAr,
              ),
              onDelete: (doc) => _deleteDocument(
                category: 'id_card_back',
                documentId: doc.id,
                isAr: isAr,
              ),
              isAr: isAr,
            ),
            const SizedBox(height: 16),
            _buildAttachmentGroup(
              title: isAr
                  ? 'كشف حساب آخر 3 شهور'
                  : 'Bank Statements (Last 3 Months)',
              documents: _financeProfile.bankStatements,
              uploadLabel: isAr ? 'إضافة ملفات' : 'Add Files',
              onUpload: () => _pickAndUploadDocuments(
                category: 'bank_statements',
                isAr: isAr,
                allowMultiple: true,
              ),
              onDelete: (doc) => _deleteDocument(
                category: 'bank_statements',
                documentId: doc.id,
                isAr: isAr,
              ),
              isAr: isAr,
            ),
            const SizedBox(height: 16),
            _buildAttachmentGroup(
              title: isAr ? 'مرفقات إضافية' : 'Additional Attachments',
              documents: _financeProfile.additionalAttachments,
              uploadLabel: isAr ? 'إضافة ملفات' : 'Add Files',
              onUpload: () => _pickAndUploadDocuments(
                category: 'additional_attachments',
                isAr: isAr,
                allowMultiple: true,
              ),
              onDelete: (doc) => _deleteDocument(
                category: 'additional_attachments',
                documentId: doc.id,
                isAr: isAr,
              ),
              isAr: isAr,
            ),
            if (_isAttachmentBusy) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isAr ? 'جاري تحديث المرفقات...' : 'Updating attachments...',
                    style: const TextStyle(color: Color(0xFF1A2543)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionSelector({
    required String label,
    required String? value,
    required ValueChanged<String?>? onChanged,
    required bool isAr,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: [
        DropdownMenuItem(
          value: 'Yes',
          child: Text(isAr ? 'نعم' : 'Yes'),
        ),
        DropdownMenuItem(
          value: 'No',
          child: Text(isAr ? 'لا' : 'No'),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildInstallmentDisclosure(bool isAr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAr
                  ? 'تُطلب مستندات الهوية وكشف الحساب فقط لمراجعة أهلية طلبات التقسيط، والتحقق من البيانات، والمساعدة في منع الاحتيال. رفع المستندات أو حفظ الملف لا يعني الموافقة النهائية تلقائياً.'
                  : 'ID and bank-statement documents are requested only to review installment eligibility, verify submitted information, and help prevent fraud. Uploading documents or saving the profile does not mean automatic final approval.',
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                height: 1.45,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentGroup({
    required String title,
    required List<ProfileDocument> documents,
    required String uploadLabel,
    required VoidCallback onUpload,
    required ValueChanged<ProfileDocument> onDelete,
    required bool isAr,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
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
                onPressed: _isAttachmentBusy ? null : onUpload,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(uploadLabel),
              ),
            ],
          ),
          if (documents.isEmpty)
            Text(
              isAr ? 'لا توجد ملفات مرفوعة.' : 'No uploaded files.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...documents.map(
              (doc) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_file_rounded),
                title: Text(
                  doc.name.isEmpty ? doc.url : doc.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _openDocument(doc.url, isAr),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: _isAttachmentBusy ? null : () => onDelete(doc),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showContactDialog(bool isAr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // حواف دائرية أكثر
        title: Text(isAr ? 'وسائل التواصل' : 'Contact Methods', style: const TextStyle(color: Color(0xFF1A2543), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContactTile(
              icon: Icons.phone_android_rounded, // أيقونة واتساب
              title: isAr ? "قسم التحصيل" : "Collections",
              subtitle: "50105685",
              color: Colors.green.shade600, // لون أخضر داكن
              onTap: () => _openWhatsApp("+97450105685", isAr),
            ),
            _buildContactTile(
              icon: Icons.phone_android_rounded,
              title: isAr ? "الاستفسار والطلب والمبيعات" : "Inquiries, orders & sales",
              subtitle: "77704313",
              color: Colors.green.shade600,
              onTap: () => _openWhatsApp("+97477704313", isAr),
            ),
            _buildContactTile(
              icon: Icons.phone_android_rounded,
              title: isAr ? "الاستفسار والطلب والمبيعات" : "Inquiries, orders & sales",
              subtitle: "71727771",
              color: Colors.green.shade600,
              onTap: () => _openWhatsApp("+97471727771", isAr),
            ),
            _buildContactTile(
              icon: Icons.email_rounded, // أيقونة بريد إلكتروني
              title: "support@creditphoneqatar.com",
              color: Colors.blue.shade600, // لون أزرق داكن
              onTap: () => _launchEmail("support@creditphoneqatar.com", isAr),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(isAr ? 'إغلاق' : 'Close', style: const TextStyle(color: Color(0xFF1A2543))),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  // دالة مساعدة لبناء عناصر الاتصال
  Widget _buildContactTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(title, style: const TextStyle(color: Color(0xFF1A2543), fontSize: 16, fontWeight: FontWeight.w700)),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: Colors.grey.shade50,
      ),
    );
  }

  void _openWhatsApp(String phoneNumber, bool isAr) async {
    final url = "https://wa.me/$phoneNumber";
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        _showSnackBar(isAr ? 'تعذر فتح واتساب. الرجاء التأكد من تثبيت التطبيق.' : 'Could not open WhatsApp. Please ensure the app is installed.', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(isAr ? 'حدث خطأ أثناء فتح واتساب.' : 'An error occurred while opening WhatsApp.', Colors.red);
    }
  }

  void _launchEmail(String email, bool isAr) async {
    final uri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        _showSnackBar(isAr ? 'تعذر فتح تطبيق البريد الإلكتروني.' : 'Could not open email app.', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(isAr ? 'حدث خطأ أثناء فتح تطبيق البريد الإلكتروني.' : 'An error occurred while opening the email app.', Colors.red);
    }
  }
}