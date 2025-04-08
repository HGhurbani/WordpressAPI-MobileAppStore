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

    final appBarTitle = language == 'ar' ? "حسابي" : "Profile";
    final notLoggedInText = language == 'ar' ? "لم تقم بتسجيل الدخول" : "You are not logged in";
    final loginButtonText = language == 'ar' ? "تسجيل الدخول" : "Login";
    final registerButtonText = language == 'ar' ? "إنشاء حساب" : "Register";
    final welcomeText = language == 'ar' ? "مرحباً،" : "Welcome,";
    final emailText = language == 'ar' ? "بريدك:" : "Your email:";
    final logoutButtonText = language == 'ar' ? "تسجيل الخروج" : "Logout";
    final ordersText = language == 'ar' ? "طلباتي" : "My Orders";
    final addressText = language == 'ar' ? "عناويني" : "My Address";
    final settingsText = language == 'ar' ? "الإعدادات" : "Settings";

    if (!userProvider.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: Text(appBarTitle),
          centerTitle: true,
          backgroundColor: const Color(0xFF1d0fe3),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  notLoggedInText,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1d0fe3),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
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
                      backgroundColor: const Color(0xff1d0fe3),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
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

    final user = userProvider.user!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: const Color(0xFF1d0fe3),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[300],
            child: Text(user.username[0].toUpperCase(), style: const TextStyle(fontSize: 32, color: Colors.white)),
          ),
          const SizedBox(height: 16),
          Text("$welcomeText ${user.username}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text("$emailText ${user.email}", style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 24),

          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: Text(ordersText),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, '/orders'),
          ),
          const Divider(),

          // ListTile(
          //   leading: const Icon(Icons.location_on_outlined),
          //   title: Text(addressText),
          //   trailing: const Icon(Icons.arrow_forward_ios),
          //   onTap: () => Navigator.pushNamed(context, '/addresses'),
          // ),
          // const Divider(),

          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(settingsText),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          const Divider(),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1d0fe3),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 50),
              ),
              onPressed: () {
                userProvider.logout();
                Navigator.pushReplacementNamed(context, '/main');
              },
              child: Text(logoutButtonText),
            ),
          ),
        ],
      ),
    );
  }

}
