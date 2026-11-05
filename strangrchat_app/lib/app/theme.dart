import 'package:flutter/material.dart';

import 'tokens.dart';

class AppTheme {
  static const Color primaryCoral = AppTokens.forest;
  static const Color deepPlum = AppTokens.sage;
  static const Color warmIvory = AppTokens.bg;
  static const Color softBlush = AppTokens.sageSoft;
  static const Color mainText = AppTokens.text;
  static const Color secondaryText = AppTokens.textMuted;
  static const Color border = AppTokens.outline;
  static const Color surface = AppTokens.surface;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppTokens.bg,
      colorScheme: const ColorScheme.light(
        primary: AppTokens.coralDeep,
        onPrimary: AppTokens.onCoralDeep,
        secondary: AppTokens.tangerine,
        onSecondary: AppTokens.ink,
        surface: AppTokens.surface,
        onSurface: AppTokens.ink,
        error: AppTokens.danger,
        onError: AppTokens.onCoralDeep,
        outline: AppTokens.outlineStrong,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppTokens.text,
          fontSize: 40,
          height: 1.1,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          color: AppTokens.text,
          fontSize: 32,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        displaySmall: TextStyle(
          color: AppTokens.text,
          fontSize: 28,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        headlineLarge: TextStyle(
          color: AppTokens.text,
          fontSize: 24,
          height: 1.25,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        headlineMedium: TextStyle(
          color: AppTokens.text,
          fontSize: 20,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: TextStyle(
          color: AppTokens.text,
          fontSize: 18,
          height: 1.33,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: AppTokens.text,
          fontSize: 18,
          height: 1.33,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppTokens.text,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: AppTokens.text,
          fontSize: 13,
          height: 1.23,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        bodyLarge: TextStyle(color: AppTokens.text, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(
          color: AppTokens.textMuted,
          fontSize: 14,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          color: AppTokens.textMuted,
          fontSize: 12,
          height: 1.33,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius20),
          borderSide: const BorderSide(color: AppTokens.outlineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius20),
          borderSide: const BorderSide(color: AppTokens.outlineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius20),
          borderSide: const BorderSide(color: AppTokens.coralDeep, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.coralDeep,
          foregroundColor: AppTokens.onCoralDeep,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            vertical: AppTokens.space16,
            horizontal: AppTokens.space24,
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppTokens.coralDeep,
          foregroundColor: AppTokens.onCoralDeep,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            vertical: AppTokens.space16,
            horizontal: AppTokens.space24,
          ),
        ),
      ),
    );
  }
}
