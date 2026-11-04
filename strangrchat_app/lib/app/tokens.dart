import 'package:flutter/material.dart';

abstract final class AppTokens {
  static const Color bg = Color(0xFFF7F8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceHigh = Color(0xFFEEF2EC);
  static const Color outline = Color(0xFFD8E1D7);
  static const Color outlineStrong = Color(0xFF7A8F7D);
  static const Color text = Color(0xFF1E2B22);
  static const Color textMuted = Color(0xFF56645A);
  static const Color forest = Color(0xFF355E45);
  static const Color onForest = Color(0xFFFFFFFF);
  static const Color sage = Color(0xFF7E9C80);
  static const Color sageLight = Color(0xFFB8CEB8);
  static const Color sageSoft = Color(0xFFDCE8DA);
  static const Color success = Color(0xFF286747);
  static const Color danger = Color(0xFFB4233A);

  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;

  static const double radius12 = 12;
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
