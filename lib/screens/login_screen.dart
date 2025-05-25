import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../providers/locale_provider.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;

  void _login() async {
    setState(() => _loading = true);
    try {
      final user = await _authService.login(
        _usernameController.text,
        _passwordController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_token', user.token);
      await prefs.setString('user_name', user.username);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_phone', user.phone);

      Provider.of<UserProvider>(context, listen: false).setUser(user);
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل في تسجيل الدخول: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _skipLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final String language = localeProvider.locale.languageCode;
    final isAr = language == 'ar';

    final String titleText = isAr ? "تسجيل الدخول" : "Login";
    final String usernameHint = isAr ? "اسم المستخدم" : "Username";
    final String passwordHint = isAr ? "كلمة المرور" : "Password";
    final String buttonText = isAr ? "دخـول" : "Login";
    final String skipText = isAr ? "تخطي" : "Skip";
    final String forgotPasswordText = isAr ? "نسيت كلمة المرور؟" : "Forgot Password?";

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.12),
              Image.asset(
                'assets/images/logo_login.png',
                height: 200, // تم تكبير الشعار
              ),
              const SizedBox(height: 30),
              Text(
                titleText,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2543),
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person, color: Color(0xFF1A2543)),
                  hintText: usernameHint,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF1A2543)),
                  hintText: passwordHint,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _loading
                  ? const CircularProgressIndicator(color: Color(0xFF1A2543))
                  : ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2543),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  );
                },
                child: Text(
                  forgotPasswordText,
                  style: const TextStyle(color: Color(0xFF6FE0DA), fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _skipLogin,
                child: Text(
                  skipText,
                  style: const TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
              SizedBox(height: size.height * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
