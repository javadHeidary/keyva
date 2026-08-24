import 'package:flutter/material.dart';
import 'package:keyva/core/di/injection_container.dart';
import 'package:keyva/core/image/cached_remote_image.dart';

class AppCachedRemoteImage extends StatelessWidget {
  const AppCachedRemoteImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    required this.errorWidget,
    this.fit = BoxFit.cover,
    this.cacheKey,
    this.placeholder,
    this.loader,
  });

  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final String? cacheKey;
  final Widget errorWidget;
  final Widget? placeholder;
  final CachedRemoteImage? loader;

  @override
  Widget build(BuildContext context) {
    final imageLoader = loader ?? _loaderFromGetIt();
    if (imageLoader == null) {
      return SizedBox(width: width, height: height, child: errorWidget);
    }

    return imageLoader.build(
      url: url,
      width: width,
      height: height,
      fit: fit,
      cacheKey: cacheKey,
      errorWidget: errorWidget,
      placeholder: placeholder,
    );
  }

  CachedRemoteImage? _loaderFromGetIt() {
    if (getIt.isRegistered<CachedRemoteImage>()) {
      return getIt<CachedRemoteImage>();
    }
    return null;
  }
}
