import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_sizes.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';

enum AppDialogType { info, success, warning, error, simple }

class AppDialogWidget extends StatelessWidget {
  final AppDialogType type;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback? onConfirm;
  final Widget? customIcon;

  const AppDialogWidget({
    super.key,
    this.type = AppDialogType.info,
    required this.title,
    required this.description,
    this.buttonText = 'متوجه شدم',
    this.onConfirm,
    this.customIcon,
  });

  static Future<void> show(
    BuildContext context, {
    AppDialogType type = AppDialogType.info,
    required String title,
    required String description,
    String buttonText = 'متوجه شدم',
    VoidCallback? onConfirm,
    Widget? customIcon,
    bool barrierDismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: context.colors.overlay,
      builder: (context) => AppDialogWidget(
        type: type,
        title: title,
        description: description,
        buttonText: buttonText,
        onConfirm: onConfirm,
        customIcon: customIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final visuals = _resolveVisuals(colors);

    return Dialog(
      backgroundColor: colors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.modal),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 24.s),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl.s,
          AppSpacing.xxl.s,
          AppSpacing.xl.s,
          AppSpacing.xl.s,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64.s,
              height: 64.s,
              decoration: BoxDecoration(
                color: visuals.bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(child: customIcon ?? visuals.icon),
            ),

            SizedBox(height: AppSpacing.xl.s),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headlineSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),

            SizedBox(height: AppSpacing.sm.s),

            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),

            SizedBox(height: AppSpacing.xxl.s),

            // Button
            SizedBox(
              width: double.infinity,
              height: AppSizes.primaryButtonHeight.s,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: AppTypography.button.copyWith(color: colors.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _DialogVisuals _resolveVisuals(AppColorsExtension colors) {
    switch (type) {
      case AppDialogType.info:
        return _DialogVisuals(
          icon: Icon(Icons.info_outline_rounded, size: 32.s, color: colors.primary),
          bgColor: colors.primary.withOpacity(0.12),
        );
      case AppDialogType.success:
        return _DialogVisuals(
          icon: Icon(
            Icons.check_circle_outline_rounded,
            size: 32.s,
            color: colors.success,
          ),
          bgColor: colors.success.withOpacity(0.12),
        );
      case AppDialogType.warning:
        return _DialogVisuals(
          icon: Icon(Icons.warning_amber_rounded, size: 32.s, color: colors.warning),
          bgColor: colors.warning.withOpacity(0.12),
        );
      case AppDialogType.error:
        return _DialogVisuals(
          icon: Icon(Icons.error_outline_rounded, size: 32.s, color: colors.error),
          bgColor: colors.error.withOpacity(0.12),
        );
      case AppDialogType.simple:
        return _DialogVisuals(
          icon: Icon(
            Icons.info_outline_rounded,
            size: 32.s,
            color: colors.textSecondary,
          ),
          bgColor: colors.secondaryButton,
        );
    }
  }
}

class _DialogVisuals {
  final Widget icon;
  final Color bgColor;

  const _DialogVisuals({
    required this.icon,
    required this.bgColor,
  });
}
