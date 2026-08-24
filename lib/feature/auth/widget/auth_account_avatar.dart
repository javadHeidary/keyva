import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/shared/icons/app_icons.dart';

class AuthAccountAvatar extends StatelessWidget {
  const AuthAccountAvatar({
    super.key,
    required this.username,
    this.size,
  });

  final String username;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolvedSize = size ?? AppSizes.itemHeight.s;
    final trimmed = username.trim();

    return Container(
      width: resolvedSize,
      height: resolvedSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.strengthBarBg,
        borderRadius: BorderRadius.circular(AppRadius.xLarge.s),
      ),
      child: trimmed.isEmpty
          ? Icon(
              AppIcon.lock,
              size: AppSizes.iconLg.s,
              color: colors.textSecondary,
            )
          : Text(
              String.fromCharCodes(trimmed.runes.take(1)),
              style: AppTypography.titleLarge.copyWith(
                color: colors.textPrimary,
              ),
            ),
    );
  }
}
