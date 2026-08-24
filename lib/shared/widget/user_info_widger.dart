import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/shared/widget/keyva_logo.dart';

class UserInfoWidget extends StatelessWidget {
  const UserInfoWidget({
    super.key,
    required this.name,
    this.onEdit,
  });

  final String name;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.s,
        vertical: AppSpacing.sm.s + 2.s,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48.s,
            height: 48.s,
            child: KeyvaLogo(size: 48.s),
          ),

          SizedBox(width: AppSpacing.md.s),

          // Name
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),

          // Edit icon
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Padding(
                padding: EdgeInsets.all(6.s),
                child: Icon(
                  Icons.edit_rounded,
                  size: AppSizes.iconMd.s,
                  color: colors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
