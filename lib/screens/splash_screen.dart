// lib/screens/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _language;

  final List<Map<String, Map<String, String>>> splashData = [
    {
      "ar": {
        "title": "مرحباً بك في كريدت فون",
        "desc": "أفضل مكان لشراء الأجهزة الإلكترونية بالتقسيط بسهولة وأمان.",
        "icon": "💳"
      },
      "en": {
        "title": "Welcome to Credit Phone",
        "desc": "Best place to buy electronics on installment with ease and safety.",
        "icon": "💳"
      },
    },
    {
      "ar": {
        "title": "خيارات مريحة للدفع",
        "desc": "اختر الجهاز، واطلبه، وسنقوم بالتواصل معك عبر واتساب.",
        "icon": "📱"
      },
      "en": {
        "title": "Easy Payment Options",
        "desc": "Choose a device, request it, and we’ll contact you via WhatsApp.",
        "icon": "📱"
      },
    },
    {
      "ar": {
        "title": "ابدأ الآن",
        "desc": "استعرض المنتجات واختر الأنسب لك، واطلبه فوراً.",
        "icon": "🚀"
      },
      "en": {
        "title": "Get Started",
        "desc": "Browse products, pick what suits you, and request easily.",
        "icon": "🚀"
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
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

  void _next() {
    if (_currentPage < splashData.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff180cb5),
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
            const Icon(Icons.language, size: 90, color: Colors.white),
            const SizedBox(height: 30),
            const Text("Choose Language / اختر اللغة",
                style: TextStyle(fontSize: 20, color: Colors.white)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _selectLanguage('ar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xff180cb5),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("العربية"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _selectLanguage('en'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xff180cb5),
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
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: splashData.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final data = splashData[index][_language]!;
              return _buildPage(
                icon: data['icon']!,
                title: data['title']!,
                desc: data['desc']!,
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
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff180cb5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(_currentPage == 2
                ? (_language == 'ar' ? "ابدأ" : "Start")
                : (_language == 'ar' ? "التالي" : "Next")),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPage({required String icon, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 30),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(splashData.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
