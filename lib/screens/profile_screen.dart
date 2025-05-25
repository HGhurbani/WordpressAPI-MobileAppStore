import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/locale_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final language = localeProvider.locale.languageCode;
    final isArabic = language == 'ar';

    final appBarTitle = isArabic ? "حسابي" : "Profile";
    final notLoggedInText = isArabic ? "لم تقم بتسجيل الدخول" : "You are not logged in";
    final loginButtonText = isArabic ? "تسجيل الدخول" : "Login";
    final registerButtonText = isArabic ? "إنشاء حساب" : "Register";

    if (!userProvider.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: Text(appBarTitle),
          centerTitle: true,
          backgroundColor: const Color(0xFF1A2543),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(notLoggedInText, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2543),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: Text(loginButtonText),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6FE0DA),
                      foregroundColor: const Color(0xFF1A2543),
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: Text(registerButtonText),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: const Color(0xFF1A2543),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _buildProfileContent(context, localeProvider, userProvider),
    );
  }

  Widget _buildProfileContent(BuildContext context, LocaleProvider localeProvider, UserProvider userProvider) {
    final language = localeProvider.locale.languageCode;
    final isArabic = language == 'ar';

    final user = userProvider.user!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFF1A2543),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF6FE0DA),
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isArabic ? "مرحباً، ${user.username}" : "Welcome, ${user.username}",
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  "${isArabic ? 'البريد الإلكتروني:' : 'Email:'} ${user.email}",
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        _buildOptionCard(
          context,
          icon: Icons.shopping_bag,
          label: isArabic ? 'طلباتي' : 'My Orders',
          onTap: () => Navigator.pushNamed(context, '/orders'),
        ),
        _buildOptionCard(
          context,
          icon: Icons.settings,
          label: isArabic ? 'الإعدادات / Settings' : 'الإعدادات / Settings',
          onTap: () => Navigator.pushNamed(context, '/settings'),
        ),

        const SizedBox(height: 30),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A2543),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          ),
          icon: const Icon(Icons.logout,color: Colors.white,),
          label: Text(isArabic ? 'تسجيل الخروج' : 'Logout'),
          onPressed: () {
            userProvider.logout();
            Navigator.pushReplacementNamed(context, '/main');
          },
        ),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          ),
          icon: const Icon(Icons.delete_forever, color: Colors.red,),
          label: Text(isArabic ? 'حذف الحساب' : 'Delete Account'),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(isArabic ? 'تأكيد الحذف' : 'Confirm Delete'),
                content: Text(isArabic
                    ? 'هل أنت متأكد من حذف حسابك؟ لا يمكن التراجع.'
                    : 'Are you sure you want to delete your account? This cannot be undone.'),
                actions: [
                  TextButton(
                    child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  TextButton(
                    child: Text(isArabic ? 'تأكيد الحذف' : 'Delete'),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await userProvider.deleteAccount();
              Navigator.pushReplacementNamed(context, '/main');
            }
          },
        ),
      ],
    );
  }

  Widget _buildOptionCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1A2543)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
