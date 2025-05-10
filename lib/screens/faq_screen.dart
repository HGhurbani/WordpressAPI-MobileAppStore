import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final faqs = [

      {
        "q": isAr ? "كم تستغرق الموافقة على الطلب؟" : "How long does approval take?",
        "a": isAr ? "يتم الرد خلال دقائق فقط بعد التقديم." : "Approval is usually granted within minutes."
      },
      {
        "q": isAr ? "هل هناك توصيل؟" : "Do you offer delivery?",
        "a": isAr ? "نعم، نوفر خدمة توصيل سريعة لجميع مناطق قطر." : "Yes, we offer fast delivery across all areas in Qatar."
      },
      {
        "q": isAr ? "كيف يمكنني الطلب؟" : "How do I place an order?",
        "a": isAr ? "فقط اختر المنتج واملأ النموذج وسنتواصل معك عبر واتساب." : "Just choose your product and fill the form, we’ll contact you via WhatsApp."
      },
      {
        "q": isAr ? "هل توجد باقات خاصة؟" : "Do you offer special packages?",
        "a": isAr ? "نعم، للموظفين والجهات الحكومية والخاصة." : "Yes, for employees and private/governmental entities."
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الأسئلة الشائعة' : 'FAQ'),
        centerTitle: true,
        backgroundColor: const Color(0xff180cb5),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return ExpansionTile(
            title: Text(
              faqs[index]["q"]!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
                child: Text(
                  faqs[index]["a"]!,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
