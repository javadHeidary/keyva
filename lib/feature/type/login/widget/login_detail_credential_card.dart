import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class LoginDetailCredentialCard extends StatelessWidget {
  const LoginDetailCredentialCard({
    super.key,
    this.icon,
    required this.label,
    required this.value,
    this.leading,
    this.iconBackgroundColor,
    this.iconColor,
    this.maxLines = 1,
    this.trailing,
  }) : assert(icon != null || leading != null, 'icon or leading is required');

  final IconData? icon;
  final String label;
  final String value;
  final Widget? leading;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final int maxLines;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final badgeBg =
        iconBackgroundColor ?? colors.primary.withValues(alpha: 0.12);
    final badgeIconColor = iconColor ?? colors.primary;

    final Widget leadingBadge = leading != null
        ? SizedBox(width: 44.s, height: 44.s, child: leading)
        : Container(
            width: 44.s,
            height: 44.s,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Icon(icon!, size: AppSizes.iconMd.s, color: badgeIconColor),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: context.shadows.card,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg.s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            leadingBadge,
            SizedBox(width: AppSpacing.md.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs.s),
                  Text(
                    value.isEmpty ? '—' : value,
                    style: AppTypography.titleMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class LoginDetailsSectionLabel extends StatelessWidget {
  const LoginDetailsSectionLabel({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: AppSpacing.xs.s, bottom: AppSpacing.sm.h),
      child: Text(
        title,
        style: AppTypography.labelMedium.copyWith(
          color: context.colors.textTertiary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class LoginDetailActionIcon extends StatelessWidget {
  const LoginDetailActionIcon({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: AppSizes.iconMd.s, color: colors.textSecondary),
      padding: EdgeInsets.all(AppSpacing.xs.s),
      constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    );
  }
}
