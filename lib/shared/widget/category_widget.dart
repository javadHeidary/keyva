import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class CategoryCardWidget extends StatelessWidget {
  const CategoryCardWidget({
    super.key,
    required this.title,
    required this.itemCount,
    required this.icon,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  final String title;
  final int itemCount;
  final Widget icon;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shadows = context.shadows;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md.h),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          boxShadow: shadows.card,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(height: 40.s, child: icon),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  '$itemCount مورد',
                  style: AppTypography.labelLarge.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
            Positioned(
              top: 10.s,
              left: 0,
              child: _ActionIcon(
                icon: Icon(
                  Icons.edit_rounded,
                  size: AppSizes.iconSm.s,
                  color: colors.textSecondary,
                ),
                onTap: onEdit,
              ),
            ),
            Positioned(
              top: 10.s,
              left: 25.s,
              child: _ActionIcon(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: AppSizes.iconSm.s,
                  color: colors.textSecondary,
                ),
                onTap: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, this.onTap});

  final Widget icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: icon,
    );
  }
}
