import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../providers/user_provider.dart';

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

  @override
  void initState() {
    super.initState();
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
      appBar: AppBar(
        title: Text(isAr ? 'الإعدادات' : 'Settings'),
        backgroundColor: const Color(0xff1d0fe3),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            icon: Icons.language,
            title: isAr ? 'اللغة' : 'Language',
            trailing: DropdownButton<String>(
              value: languageCode,
              underline: const SizedBox(),
              onChanged: (value) {
                if (value != null) localeProvider.setLocale(Locale(value));
              },
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _sectionCard(
            icon: Icons.notifications,
            title: isAr ? 'الإشعارات' : 'Notifications',
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (val) => setState(() => notificationsEnabled = val),
              activeColor: const Color(0xff1d0fe3),
            ),
          ),
          const SizedBox(height: 20),

          if (isLoggedIn) ...[
            Text(isAr ? "المعلومات الشخصية" : "Personal Info",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _buildInputField(
              controller: _nameController,
              hint: isAr ? 'الاسم' : 'Name',
              icon: Icons.person,
            ),
            const SizedBox(height: 10),
            _buildInputField(
              controller: _emailController,
              hint: isAr ? 'البريد الإلكتروني' : 'Email',
              icon: Icons.email,
            ),
            const SizedBox(height: 10),
            _buildInputField(
              controller: _phoneController,
              hint: isAr ? 'رقم الهاتف' : 'Phone',
              icon: Icons.phone,
            ),
            const SizedBox(height: 10),
            _buildInputField(
              controller: _passwordController,
              hint: isAr ? 'كلمة المرور' : 'Password',
              icon: Icons.lock,
              obscure: true,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1d0fe3),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              label: Text(isAr ? 'حفظ التعديلات' : 'Save Changes', style: const TextStyle(color: Colors.white)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isAr ? 'تم حفظ البيانات' : 'Changes saved'),
                ));
              },
            ),
            const SizedBox(height: 40),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                isAr ? 'تسجيل الخروج' : 'Logout',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                userProvider.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required Widget trailing}) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xff1d0fe3)),
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
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xff1d0fe3)),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
