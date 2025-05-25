// lib/screens/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LocaleProvider>(context).locale.languageCode;
    final isAr = lang == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'سياسة الخصوصية' : 'Privacy Policy'),
        backgroundColor: const Color(0xFF1A2543),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            isAr
                ? '''
نحن نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية.

🔹 لا نقوم بجمع بيانات الدفع، فجميع الطلبات تتم عبر تطبيق واتساب فقط.
🔹 يتم استخدام البيانات مثل الاسم، الهاتف والملاحظة لتسهيل التواصل معك فقط.
🔹 لا نشارك بياناتك مع أي طرف ثالث.
🔹 قد نقوم باستخدام رقم الهاتف للتواصل بشأن حالة الطلب.

هذا التطبيق خاص بطلب منتجات بالتقسيط داخل قطر، دون الحاجة لأي مدفوعات إلكترونية.
'''
                : '''
We respect your privacy and are committed to protecting your personal data.

🔹 We do not collect any payment data. Orders are only placed via WhatsApp.
🔹 Information like name, phone, and notes are used to contact you only.
🔹 We do not share your data with any third parties.
🔹 Your phone number may be used to follow up on your order status.

This app is for installment-based product ordering inside Qatar without online payments.
''',
            style: const TextStyle(fontSize: 16, height: 1.6),
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}
