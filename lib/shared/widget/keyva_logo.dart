import 'package:flutter/material.dart';
import 'package:keyva/core/gen/assets.gen.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class KeyvaLogo extends StatelessWidget {
  const KeyvaLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final logo = context.isDark
        ? Assets.images.logoDarkMode
        : Assets.images.logoLightMode;

    return logo.image(
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
