import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _language;
  bool _dontShowAgain = false;

  final List<Map<String, String>> arContent = [
    {
      'title': 'أول متجر إلكتروني بالتقسيط في قطر!',
      'desc':
      'مرحباً بك في كريدت فون – وجهتك الأولى لشراء الأجهزة بالتقسيط بكل سهولة وأمان.\nتجربة تسوق مرنة ومريحة تبدأ من هنا.',
    },
    {
      'title': 'خطط تقسيط تناسبك',
      'desc':
      'اختر خطة التقسيط التي تناسبك من شهرين وحتى 6 أشهر.\nأو خصصها كما تشاء حسب ميزانيتك واحتياجاتك!',
    },
    {
      'title': 'استلم أولاً، وادفع لاحقاً',
      'desc':
      'نوصّل جهازك خلال ساعات مجاناً بعد تأكيد الطلب.\nالدفع يتم فقط بعد استلام الجهاز والتأكد من جودته.',
    },
  ];


  final List<Map<String, String>> enContent = [
    {
      'title': 'Qatar\'s First Installment Online Store!',
      'desc':
      'Welcome to Credit Phone – your #1 destination for installment-based device shopping.\nA flexible and secure experience starts here.',
    },
    {
      'title': 'Customizable Installment Plans',
      'desc':
      'Choose a plan that suits you – from 2 up to 6 months.\nYou can even customize your payment schedule!',
    },
    {
      'title': 'Receive First, Pay Later',
      'desc':
      'We deliver your device within hours – for FREE!\nPay only after receiving and checking your order.',
    },
  ];


  final List<IconData> icons = [
    Icons.storefront_rounded,
    Icons.payments_rounded ,
    Icons.local_shipping_rounded,
  ];

  final List<Color> iconColors = [
    Color(0xFF1A2543), // dark blue
    Colors.teal,
    Colors.green,
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _initializeNotifications();
    _checkIfShouldSkipIntro();
  }

  Future<void> _checkIfShouldSkipIntro() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldSkip = prefs.getBool('skip_intro') ?? false;

    if (shouldSkip) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      _loadLanguage();
      _initializeNotifications();
    }
  }


  Future<void> _initializeNotifications() async {
    await NotificationService().initialize();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_lang');
    if (savedLang != null) {
      setState(() => _language = savedLang);
      Provider.of<LocaleProvider>(context, listen: false).setLocale(Locale(savedLang));
    }
  }

  Future<void> _selectLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', langCode);
    setState(() => _language = langCode);
    Provider.of<LocaleProvider>(context, listen: false).setLocale(Locale(langCode));
  }

  Future<void> _next() async {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (_dontShowAgain) {
        await prefs.setBool('skip_intro', true); // ✅ حفظ التفضيل
      }
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECFDFC),
      body: _language == null ? _buildLanguageSelector() : _buildIntroPages(),
    );
  }

  Widget _buildLanguageSelector() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.language, size: 90, color: Color(0xFF1A2543)),
            const SizedBox(height: 30),
            const Text(
              "Choose Language / اختر اللغة",
              style: TextStyle(fontSize: 20, color: Color(0xFF1A2543)),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _selectLanguage('ar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6FE0DA),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("العربية"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _selectLanguage('en'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6FE0DA),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("English"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroPages() {
    final content = _language == 'ar' ? arContent : enContent;
    final doNotShowText = _language == 'ar' ? 'عدم العرض مرة أخرى' : 'Don\'t show again';

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: content.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return _buildPage(
                icon: icons[index],
                iconColor: iconColors[index],
                title: content[index]['title']!,
                desc: content[index]['desc']!,
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        _buildDots(),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A2543),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(
              _currentPage == 2
                  ? (_language == 'ar' ? "ابدأ الآن" : "Start Now")
                  : (_language == 'ar' ? "التالي" : "Next"),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Visibility(
            visible: _currentPage == 2, // ✅ شرط الظهور
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _dontShowAgain,
                  onChanged: (value) => setState(() => _dontShowAgain = value ?? false),
                ),
                GestureDetector(
                  onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
                  child: Text(
                    doNotShowText,
                    style: const TextStyle(
                      color: Color(0xFF1A2543),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            _language == 'ar'
                ? "مرخص من وزارة الصناعة والتجارة في قطر"
                : "Licensed by the Ministry of Commerce and Industry in Qatar",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1A2543),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPage({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Icon(icon, size: 64, color: iconColor),
          ),
          const SizedBox(height: 30),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              color: Color(0xFF1A2543),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1A2543),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFF6FE0DA)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
