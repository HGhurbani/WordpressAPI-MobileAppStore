import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6FE0DA); // فيروزي
  static const Color secondaryColor = Color(0xFF1A2543); // أزرق داكن
  static const Color backgroundColor = Color(0xFFF0FDFD); // خلفية ناعمة

  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'Cairo',
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
      ),
    );
  }
}
