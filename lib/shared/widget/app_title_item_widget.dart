import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class AppTitleItemWidget extends StatelessWidget {
  final String? title;
  const AppTitleItemWidget({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(right: AppSpacing.xs.s, bottom: AppSpacing.sm.h),
      child: Text(
        title ?? '',
        style: AppTypography.titleMedium.copyWith(color: colors.textPrimary),
      ),
    );
  }
}
