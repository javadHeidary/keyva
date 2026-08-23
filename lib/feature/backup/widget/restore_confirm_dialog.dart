import 'package:flutter/material.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';

Future<bool> showRestoreConfirmDialog(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmText,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: context.colors.overlay,
    barrierDismissible: false,
    builder: (dialogContext) {
      final colors = dialogContext.colors;
      return Dialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.xl.h),
              AppButtonWidget(
                key: const Key('backup-restore-confirm'),
                title: confirmText,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
              SizedBox(height: AppSpacing.sm.h),
              TextButton(
                key: const Key('backup-restore-cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'انصراف',
                  style: AppTypography.button.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return confirmed == true;
}
