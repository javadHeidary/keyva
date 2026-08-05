import 'package:flutter/material.dart';

class AppResponsive {
  AppResponsive._();

  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double _scaleWidth;
  static late double _scaleHeight;
  static late double _scale;

  static const double _designWidth = 390.0;
  static const double _designHeight = 844.0;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;

    _scaleWidth = screenWidth / _designWidth;
    _scaleHeight = screenHeight / _designHeight;

    _scale = _scaleWidth.clamp(0.85, 1.15);
  }

  static double s(num size) => size * _scale;
  static double sw(num size) => size * _scaleWidth;
  static double sh(num size) => size * _scaleHeight;
  static double sp(num fontSize) => fontSize * _scale.clamp(0.90, 1.10);

  static double wp(num percent) => screenWidth * percent;
  static double hp(num percent) => screenHeight * percent;
}
