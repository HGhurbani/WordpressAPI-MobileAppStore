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
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;

  void _register() async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final language = localeProvider.locale.languageCode;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _loading = true);

    try {
      await _authService.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _phoneController.text.trim(),
      );

      final user = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      Provider.of<UserProvider>(context, listen: false).setUser(user);
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(language == "ar" ? "فشل: $e" : "Failed: $e"),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final String language = localeProvider.locale.languageCode;

    final String titleText = language == "ar" ? "إنشاء حساب" : "Register";
    final String usernameHint = language == "ar" ? "اسم المستخدم" : "Username";
    final String emailHint = language == "ar" ? "البريد الإلكتروني" : "Email";
    final String passwordHint = language == "ar" ? "كلمة المرور" : "Password";
    final String confirmHint = language == "ar" ? "تأكيد كلمة المرور" : "Confirm Password";
    final String buttonText = language == "ar" ? "إنشاء حساب" : "Register";

    final size = MediaQuery.of(context).size;

    final String usernameError = language == "ar"
        ? "يرجى إدخال اسم المستخدم"
        : "Please enter a username";
    final String emailError = language == "ar"
        ? "يرجى إدخال بريد إلكتروني صالح"
        : "Please enter a valid email";
    final String phoneError = language == "ar"
        ? "يرجى إدخال رقم جوال"
        : "Please enter a phone number";
    final String passwordError = language == "ar"
        ? "يرجى إدخال كلمة المرور"
        : "Please enter a password";
    final String confirmEmptyError = language == "ar"
        ? "يرجى تأكيد كلمة المرور"
        : "Please confirm your password";
    final String confirmError = language == "ar"
        ? "كلمة المرور غير متطابقة"
        : "Passwords do not match";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
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
                const SizedBox(height: 30),
                TextFormField(
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return usernameError;
                    }
                    return null;
                  },
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
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(email)) {
                      return emailError;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email, color: Color(0xFF1A2543)),
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
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return phoneError;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone, color: Color(0xFF1A2543)),
                    hintText: language == "ar" ? "رقم الجوال" : "Phone",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return passwordError;
                    }
                    return null;
                  },
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
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return confirmEmptyError;
                    }
                    if (value != _passwordController.text) {
                      return confirmError;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1A2543)),
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
                    ? const CircularProgressIndicator(color: Color(0xFF1A2543))
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A2543),
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }
}
