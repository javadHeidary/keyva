import 'package:flutter/material.dart';
import 'package:keyva/core/image/cached_remote_image.dart';

class FakeCachedRemoteImage implements CachedRemoteImage {
  FakeCachedRemoteImage({this.fail = false});

  final bool fail;
  String? lastUrl;
  String? lastCacheKey;

  @override
  Widget build({
    required String url,
    required double width,
    required double height,
    required BoxFit fit,
    String? cacheKey,
    required Widget errorWidget,
    Widget? placeholder,
  }) {
    lastUrl = url;
    lastCacheKey = cacheKey;
    if (fail) {
      return errorWidget;
    }
    return SizedBox(
      key: const Key('fake-cached-remote-image'),
      width: width,
      height: height,
      child: const ColoredBox(color: Color(0xFF2E7D32)),
    );
  }
}
