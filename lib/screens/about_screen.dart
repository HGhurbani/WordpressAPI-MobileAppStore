import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'نبذة عنا' : 'About Us'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A2543),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(isAr ? "من نحن" : "Who We Are"),
            _sectionText(isAr
                ? "كريدت فون هي الشركة الرائدة في قطر في مجال تقسيط الهواتف الذكية والأجهزة الإلكترونية..."
                : "Credit Phone is Qatar’s leading company for smartphone and electronics installment plans..."),

            _sectionTitle(isAr ? "خدماتنا" : "Our Services"),
            _bulletList([
              isAr ? "تقسيط الهواتف الذكية (iPhone، Samsung، وغيرها)" : "Smartphone installment (iPhone, Samsung, etc.)",
              isAr ? "تقسيط الأجهزة الإلكترونية (لابتوبات، شاشات، بلاي ستيشن...)" : "Electronics installment (laptops, screens, PS5...)",
              isAr ? "خدمة توصيل سريعة داخل قطر" : "Fast delivery across Qatar",
              isAr ? "الدفع عند الاستلام وخطط سداد مرنة" : "Cash on delivery with flexible monthly plans",
              isAr ? "باقات خاصة للموظفين والجهات الحكومية" : "Special plans for employees & government sectors",
            ]),

            _sectionTitle(isAr ? "رؤيتنا" : "Our Vision"),
            _sectionText(isAr
                ? "أن نكون الخيار الأول في قطر لكل من يبحث عن تقسيط ذكي وسهل للجوالات والإلكترونيات."
                : "To be Qatar’s top choice for smart and easy installment solutions."),

            _sectionTitle(isAr ? "مهمتنا" : "Our Mission"),
            _sectionText(isAr
                ? "نساعد العملاء على امتلاك أحدث الأجهزة اليوم والدفع لاحقًا بخطط مريحة."
                : "Helping customers own the latest tech today and pay later with comfort."),

            _sectionTitle(isAr ? "لماذا كريدت فون؟" : "Why Credit Phone?"),
            _bulletList([
              isAr ? "موافقة خلال دقائق" : "Approval within minutes",
              isAr ? "تسليم فوري أو في نفس اليوم" : "Instant or same-day delivery",
              isAr ? "دعم كامل قبل وبعد البيع" : "Full support before & after sale",
              isAr ? "تقسيط يناسب راتبك والتزاماتك" : "Installments fit your salary & obligations",
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  );

  Widget _sectionText(String text) => Text(
    text,
    style: const TextStyle(fontSize: 15, height: 1.6),
    textAlign: TextAlign.justify,
  );

  Widget _bulletList(List<String> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items.map((e) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Text("• ", style: TextStyle(fontSize: 16)),
          Expanded(child: Text(e, style: const TextStyle(fontSize: 15))),
        ],
      ),
    )).toList(),
  );
}
