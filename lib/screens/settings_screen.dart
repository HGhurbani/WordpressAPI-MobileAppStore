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
  final NotificationService _notificationService = NotificationService();

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
        title: Text(isAr ? 'الإعدادات / Settings' : 'Settings / الإعدادات'),
        backgroundColor: const Color(0xFF1A2543),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            isAr ? 'عام' : 'General',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A2543)),
          ),
          const SizedBox(height: 10),

          _sectionCard(
            icon: Icons.language,
            title: isAr ? 'Language / اللغة' : 'Language / اللغة',
            trailing: DropdownButton<String>(
              value: languageCode,
              underline: const SizedBox(),
              onChanged: (value) {
                if (value != null) {
                  localeProvider.setLocale(Locale(value));

                  // إعادة توجيه المستخدم للصفحة الرئيسية
                  Future.delayed(const Duration(milliseconds: 300), () {
                    Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
                  });
                }
              },

              items: const [
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _sectionCard(
            icon: Icons.notifications_active_outlined,
            title: isAr ? 'الإشعارات' : 'Notifications',
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (val) async {
                await _notificationService.setNotificationsEnabled(val);
                setState(() => notificationsEnabled = val);
              },
              activeColor: const Color(0xFF6FE0DA), // اللون عند التشغيل
              inactiveTrackColor: Colors.grey.shade400, // لون الخلفية عند الإيقاف
              inactiveThumbColor: Colors.grey.shade700, // لون الزر عند الإيقاف
            )

          ),

          const SizedBox(height: 30),
          if (isLoggedIn) ...[
            Text(
              isAr ? "معلومات الحساب" : "Account Info",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A2543)),
            ),
            const SizedBox(height: 10),
            _buildInputField(
              controller: _nameController,
              hint: isAr ? 'الاسم الكامل' : 'Full Name',
              icon: Icons.person,
            ),
            const SizedBox(height: 10),
            _buildInputField(
              controller: _emailController,
              hint: isAr ? 'البريد الإلكتروني' : 'Email',
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 10),
            _buildInputField(
              controller: _phoneController,
              hint: isAr ? 'رقم الجوال' : 'Phone Number',
              icon: Icons.phone_android_outlined,
            ),
            const SizedBox(height: 10),
            _buildInputField(
              controller: _passwordController,
              hint: isAr ? 'كلمة المرور الجديدة' : 'New Password',
              icon: Icons.lock_outline,
              obscure: true,
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2543),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              label: Text(
                isAr ? 'حفظ التعديلات' : 'Save Changes',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              onPressed: () async {
                final name = _nameController.text.trim();
                final email = _emailController.text.trim();
                final phone = _phoneController.text.trim();
                final password = _passwordController.text.trim();

                final success = await ApiService().updateUserInfo(
                  name: name,
                  email: email,
                  phone: phone,
                  password: password.isNotEmpty ? password : null,
                );

                if (success) {
                  // تحديث بيانات المستخدم في UserProvider
                  userProvider.updateUser(
                    username: name,
                    email: email,
                    phone: phone,
                  );

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: const Color(0xFF6FE0DA),
                    content: Text(isAr ? 'تم حفظ البيانات بنجاح' : 'Changes saved successfully'),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(isAr ? 'فشل في حفظ البيانات' : 'Failed to save changes'),
                  ));
                }
              },

            ),
            const SizedBox(height: 30),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.red.shade50,
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                isAr ? 'تسجيل الخروج' : 'Logout',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                userProvider.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
            const SizedBox(height: 30),
          ],

          Text(
            isAr ? 'الدعم والمساعدة' : 'Support & Help',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A2543)),
          ),
          const SizedBox(height: 10),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.grey.shade100,
            leading: const Icon(Icons.support_agent, color: Color(0xFF1A2543)),
            title: Text(isAr ? 'الاستفسارات والشكاوى' : 'Inquiries & Complaints'),
            onTap: () => _showContactDialog(isAr),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required Widget trailing}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1A2543)),
        title: Text(title),
        trailing: trailing,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF6FE0DA)),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _showContactDialog(bool isAr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isAr ? 'وسائل التواصل' : 'Contact Methods'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text("50105685"),
              onTap: () => _openWhatsApp("+97450105685"),
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text("77704313"),
              onTap: () => _openWhatsApp("+97477704313"),
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: Colors.blue),
              title: const Text("support@creditphoneqatar.com"),
              onTap: () => _launchEmail("support@creditphoneqatar.com"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(isAr ? 'إغلاق' : 'Close'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void _openWhatsApp(String phoneNumber) async {
    final url = "https://wa.me/$phoneNumber";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
