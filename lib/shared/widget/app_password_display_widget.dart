import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class AppPasswordDisplayWiget extends StatelessWidget {
  const AppPasswordDisplayWiget({
    super.key,
    required this.password,
    required this.isVisible,
    required this.onToggleVisibility,
    required this.onCopy,
    required this.leadingIcon,
    this.trailingIcon,
    this.height,
    this.padding,
  });

  final String password;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onCopy;
  final Widget? trailingIcon;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Widget leadingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: height ?? AppSizes.itemHeight.s,
      child: Padding(
        padding:
            padding ??
            EdgeInsets.symmetric(
              horizontal: AppSpacing.lg.s,
              vertical: AppSpacing.sm.s,
            ),
        child: Row(
          children: [
            leadingIcon,
            SizedBox(width: AppSpacing.sm.s),

            SizedBox(width: AppSpacing.md.s),
            Expanded(
              child: Text(
                password.isEmpty
                    ? ''
                    : isVisible
                    ? password
                    : '•' * password.length,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textPrimary,
                  letterSpacing: isVisible ? 0 : 1.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailingIcon != null) ...[
              SizedBox(width: AppSpacing.md.s),
              trailingIcon!,
            ],
            GestureDetector(
              onTap: onCopy,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.copy_rounded,
                size: AppSizes.iconMd.s,
                color: colors.textSecondary,
              ),
            ),
            SizedBox(width: AppSpacing.sm.s),
            GestureDetector(
              onTap: onToggleVisibility,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                isVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: AppSizes.iconMd.s,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// example usage
// Obx(() => AppPasswordDisplay(
//   password: controller.generatedPassword.value,
//   isVisible: controller.isPasswordVisible.value,
//   onToggleVisibility: controller.togglePasswordVisibility,
//   onCopy: controller.copyPassword,
// ))