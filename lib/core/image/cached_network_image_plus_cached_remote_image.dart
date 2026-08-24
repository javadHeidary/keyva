import 'package:flutter/material.dart';
import 'package:cached_network_image_plus/flutter_cached_network_image_plus.dart';
import 'package:keyva/core/image/cached_remote_image.dart';

class CachedNetworkImagePlusCachedRemoteImage implements CachedRemoteImage {
  const CachedNetworkImagePlusCachedRemoteImage();

  static const _quietShimmer = Color.fromRGBO(232, 232, 232, 1);

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
    return CacheNetworkImagePlus(
      imageUrl: url,
      width: width,
      height: height,
      boxFit: fit,
      cacheKey: cacheKey,
      errorWidget: errorWidget,
      backgroundColor: _quietShimmer,
      shimmerBaseColor: _quietShimmer,
      shimmerHighlightColor: _quietShimmer,
      shimmerBackColor: _quietShimmer,
    );
  }
}
