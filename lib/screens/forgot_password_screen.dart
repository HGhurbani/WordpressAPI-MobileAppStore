import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _isSuccessMessage = false; // Add this to differentiate message type

  Future<void> _resetPassword() async {
    setState(() {
      _loading = true;
      _message = null;
      _isSuccessMessage = false;
    });

    final email = _emailController.text.trim();

    // Validate email format
    if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
      setState(() {
        _message = "الرجاء إدخال بريد إلكتروني صالح.";
        _isSuccessMessage = false;
        _loading = false;
      });
      return;
    }

    final url = Uri.parse('https://creditphoneqatar.com/wp-json/wp/v2/users/lost-password'); // ← غيّر الرابط حسب API فعلي

    try {
      final response = await http.post(
        url,
        body: jsonEncode({'email': email}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _message = "تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك.";
          _isSuccessMessage = true;
        });
      } else {
        final responseBody = json.decode(response.body);
        String errorMessage = "فشل في إرسال البريد. تأكد من صحة الإيميل.";
        if (responseBody['message'] != null) {
          errorMessage = responseBody['message']; // Use message from API if available
        }
        setState(() {
          _message = errorMessage;
          _isSuccessMessage = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = "حدث خطأ غير متوقع. الرجاء المحاولة لاحقاً.";
        _isSuccessMessage = false;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    // Define your brand colors
    const Color primaryColor = Color(0xFF1A2543); // Dark Blue
    const Color accentColor = Color(0xFFFDC029); // Example: A contrasting accent color (Yellow/Gold) if part of identity
    const Color textColor = Colors.black87;
    const Color successColor = Colors.green;
    const Color errorColor = Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? "نسيت كلمة المرور" : "Forgot Password"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0, // Remove shadow for a flatter design
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children horizontally
          children: [
            Text(
              isAr
                  ? "أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور."
                  : "Enter your email to receive a password reset link.",
              style: const TextStyle(fontSize: 16, color: textColor),
              textAlign: TextAlign.center, // Center the descriptive text
            ),
            const SizedBox(height: 32), // More spacing
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: isAr ? "البريد الإلكتروني" : "Email",
                labelStyle: TextStyle(color: primaryColor), // Label color
                prefixIcon: Icon(Icons.email, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2), // Border color when not focused
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 2), // Highlight when focused
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.5), width: 1), // Lighter border when not focused
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), // Adjust padding
              ),
              cursorColor: primaryColor, // Cursor color
            ),
            const SizedBox(height: 32),
            _loading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)))
                : ElevatedButton(
              onPressed: _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 55), // Slightly taller button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), // Match input field border radius
                ),
                elevation: 5, // Add a subtle shadow
              ),
              child: Text(
                isAr ? "إرسال رابط إعادة التعيين" : "Send Reset Link", // More descriptive text
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(
                  color: _isSuccessMessage ? successColor : errorColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center, // Center the message
              ),
          ],
        ),
      ),
    );
  }
}