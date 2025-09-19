import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final NotificationService _notificationService = NotificationService();
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges(
      UserProvider userProvider, bool isAr) async {
    // التحقق من صحة البريد الإلكتروني ورقم الهاتف قبل الإرسال
    if (!_isValidEmail(_emailController.text.trim())) {
      _showSnackBar(isAr ? 'الرجاء إدخال بريد إلكتروني صحيح.' : 'Please enter a valid email address.', Colors.red);
      return;
    }
    // يمكنك إضافة التحقق من رقم الهاتف هنا إذا كان لديك صيغة معينة

    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    bool success = false;
    try {
      success = await _apiService.updateUserInfo(
        name: name,
        email: email,
        phone: phone,
        password: password.isNotEmpty ? password : null,
      );
    } catch (e) {
      if (e.toString().contains('expired_token')) {
        if (!mounted) return;
        _showSnackBar(isAr ? 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى.' : 'Session expired, please log in again.', Colors.red);
        await userProvider.logout();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        setState(() {
          _isLoading = false;
        });
        return;
      } else if (e.toString().contains('user_id_missing')) {
        if (!mounted) return;
        _showSnackBar(
          isAr
              ? 'لم يتم العثور على معرف المستخدم. يرجى تسجيل الخروج ثم تسجيل الدخول مرة أخرى لإعادة المزامنة.'
              : 'User ID is missing. Please log out and log in again to refresh your data.',
          Colors.orange,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    if (success) {
      await userProvider.updateUser(
        username: name,
        email: email,
        phone: phone,
      );
      if (!mounted) return;
      _showSnackBar(isAr ? 'تم حفظ البيانات بنجاح!' : 'Changes saved successfully!', const Color(0xFF6FE0DA));
    } else {
      _showSnackBar(isAr ? 'فشل في حفظ البيانات. الرجاء المحاولة مرة أخرى.' : 'Failed to save changes. Please try again.', Colors.red);
    }

    setState(() {
      _isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final languageCode = localeProvider.locale.languageCode;
    final isAr = languageCode == 'ar';
    final isLoggedIn = userProvider.isLoggedIn;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: Text(isAr ? 'الإعدادات / Settings' : 'الإعدادات / Settings'), // عنوان أبسط
        backgroundColor: const Color(0xFF1A2543),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4, // زيادة الظل لإبراز شريط التطبيق
        shadowColor: Colors.black.withOpacity(0.3), // لون الظل
      ),
      body: ListView(
        padding: const EdgeInsets.all(20), // زيادة الهامش العام
        physics: const BouncingScrollPhysics(), // تأثير الارتداد عند التمرير
        children: [
          _buildSectionHeader(isAr ? 'عام' : 'General', context),
          const SizedBox(height: 15),

          _sectionCard(
            icon: Icons.language_rounded, // أيقونة أوضح
            title: isAr ? 'اللغة / Language' : 'اللغة / Language',
            trailing: DropdownButtonHideUnderline( // إخفاء الخط السفلي
              child: DropdownButton<String>(
                value: languageCode,
                icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF1A2543)), // أيقونة سهم أوضح
                onChanged: (value) {
                  if (value != null) {
                    localeProvider.setLocale(Locale(value));
                    Future.delayed(const Duration(milliseconds: 300), () {
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
            trailing: Switch.adaptive( // استخدام Switch.adaptive لتناسب المنصات المختلفة
              value: notificationsEnabled,
              onChanged: (val) async {
                await _notificationService.setNotificationsEnabled(val);
                setState(() => notificationsEnabled = val);
              },
              activeColor: const Color(0xFF6FE0DA),
              inactiveTrackColor: Colors.grey.shade300, // لون خلفية أفتح عند الإيقاف
              inactiveThumbColor: Colors.grey.shade600, // لون الزر عند الإيقاف
            ),
          ),

          const SizedBox(height: 40), // مسافة أكبر بين الأقسام
          if (isLoggedIn) ...[
            _buildSectionHeader(isAr ? "معلومات الحساب" : "Account Info", context),
            const SizedBox(height: 15),
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
                width: 24, // حجم أكبر للمؤشر
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5, // سمك أكبر للمؤشر
                ),
              )
                  : const Icon(Icons.save_alt_rounded, color: Colors.white, size: 24), // أيقونة أوضح
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2543),
                padding: const EdgeInsets.symmetric(vertical: 18), // حشوة أكبر للزر
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // حواف دائرية أكثر للزر
                elevation: 0, // ظل أكبر للزر
              ),
              label: Text(
                isAr ? 'حفظ التعديلات' : 'Save Changes',
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600), // خط أكبر وأكثر سمكاً
              ),
              onPressed: _isLoading ? null : () => _saveChanges(userProvider, isAr),
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
              title: "50105685",
              color: Colors.green.shade600, // لون أخضر داكن
              onTap: () => _openWhatsApp("+97450105685", isAr),
            ),
            _buildContactTile(
              icon: Icons.phone_android_rounded,
              title: "77704313",
              color: Colors.green.shade600,
              onTap: () => _openWhatsApp("+97477704313", isAr),
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
    required Color color,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(title, style: const TextStyle(color: Color(0xFF1A2543), fontSize: 16)),
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