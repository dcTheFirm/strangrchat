import 'package:flutter/material.dart';

abstract final class AppTokens {
  static const Color bg = Color(0xFFFFF8F4);
  static const Color surface = Color(0xFFFFFEFC);
  static const Color surfaceHigh = Color(0xFFFFF0E8);
  static const Color peach = Color(0xFFFFD6C2);
  static const Color blush = Color(0xFFF5C2D7);
  static const Color lavender = Color(0xFFD8B3E5);
  static const Color coral = Color(0xFFF15B50);
  static const Color coralDeep = Color(0xFFB94336);
  static const Color tangerine = Color(0xFFFF913F);
  static const Color ink = Color(0xFF211C1B);
  static const Color muted = Color(0xFF756B69);
  static const Color line = Color(0xFFEDE3DE);
  static const Color navDark = Color(0xFF211C1B);
  static const Color success = Color(0xFF187A58);
  static const Color danger = Color(0xFFB4233A);
  static const Color onCoralDeep = Color(0xFFFFFFFF);

  static const Color outlineStrong = Color(0xFF9B857A);

  static const Color text = ink;
  static const Color textMuted = muted;
  static const Color outline = line;
  static const Color forest = coralDeep;
  static const Color onForest = onCoralDeep;
  static const Color sage = coral;
  static const Color sageLight = tangerine;
  static const Color sageSoft = peach;

  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;

  static const double radius12 = 12;
  static const double radius16 = 16;
  static const double radius20 = 20;
  static const double radius28 = 28;

  static const double iconSmall = 16;
  static const double iconMedium = 20;
  static const double iconLarge = 24;
  static const double sheetHandleWidth = 36;

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 380);
  static const Duration orbBreath = Duration(milliseconds: 4000);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve move = Curves.easeInOutCubicEmphasized;
}
