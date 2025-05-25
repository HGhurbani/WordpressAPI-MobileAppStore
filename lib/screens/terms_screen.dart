// lib/screens/terms_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LocaleProvider>(context).locale.languageCode;
    final isAr = lang == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'شروط الاستخدام' : 'Terms of Use'),
        backgroundColor: const Color(0xFF1A2543),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            isAr
                ? '''
عند استخدامك هذا التطبيق فإنك توافق على الشروط التالية:

🔸 هذا التطبيق يستخدم فقط لعرض المنتجات وتقديم طلب عبر تطبيق واتساب.
🔸 لا يحتوي التطبيق على وسائل دفع إلكترونية.
🔸 لا يعتبر الطلب ملزماً حتى يتم تأكيده من قبل فريقنا عبر واتساب.
🔸 يحق لنا تعديل الشروط دون إشعار مسبق.
🔸 يجب أن يكون المستخدم مقيماً داخل قطر.

هذا التطبيق تابع لمتجر إلكتروني يقدم خدمات التقسيط على الأجهزة الإلكترونية.
'''
                : '''
By using this app, you agree to the following terms:

🔸 The app is only for browsing products and placing orders via WhatsApp.
🔸 There are no online payment methods in this app.
🔸 Orders are not final until confirmed by our team on WhatsApp.
🔸 We may update terms without prior notice.
🔸 User must be a resident of Qatar.

This app is for an electronic store offering installment services for electronics in Qatar.
''',
            style: const TextStyle(fontSize: 16, height: 1.6),
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}
