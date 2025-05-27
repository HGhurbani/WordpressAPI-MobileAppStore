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

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _language;
  bool _dontShowAgain = false;
  bool _isInitializing = true;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _logoController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoAnimation;

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
    Icons.payments_rounded,
    Icons.local_shipping_rounded,
  ];

  final List<List<Color>> gradientColors = [
    [Color(0xFF1A2543), Color(0xFF2A3B5C)], // dark blue gradient
    [Color(0xFF009688), Color(0xFF00BCD4)], // teal gradient
    [Color(0xFF4CAF50), Color(0xFF8BC34A)], // green gradient
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeApp() async {
    // Start logo animation
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    final shouldSkip = prefs.getBool('skip_intro') ?? false;

    if (shouldSkip) {
      await Future.delayed(const Duration(milliseconds: 1500));
      Navigator.pushReplacementNamed(context, '/main');
      return;
    }

    await _loadLanguage();
    await _initializeNotifications();

    setState(() => _isInitializing = false);

    // Start animations for language selector or intro
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService().initialize();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_lang');
    if (savedLang != null) {
      setState(() => _language = savedLang);
      if (mounted) {
        Provider.of<LocaleProvider>(context, listen: false).setLocale(Locale(savedLang));
      }
    }
  }

  Future<void> _selectLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', langCode);
    setState(() => _language = langCode);

    if (mounted) {
      Provider.of<LocaleProvider>(context, listen: false).setLocale(Locale(langCode));
    }

    // Animate transition to intro pages
    await _fadeController.reverse();
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
  }

  Future<void> _next() async {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (_dontShowAgain) {
        await prefs.setBool('skip_intro', true);
      }

      // Smooth transition to main screen
      await _fadeController.reverse();
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB2EBF2),
              Color(0xFFE0F7FA),
              Color(0xFFB2EBF2),
            ],
          ),
        ),
        child: SafeArea(
          child: _isInitializing
              ? _buildLoadingScreen()
              : _language == null
              ? _buildLanguageSelector()
              : _buildIntroPages(),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _logoAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _logoAnimation.value,
                child: Transform.rotate(
                  angle: _logoAnimation.value * 0.5,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A2543), Color(0xFF6FE0DA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6FE0DA).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.phone_android,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          AnimatedBuilder(
            animation: _logoAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _logoAnimation.value,
                child: const Text(
                  "Credit Phone",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2543),
                    letterSpacing: 1.2,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 50),
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6FE0DA)),
              strokeWidth: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF1A2543), Color(0xFF6FE0DA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF6FE0DA).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.language,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      "Choose Language / اختر اللغة",
                      style: TextStyle(
                        fontSize: 22,
                        color: Color(0xFF1A2543),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 50),
                    _buildLanguageButton(
                      text: "العربية",
                      onPressed: () => _selectLanguage('ar'),
                      icon: Icons.flag,
                    ),
                    const SizedBox(height: 16),
                    _buildLanguageButton(
                      text: "English",
                      onPressed: () => _selectLanguage('en'),
                      icon: Icons.flag_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageButton({
    required String text,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6FE0DA).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A2543),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: Color(0xFF6FE0DA), width: 2),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildIntroPages() {
    final content = _language == 'ar' ? arContent : enContent;
    final doNotShowText = _language == 'ar' ? 'عدم العرض مرة أخرى' : 'Don\'t show again';

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: content.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    return _buildPage(
                      index: index,
                      title: content[index]['title']!,
                      desc: content[index]['desc']!,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              _buildDots(),
              const SizedBox(height: 40),
              _buildActionButtons(doNotShowText),
              const SizedBox(height: 20),
              _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPage({
    required int index,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'icon_$index',
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: gradientColors[index],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[index][1].withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icons[index],
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              color: Color(0xFF1A2543),
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFF6FE0DA).withOpacity(0.3)),
            ),
            child: Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1A2543),
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
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
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: _currentPage == index ? 32 : 12,
          height: 12,
          decoration: BoxDecoration(
            gradient: _currentPage == index
                ? LinearGradient(colors: [Color(0xFF6FE0DA), Color(0xFF6FE0DA)])
                : null,
            color: _currentPage == index ? null : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
            boxShadow: _currentPage == index
                ? [
              BoxShadow(
                color: Color(0xFF6FE0DA).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildActionButtons(String doNotShowText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [Color(0xFF1A2543), Color(0xFF2A3B5C)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF1A2543).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _currentPage == 2
                    ? (_language == 'ar' ? "ابدأ الآن" : "Start Now")
                    : (_language == 'ar' ? "التالي" : "Next"),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (_currentPage == 2) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF6FE0DA).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _dontShowAgain ? Color(0xFF6FE0DA) : Colors.transparent,
                        border: Border.all(
                          color: _dontShowAgain ? Color(0xFF6FE0DA) : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _dontShowAgain
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      doNotShowText,
                      style: const TextStyle(
                        color: Color(0xFF1A2543),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Text(
        _language == 'ar'
            ? "مرخص من وزارة الصناعة والتجارة في قطر"
            : "Licensed by the Ministry of Commerce and Industry in Qatar",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF1A2543).withOpacity(0.7),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}