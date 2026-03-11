import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:creditphoneqa/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
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
  String? _generalError;

  String _getFriendlyRegisterErrorMessage(dynamic error) {
    final l10n = AppLocalizations.of(context)!;

    if (error is SocketException) {
      return l10n.authErrorNoInternet;
    }

    if (error is TimeoutException) {
      return l10n.authErrorTimeout;
    }

    if (error is AuthException) {
      final code = error.code.toLowerCase();
      final msg = error.message.toLowerCase();

      bool containsAny(String value, List<String> needles) =>
          needles.any((n) => value.contains(n));

      if (containsAny(code, ['email']) && containsAny(code, ['exists', 'already'])) {
        return l10n.authErrorEmailExists;
      }
      if (containsAny(code, ['username', 'user']) &&
          containsAny(code, ['exists', 'already', 'taken'])) {
        return l10n.authErrorUsernameExists;
      }
      if (containsAny(code, ['invalid_email']) ||
          (code.contains('email') && code.contains('invalid'))) {
        return l10n.authErrorInvalidEmail;
      }
      if (containsAny(code, ['weak_password']) ||
          (code.contains('password') && code.contains('weak'))) {
        return l10n.authErrorWeakPassword;
      }

      if (containsAny(msg, ['already registered', 'already exists', 'email exists'])) {
        return l10n.authErrorEmailExists;
      }
      if (containsAny(msg, ['username exists', 'username already', 'already taken'])) {
        return l10n.authErrorUsernameExists;
      }
      if (containsAny(msg, ['invalid email', 'email is not valid'])) {
        return l10n.authErrorInvalidEmail;
      }
      if (containsAny(msg, ['weak password', 'password is too weak'])) {
        return l10n.authErrorWeakPassword;
      }
    }

    final raw = error.toString().toLowerCase();
    if (raw.contains('woocommerce') ||
        raw.contains('server error') ||
        raw.contains('internal server error') ||
        raw.contains('503') ||
        raw.contains('502')) {
      return l10n.authErrorServerIssue;
    }

    return l10n.authErrorGenericRegister;
  }

  void _register() async {
    setState(() => _generalError = null);

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
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.authRegisterSuccess)),
            ],
          ),
          backgroundColor: const Color(0xFF6FE0DA),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(milliseconds: 900),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _generalError = _getFriendlyRegisterErrorMessage(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final size = MediaQuery.of(context).size;

    final String usernameError = l10n.authEnterUsername;
    final String emailError = l10n.authEnterEmailValid;
    final String phoneError = l10n.authEnterPhone;
    final String passwordError = l10n.authEnterPassword;
    final String confirmEmptyError = l10n.authEnterConfirmPassword;
    final String confirmError = l10n.authPasswordsDoNotMatch;

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
                  l10n.authRegisterTitle,
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
                    if (value.trim().length < 3) {
                      return l10n.authUsernameMinLength;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person, color: Color(0xFF1A2543)),
                    hintText: l10n.authUsernameHint,
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
                    hintText: l10n.authEmailHint,
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
                    hintText: l10n.authPhoneHint,
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
                    if (value.length < 6) {
                      return l10n.authPasswordMinLength;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF1A2543)),
                    hintText: l10n.authPasswordHint,
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
                    hintText: l10n.authConfirmPasswordHint,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (_generalError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _generalError!,
                            style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
                            l10n.authRegisterButton,
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
