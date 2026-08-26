import 'package:flutter/material.dart';
import 'package:keyva/core/gen/assets.gen.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final logo = context.isDark
        ? Assets.images.logoDarkMode
        : Assets.images.logoLightMode;
    final logoSize = compact ? AppSizes.itemHeight.s : 72.s;

    return Column(
      children: [
        logo.image(width: logoSize, height: logoSize, fit: BoxFit.contain),
        SizedBox(height: AppSpacing.sm.h),
        Text(
          'کیوا',
          style: AppTypography.headlineMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
