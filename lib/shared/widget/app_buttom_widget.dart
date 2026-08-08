import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

class AppButton extends StatelessWidget {
  AppButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
    this.height,
    this.width,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
  });

  final String title;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final Widget? icon;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? textStyle;
  final Duration duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final bool isDisabled = !enabled || isLoading || onPressed == null;

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? AppSizes.primaryButtonHeight.s,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? colors.primary,
          foregroundColor: foregroundColor ?? colors.onPrimary,
          disabledBackgroundColor: colors.disabled,
          disabledForegroundColor: colors.textTertiary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button.s),
          ),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.s),
          textStyle: textStyle ?? AppTypography.button,
        ),
        child: AnimatedSwitcher(
          duration: duration,
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 22.s,
                  height: 22.s,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.s,
                    color: foregroundColor ?? colors.onPrimary,
                  ),
                )
              : Row(
                  key: const ValueKey('content'),
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      SizedBox(width: AppSpacing.sm.s),
                    ],
                    Text(title, style: textStyle ?? AppTypography.button),
                  ],
                ),
        ),
      ),
    );
  }
}
