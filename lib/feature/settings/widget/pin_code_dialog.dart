import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keyva/core/theme/app_radius.dart';
import 'package:keyva/core/theme/app_spacing.dart';
import 'package:keyva/core/theme/app_typography.dart';
import 'package:keyva/core/theme/extensions/responsive_extentions.dart';
import 'package:keyva/core/theme/extensions/theme_extentions.dart';
import 'package:keyva/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:keyva/shared/widget/app_buttom_widget.dart';
import 'package:keyva/shared/widget/app_textfield_widget.dart';

Future<void> showPinCodeDialog(BuildContext context) {
  final pinController = TextEditingController();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تنظیم کد PIN',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
              AppTextFieldWidget(
                controller: pinController,
                labelText: 'کد PIN',
                obscureText: true,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              SizedBox(height: AppSpacing.md.h),
              AppTextFieldWidget(
                controller: confirmController,
                labelText: 'تکرار PIN',
                obscureText: true,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              SizedBox(height: AppSpacing.xl.h),
              AppButtonWidget(
                title: 'ذخیره',
                onPressed: () => controller.onPinSubmitted(
                  pin: pinController.text,
                  confirmPin: confirmController.text,
                  context: dialogContext,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
