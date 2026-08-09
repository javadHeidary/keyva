import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class LoginCircleIcon extends StatelessWidget {
  const LoginCircleIcon({super.key, required this.icon, this.size});

  final Widget icon;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimension = size ?? 40.s;

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: colors.input,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Center(child: icon),
    );
  }
}
