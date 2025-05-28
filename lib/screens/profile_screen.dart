import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/locale_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  // الألوان الأساسية للهوية
  static const Color _primaryColor = Color(0xFF1A2543);
  static const Color _accentColor = Color(0xFF6FE0DA);
  static const Color _backgroundColor = Color(0xFFF7F9FA);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final language = localeProvider.locale.languageCode;
    final isArabic = language == 'ar';

    final appBarTitle = isArabic ? "حسابي" : "My Account"; // عنوان أبسط

    return Scaffold(
      backgroundColor: _backgroundColor, // خلفية موحدة للشاشة
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 4, // زيادة الظل لشريط التطبيق
        shadowColor: Colors.black.withOpacity(0.3), // لون الظل
      ),
      body: userProvider.isLoggedIn
          ? _buildProfileContent(context, localeProvider, userProvider)
          : _buildNotLoggedInSection(context, isArabic),
    );
  }

  // --- قسم عدم تسجيل الدخول (Not Logged In Section) ---
  Widget _buildNotLoggedInSection(BuildContext context, bool isArabic) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      // يمكن إضافة تدرج لوني خفيف للخلفية هنا إذا أردت
      // decoration: const BoxDecoration(
      //   gradient: LinearGradient(
      //     begin: Alignment.topCenter,
      //     end: Alignment.bottomCenter,
      //     colors: [_backgroundColor, Color(0xFFE0E5E9)],
      //   ),
      // ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32), // حشوة أكبر
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // توسيط المحتوى أفقياً
          children: [
            const SizedBox(height: 40),

            // رسم توضيحي أنيق
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.15), // ظل أكثر وضوحاً
                    blurRadius: 25, // زيادة التمويه
                    offset: const Offset(0, 15), // إزاحة أكبر للظل
                  ),
                ],
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 80,
                color: _primaryColor.withOpacity(0.6), // لون أيقونة فاتح قليلاً
              ),
            ),

            const SizedBox(height: 40), // مسافة أكبر

            // عنوان ترحيبي
            Text(
              isArabic ? "مرحباً بك في حسابك!" : "Welcome to Your Account!", // نص ترحيبي أكثر تحديداً
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16), // مسافة أكبر

            // وصف توضيحي
            Text(
              isArabic
                  ? "سجّل الدخول أو أنشئ حسابًا جديدًا للوصول إلى بياناتك الشخصية، متابعة طلباتك، والاستفادة من جميع الميزات الحصرية."
                  : "Login or create a new account to access your personal data, track your orders, and enjoy all exclusive features.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600, // لون نص أوضح
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 50), // مسافة كبيرة قبل الأزرار

            // أزرار تسجيل الدخول والتسجيل
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0), // لا حاجة لحشوة إضافية هنا
              child: Column(
                children: [
                  // زر تسجيل الدخول الرئيسي
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor, // اللون الأساسي للهوية
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60), // حجم أكبر للزر
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // حواف دائرية للزر
                      ),
                      elevation: 0, // ظل أكبر للزر
                      shadowColor: _primaryColor.withOpacity(0.4), // لون ظل مناسب
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    icon: const Icon(Icons.login_rounded, size: 24), // أيقونة أكبر
                    label: Text(
                      isArabic ? "تسجيل الدخول" : "Login",
                      style: const TextStyle(
                        fontSize: 18, // خط أكبر
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20), // مسافة أكبر بين الأزرار

                  // زر إنشاء حساب جديد
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor, // اللون الثانوي للهوية
                      foregroundColor: _primaryColor, // لون النص المناسب
                      minimumSize: const Size(double.infinity, 60), // حجم أكبر للزر
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0, // ظل أكبر
                      shadowColor: _accentColor.withOpacity(0.4), // لون ظل مناسب
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    icon: const Icon(Icons.person_add_rounded, size: 24), // أيقونة أكبر
                    label: Text(
                      isArabic ? "إنشاء حساب جديد" : "Create New Account",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30), // مسافة أكبر

            // رابط التسوق بدون تسجيل
            TextButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/main');
              },
              icon: Icon(
                Icons.shopping_bag_outlined,
                color: Colors.grey.shade700, // لون أيقونة أغمق
                size: 20, // أيقونة أكبر
              ),
              label: Text(
                isArabic ? "متابعة التسوق كزائر" : "Continue as Guest", // نص أبسط
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500, // خط أسمك قليلاً
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- قسم عند تسجيل الدخول (Logged In Section) ---
  Widget _buildProfileContent(BuildContext context, LocaleProvider localeProvider, UserProvider userProvider) {
    final language = localeProvider.locale.languageCode;
    final isArabic = language == 'ar';

    final user = userProvider.user!;

    return ListView(
      padding: const EdgeInsets.all(20), // حشوة أكبر
      physics: const BouncingScrollPhysics(), // تأثير ارتداد عند التمرير
      children: [
        // بطاقة معلومات المستخدم (Header Card)
        Card(
          elevation: 6, // ظل أكبر
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // حواف دائرية أكثر
          color: _primaryColor, // لون خلفية البطاقة الأساسي
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20), // حشوة أكبر
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45, // حجم أكبر للصورة الرمزية
                  backgroundColor: _accentColor, // اللون الثانوي للهوية
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold), // خط أكبر وأسمك
                  ),
                ),
                const SizedBox(height: 16), // مسافة أكبر
                Text(
                  isArabic ? "مرحباً، ${user.username}!" : "Hello, ${user.username}!", // إضافة علامة تعجب
                  style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8), // مسافة أكبر
                Text(
                  "${isArabic ? 'البريد الإلكتروني:' : 'Email:'} ${user.email}",
                  style: const TextStyle(fontSize: 15, color: Colors.white70),
                ),
                if (user.phone != null && user.phone!.isNotEmpty) // عرض رقم الهاتف إذا كان موجوداً
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "${isArabic ? 'رقم الجوال:' : 'Phone:'} ${user.phone}",
                      style: const TextStyle(fontSize: 15, color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30), // مسافة أكبر

        // أقسام الخيارات
        _buildSectionTitle(isArabic ? 'إدارة الحساب' : 'Account Management', context),
        const SizedBox(height: 10),

        _buildOptionCard(
          context,
          icon: Icons.shopping_bag_rounded, // أيقونة محدثة
          label: isArabic ? 'طلباتي' : 'My Orders',
          onTap: () => Navigator.pushNamed(context, '/orders'),
        ),
        _buildOptionCard(
          context,
          icon: Icons.settings_rounded, // أيقونة محدثة
          label: isArabic ? 'الإعدادات / Settings' : 'الإعدادات / Settings', // نص أبسط
          onTap: () => Navigator.pushNamed(context, '/settings'),
        ),
        // يمكنك إضافة المزيد من الخيارات هنا مثل:
        // _buildOptionCard(
        //   context,
        //   icon: Icons.favorite_rounded,
        //   label: isArabic ? 'المفضلة' : 'Favorites',
        //   onTap: () => Navigator.pushNamed(context, '/favorites'),
        // ),
        // _buildOptionCard(
        //   context,
        //   icon: Icons.location_on_rounded,
        //   label: isArabic ? 'عناويني' : 'My Addresses',
        //   onTap: () => Navigator.pushNamed(context, '/addresses'),
        // ),

        const SizedBox(height: 40), // مسافة أكبر

        // أزرار الإجراءات
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor, // اللون الأساسي للهوية
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18), // حشوة أكبر
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // حواف دائرية أكثر
            elevation: 0, // ظل أكبر
            shadowColor: _primaryColor.withOpacity(0.3),
          ),
          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 24), // أيقونة محدثة وأكبر
          label: Text(
            isArabic ? 'تسجيل الخروج' : 'Logout',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          onPressed: () {
            _confirmLogout(context, userProvider, isArabic); // استدعاء دالة تأكيد تسجيل الخروج
          },
        ),

        const SizedBox(height: 15), // مسافة بين الأزرار

        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade600, // لون أحمر أغمق للزر
            side: BorderSide(color: Colors.red.shade400, width: 1.5), // حدود أسمك
            padding: const EdgeInsets.symmetric(vertical: 18), // حشوة أكبر
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // حواف دائرية أكثر
            elevation: 2, // ظل خفيف
          ),
          icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 24), // أيقونة محدثة وأكبر
          label: Text(
            isArabic ? 'حذف الحساب' : 'Delete Account',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          onPressed: () => _confirmDeleteAccount(context, userProvider, isArabic), // استدعاء دالة تأكيد حذف الحساب
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // دالة مساعدة لبناء عنوان القسم
  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0, top: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: _primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // دالة مساعدة لبناء بطاقات الخيارات
  Widget _buildOptionCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12), // مسافة أقل بين البطاقات
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // حواف دائرية أكثر
      elevation: 3, // ظل أكبر للبطاقة
      shadowColor: Colors.grey.withOpacity(0.15), // لون ظل خفيف
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // حشوة داخلية
          child: Row(
            children: [
              Icon(icon, color: _primaryColor, size: 28), // أيقونة أكبر
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    color: _primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey), // سهم أوضح وأصغر
            ],
          ),
        ),
      ),
    );
  }

  // دالة تأكيد تسجيل الخروج (مكررة من SettingsScreen مع تعديل طفيف)
  void _confirmLogout(BuildContext context, UserProvider userProvider, bool isArabic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isArabic ? 'تأكيد تسجيل الخروج' : 'Confirm Logout', style: const TextStyle(color: _primaryColor)),
        content: Text(isArabic ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟' : 'Are you sure you want to log out?', style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            child: Text(isArabic ? 'إلغاء' : 'Cancel', style: const TextStyle(color: _primaryColor)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isArabic ? 'تسجيل الخروج' : 'Logout', style: const TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(context);
              userProvider.logout();
              Navigator.pushReplacementNamed(context, '/login'); // إعادة توجيه لصفحة تسجيل الدخول
            },
          ),
        ],
      ),
    );
  }

  // دالة تأكيد حذف الحساب
  void _confirmDeleteAccount(BuildContext context, UserProvider userProvider, bool isArabic) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isArabic ? 'تأكيد حذف الحساب' : 'Confirm Account Deletion', style: const TextStyle(color: _primaryColor)),
        content: Text(
          isArabic ? 'هل أنت متأكد تمامًا من رغبتك في حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء وسيتم فقدان جميع بياناتك.' : 'Are you absolutely sure you want to delete your account? This action cannot be undone, and all your data will be lost.',
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            child: Text(isArabic ? 'إلغاء' : 'Cancel', style: const TextStyle(color: _primaryColor)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isArabic ? 'حذف الحساب' : 'Delete Account', style: const TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // هنا يجب أن تستدعي خدمة API لحذف الحساب
      // for example: final success = await ApiService().deleteAccount();
      // في هذا المثال، سنفترض النجاح ونقوم بحذف البيانات محلياً
      await userProvider.deleteAccount(); // يجب أن تتضمن هذه الدالة منطق حذف الحساب من الـ API
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'تم حذف الحساب بنجاح.' : 'Account deleted successfully.', style: const TextStyle(color: Colors.white)),
          backgroundColor: _accentColor,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login'); // أو إلى الشاشة الرئيسية كزائر
    }
  }
}