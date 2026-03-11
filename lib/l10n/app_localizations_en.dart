// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonClose => 'Close';

  @override
  String get authLoginTitle => 'Login';

  @override
  String get authLoginSubtitle => 'Welcome back, please login to continue';

  @override
  String get authUsernameHint => 'Username';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authRememberMe => 'Remember me';

  @override
  String get authForgotPassword => 'Forgot Password?';

  @override
  String get authSkip => 'Skip';

  @override
  String get authLoginButton => 'Login';

  @override
  String get authRegisterTitle => 'Register';

  @override
  String get authRegisterButton => 'Register';

  @override
  String get authEmailHint => 'Email';

  @override
  String get authPhoneHint => 'Phone';

  @override
  String get authConfirmPasswordHint => 'Confirm Password';

  @override
  String get authLoginSuccess => 'Signed in successfully.';

  @override
  String get authRegisterSuccess => 'Account created successfully.';

  @override
  String get authEnterUsername => 'Please enter username';

  @override
  String get authUsernameMinLength => 'Username must be at least 3 characters';

  @override
  String get authEnterPassword => 'Please enter password';

  @override
  String get authPasswordMinLength => 'Password must be at least 6 characters';

  @override
  String get authEnterEmailValid => 'Please enter a valid email';

  @override
  String get authEnterPhone => 'Please enter a phone number';

  @override
  String get authEnterConfirmPassword => 'Please confirm your password';

  @override
  String get authPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get authErrorGenericLogin =>
      'An unexpected error occurred while logging in. Please try again later.';

  @override
  String get authErrorGenericRegister =>
      'We couldn\'t create your account. Please try again later.';

  @override
  String get authErrorNoInternet =>
      'Unable to connect. Please check your internet connection.';

  @override
  String get authErrorTimeout => 'The connection timed out. Please try again.';

  @override
  String get authErrorInvalidCredentials =>
      'The login details are incorrect. Please check your username or password.';

  @override
  String get authErrorServerIssue =>
      'We are experiencing a server issue right now. Please try again later.';

  @override
  String get authErrorEmailExists =>
      'This email is already registered. Please sign in instead.';

  @override
  String get authErrorUsernameExists =>
      'This username is already taken. Please choose another.';

  @override
  String get authErrorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get authErrorWeakPassword =>
      'Your password is too weak. Please choose a stronger one.';
}
