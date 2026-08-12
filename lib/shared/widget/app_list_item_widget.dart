import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class AppListItemWidget extends StatelessWidget {
  const AppListItemWidget({
    super.key,
    this.leadingIcon,
    this.onLeadingPressed,
    this.trailingIcon,
    this.title,
    this.subtitle,
    this.onTap,
    this.height,
    this.padding,
  });

  final Widget? leadingIcon;
  final VoidCallback? onLeadingPressed;
  final Widget? trailingIcon;
  final String? title;
  final String? subtitle;
  final VoidCallback? onTap;
  final double? height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height ?? AppSizes.itemHeight.h,
          child: Padding(
            padding:
                padding ??
                EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg.s,
                  vertical: AppSpacing.sm.s,
                ),
            child: Row(
              children: [
                if (trailingIcon != null) ...[
                  trailingIcon!,
                  SizedBox(width: AppSpacing.md.s),
                ],

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: AppTypography.titleMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (title != null && subtitle != null)
                        SizedBox(height: 2.s),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                if (leadingIcon != null) ...[
                  SizedBox(width: AppSpacing.md.s),
                  GestureDetector(
                    onTap: onLeadingPressed,
                    behavior: HitTestBehavior.opaque,
                    child: leadingIcon!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
