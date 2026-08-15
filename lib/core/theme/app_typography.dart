import 'package:flutter/material.dart';

/// Typography system
/// Supports both Persian (RTL) and English
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Kalameh';
  static const String fontFamilyFaNum = 'Kalameh(FaNum)';

  static TextStyle withFaNum(TextStyle style) {
    return style.copyWith(fontFamily: fontFamilyFaNum);
  }

  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    Color? color,
    letterSpacing,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
      letterSpacing: letterSpacing,
      fontFamily: fontFamily,
    );
  }

  // Display
  static TextStyle displayLarge = _base(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static TextStyle displayMedium = _base(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static TextStyle displaySmall = _base(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Headline
  static TextStyle headlineLarge = _base(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static TextStyle headlineMedium = _base(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static TextStyle headlineSmall = _base(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Title
  static TextStyle titleLarge = _base(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle titleMedium = _base(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle titleSmall = _base(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body
  static TextStyle bodyLarge = _base(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodyMedium = _base(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodySmall = _base(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  // Label
  static TextStyle labelLarge = _base(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle labelMedium = _base(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  static TextStyle labelSmall = _base(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  // Button text
  static TextStyle button = _base(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
  );
}
