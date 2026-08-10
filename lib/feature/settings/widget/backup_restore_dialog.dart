import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';

Future<void> showBackupRestoreDialog(BuildContext context) {
  final controller = Get.find<SettingsViewModel>();

  return showDialog<void>(
    context: context,
    barrierColor: context.colors.overlay,
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
                'پشتیبان‌گیری و بازیابی',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
              Text(
                'فایل پشتیبان به‌صورت محلی و رمزنگاری‌شده ذخیره می‌شود. '
                'در این فاز فقط رابط کاربری نمایش داده می‌شود.',
                textAlign: TextAlign.right,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.xl.h),
              AppButtonWidget(
                title: 'ایجاد پشتیبان',
                icon: const Icon(Icons.upload_rounded),
                onPressed: () {
                  controller.onBackupExportTap(dialogContext);
                },
              ),
              SizedBox(height: AppSpacing.sm.h),
              AppButtonWidget(
                title: 'بازیابی از پشتیبان',
                backgroundColor: colors.input,
                foregroundColor: colors.textPrimary,
                icon: Icon(Icons.download_rounded, color: colors.textPrimary),
                onPressed: () {
                  controller.onBackupImportTap(dialogContext);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
