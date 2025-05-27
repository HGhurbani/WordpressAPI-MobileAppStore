import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

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
            isAr ? 'نبذة عنا' : 'About Us',
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Optional: Add a welcoming image or logo at the top
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 25.0),
                    child: Image.asset(
                      'assets/images/logo.png', // Assuming you have a logo in assets
                      height: 100, // Adjust size as needed
                      width: 100,
                    ),
                  ),
                ),

                _buildSectionHeader(
                  context,
                  isAr ? "من نحن" : "Who We Are",
                  Icons.business_center_outlined,
                ),
                _sectionText(isAr
                    ? "كريدت فون هي الشركة الرائدة في قطر في مجال تقسيط الهواتف الذكية والأجهزة الإلكترونية. نحن نلتزم بتقديم أفضل الحلول المالية لعملائنا لامتلاك أحدث التقنيات دون عناء الدفع الفوري."
                    : "Credit Phone is Qatar’s leading company for smartphone and electronics installment plans. We are committed to providing our customers with the best financial solutions to own the latest technology without the burden of immediate payment.",
                    textDirection),
                const SizedBox(height: 20),

                _buildSectionHeader(
                  context,
                  isAr ? "خدماتنا" : "Our Services",
                  Icons.featured_play_list_outlined,
                ),
                _bulletList(
                  [
                    isAr ? "تقسيط الهواتف الذكية (iPhone، Samsung، وغيرها من العلامات التجارية الرائدة)" : "Smartphone installment (iPhone, Samsung, and other leading brands)",
                    isAr ? "تقسيط الأجهزة الإلكترونية المتنوعة (لابتوبات، شاشات، أجهزة ألعاب مثل بلاي ستيشن وغيرها)" : "Diverse electronics installment (laptops, screens, gaming consoles like PS5, etc.)",
                    isAr ? "خدمة توصيل سريعة وموثوقة لجميع أنحاء قطر" : "Fast and reliable delivery service across Qatar",
                    isAr ? "خيارات دفع مرنة تشمل الدفع عند الاستلام وخطط سداد ميسرة" : "Flexible payment options including cash on delivery and easy monthly plans",
                    isAr ? "باقات خاصة وحلول تمويلية مخصصة للموظفين والجهات الحكومية" : "Special packages and tailored financing solutions for employees & government sectors",
                  ],
                  textDirection,
                ),
                const SizedBox(height: 20),

                _buildSectionHeader(
                  context,
                  isAr ? "رؤيتنا" : "Our Vision",
                  Icons.remove_red_eye_outlined,
                ),
                _sectionText(isAr
                    ? "أن نكون الخيار الأول والموثوق به في قطر لكل من يبحث عن حلول تقسيط ذكية وسهلة للحصول على أحدث الجوالات والأجهزة الإلكترونية، مع التزامنا بأعلى معايير الجودة والخدمة."
                    : "To be Qatar’s foremost and trusted choice for smart and easy installment solutions to acquire the latest mobile phones and electronics, while maintaining the highest standards of quality and service.",
                    textDirection),
                const SizedBox(height: 20),

                _buildSectionHeader(
                  context,
                  isAr ? "مهمتنا" : "Our Mission",
                  Icons.track_changes_outlined,
                ),
                _sectionText(isAr
                    ? "تتمثل مهمتنا في تمكين عملائنا من امتلاك أحدث الأجهزة التقنية اليوم والدفع لاحقًا من خلال خطط سداد مريحة ومناسبة لميزانيتهم، مما يساهم في تحسين جودة حياتهم الرقمية."
                    : "Our mission is to empower our customers to own the latest tech devices today and pay later through convenient and budget-friendly installment plans, thereby enhancing their digital quality of life.",
                    textDirection),
                const SizedBox(height: 20),

                _buildSectionHeader(
                  context,
                  isAr ? "لماذا كريدت فون؟" : "Why Choose Credit Phone?",
                  Icons.thumb_up_alt_outlined,
                ),
                _bulletList(
                  [
                    isAr ? "موافقة سريعة على الطلب خلال دقائق معدودة" : "Swift approval for your request within minutes",
                    isAr ? "تسليم فوري للمنتجات أو في نفس اليوم لضمان سرعة الخدمة" : "Instant or same-day delivery for prompt service",
                    isAr ? "دعم شامل ومتكامل قبل وبعد البيع لضمان رضا العملاء" : "Comprehensive pre- and post-sale support to ensure customer satisfaction",
                    isAr ? "خطط تقسيط مرنة تتناسب تمامًا مع راتبك والتزاماتك المالية" : "Flexible installment plans perfectly aligned with your salary and financial obligations",
                  ],
                  textDirection,
                ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    isAr ? 'نحن هنا لنجعل حياتك أسهل وأكثر اتصالاً.' : 'We are here to make your life easier and more connected.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
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
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6FE0DA), size: 30), // Larger icon
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22, // Larger title
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

  Widget _sectionText(String text, TextDirection textDirection) => Padding(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 16, // Consistent font size
        height: 1.7, // Improved line height for readability
        color: Colors.grey[800],
      ),
      textAlign: TextAlign.justify, // Justify text for a clean look
      textDirection: textDirection,
    ),
  );

  Widget _bulletList(List<String> items, TextDirection textDirection) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items.map((e) => Padding(
      padding: const EdgeInsets.only(bottom: 8), // More padding between items
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align icon and text at top
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6.0), // Adjust bullet point vertical alignment
            child: Icon(Icons.check_circle_outline, size: 18, color: const Color(0xFF6FE0DA)), // Use a more distinct icon
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              e,
              style: TextStyle(
                fontSize: 16, // Consistent font size
                height: 1.5,
                color: Colors.grey[800],
              ),
              textDirection: textDirection,
            ),
          ),
        ],
      ),
    )).toList(),
  );
}