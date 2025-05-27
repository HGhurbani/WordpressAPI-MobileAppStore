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
    final textDirection = isAr ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isAr ? 'شروط الاستخدام' : 'Terms of Use',
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
          color: const Color(0xFFF9F9F9), // Subtle background color
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  context,
                  isAr ? 'مقدمة' : 'Introduction',
                  Icons.policy_outlined,
                ),
                _buildParagraph(
                  isAr
                      ? 'باستخدامك لتطبيق Credit Phone، فإنك توافق على الالتزام بالشروط والأحكام الموضحة أدناه. يرجى قراءة هذه الشروط بعناية قبل استخدام التطبيق.'
                      : 'By using the Credit Phone app, you agree to be bound by the terms and conditions outlined below. Please read these terms carefully before using the application.',
                  textDirection,
                ),
                const SizedBox(height: 20),

                _buildSectionHeader(
                  context,
                  isAr ? 'طبيعة الخدمة' : 'Nature of Service',
                  Icons.shopping_bag_outlined,
                ),
                _buildBulletPoint(
                  isAr
                      ? 'يُستخدم هذا التطبيق حصريًا لعرض المنتجات المتاحة وتسهيل عملية تقديم طلبات الشراء عبر تطبيق واتساب.'
                      : 'This application is exclusively used for displaying available products and facilitating the placement of purchase orders via the WhatsApp application.',
                  textDirection,
                ),
                _buildBulletPoint(
                  isAr
                      ? 'لا يتضمن التطبيق أي وظائف أو بوابات للدفع الإلكتروني المباشر. تتم جميع المعاملات المالية خارج التطبيق.'
                      : 'The application does not include any direct electronic payment functionalities or gateways. All financial transactions occur outside the app.',
                  textDirection,
                ),
                const SizedBox(height: 20),

                _buildSectionHeader(
                  context,
                  isAr ? 'تأكيد الطلبات' : 'Order Confirmation',
                  Icons.check_circle_outline,
                ),
                _buildBulletPoint(
                  isAr
                      ? 'يعتبر الطلب المقدم عبر التطبيق طلبًا مبدئيًا وغير ملزم حتى يتم تأكيده بشكل رسمي من قبل فريق Credit Phone عبر محادثة واتساب.'
                      : 'An order placed through the application is considered an initial, non-binding request until it is officially confirmed by the Credit Phone team via a WhatsApp conversation.',
                  textDirection,
                ),
                const SizedBox(height: 20),

                _buildSectionHeader(
                  context,
                  isAr ? 'تعديل الشروط' : 'Modification of Terms',
                  Icons.update_outlined,
                ),
                _buildParagraph(
                  isAr
                      ? 'نحتفظ بالحق في تعديل أو تحديث هذه الشروط في أي وقت ودون إشعار مسبق. يُعد استمرارك في استخدام التطبيق بعد أي تعديلات موافقة منك على الشروط المعدلة.'
                      : 'We reserve the right to modify or update these terms at any time without prior notice. Your continued use of the application after any modifications constitutes your acceptance of the revised terms.',
                  textDirection,
                ),
                const SizedBox(height: 20),

                _buildSectionHeader(
                  context,
                  isAr ? 'متطلبات المستخدم' : 'User Requirements',
                  Icons.person_outline,
                ),
                _buildBulletPoint(
                  isAr
                      ? 'يجب أن يكون المستخدم مقيمًا داخل دولة قطر للاستفادة من خدمات التطبيق وتقديم الطلبات.'
                      : 'Users must be residents within the State of Qatar to utilize the application\'s services and place orders.',
                  textDirection,
                ),
                const SizedBox(height: 20),

                _buildSectionHeader(
                  context,
                  isAr ? 'نبذة عن التطبيق' : 'About the App',
                  Icons.info_outline,
                ),
                _buildParagraph(
                  isAr
                      ? 'هذا التطبيق هو واجهة لمتجر إلكتروني متخصص في تقديم خدمات التقسيط على الأجهزة الإلكترونية لمقيمي دولة قطر.'
                      : 'This application serves as an interface for an electronic store specializing in offering installment services for electronic devices to residents of Qatar.',
                  textDirection,
                ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    isAr ? 'نتطلع لخدمتكم.' : 'We look forward to serving you.',
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
        textAlign: TextAlign.justify,
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