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

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md.h),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Center(
              child: Column(
                children: [
                  SizedBox(height: AppSpacing.xl),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 44.s,
                        height: 44.s,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                        alignment: Alignment.center,
                        child: icon,
                      ),

                      SizedBox(width: AppSpacing.md.w),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            textDirection: TextDirection.rtl,
                            style: AppTypography.titleMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs.h),
                          Text(
                            '$itemCount مورد',
                            textDirection: TextDirection.rtl,
                            style: AppTypography.withFaNum(
                              AppTypography.bodyMedium.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0.s,
            left: -8.s,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit?.call();
                } else if (value == 'delete') {
                  onDelete?.call();
                }
              },
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.more_vert_rounded,
                size: AppSizes.iconMd.s,
                color: colors.textSecondary,
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                PopupMenuItem(value: 'delete', child: Text('حذف')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
