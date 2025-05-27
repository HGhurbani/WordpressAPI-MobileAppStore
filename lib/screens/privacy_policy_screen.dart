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
    final textDirection = isAr ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isAr ? 'سياسة الخصوصية' : 'Privacy Policy',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: const Color(0xFF1A2543),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0, // Remove shadow for a cleaner look
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Container(
          // Optional: Add a subtle background color or gradient
          color: const Color(0xFFF9F9F9),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  context,
                  isAr ? 'مقدمة' : 'Introduction',
                  Icons.info_outline,
                ),
                _buildParagraph(
                  isAr
                      ? 'نحن في Credit Phone نحترم خصوصيتك ونلتزم التزامًا كاملاً بحماية بياناتك الشخصية. توضح هذه السياسة كيف نقوم بجمع معلوماتك واستخدامها وحمايتها.'
                      : 'At Credit Phone, we highly respect your privacy and are fully committed to protecting your personal data. This policy explains how we collect, use, and safeguard your information.',
                  textDirection,
                ),
                const SizedBox(height: 20),

                _buildSectionHeader(
                  context,
                  isAr ? 'جمع واستخدام البيانات' : 'Data Collection and Usage',
                  Icons.data_usage,
                ),
                _buildBulletPoint(
                  isAr
                      ? 'لا نقوم بجمع أي بيانات دفع إلكترونية. تتم جميع الطلبات والمعاملات المالية بشكل حصري عبر تطبيق واتساب.'
                      : 'We do not collect any electronic payment data. All orders and financial transactions are handled exclusively via WhatsApp.',
                  textDirection,
                ),
                _buildBulletPoint(
                  isAr
                      ? 'البيانات التي نجمعها (مثل الاسم، رقم الهاتف، وأي ملاحظات تقدمها) تستخدم فقط لتسهيل التواصل معك ومعالجة طلباتك بفعالية.'
                      : 'The data we collect (such as your name, phone number, and any notes you provide) is solely used to facilitate communication with you and to process your orders efficiently.',
                  textDirection,
                ),
                _buildBulletPoint(
                  isAr
                      ? 'قد نستخدم رقم هاتفك للتواصل معك بخصوص حالة طلبك أو لتقديم الدعم اللازم.'
                      : 'Your phone number may be used to contact you regarding your order status or to provide necessary support.',
                  textDirection,
                ),
                const SizedBox(height: 20),

                _buildSectionHeader(
                  context,
                  isAr ? 'مشاركة البيانات' : 'Data Sharing',
                  Icons.security,
                ),
                _buildParagraph(
                  isAr
                      ? 'نحن نؤكد أننا لا نشارك بياناتك الشخصية مع أي طرف ثالث تحت أي ظرف من الظروف. خصوصيتك هي أولويتنا القصوى.'
                      : 'We assure you that we do not share your personal data with any third parties under any circumstances. Your privacy is our utmost priority.',
                  textDirection,
                ),
                const SizedBox(height: 20),

                _buildSectionHeader(
                  context,
                  isAr ? 'نطاق التطبيق' : 'Application Scope',
                  Icons.phone_android,
                ),
                _buildParagraph(
                  isAr
                      ? 'يختص هذا التطبيق بتقديم خدمة طلب المنتجات بالتقسيط حصريًا داخل دولة قطر، ولا يتضمن أي آليات للمدفوعات الإلكترونية المباشرة ضمن التطبيق.'
                      : 'This application is exclusively designed for facilitating installment-based product orders within Qatar. It does not include any direct in-app electronic payment mechanisms.',
                  textDirection,
                ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    isAr ? 'شكرًا لثقتك بنا.' : 'Thank you for trusting us.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                    textDirection: textDirection,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6FE0DA), size: 28),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2543),
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Divider(color: Color(0xFF6FE0DA), thickness: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParagraph(String text, TextDirection textDirection) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Colors.grey[800],
        ),
        textAlign: TextAlign.justify, // Justify text for a more formal look
        textDirection: textDirection,
      ),
    );
  }

  Widget _buildBulletPoint(String text, TextDirection textDirection) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 10, right: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: const Color(0xFF6FE0DA)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey[800],
              ),
              textDirection: textDirection,
            ),
          ),
        ],
      ),
    );
  }
}