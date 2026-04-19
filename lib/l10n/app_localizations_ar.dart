// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get commonClose => 'إغلاق';

  @override
  String get authLoginTitle => 'تسجيل الدخول';

  @override
  String get authLoginSubtitle => 'مرحباً بك، يرجى تسجيل الدخول للمتابعة';

  @override
  String get authUsernameHint => 'اسم المستخدم';

  @override
  String get authPasswordHint => 'كلمة المرور';

  @override
  String get authRememberMe => 'تذكرني';

  @override
  String get authForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get authSkip => 'تخطي';

  @override
  String get authLoginButton => 'تسجيل الدخول';

  @override
  String get authRegisterTitle => 'إنشاء حساب';

  @override
  String get authRegisterButton => 'إنشاء حساب';

  @override
  String get authEmailHint => 'البريد الإلكتروني';

  @override
  String get authPhoneHint => 'رقم الجوال';

  @override
  String get authConfirmPasswordHint => 'تأكيد كلمة المرور';

  @override
  String get authLoginSuccess => 'تم تسجيل الدخول بنجاح.';

  @override
  String get authRegisterSuccess => 'تم إنشاء الحساب بنجاح.';

  @override
  String get authEnterUsername => 'يرجى إدخال اسم المستخدم';

  @override
  String get authUsernameMinLength =>
      'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';

  @override
  String get authEnterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get authPasswordMinLength =>
      'كلمة المرور يجب أن تكون 6 أحرف على الأقل';

  @override
  String get authEnterEmailValid => 'يرجى إدخال بريد إلكتروني صالح';

  @override
  String get authEnterPhone => 'يرجى إدخال رقم جوال';

  @override
  String get authEnterConfirmPassword => 'يرجى تأكيد كلمة المرور';

  @override
  String get authPasswordsDoNotMatch => 'كلمة المرور غير متطابقة';

  @override
  String get authErrorGenericLogin =>
      'حدث خطأ غير متوقع أثناء تسجيل الدخول. حاول مرة أخرى لاحقاً.';

  @override
  String get authErrorGenericRegister =>
      'تعذّر إنشاء الحساب. يرجى المحاولة مرة أخرى لاحقاً.';

  @override
  String get authErrorNoInternet =>
      'تعذر الاتصال. يرجى التحقق من اتصال الإنترنت.';

  @override
  String get authErrorTimeout => 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.';

  @override
  String get authErrorInvalidCredentials =>
      'بيانات تسجيل الدخول غير صحيحة. يرجى التحقق من اسم المستخدم أو كلمة المرور.';

  @override
  String get authErrorServerIssue =>
      'نواجه مشكلة في الخادم حالياً. يرجى المحاولة لاحقاً.';

  @override
  String get authErrorEmailExists =>
      'هذا البريد الإلكتروني مسجل بالفعل. يرجى تسجيل الدخول بدلاً من ذلك.';

  @override
  String get authErrorUsernameExists =>
      'اسم المستخدم مستخدم بالفعل. يرجى اختيار اسم آخر.';

  @override
  String get authErrorInvalidEmail => 'يرجى إدخال بريد إلكتروني صحيح.';

  @override
  String get authErrorWeakPassword =>
      'كلمة المرور ضعيفة. يرجى اختيار كلمة مرور أقوى.';
}
