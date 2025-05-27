import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LocaleProvider>(context).locale.languageCode;
    final isAr = lang == 'ar';
    final textDirection = isAr ? TextDirection.rtl : TextDirection.ltr;

    final faqs = [
      {
        "q": isAr ? "كم تستغرق الموافقة على الطلب؟" : "How long does approval take?",
        "a": isAr ? "يتم الرد خلال دقائق فقط بعد التقديم على طلبك. نسعى لتقديم أسرع خدمة ممكنة." : "Approval is usually granted within minutes after submitting your application. We strive to provide the fastest service possible."
      },
      {
        "q": isAr ? "هل هناك توصيل للمنتجات؟" : "Do you offer product delivery?",
        "a": isAr ? "نعم، نوفر خدمة توصيل سريعة وموثوقة لجميع مناطق ومدن قطر لضمان وصول منتجاتك بأمان." : "Yes, we offer fast and reliable delivery service across all regions and cities in Qatar to ensure your products arrive safely."
      },
      {
        "q": isAr ? "كيف يمكنني تقديم طلب شراء؟" : "How do I place a purchase order?",
        "a": isAr ? "فقط اختر المنتج الذي ترغب به من التطبيق واملأ نموذج الطلب المخصص. بعد ذلك، سنتواصل معك مباشرة عبر واتساب لتأكيد التفاصيل وإتمام العملية." : "Simply choose the product you desire from the app and fill out the dedicated order form. Afterward, we will contact you directly via WhatsApp to confirm details and complete the process."
      },
      {
        "q": "هل توجد باقات أو عروض خاصة؟", // Changed text slightly for better clarity
        "a": isAr ? "بالتأكيد! نوفر باقات وعروضاً خاصة مصممة خصيصًا للموظفين في القطاعين الحكومي والخاص، بالإضافة إلى الجهات الاعتبارية." : "Absolutely! We offer special packages and deals designed specifically for employees in both governmental and private sectors, as well as for corporate entities."
      },
      {
        "q": isAr ? "ما هي المستندات المطلوبة للتقسيط؟" : "What documents are required for installment plans?",
        "a": isAr ? "عادةً ما نحتاج إلى بطاقة الهوية القطرية، وكشف حساب بنكي لآخر 3-6 أشهر، وشهادة راتب حديثة أو إثبات دخل. قد تختلف المتطلبات بناءً على حالة الطلب." : "Typically, we require a Qatari ID, bank statements for the last 3-6 months, and a recent salary certificate or proof of income. Requirements may vary based on the application."
      },
      {
        "q": isAr ? "هل يمكنني إلغاء طلبي بعد التقديم؟" : "Can I cancel my order after submission?",
        "a": isAr ? "يمكنك إلغاء الطلب قبل أن يتم تأكيده وشحنه من قبل فريقنا. يرجى التواصل معنا عبر واتساب في أقرب وقت ممكن إذا كنت ترغب في الإلغاء." : "You can cancel your order before it has been confirmed and shipped by our team. Please contact us via WhatsApp as soon as possible if you wish to cancel."
      },
    ];

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isAr ? 'الأسئلة الشائعة' : 'Frequently Asked Questions', // More formal English title
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: const Color(0xFF6FE0DA), size: 30),
                        const SizedBox(width: 10),
                        Text(
                          isAr ? 'هل لديك استفسار؟' : 'Have a question?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2543),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr
                          ? 'تجد هنا إجابات لأكثر الأسئلة شيوعاً حول خدماتنا.'
                          : 'Find answers to the most frequently asked questions about our services here.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      textDirection: textDirection,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16), // Adjust horizontal padding
                  itemCount: faqs.length,
                  itemBuilder: (context, index) {
                    return Card(
                      // Wrap in a Card for a subtle elevated look
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect( // Clip children to follow card's rounded corners
                        borderRadius: BorderRadius.circular(12),
                        child: Theme( // Override expansion tile theme for custom arrow color
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent, // Hide default divider
                          ),
                          child: ExpansionTile(
                            iconColor: const Color(0xFF6FE0DA), // Custom arrow color
                            collapsedIconColor: const Color(0xFF1A2543), // Custom collapsed arrow color
                            title: Text(
                              faqs[index]["q"]!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700, // Make question bolder
                                fontSize: 16,
                                color: Color(0xFF1A2543),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 16, // More padding
                                  left: 16,
                                  right: 16,
                                ),
                                child: Text(
                                  faqs[index]["a"]!,
                                  style: TextStyle(
                                    fontSize: 15, // Slightly larger answer font
                                    height: 1.6, // Better line spacing
                                    color: Colors.grey[800],
                                  ),
                                  textAlign: TextAlign.justify, // Justify answer text
                                  textDirection: textDirection,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}