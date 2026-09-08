import 'package:flutter/material.dart';

/// Design tokens for 반짝산책 UIUX spec v0.4 (light only).
abstract final class AppColors {
  static const Color bg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF7F7F5);
  static const Color primary = Color(0xFFFF6B4A);
  static const Color primarySoft = Color(0xFFFFE5DE);
  static const Color secondary = Color(0xFF3DB8A0);
  static const Color text = Color(0xFF1A1A1A);
  static const Color textMuted = Color(0xFF8E8E8E);
  static const Color border = Color(0xFFEFEFEF);
  static const Color danger = Color(0xFFE5484D);
  static const Color tabInactive = Color(0xFFB0B0B0);
  static const Color overlay = Color(0x66000000);
  static const Color onPrimary = Color(0xFFFFFFFF);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AppRadius {
  static const double card = 20;
  static const double button = 16;
  static const double chip = 999;
  static const double sheetTop = 24;
  static const double input = 16;
}

abstract final class AppSizes {
  static const double buttonHeight = 52;
  static const double tabBarHeight = 64;
  static const double socialIcon = 24;
}

abstract final class AppTypography {
  static const String fontFamily = 'Pretendard';

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.4,
    color: AppColors.text,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.2,
    color: AppColors.text,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.text,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.text,
  );
}
