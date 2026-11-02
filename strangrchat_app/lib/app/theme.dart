import 'package:flutter/material.dart';

class AppTheme {
  // Brand Color Tokens
  static const Color primaryCoral = Color(0xFFFF6B61);
  static const Color deepPlum = Color(0X4A234F);
  static const Color warmIvory = Color(0xFFFFF9F5);
  static const Color softBlush = Color(0xFFFCE8E4);
  static const Color mainText = Color(0xFF29232D);
  static const Color secondaryText = Color(0xFF6E6572);
  static const Color border = Color(0xFFE9DFE3);
  static const Color surface = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: warmIvory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryCoral,
        primary: primaryCoral,
        secondary: deepPlum,
        surface: surface,
        onSurface: mainText,
        error: primaryCoral,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: mainText, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: mainText, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: mainText, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: mainText, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: mainText, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: mainText, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: mainText, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: mainText, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: mainText, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: mainText),
        bodyMedium: TextStyle(color: secondaryText),
        bodySmall: TextStyle(color: secondaryText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryCoral, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCoral,
          foregroundColor: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
