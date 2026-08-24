import 'package:flutter/material.dart';

abstract interface class CachedRemoteImage {
  Widget build({
    required String url,
    required double width,
    required double height,
    required BoxFit fit,
    String? cacheKey,
    required Widget errorWidget,
    Widget? placeholder,
  });
}
