import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/shared/icons/app_icons.dart';
import 'package:keyva/shared/widget/app_loading_widger.dart';

class AuthMethodTile extends StatelessWidget {
  const AuthMethodTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLoading = false,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDisabled = !enabled || isLoading;

    return Material(
      color: colors.secondaryButton,
      borderRadius: BorderRadius.circular(AppRadius.card.s),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.card.s),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: AppSizes.itemHeight.h),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg.s,
              vertical: AppSpacing.md.h,
            ),
            child: Row(
              children: [
                Container(
                  width: AppSizes.iconXl.s + AppSpacing.md.s,
                  height: AppSizes.iconXl.s + AppSpacing.md.s,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.input,
                    borderRadius: BorderRadius.circular(AppRadius.medium.s),
                  ),
                  child: Icon(
                    icon,
                    size: AppSizes.iconLg.s,
                    color: colors.primary,
                  ),
                ),
                SizedBox(width: AppSpacing.lg.s),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (isLoading)
                  AppLoadingWidget.inline(color: colors.primary)
                else
                  Icon(
                    AppIcon.chevronLeft,
                    size: AppSizes.iconMd.s,
                    color: colors.textTertiary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
