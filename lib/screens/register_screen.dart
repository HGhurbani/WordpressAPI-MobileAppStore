import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController  = TextEditingController();
  final _confirmController  = TextEditingController();
  final _authService = AuthService(); // تأكد من وجود دالة register في AuthService
  bool _loading = false;

  void _register() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("كلمة المرور غير متطابقة")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // إنشاء الحساب
      await _authService.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _phoneController.text.trim(),
      );

      // تسجيل الدخول تلقائي بعد إنشاء الحساب
      final user = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      Provider.of<UserProvider>(context, listen: false).setUser(user);
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final String language = localeProvider.locale.languageCode;

    // تعيين النصوص بناءً على اللغة
    final String titleText = language == "ar" ? "إنشاء حساب" : "Register";
    final String usernameHint = language == "ar" ? "اسم المستخدم" : "Username";
    final String emailHint = language == "ar" ? "البريد الإلكتروني" : "Email";
    final String passwordHint = language == "ar" ? "كلمة المرور" : "Password";
    final String confirmHint = language == "ar" ? "تأكيد كلمة المرور" : "Confirm Password";
    final String buttonText = language == "ar" ? "إنشاء حساب" : "Register";

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.15),
              // شعار صفحة التسجيل
              Image.asset(
                'assets/images/logo_login.png',
                height: 120,
              ),
              SizedBox(height: size.height * 0.05),
              // عنوان الصفحة
              Text(
                titleText,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1d0fe3),
                ),
              ),
              SizedBox(height: size.height * 0.05),
              // حقل اسم المستخدم
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person, color: const Color(0xFF1d0fe3)),
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
              // حقل البريد الإلكتروني
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email, color: const Color(0xFF1d0fe3)),
                  hintText: emailHint,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // حقل كلمة المرور
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock, color: const Color(0xFF1d0fe3)),
                  hintText: passwordHint,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // حقل تأكيد كلمة المرور
              TextField(
                controller: _confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline, color: const Color(0xFF1d0fe3)),
                  hintText: confirmHint,
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
                  ? CircularProgressIndicator(color: const Color(0xFF1d0fe3))
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1d0fe3),
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
