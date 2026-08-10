import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';

Future<void> showChangeMasterPasswordDialog(BuildContext context) {
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'تغییر رمز اصلی',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.lg.h),
                AppTextFieldWidget(
                  controller: currentController,
                  labelText: 'رمز اصلی فعلی',
                  obscureText: true,
                  textDirection: TextDirection.ltr,
                ),
                SizedBox(height: AppSpacing.md.h),
                AppTextFieldWidget(
                  controller: newController,
                  labelText: 'رمز اصلی جدید',
                  obscureText: true,
                  textDirection: TextDirection.ltr,
                ),
                SizedBox(height: AppSpacing.md.h),
                AppTextFieldWidget(
                  controller: confirmController,
                  labelText: 'تکرار رمز جدید',
                  obscureText: true,
                  textDirection: TextDirection.ltr,
                ),
                SizedBox(height: AppSpacing.xl.h),
                AppButtonWidget(
                  title: 'تأیید',
                  onPressed: () => controller.onChangeMasterPasswordSubmitted(
                    currentPassword: currentController.text,
                    newPassword: newController.text,
                    confirmPassword: confirmController.text,
                    context: dialogContext,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
